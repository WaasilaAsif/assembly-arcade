# filepath: e:\assembly-arcade\build.ps1

$jwasm  = "c:\Users\Home\.vscode\extensions\istareatscreens.masm-runner-0.9.1\native\JWASM\JWASM.EXE"
$jwlink = "c:\Users\Home\.vscode\extensions\istareatscreens.masm-runner-0.9.1\native\JWLINK\JWlink.exe"
$irvine = "c:\Users\Home\.vscode\extensions\istareatscreens.masm-runner-0.9.1\native\irvine"
$src    = "e:\assembly-arcade\src"
$out    = "e:\assembly-arcade\bin"

# Create output dir if it doesn't exist
if (!(Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

$files = @(
    "$src\main.asm",
    "$src\games\maze.asm",
    "$src\games\snake.asm",
    "$src\games\hangman.asm",
    "$src\games\tictactoe.asm"
)

$failed = $false

# Assemble each file
foreach ($f in $files) {
    if (!(Test-Path $f)) {
        Write-Host "SKIP (not found): $f" -ForegroundColor Yellow
        continue
    }
    $obj = $f -replace '\.asm$', '.obj'
    Write-Host "Assembling $f ..." -ForegroundColor Cyan
    & $jwasm /Zd /coff /Fo"$obj" /I"$irvine" "$f"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $f" -ForegroundColor Red
        $failed = $true
        break
    }
}

if ($failed) { exit 1 }

# Collect only .obj files that actually exist
$objFiles = $files |
    ForEach-Object { $_ -replace '\.asm$', '.obj' } |
    Where-Object { Test-Path $_ }

if ($objFiles.Count -eq 0) {
    Write-Host "No .obj files found to link." -ForegroundColor Red
    exit 1
}

# Build JWlink file arguments as a flat array
$fileArgList = @()
foreach ($obj in $objFiles) {
    $fileArgList += "file"
    $fileArgList += "`"$obj`""
}

Write-Host "Linking..." -ForegroundColor Cyan
& $jwlink format windows pe `
    LIBPATH "$irvine" `
    LIBRARY "$irvine\Irvine32.lib" `
    LIBRARY "$irvine\Kernel32.lib" `
    LIBRARY "$irvine\User32.lib" `
    @fileArgList `
    name "$out\arcade.exe"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build succeeded: $out\arcade.exe" -ForegroundColor Green
} else {
    Write-Host "Link failed." -ForegroundColor Red
    exit 1
}