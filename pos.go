package main

// #include <stdlib.h>
// #include "pos.h"
import "C"
import "unsafe"

// RegisterQmlMousePos registers MousePos as QML object
func RegisterQmlMousePos(uri string, versionMajor int, versionMinor int, qmlName string) {
	cURI := C.CString(uri)
	cQmlName := C.CString(qmlName)
	cVersionMajor := C.int(int32(versionMajor))
	cVersionMinor := C.int(int32(versionMinor))
	defer func() {
		C.free(unsafe.Pointer(cURI))
		C.free(unsafe.Pointer(cQmlName))
	}()

	C.MousePos_RegisterQML(cURI, cVersionMajor, cVersionMinor, cQmlName)
}
