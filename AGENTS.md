# Agent Guidelines for PowerShell in This Repo

These rules help avoid common PowerShell pitfalls (especially string
interpolation and path handling) and keep scripts consistent across the repo.

## Scope
- Scripts live under `scripts/` and are used by the Qt 4 Simulator tooling and
  small test harnesses in `tests/`.
- These guidelines target Windows PowerShell 5.x and PowerShell 7.x.

## Naming Conventions
- Script files use dash/kebab case: `lower-kebab-case.ps1`.
  - Examples: `build-simulator.ps1`, `test-tls.ps1`, `inspect-sim-runtime.ps1`.
  - Do not mix underscores and dashes. Prefer dashes consistently.
- Functions and parameters use PascalCase: `WriteInfo`, `-QtSdkRoot`.
- Private helpers may be prefixed with `_` inside a script.

## Required Boilerplate
Every new script should start with the following:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
param()
```

Recommendations:
- Use `param()` with explicit types and `ValidateSet`/`ValidateNotNullOrEmpty`.
- Wrap the main flow in `try { ... } catch { Write-Error $_; exit 1 }`.

## String Interpolation Rules (Important)
PowerShell’s string interpolation can misparse variables adjacent to punctuation
or letters. Use subexpressions to avoid surprises.

- Surround variables with `$()` when followed by non‑whitespace characters
  (especially `:` `.` `,` `;` `)` `]`):
  - Good: `"Missing DLL in $($dllSrc): $name"`
  - Bad:  `"Missing DLL in $dllSrc: $name"`  # parsed as `$dllSrc:` and fails
- Prefer single quotes when no interpolation is needed: `'literal text'`.
- For complex formatting, use `-f` operator:
  - `"Missing DLL in {0}: {1}" -f $dllSrc, $name`

## Paths and File Operations
- Always use `Join-Path` to build paths; never hand‑concat with `\` or `/`.
- Use `-LiteralPath` with cmdlets like `Set-Content`, `Get-Item` to avoid
  wildcard expansion issues.
- Prefer `$PSScriptRoot` (or `$MyInvocation.MyCommand.Path`) to locate script‑
  relative resources. Convert to a directory once: `$repo = Split-Path -Parent $PSScriptRoot`.
- When creating directories, use: `New-Item -ItemType Directory -Force | Out-Null`.

## External Processes
- Invoke executables with the call operator `&` and pass arguments as separate
  tokens: `& $qmake $pro $args`.
- Check exit codes via `$LASTEXITCODE` immediately after the call; treat non‑zero
  as failure and `throw`.
- Avoid string‑joined command lines; let PowerShell handle quoting by passing
  arguments as separate items in an array when needed.
- For capturing output, prefer `System.Diagnostics.ProcessStartInfo` or run
  directly and read `$LASTEXITCODE` (keep it simple for CLI tools).

## Error Handling
- Use `throw` for fatal errors; use `Write-Warning` for non‑fatal notices.
- Do not rely on `$?` for process success; external processes set
  `$LASTEXITCODE`.
- Keep `try { ... } finally { Pop-Location }` around `Push-Location` blocks.

## Environment and PATH
- Prepend tool locations to `PATH` rather than replacing it:
  `"$tools;$env:PATH"`.
- Keep PATH mutations scoped to the current process; avoid writing to machine or
  user environment.

## Logging
- Provide lightweight helpers in each script:
  ```powershell
  function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
  function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
  function Write-Err($m){ Write-Host "[ERR ] $m" -ForegroundColor Red }
  ```
- Prefer `Write-Error` for terminating errors in catch blocks.

## Debug vs Release
- Tests in this repo (e.g., TLS harness) are Debug‑only. Release builds require
  a separate set of patched Qt4 DLLs and are not attempted by test scripts.
- When staging runtime DLLs next to an EXE, ensure all Qt debug DLLs come from
  the same build and match the toolchain.

## Plugin Search
- Constrain plugin lookup to the application directory to avoid mixing SDK
  plugins: write `qt.conf` with:
  ```
  [Paths]
  Plugins = plugins
  ```
- Alternatively, in code: `QCoreApplication::setLibraryPaths(QStringList() << QCoreApplication::applicationDirPath());`

## File Encodings
- Use explicit encodings when writing files: `-Encoding ASCII` or `-Encoding UTF8`.
- Prefer BOM‑less UTF‑8 unless a tool requires otherwise.

## Common Gotchas Checklist
- [ ] Quoted strings: subexpressions used where variables touch punctuation.
- [ ] Paths built with `Join-Path`; file ops use `-LiteralPath`.
- [ ] Checked `$LASTEXITCODE` after every external tool.
- [ ] `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` set.
- [ ] `Push-Location` wrapped with `try/finally` + `Pop-Location`.
- [ ] Debug/Release artifacts are not mixed; DLLs staged consistently.

