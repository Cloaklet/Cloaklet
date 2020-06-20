// +build mage

package main

import (
	"fmt"
	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Clean cleans up all built artifacts
func Clean() error {
	if err := sh.Rm("Cloaklet.app"); err != nil {
		return err
	}
	if err := sh.Rm("Cloaklet"); err != nil {
		return err
	}
	if err := sh.Rm("gocryptfs"); err != nil {
		return err
	}
	if err := sh.Rm("vendor"); err != nil {
		return err
	}
	return nil
}

// InstallDeps installs required golang tools
func InstallDeps() error {
	// Require qamel tool to present
	if _, err := exec.LookPath("qamel"); err != nil {
		return err
	}
	// Download gocryptfs binary
	resp, err := http.Get("https://github.com/JokerQyou/Cloaklet/releases/download/pre/gocryptfs_v1.8.0_darwin_catalina-static_amd64")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	binFile, err := os.Create("gocryptfs")
	if err != nil {
		return err
	}
	defer binFile.Close()

	_, err = io.Copy(binFile, resp.Body)
	if err != nil {
		return err
	}

	if err = os.Chmod("gocryptfs", 0755); err != nil {
		return err
	}

	return nil
}

// Build builds the main binary
func Build() error {
	mg.SerialDeps(Clean, InstallDeps)
	// Generate Qt moc header
	qtMocBin, err := findInQamelProfile("moc")
	if err != nil {
		return err
	}
	if err = sh.RunV(qtMocBin, "-o", "moc-extend.h", "extend.h"); err != nil {
		return err
	}
	// Build the binary
	return sh.RunV("qamel", "build", "--skip-vendoring", "-o", "Cloaklet")
}

// findInQamelProfile interprets qamel profile output and finds value of given key
// Notice: `key` is lowercase; Space characters in result is trimmed.
func findInQamelProfile(key string) (v string, err error) {
	var profileContent string
	key = strings.ToLower(key)
	profileContent, err = sh.Output("qamel", "profile", "print")
	if err != nil {
		return
	}
	for _, line := range strings.Split(profileContent, "\n") {
		if !strings.Contains(line, ":") {
			continue
		}
		opt := strings.SplitN(line, ":", 2)
		if strings.TrimSpace(strings.ToLower(opt[0])) == key {
			return strings.TrimSpace(opt[1]), nil
		}
	}
	err = fmt.Errorf("%s not found in qamel profile", key)
	return
}

// BuildBundle builds the redistributable application bundle
func BuildBundle() error {
	mg.SerialDeps(Clean, InstallDeps, Build)

	// Create app bundle structure
	os.MkdirAll("Cloaklet.app/Contents/MacOS", 0755)
	os.Rename("Cloaklet", "Cloaklet.app/Contents/MacOS/Cloaklet")
	sh.RunV("cp", "Info.plist", "Cloaklet.app/Contents/Info.plist")

	// Get path of Qt tools directory from qamel profile
	qtQmakePath, err := findInQamelProfile("Qmake")
	if err != nil {
		return err
	}
	qtToolsDir := filepath.Dir(qtQmakePath)

	// Bundle linked Qt libraries
	if err = sh.RunV(
		filepath.Join(qtToolsDir, "macdeployqt"),
		"Cloaklet.app",
		"-executable=Cloaklet.app/Contents/MacOS/Cloaklet",
		"-qmldir=res",
	); err != nil {
		return err
	}

	// Bundle gocryptfs binary
	return os.Rename("gocryptfs", "Cloaklet.app/Contents/MacOS/gocryptfs")
}
