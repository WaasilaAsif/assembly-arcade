# filepath: D:\COAL-Project-final\assembly-arcade\scripts\build.ps1
# Run from anywhere -- paths resolve relative to this script's location
param(
    [string]$Target = "arcade"   # "arcade" | "snake" | "maze" | "hangman" | "tictactoe"
)

# ---------------------------------------------------------------
#  Resolve project root  (script lives in <root>\scripts\)
# ---------------------------------------------------------------
$root   = Split-Path $PSScriptRoot -Parent
$src    = "$root\src"
$out    = "$PSScriptRoot\bin"          # scripts\bin\

# ---------------------------------------------------------------
#  Find masm-runner extension on this machine automatically
# ---------------------------------------------------------------
$vsExt  = "$env:USERPROFILE\.vscode\extensions"
$runner = Get-ChildItem "$vsExt\istareatscreens.masm-runner-*" `
            -Directory -ErrorAction SilentlyContinue |
          Sort-Object Name -Descending |
          Select-Object -First 1

if (-not $runner) {
    Write-Host "ERROR: masm-runner extension not found under $vsExt" -ForegroundColor Red
    exit 1
}

$jwasm  = "$($runner.FullName)\native\JWASM\JWASM.EXE"
$jwlink = "$($runner.FullName)\native\JWLINK\JWlink.exe"
$irvine = "$($runner.FullName)\native\irvine"

foreach ($tool in @($jwasm, $jwlink)) {
    if (!(Test-Path $tool)) {
        Write-Host "ERROR: Tool not found: $tool" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------
#  File sets
# ---------------------------------------------------------------
$allFiles = @(
    "$src\main.asm",
    "$src\games\snake.asm",
    "$src\games\maze.asm",
    "$src\games\hangman.asm",
    "$src\games\tictactoe.asm"
)

$gameSources = @{
    "snake"     = "$src\games\snake.asm"
    "maze"      = "$src\games\maze.asm"
    "hangman"   = "$src\games\hangman.asm"
    "tictactoe" = "$src\games\tictactoe.asm"
}

if ($Target -eq "arcade") {
    $filesToBuild = $allFiles
    $exeName      = "arcade.exe"

} elseif ($gameSources.ContainsKey($Target)) {
    # Auto-generate a minimal stub main if it doesn't exist yet
    $stubDir  = "$src\stubs"
    $stubFile = "$stubDir\${Target}_main.asm"

    if (!(Test-Path $stubDir)) { New-Item -ItemType Directory -Path $stubDir | Out-Null }

    if (!(Test-Path $stubFile)) {
        $proto = "${Target}_start"
        $stub  = @"
INCLUDE Irvine32.inc
$proto PROTO
.code
main PROC
    call $proto
    exit
main ENDP
END main
"@
        Set-Content -Path $stubFile -Value $stub
        Write-Host "Generated stub: $stubFile" -ForegroundColor DarkCyan
    }

    $filesToBuild = @($gameSources[$Target], $stubFile)
    $exeName      = "$Target.exe"

} else {
    Write-Host "Unknown target '$Target'." -ForegroundColor Red
    Write-Host "Usage: .\scripts\build.ps1 [-Target arcade|snake|maze|hangman|tictactoe]"
    exit 1
}

# ---------------------------------------------------------------
#  Create output dir
# ---------------------------------------------------------------
if (!(Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

# ---------------------------------------------------------------
#  Assemble
# ---------------------------------------------------------------
$objFiles = @()
$failed   = $false

foreach ($f in $filesToBuild) {
    if (!(Test-Path $f)) {
        Write-Host "SKIP (not found): $f" -ForegroundColor Yellow
        continue
    }

    # Put .obj next to .asm so JWlink can find them easily
    $obj = $f -replace '\.asm$', '.obj'

    Write-Host "Assembling: $([System.IO.Path]::GetFileName($f)) ..." -ForegroundColor Cyan
    & $jwasm /Zd /coff /Fo"$obj" /I"$irvine" "$f"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ASSEMBLE FAILED: $f" -ForegroundColor Red
        $failed = $true
        break
    }
    $objFiles += $obj
}

if ($failed -or $objFiles.Count -eq 0) {
    Write-Host "Build aborted." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------
#  Link
# ---------------------------------------------------------------
$fileArgList = @()
foreach ($obj in $objFiles) {
    $fileArgList += "file"
    $fileArgList += "`"$obj`""
}

$exePath = "$out\$exeName"
Write-Host "Linking -> $exeName ..." -ForegroundColor Cyan

& $jwlink format windows pe `
    LIBPATH "$irvine" `
    LIBRARY "$irvine\Irvine32.lib" `
    LIBRARY "$irvine\Kernel32.lib" `
    LIBRARY "$irvine\User32.lib" `
    @fileArgList `
    name "$exePath"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  BUILD OK --> $exePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To run:" -ForegroundColor DarkCyan
    Write-Host "    .\scripts\bin\$exeName" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "LINK FAILED." -ForegroundColor Red
    exit 1
}