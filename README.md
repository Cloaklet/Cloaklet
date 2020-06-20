# Cloaklet

A simple GUI app wrapping around [gocryptfs](https://github.com/rfjakob/gocryptfs).
Currently usable on macOS.

UI and interaction is mimicked from [Cryptomator](https://cryptomator.org/).

# How to build

## Tool dependencies

You should have the following tools installed:

- `Qt5` suite: `brew install qt5`.
- `Clang`: `xcode-select --install` to install the CommandLine Tools from Apple.
- `Go`: `brew install go`, `1.14` would be fine.
- `qamel`: `go get -u -v github.com/go-qamel/qamel/cmd/qamel` in project root to install.

## Setup qamel profile

- Run `brew info qt5` to print the caveats for the installed Qt5 formula. What we need is the path to Qt tools, typically located at `/usr/local/opt/qt/bin`.
- Run `qamel profile setup` to setup the **default** profile, it will ask you for path of each tool, use these:
  - For Qt tools dir, use the one you got from `brew info qt5`
  - For C compiler, use `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang`
  - For C++ compiler, use `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++`

## Build for development

When building for development it's not necessary to create an application bundle, instead we just need a executable binary file. The binary file alone is fast to compile thus saves a lot of time.

### Generate moc headers

Qt's moc (Meta Object Compiler) is used to generate a header file specific to the `extend.h` file.
This file provides some extended functionality via CGO, including a QML type named `MousePos`
 which provides `MousePos.pos()` slot to effeciently get current cursor coordinates.

```bash
# This will generate "moc-extend.h" file
/usr/local/opt/qt/bin/moc -o moc-extend.h extend.h
```

### Build the binary

`qamel build` to build with the `default` profile.
Run with `./Cloaklet`.

## Build for release

Just run `go run build.go buildBundle`, it should do all the building and bundling stuff and generates `Cloaklet.app` bundle. Double click it to start the app.

## Notice

If the compiler complains about finding std library headers, you might need to set the Apple SDK path like this before running build command:

```bash
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
```

# License

GPL v3, see LICENSE file.
