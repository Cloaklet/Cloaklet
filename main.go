package main

import (
	"os"
	"time"

	"github.com/go-qamel/qamel"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

var logger zerolog.Logger

func init() {
	logWriter := zerolog.ConsoleWriter{Out: os.Stdout, TimeFormat:time.RFC3339}
	logger = log.Logger.Output(logWriter).With().Str("app", "Cloaklet").Logger()
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	RegisterQmlMousePos("MousePos", 1, 0, "MousePos")
	RegisterQmlVaultManager("VaultManager", 1, 0, "VaultManager")
}

func main() {
	app := qamel.NewApplication(len(os.Args), os.Args)
	app.SetApplicationDisplayName("Cloaklet")
	LoadFonts()

	engine := qamel.NewEngine()
	engine.Load("qrc:/res/main.qml")
	app.SetQuitOnLastWindowClosed(false)

	app.Exec()
}
