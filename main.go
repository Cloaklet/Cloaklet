package main

import (
	"os"

	"github.com/go-qamel/qamel"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

var logger zerolog.Logger

func init() {
	logger = log.Logger.With().Str("app", "Cloaklet").Logger()
	RegisterQmlMousePos("MousePos", 1, 0, "MousePos")
	RegisterQmlVaultManager("VaultManager", 1, 0, "VaultManager")
}

func main() {
	app := qamel.NewApplication(len(os.Args), os.Args)
	app.SetApplicationDisplayName("Cloaklet")

	engine := qamel.NewEngine()
	engine.Load("qrc:/res/main.qml")
	app.SetQuitOnLastWindowClosed(false)

	app.Exec()
}
