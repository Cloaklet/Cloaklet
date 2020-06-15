package main

import (
	"os"

	"github.com/go-qamel/qamel"
)

func init() {
	RegisterQmlMousePos("MousePos", 1, 0, "MousePos")
}

func main() {
	app := qamel.NewApplication(len(os.Args), os.Args)
	app.SetApplicationDisplayName("Cloaklet")

	engine := qamel.NewEngine()
	engine.Load("qrc:/res/main.qml")

	app.Exec()
}
