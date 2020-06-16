package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	"github.com/go-qamel/qamel"
)

// VaultManager manages vault unlocking / locking. It does not manage vault information storage.
type VaultManager struct {
	qamel.QmlObject
	_         func()                   `constructor:"init"`
	_         func(string, string) int `slot:"unlockVault"`
	_         func(string) int         `slot:"lockVault"`
	_         func(string) bool        `slot:"vaultUnlocked"`
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
	if vm.vaultUnlocked(vaultPath) {
		return 1
	}
	mountPoint, err := ioutil.TempDir("", "")
	if err != nil {
		return 2
	}

	args := []string{
		"-fg",
		"-extpass", "echo",
		"-extpass", password, // TODO Maybe quoting is required?
		vaultPath, mountPoint,
	}
	fmt.Printf("gocryptfs %s", strings.Join(args, " "))
	vm.processes[vaultPath] = exec.Command("gocryptfs", args...)
	vm.processes[vaultPath].Start()
	if vm.processes[vaultPath].Process == nil {
		return 3
	}
	return 0
}

// lockVault stops the corresponding gocryptfs process, return code 0 means ok
func (vm *VaultManager) lockVault(vaultPath string) int {
	if cmd, ok := vm.processes[vaultPath]; ok {
		if !cmd.ProcessState.Exited() {
			// TODO Improve quiting
			if err := cmd.Process.Signal(os.Interrupt); err != nil {
				return 1
			}
		}
	}
	return 0
}

// vaultUnlocked returns the current unlock state.
// If corresponding gocryptfs process is not alive, the vault is considered locked.
func (vm *VaultManager) vaultUnlocked(vaultPath string) bool {
	if cmd, ok := vm.processes[vaultPath]; ok {
		return !cmd.ProcessState.Exited()
	}
	return false
}
