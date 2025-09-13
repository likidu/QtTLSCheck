# QtTLSCheck

A minimal Qt 4.x application for Symbian/Qt Simulator that shows a centered button. Clicking it performs a TLS handshake + HTTP GET to a TLS 1.2–only endpoint and prints status to Qt Creator's Application Output.

This project is intended to run in the Qt Simulator (Qt 4.7.4, MinGW) and on Symbian Belle devices when built with the appropriate kit. For the Simulator, use the patched Qt 4.7.4 + OpenSSL 1.0.2u DLLs provided separately to enable TLS 1.1/1.2.

## Layout
- `QtTLSCheck.pro`: qmake project file
- `src/`: source code (QtWidgets + QtNetwork)
- `scripts/build-simulator.ps1`: build QtTLSCheck for the Qt Simulator
- `scripts/test-tls.ps1`: build+run a tiny Debug console TLS checker (isolated harness)
- `scripts/inspect-sim-runtime.ps1`: inspect a runtime dir for bitness/toolchain/config mismatches
- `AGENTS.md`: PowerShell authoring guidelines used in this repo
- `build-simulator/`: build output root (`debug`/`release` subfolders)
- `deps/win32/qt4-openssl/{debug,release}/`: place patched Qt 4.7.4 + OpenSSL 1.0.2u DLLs here

## Prerequisites
- Qt SDK with Qt Simulator (Qt 4.7.4, MinGW toolchain), typically under `C:\Symbian\QtSDK`.
- Patched Qt 4.7.4 DLLs with OpenSSL 1.0.2u (TLS 1.1/1.2 enabled) and the OpenSSL DLLs.
  - Debug (required): put `QtCored4.dll`, `QtNetworkd4.dll`, `libeay32.dll`, `ssleay32.dll` in `deps\win32\qt4-openssl\debug`.
  - Release (optional): put `QtCore4.dll`, `QtNetwork4.dll`, `libeay32.dll`, `ssleay32.dll` in `deps\win32\qt4-openssl\release`.
  - Intentionally do not stage `QtGui*` by default to avoid Simulator crashes from mismatched GUI plugins.

## Build (Qt Simulator)
Run from a PowerShell prompt:

```powershell
# From repo root (Debug)
./scripts/build-simulator.ps1 `
  -QtBin 'C:\Symbian\QtSDK\Simulator\Qt\mingw\bin' `
  -MakeBin 'C:\Symbian\QtSDK\mingw\bin' `
  -Config Debug

# Clean build output (real clean) then build
./scripts/build-simulator.ps1 -Config Debug -Clean
```

Notes:
- Output goes to `build-simulator\debug\` (or `release\` if building Release).
- The script runs qmake/mingw32-make and stages a minimal, matching runtime next to the exe:
  - Debug: `QtCored4.dll`, `QtNetworkd4.dll`, `libeay32.dll`, `ssleay32.dll`
  - Release: `QtCore4.dll`, `QtNetwork4.dll`, `libeay32.dll`, `ssleay32.dll`
- It writes a `qt.conf` so Qt only searches for plugins locally; plugin copying is disabled by default. If needed, pass `-CopyPlugins` to copy `bearer` and `imageformats` from the SDK (ensure they match your Qt build).
- If your Qt SDK is installed in a non-default location, adjust `-QtBin` and `-MakeBin` accordingly.

## Run
- In Qt Creator: open the project, select the Simulator kit, and run. Application Output will show TLS logs.
- Or run `build-simulator\debug\QtTLSCheck.exe` directly; the script stages the required DLLs next to the exe.

## TLS Check Details
- Uses `QSslSocket` and `QNetworkAccessManager` to GET `https://tls-v1-2.badssl.com:1012/`.
- Logs whether SSL is supported, prints OpenSSL version strings when available (Qt >= 4.8), ignores certificate errors for this probe, and reports success/failure.

## TLS Test Harness (Debug only)
- A minimal console app lives in `tests\tlscheck\` for quick verification outside GUI.
- Build and run it with:
  ```powershell
  ./scripts/test-tls.ps1           # Uses Qt SDK at C:\Symbian\QtSDK by default
  ./scripts/test-tls.ps1 -DebugPlugins  # Verbose plugin loading logs
  ```
- The script stages the Debug patched DLLs from `deps\win32\qt4-openssl\debug` and constrains plugin lookup via `qt.conf`.

## Inspect Runtime
- To sanity-check staged binaries (bitness/toolchain/config), run:
  ```powershell
  ./scripts/inspect-sim-runtime.ps1 -Config Debug               # checks build-simulator\debug by default
  ./scripts/inspect-sim-runtime.ps1 -Config Debug -OnlyNetSsl   # focus on QtNetwork + OpenSSL
  ./scripts/inspect-sim-runtime.ps1 -Config Release -Dir 'build-simulator\release'
  ```

## Symbian Device Build
- Open in Qt Creator, select a Symbian Belle kit, and build/deploy as usual. The UI is a simple QWidget-based layout with a single button and status label.
