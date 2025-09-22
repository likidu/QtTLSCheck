param(
    [string]$QtBin = 'C:\Symbian\QtSDK\Simulator\Qt\mingw\bin',
    [string]$MakeBin = 'C:\Symbian\QtSDK\mingw\bin',
    [ValidateSet('Debug','Release')][string]$Config = 'Debug',
    [switch]$Clean,
    # When set, also copy Qt plugins (bearer, imageformats) from the SDK. Off by default to avoid mismatch.
    [switch]$CopyPlugins,
    # Use Qt Simulator runtime files directly without staging them into the build directory.
    [switch]$UseQtRuntime
)

Set-StrictMode -Version Latest
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
    Write-Err ("qmake not found at {0}. Pass -QtBin to point to your Qt Simulator bin directory." -f $qmake)
    exit 3
}

$make = Join-Path $MakeBin 'mingw32-make.exe'
if (-not (Test-Path $make)) {
    Write-Err ("mingw32-make.exe not found at {0}. Pass -MakeBin to point to your MinGW bin." -f $make)
    exit 4
}

if ($UseQtRuntime -and $CopyPlugins) {
    Write-Warn 'Ignoring -CopyPlugins because -UseQtRuntime was supplied.'
}

if ($Clean) {
    if (Test-Path $buildRoot) {
        Write-Info "Cleaning $buildRoot"
        Remove-Item -Recurse -Force -LiteralPath $buildRoot -ErrorAction SilentlyContinue
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

    if (-not $UseQtRuntime) {
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
                    Copy-Item -LiteralPath $src -Destination $buildDir -Force
                    Write-Info "  + $n"
                } else {
                    Write-Warn "  - Missing in deps: $n"
                }
            }
        } else {
            Write-Warn ("Deps folder not found at {0}. Place your patched Qt 4.7.4 + OpenSSL 1.0.2u DLLs there." -f $deps)
            # Fallback: copy core Qt DLLs from QtBin so the app can still run (without TLS 1.2)
            $fallback = if ($Config -ieq 'Release') { @('QtCore4.dll','QtNetwork4.dll') } else { @('QtCored4.dll','QtNetworkd4.dll') }
            foreach ($dll in $fallback) {
                $srcDll = Join-Path $QtBin $dll
                if (Test-Path $srcDll) {
                    Copy-Item -LiteralPath $srcDll -Destination $buildDir -Force
                }
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
                        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
                        Get-ChildItem -LiteralPath $srcDir -Filter *.dll | ForEach-Object {
                            Copy-Item -LiteralPath $_.FullName -Destination $dstDir -Force
                        }
                    }
                }
            }
        }
    } else {
        Write-Info ("Skipping staging of Qt runtime files; relying on simulator runtime from {0}" -f $QtBin)

        $launcher = Join-Path $buildDir 'QtTLSCheck.run.ps1'
        $legacyLauncher = Join-Path $buildDir 'QtTLSCheck.run.cmd'
        if (Test-Path $legacyLauncher) {
            Remove-Item -LiteralPath $legacyLauncher -Force
        }

        $qtPluginsDir = Join-Path (Split-Path (Split-Path $QtBin -Parent) -Parent) 'plugins'

        $launcherLines = @(
            'param([Parameter(ValueFromRemainingArguments = $true)][string[]]$ExtraArgs = @())'
            'Set-StrictMode -Version Latest'
            '$ErrorActionPreference = ''Stop'''
            '$exe = Join-Path $PSScriptRoot ''QtTLSCheck.exe'''
            'if (-not (Test-Path -LiteralPath $exe)) {'
            '    Write-Error "QtTLSCheck.exe not found next to this launcher."'
            '    exit 1'
            '}'
            ('$env:PATH = ''{0};'' + $env:PATH' -f $QtBin)
            ('[Environment]::SetEnvironmentVariable(''Path'', $env:PATH, ''Process'')')
        )

        $launcherLines += @(
            ('if (Test-Path -LiteralPath ''{0}'') {{' -f $qtPluginsDir)
            ('    $env:QT_PLUGIN_PATH = ''{0}''' -f $qtPluginsDir)
            ('    [Environment]::SetEnvironmentVariable(''QT_PLUGIN_PATH'', $env:QT_PLUGIN_PATH, ''Process'')')
            '}'
        )

        $launcherLines += @(
            '$argsToPass = if ($ExtraArgs) { $ExtraArgs } else { @() }'
            '& $exe @argsToPass'
            'if ($LASTEXITCODE -ne 0) {'
            '    exit $LASTEXITCODE'
            '}'
        )

        Set-Content -LiteralPath $launcher -Value ($launcherLines -join "`r`n") -Encoding ASCII
        Write-Info ("Launcher created at {0}. Run it with pwsh to launch using the simulator runtime." -f $launcher)
    }

    $exe = Join-Path $buildDir 'QtTLSCheck.exe'
    if (Test-Path $exe) {
        Write-Info "Build succeeded: $exe"
    } else {
        Write-Warn ("Build completed but QtTLSCheck.exe not found in {0}. Check qmake DESTDIR in .pro." -f $buildDir)
    }
}
finally {
    Pop-Location
}
