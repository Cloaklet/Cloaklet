package main

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework AppKit
#include "rif.h"
*/
import "C"
import (
	"os"
	"unsafe"
)

// RevealInFinder calls an Objective-C function (C_RevealInFinder defined in rif.h)
// to select given `path` in its parent directory in Finder.
func RevealInFinder(path string) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))
	C.C_RevealInFinder(cPath)
}

// FUSEAvailable tells if FUSE for Mac (a.k.a. OSXFUSE) is installed
func FUSEAvailable() bool {
	const loadBin string = "/Library/Filesystems/osxfuse.fs/Contents/Resources/load_osxfuse"
	if info, err := os.Stat(loadBin); err == nil {
		return !info.IsDir()
	}
	return false
}
