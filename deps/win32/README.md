Windows runtime deps for Qt Simulator

Where to place your custom files so scripts can stage them alongside the built app/tests.

Qt 4 + OpenSSL DLLs

- Debug DLLs -> deps/win32/qt4-openssl/debug
  - QtCored4.dll, QtGuid4.dll, QtDeclaratived4.dll
  - QtNetworkd4.dll (or QtNetwork4d.dll)
  - ssleay32.dll, libeay32.dll (OpenSSL 1.0.x)
- Release DLLs -> deps/win32/qt4-openssl/release
  - QtCore4.dll, QtGui4.dll, QtDeclarative4.dll
  - QtNetwork4.dll
  - ssleay32.dll, libeay32.dll

Qt plugins (optional)

- If you rebuilt Qt plugins to match your patched DLLs, mirror them under
  deps/win32/qt4-openssl/plugins/<category> (e.g. imageformats, bearer).
- The build script now relies on the simulator runtime by default. Use the
  generated launcher or copy any extra plugins next to the exe if needed.

Using the scripts

- Build and run against the simulator runtime (default):
  - pwsh scripts/build-simulator.ps1
  - Launch with pwsh -File build-simulator/<config>/QtTLSCheck.run.ps1
- Stage patched DLLs from deps/win32/qt4-openssl instead of using the runtime:\n  - pwsh scripts/build-simulator.ps1 -UseDepDlls
  - Add -Clean to wipe the build-simulator tree before rebuilding.

Troubleshooting

- Use pwsh scripts/inspect-sim-runtime.ps1 -Config Debug to verify
  bitness/toolchain and debug/release matches.
- If you replace Core/Gui/Declarative without matching plugins, you may see exit
  code -1073741511 (0xC0000139).

