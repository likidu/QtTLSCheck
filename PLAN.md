I want to create a Symbian Qt project that can be tested in Qt Simulator from Qt Creator environment, and also be able to run on the actual Symbian Belle device.

The flow of this app is pretty simple, there is a Button in the middle of the canvas. When I click on that, it performs a TLS check and can output the result in the Qt Creator console output window to show the result, which the logic you can pretty much refer to the `ref.cpp`

- I want to use the Symbian Belle native Qt UI component (Qt Quick?) for button
  the deps\win32\qt4-openssl\debug folder contain the patched custom Qt4 dll files that support TLS 1.1 and 1.2 that can be run in Qt Simulator, together with the OpenSSL 1.0.2u dlls. They were all built with QtSDK MinGW (C:\Symbian\QtSDK\Simulator\Qt\mingw\bin).
- Which means you should use these dlls over the ones in the Qt Simulator default folder to have the right TLS 1.1 / 1.2 support. The patched custom Qt version is 4.7.4.
  Please also create the Powershell build script for the Qt Simulator so I can build it from the CLI.
- All the built output for the Qt Simulator should be put in the `build-simulator` folder.
- Add the README in the root about how to build is using the script
