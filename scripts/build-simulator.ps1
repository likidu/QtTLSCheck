param(
    [string]$QtBin = 'C:\Symbian\QtSDK\Simulator\Qt\mingw\bin',
    [string]$MakeBin = 'C:\Symbian\QtSDK\mingw\bin',
    [ValidateSet('Debug','Release')][string]$Config = 'Debug',
    [switch]$Clean,
    # When set, also copy Qt plugins (bearer, imageformats) from the SDK. Off by default to avoid mismatch.
    [switch]$CopyPlugins
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[ERR ] $msg" -ForegroundColor Red }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $scriptDir '..')
$buildRoot = Join-Path $root 'build-simulator'
$cfgLower = $Config.ToLower()
$buildDir = Join-Path $buildRoot $cfgLower
$proFile = Join-Path $root 'QtTLSCheck.pro'

Write-Info "Root: $root"
Write-Info "Build: $buildDir"
Write-Info "QtBin: $QtBin"
Write-Info "MakeBin: $MakeBin"
Write-Info "Config: $Config"

if (-not (Test-Path $proFile)) {
    Write-Err "Missing .pro file at $proFile"
    exit 2
}

$qmake = Join-Path $QtBin 'qmake.exe'
if (-not (Test-Path $qmake)) {
    Write-Err "qmake not found at $qmake. Pass -QtBin to point to your Qt Simulator bin directory."
    exit 3
}

$make = Join-Path $MakeBin 'mingw32-make.exe'
if (-not (Test-Path $make)) {
    Write-Err "mingw32-make.exe not found at $make. Pass -MakeBin to point to your MinGW bin."
    exit 4
}

if ($Clean) {
    if (Test-Path $buildRoot) {
        Write-Info "Cleaning $buildRoot"
        Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
}

# Ensure tools are on PATH (useful if DLLs are colocated)
$env:PATH = "$QtBin;$MakeBin;$env:PATH"

Push-Location $buildDir
try {
    Write-Info "Running qmake..."
    & $qmake $proFile -spec win32-g++ "CONFIG+=$Config" | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "qmake failed with exit code $LASTEXITCODE" }

    Write-Info "Building with mingw32-make..."
    & $make -j $env:NUMBER_OF_PROCESSORS | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "mingw32-make failed with exit code $LASTEXITCODE" }

    # Copy patched Qt + OpenSSL DLLs next to the built exe so they are used at runtime
    $depsRoot = Join-Path $root 'deps\win32\qt4-openssl'
    $cfgDir = if ($Config -ieq 'Release') { 'release' } else { 'debug' }
    $deps = Join-Path $depsRoot $cfgDir
    if (Test-Path $deps) {
        Write-Info ("Staging patched {0} DLLs from {1}" -f $Config, $deps)
        # Minimal, stable set: QtCore + QtNetwork + OpenSSL
        $qtDbgBase = @('QtCored4.dll','QtNetworkd4.dll')
        $qtRelBase = @('QtCore4.dll','QtNetwork4.dll')
        $openssl = @('libeay32.dll','ssleay32.dll')
        $names = if ($Config -ieq 'Release') { $qtRelBase + $openssl } else { $qtDbgBase + $openssl }
        foreach ($n in $names) {
            $src = Join-Path $deps $n
            if (Test-Path $src) {
                Copy-Item -Force $src $buildDir
                Write-Info "  + $n"
            } else {
                Write-Warn "  - Missing in deps: $n"
            }
        }
    } else {
        Write-Warn "Deps folder not found at $deps. Place your patched Qt 4.7.4 + OpenSSL 1.0.2u DLLs there."
        # Fallback: copy core Qt DLLs from QtBin so the app can still run (without TLS 1.2)
        $fallback = if ($Config -ieq 'Release') { @('QtCore4.dll','QtNetwork4.dll') } else { @('QtCored4.dll','QtNetworkd4.dll') }
        foreach ($dll in $fallback) {
            $src = Join-Path $QtBin $dll
            if (Test-Path $src) { Copy-Item -Force $src $buildDir }
        }
    }

    # Constrain plugin lookup to local folder
    $qtConfContent = "[Paths]`nPlugins = plugins`n"
    Set-Content -LiteralPath (Join-Path $buildDir 'qt.conf') -Value $qtConfContent -Encoding ASCII

    # Optionally copy a minimal set of plugins (bearer, imageformats) if available
    if ($CopyPlugins) {
        $qtPluginsDir = Join-Path (Split-Path (Split-Path $QtBin -Parent) -Parent) 'plugins'
        if (Test-Path $qtPluginsDir) {
            foreach ($sub in @('bearer','imageformats')) {
                $srcDir = Join-Path $qtPluginsDir $sub
                $dstDir = Join-Path $buildDir (Join-Path 'plugins' $sub)
                if (Test-Path $srcDir) {
                    New-Item -ItemType Directory -Force $dstDir | Out-Null
                    Get-ChildItem $srcDir -Filter *.dll | ForEach-Object { Copy-Item -Force $_.FullName $dstDir }
                }
            }
        }
    }

    $exe = Join-Path $buildDir 'QtTLSCheck.exe'
    if (Test-Path $exe) {
        Write-Info "Build succeeded: $exe"
    } else {
        Write-Warn "Build completed but QtTLSCheck.exe not found in $buildDir. Check qmake DESTDIR in .pro."
    }
}
finally {
    Pop-Location
}
