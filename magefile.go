// +build mage

package main

import (
	"errors"
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
	return sh.RunV("qamel", "build", "--skip-vendoring", "-o", "Cloaklet")
}

// BuildBundle builds the redistributable application bundle
func BuildBundle() error {
	mg.SerialDeps(Clean, InstallDeps, Build)
	os.MkdirAll("Cloaklet.app/Contents/MacOS", 0755)
	os.Rename("Cloaklet", "Cloaklet.app/Contents/MacOS/Cloaklet")
	sh.RunV("cp", "Info.plist", "Cloaklet.app/Contents/Info.plist")
	// Get path of Qt tools directory from qamel profile
	profileContent, err := sh.Output("qamel", "profile", "print")
	if err != nil {
		return err
	}
	qtToolsDir := ""
	for _, line := range strings.Split(profileContent, "\n") {
		if !strings.Contains(line, ":") {
			continue
		}
		opt := strings.SplitN(line, ":", 2)
		if strings.TrimSpace(opt[0]) == "Qmake" {
			qtToolsDir = filepath.Dir(strings.TrimSpace(opt[1]))
			break
		}
	}
	if qtToolsDir == "" {
		return errors.New("failed to locate Qt macdeployqt tool")
	}
	if err = sh.RunV(
		filepath.Join(qtToolsDir, "macdeployqt"),
		"Cloaklet.app",
		"-executable=Cloaklet.app/Contents/MacOS/Cloaklet",
		"-qmldir=res",
	); err != nil {
		return err
	}

	return os.Rename("gocryptfs", "Cloaklet.app/Contents/MacOS/gocryptfs")
}