package main

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework AppKit
#include "rif.h"
*/
import "C"
import "unsafe"

// RevealInFinder calls an Objective-C function (C_RevealInFinder defined in rif.h)
// to select given `path` in its parent directory in Finder.
func RevealInFinder(path string) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))
	C.C_RevealInFinder(cPath)
}
