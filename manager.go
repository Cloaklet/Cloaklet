package main

import (
	"io/ioutil"
	"os"
	"os/exec"
	"syscall"
	"time"

	"github.com/go-qamel/qamel"
)

// VaultManager manages vault unlocking / locking. It does not manage vault information storage.
type VaultManager struct {
	qamel.QmlObject
	_         func()                   `constructor:"init"`
	_         func(string, string) int `slot:"unlockVault"`
	_         func(string) int         `slot:"lockVault"`
	_         func(string)             `signal:"vaultUnlocked"`
	_         func(string)             `signal:"vaultLocked"`
	processes map[string]*exec.Cmd
}

func (vm *VaultManager) init() {
	vm.processes = map[string]*exec.Cmd{}
}

// unlockVault starts a gocryptfs process to unlock and mount the given vault.
// The vault will be mounted to a path with random directory name.
// Return code 0 means ok.
func (vm *VaultManager) unlockVault(vaultPath string, password string) int {
	// FIXME
	if cmd, ok := vm.processes[vaultPath]; ok {
		// Existing process will return <nil> to SIG0
		if err := cmd.Process.Signal(syscall.Signal(0)); err == nil {
			return 1
		}
	}

	mountPoint, err := ioutil.TempDir("", "")
	if err != nil {
		return 2
	}

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
	vm.processes[vaultPath] = exec.Command("gocryptfs", args...)
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
	defer vm.vaultUnlocked(vaultPath)
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
			defer delete(vm.processes, vaultPath)
		}
	}
	defer vm.vaultLocked(vaultPath)
	return 0
}
