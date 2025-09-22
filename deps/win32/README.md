Windows runtime deps for Qt Simulator

Where to place your custom files so scripts can stage them alongside the built app/tests.

Qt 4 + OpenSSL DLLs

- Debug DLLs ? `deps/win32/qt4-openssl/debug`
  - QtCored4.dll, QtGuid4.dll, QtDeclaratived4.dll
  - QtNetworkd4.dll (or QtNetwork4d.dll)
  - ssleay32.dll, libeay32.dll (OpenSSL 1.0.x)
- Release DLLs ? `deps/win32/qt4-openssl/release`
  - QtCore4.dll, QtGui4.dll, QtDeclarative4.dll
  - QtNetwork4.dll
  - ssleay32.dll, libeay32.dll

Qt plugins (optional)

- If you rebuilt Qt plugins to match your patched DLLs, mirror them under
  `deps/win32/qt4-openssl/plugins/<category>` (e.g. `imageformats`, `bearer`).
- The build script no longer copies these automatically; launch via
  `-UseQtRuntime` to consume the simulator?s stock plugins or copy the ones you
  need beside the executable yourself.

Using the scripts

- Build and stage patched DLLs next to the simulator build:
  - Debug: `pwsh scripts/build-simulator.ps1 -Config Debug`
  - Release: `pwsh scripts/build-simulator.ps1 -Config Release`
  - Add `-Clean` to wipe the `build-simulator` tree before rebuilding.
- Rely on the Qt Simulator runtime instead of staging DLLs:
  - `pwsh scripts/build-simulator.ps1 -UseQtRuntime`
  - Use the generated `QtTLSCheck.run.ps1` launcher to run with the simulator?s
    environment (Qt DLLs, plugins, imports).

Troubleshooting

- Use `pwsh scripts/inspect-sim-runtime.ps1 -Config Debug` to verify
  bitness/toolchain and debug/release matches.
- If you replace Core/Gui/Declarative without matching plugins, you may see exit
  code -1073741511 (0xC0000139).
