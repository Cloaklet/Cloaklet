package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/go-qamel/qamel"
)

// VaultManager manages vault unlocking / locking. It does not manage vault information storage.
/*
  Signals (events):
  - vaultUnlocked(vaultPath, mountPoint)
  - vaultLocked(vaultPath)
  - alert(message)
  Slots (methods available to Javascript):
  - unlockVault(vaultPath, password)
  - lockVault(vaultPath)
  - revealVault(vaultPath)
  - revealMountPoint(vaultPath)
  - createNewVault(name, location, password)
  - fuseAvailable()
*/
type VaultManager struct {
	qamel.QmlObject
	_           func()                           `constructor:"init"`
	_           func(string, string) int         `slot:"unlockVault"`
	_           func(string) int                 `slot:"lockVault"`
	_           func(string)                     `slot:"revealVault"`
	_           func(string)                     `slot:"revealMountPoint"`
	_           func(string, string, string) int `slot:"createNewVault"`
	_           func() bool                      `slot:"fuseAvailable"`
	_           func(string, string)             `signal:"vaultUnlocked"`
	_           func(string)                     `signal:"vaultLocked"`
	_           func(string)                     `signal:"alert"`
	processes   map[string]*exec.Cmd
	mountpoints map[string]string
	cmd         string // Path to `gocryptfs` binary
}

func (vm *VaultManager) init() {
	vm.processes = map[string]*exec.Cmd{}
	vm.mountpoints = map[string]string{}

	if executable, err := os.Executable(); err == nil {
		cmdBin := filepath.Join(filepath.Dir(executable), "gocryptfs")
		if _, err := os.Stat(cmdBin); os.IsNotExist(err) {
			cmdBin, err = exec.LookPath("gocryptfs")
			if err != nil {
				logger.Fatal().Err(err).Msg("Failed to find gocryptfs binary")
			}
		}
		vm.cmd = cmdBin
		logger.Info().Str("binary", cmdBin).Msg("Found gocryptfs binary")
	} else {
		logger.Fatal().Err(err).Msg("Failed to get executable directory")
	}
	rand.Seed(time.Now().UnixNano() + int64(os.Getpid()))
}

// unlockVault starts a gocryptfs process to unlock and mount the given vault.
// The vault will be mounted to a path with random directory name.
// Return code 0 means ok.
func (vm *VaultManager) unlockVault(vaultPath string, password string) int {
	if cmd, ok := vm.processes[vaultPath]; ok {
		// Existing process will return <nil> to SIG0
		if err := cmd.Process.Signal(syscall.Signal(0)); err == nil {
			return 1
		}
	}

	mountPoint := filepath.Join("/Volumes", strconv.FormatInt(int64(rand.Int31()), 16))

	// Prepare password file
	pwFile, err := ioutil.TempFile("", "")
	if err != nil {
		return 3
	}
	// TODO gocryptfs seems to be using passfile longer than we expected
	// Just delay for several seconds before deleting it.
	defer func() {
		time.AfterFunc(time.Second*5, func() {
			os.Remove(pwFile.Name())
		})
	}()

	written, err := pwFile.Write([]byte(password))
	defer pwFile.Close()
	if written != len(password) || err != nil {
		return 4
	}

	args := []string{
		"-fg",
		"-passfile", pwFile.Name(),
		vaultPath, mountPoint,
	}
	vm.processes[vaultPath] = exec.Command(vm.cmd, args...)
	vm.mountpoints[vaultPath] = mountPoint
	vm.processes[vaultPath].Start()
	// Seems to be necessary, otherwise the process becomes zombie after exiting.
	go func() {
		if err := vm.processes[vaultPath].Wait(); err != nil {
			// TODO Read from stderr and display the error message to user
			defer vm.vaultLocked(vaultPath)
		}
	}()
	if vm.processes[vaultPath].ProcessState != nil {
		return 5
	}
	defer vm.vaultUnlocked(vaultPath, mountPoint)
	return 0
}

// lockVault stops the corresponding gocryptfs process, return code 0 means ok
func (vm *VaultManager) lockVault(vaultPath string) int {
	if cmd, ok := vm.processes[vaultPath]; ok {
		// Existing process will return <nil> to SIG0
		if err := cmd.Process.Signal(syscall.Signal(0)); err == nil {
			if err = cmd.Process.Signal(os.Interrupt); err != nil {
				return 1
			}
			defer delete(vm.mountpoints, vaultPath)
			defer delete(vm.processes, vaultPath)
		}
	}
	defer vm.vaultLocked(vaultPath)
	return 0
}

// revealVault reveals the encrypted vault in Finder
func (vm *VaultManager) revealVault(vaultPath string) {
	// Finder cannot show hidden items
	if filepath.Base(vaultPath)[0] == '.' {
		return
	}
	// Path does not exist
	if _, err := os.Stat(vaultPath); err != nil && os.IsNotExist(err) {
		return
	}
	RevealInFinder(vaultPath)
}

// revealMountPoint reveals the decrypted mountpoint in Finder for given `vaultPath`
func (vm *VaultManager) revealMountPoint(vaultPath string) {
	if mountPoint, ok := vm.mountpoints[vaultPath]; ok {
		if _, err := os.Stat(mountPoint); err == nil {
			RevealInFinder(mountPoint)
		}
	}
}

// createNewVault creates a vault named `name` in `location` using `password`
// Currently the masterkey is not printed, please remember your password.
func (vm *VaultManager) createNewVault(name string, location string, password string) int {
	// Create vault directory
	vaultDirectory := filepath.Join(location, name)
	info, err := os.Stat(vaultDirectory)
	// An existing file is blocking us from creating the vault directory
	if err == nil && !info.IsDir() {
		return 1
	}
	if err != nil && os.IsNotExist(err) {
		if err = os.MkdirAll(vaultDirectory, 0700); err != nil {
			logger.Error().
				Err(err).
				Str("vaultDirectory", vaultDirectory).
				Msg("Failed to create vault directory")
			return 5
		}
	}
	// Prepare password file
	pwFile, err := ioutil.TempFile("", "")
	if err != nil {
		return 2
	}
	defer os.Remove(pwFile.Name())

	written, err := pwFile.Write([]byte(password))
	defer pwFile.Close()
	if written != len(password) || err != nil {
		return 3
	}

	args := []string{
		"-init",
		"-passfile", pwFile.Name(),
		vaultDirectory,
	}
	fmt.Printf("%s %s", vm.cmd, strings.Join(args, " "))
	ctx, cancel := context.WithTimeout(context.TODO(), time.Second*10)
	defer cancel()
	cmd := exec.CommandContext(ctx, vm.cmd, args...)
	if err := cmd.Run(); err != nil {
		logger.Error().
			Err(err).
			Str("vaultDirectory", vaultDirectory).
			Int("returnCode", cmd.ProcessState.ExitCode()).
			Msg("gocryptfs process exited with error")
		return 4
	}
	return 0
}

// fuseAvailable tells if FUSE for Mac (a.k.a. OSXFUSE) is installed
func (vm *VaultManager) fuseAvailable() bool {
	const loadBin string = "/Library/Filesystems/osxfuse.fs/Contents/Resources/load_osxfuse"
	if info, err := os.Stat(loadBin); err == nil {
		return !info.IsDir()
	}
	return false
}
