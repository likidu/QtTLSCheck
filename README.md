# QtTLSCheck

A minimal Qt 4.x application for the Symbian/Qt Simulator that presents a Belle-inspired QML interface. Tapping the action starts a TLS handshake + HTTP GET to a TLS 1.2-only endpoint and prints progress to the console/Qt Creator Application Output.

The project targets the Qt Simulator (Qt 4.7.4, MinGW) and can also run on Symbian Belle when built with the appropriate kit. In the simulator we default to the stock Qt runtime shipped with the SDK, but you can stage patched Qt 4.7.4 + OpenSSL 1.0.2u DLLs from `deps/` when you need TLS 1.1/1.2 support without the simulator install.

## Layout
- `QtTLSCheck.pro`: qmake project
- `src/`: C++ backend (`TlsChecker`, QML bootstrap)
- `qml/`: QML UI and resource collection
- `scripts/build-simulator.ps1`: build QtTLSCheck for the simulator (defaults to Qt runtime)
- `scripts/test-tls.ps1`: debug console TLS checker
- `scripts/inspect-sim-runtime.ps1`: inspect a runtime directory for mismatches
- `AGENTS.md`: PowerShell authoring guidelines
- `build-simulator/`: build output root (`debug`/`release`)
- `deps/win32/qt4-openssl/{debug,release}/`: optional patched Qt + OpenSSL DLLs to stage when needed

## Prerequisites
- Qt SDK with Qt Simulator (Qt 4.7.4, MinGW), typically installed under `C:\Symbian\QtSDK`.
- Optional: patched Qt 4.7.4 DLLs with OpenSSL 1.0.2u (TLS 1.1/1.2) and the matching OpenSSL DLLs.
  - Debug: place `QtCored4.dll`, `QtNetworkd4.dll`, `libeay32.dll`, `ssleay32.dll` in `deps\win32\qt4-openssl\debug`.
  - Release: place `QtCore4.dll`, `QtNetwork4.dll`, `libeay32.dll`, `ssleay32.dll` in `deps\win32\qt4-openssl\release`.

## Build (Qt Simulator)
From a PowerShell prompt in the repo root:

```powershell
# Default: build and use the simulator runtime
pwsh scripts/build-simulator.ps1 -Config Debug

# Clean then build
pwsh scripts/build-simulator.ps1 -Config Debug -Clean

# Stage patched DLLs from deps/win32 instead of using the runtime
pwsh scripts/build-simulator.ps1 -Config Debug -UseDepDlls
```

Notes:
- Output lands in `build-simulator\debug\` (or `release\` when `-Config Release`).
- When `-UseDepDlls` is omitted the script wires PATH for the simulator?s Qt runtime and generates `QtTLSCheck.run.ps1` for launching.
- When `-UseDepDlls` is provided the script copies the patched DLL set (QtCore/QtNetwork/OpenSSL) from `deps\win32\qt4-openssl\<config>` beside the exe. Missing files trigger warnings so you can verify your dep cache.
- Adjust `-QtBin` / `-MakeBin` if your SDK lives outside the default paths.

## Run
- **Simulator runtime (default):** run `pwsh -File build-simulator\debug\QtTLSCheck.run.ps1` (or the release variant). The launcher ensures PATH and plugin lookup point at the simulator install.
- **Staged DLL mode:** run `build-simulator\debug\QtTLSCheck.exe` directly; the required DLLs were copied next to the executable.
- In Qt Creator you can open the project, pick the Simulator kit, and launch as usual. The console will show the TLS log messages.

## TLS Check Details
- Uses `QSslSocket` + `QNetworkAccessManager` to GET `https://tls-v1-2.badssl.com:1012/`.
- Logs SSL availability, build/runtime OpenSSL version strings (Qt >= 4.8), ignores certificate errors for this probe, and reports success/failure to both stdout and the QML status label.

## TLS Test Harness (Debug only)
- A minimal console harness lives under `tests\tlscheck\` for quick iteration.
- Build and run with:
  ```powershell
  pwsh scripts/test-tls.ps1                     # Uses Qt SDK at C:\Symbian\QtSDK by default
  pwsh scripts/test-tls.ps1 -DebugPlugins       # Verbose plugin loading
  ```
- The harness stages the Debug patched DLLs from `deps\win32\qt4-openssl\debug` and constrains plugin lookup via `qt.conf`.

## Inspect Runtime
- Validate staged binaries (bitness/toolchain/config) with:
  ```powershell
  pwsh scripts/inspect-sim-runtime.ps1 -Config Debug               # checks build-simulator\debug by default
  pwsh scripts/inspect-sim-runtime.ps1 -Config Debug -OnlyNetSsl   # focus on QtNetwork + OpenSSL
  pwsh scripts/inspect-sim-runtime.ps1 -Config Release -Dir 'build-simulator\release'
  ```

## Symbian Device Build
- Open in Qt Creator, choose a Symbian Belle kit, and build/deploy as needed. The UI is delivered via QML, backed by the same `TlsChecker` service logic used in the simulator.
