<#
Builds and runs a tiny Qt4 console app (Debug only) that verifies TLS 1.2 works at runtime.

It uses the Qt SDK toolchain and stages patched Debug Qt4 + OpenSSL DLLs from
deps/win32/qt4-openssl/debug next to the test exe. Plugins are constrained locally.

Usage:
  ./scripts/test-tls.ps1
  ./scripts/test-tls.ps1 -QtSdkRoot 'C:\\Symbian\\QtSDK' -DebugPlugins
#>

Param(
    [string]$QtSdkRoot = 'c:\symbian\qtsdk',
    # Emit QT_DEBUG_PLUGINS=1 while running for easier diagnostics
    [switch]$DebugPlugins
)

$ErrorActionPreference = 'Stop'

function Add-ToPathFront([string[]]$paths) {
    $front = ($paths | Where-Object { $_ -and (Test-Path $_) }) -join ';'
    if (-not [string]::IsNullOrWhiteSpace($front)) {
        $env:PATH = "$front;$env:PATH"
    }
}

try {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    Set-Location $repoRoot

    $qmake = Join-Path $QtSdkRoot 'simulator\qt\mingw\bin\qmake.exe'
    $make  = Join-Path $QtSdkRoot 'mingw\bin\mingw32-make.exe'
    $qtBin = Join-Path $QtSdkRoot 'simulator\qt\mingw\bin'
    $gccBin = Join-Path $QtSdkRoot 'mingw\bin'

    if (-not (Test-Path $qmake)) { throw "qmake not found: $qmake" }
    if (-not (Test-Path $make))  { throw "mingw32-make not found: $make" }

    Add-ToPathFront @($qtBin, $gccBin)

    $buildDir = Join-Path $repoRoot 'build-simulator\tlscheck'
    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

    Push-Location $buildDir
    try {
        $cfgArg = 'CONFIG+=debug'
        $proPath = Join-Path $repoRoot 'tests\tlscheck\tlscheck.pro'
        Write-Host "qmake: `"$qmake`" `"$proPath`" -r -spec win32-g++ $cfgArg"
        & $qmake $proPath '-r' '-spec' 'win32-g++' $cfgArg
        if ($LASTEXITCODE -ne 0) { throw "qmake failed with exit code $LASTEXITCODE" }

        $jobs = if ($env:NUMBER_OF_PROCESSORS) { [int]$env:NUMBER_OF_PROCESSORS } else { 2 }
        Write-Host "make: `"$make`" -j $jobs (cwd: $buildDir)"
        & $make '-j' $jobs
        if ($LASTEXITCODE -ne 0) { throw "mingw32-make failed with exit code $LASTEXITCODE" }

        # Locate built exe under config subdir
        $exe = Join-Path (Join-Path $buildDir 'debug') 'tlscheck.exe'
        if (-not (Test-Path $exe)) {
            $cand = Get-ChildItem -Recurse -File -Filter tlscheck.exe -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($cand) { $exe = $cand.FullName }
        }
        if (-not (Test-Path $exe)) { throw "tlscheck.exe not found under $buildDir" }

        # Stage required Debug Qt + OpenSSL DLLs (must exist)
        $depsRoot = Join-Path $repoRoot 'deps\win32\qt4-openssl'
        $dllSrc = Join-Path $depsRoot 'debug'
        $outDir = Split-Path -Parent $exe
        if (-not (Test-Path $dllSrc)) { throw "TLS deps folder not found: $dllSrc (expected Debug patched DLLs)." }

        $qtDbg = @('QtCored4.dll','QtGuid4.dll','QtNetworkd4.dll')
        $openssl = @('libeay32.dll','ssleay32.dll')
        foreach ($name in ($qtDbg + $openssl)) {
            $src = Join-Path $dllSrc $name
            if (-not (Test-Path $src)) { throw "Missing required DLL in $($dllSrc): $name" }
            Copy-Item -Force $src $outDir
            Write-Host "Staged: $name"
        }

        # Constrain plugin lookup so Qt does not scan the SDK plugins (avoids mismatched debug/release warnings)
        $qtConf = "[Paths]`nPlugins = plugins`n"
        Set-Content -LiteralPath (Join-Path $outDir 'qt.conf') -Value $qtConf -Encoding ASCII
        # Create an empty plugins folder; bearer plugins are optional for this test
        $pluginsDir = Join-Path $outDir 'plugins'
        if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Force $pluginsDir | Out-Null }
        Write-Host "Created qt.conf and local plugins/ to constrain plugin search"

        Write-Host "Running: $exe"
        if ($DebugPlugins) { $env:QT_DEBUG_PLUGINS = '1' }
        & $exe
        $code = $LASTEXITCODE
        if ($code -eq 0) {
            Write-Host "TLS check: SUCCESS (TLS 1.2 handshake ok)" -ForegroundColor Green
        } else {
            Write-Error "TLS check: FAILED with exit code $code"
            exit $code
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_
    exit 1
}
