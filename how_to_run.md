# How to Run — Assembly Arcade

## Prerequisites

1. **Install VS Code** — https://code.visualstudio.com
2. **Install the MASM Runner extension**
   - Open VS Code → Extensions (`Ctrl+Shift+X`)
   - Search **MASM Runner** (by istareatscreens) and install it
   - This automatically installs JWasm and JWlink internally
3. **Clone the repository**
   ```powershell
   git clone <your-repo-url> e:\assembly-arcade
   cd e:\assembly-arcade
   ```

---

## First Time Setup

Strip the BOM from all `.asm` files (only needed once after cloning):

```powershell
Get-ChildItem "e:\assembly-arcade\src" -Recurse -Filter "*.asm" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content | Set-Content $_.FullName -Encoding UTF8NoBOM
}
```

> **Why?** VS Code sometimes saves files as UTF-8 with BOM by default. JWasm does not understand the BOM and will fail on line 1 with a `Syntax error: ■`.

---

## Building

```powershell
cd e:\assembly-arcade\scripts
.\build.ps1
```

A successful build looks like:

```
Assembling e:\assembly-arcade\src\main.asm ...        0 errors
Assembling e:\assembly-arcade\src\games\maze.asm ...  0 errors
Assembling e:\assembly-arcade\src\games\snake.asm ... 0 errors
...
Linking...
Build succeeded: e:\assembly-arcade\bin\arcade.exe
```

---

## Running

```powershell
e:\assembly-arcade\bin\arcade.exe
```

Use the menu to select a game:

```
Assembly Mini Arcade

1. Snake
2. Maze
3. Hangman
4. Tic-Tac-Toe
Q. Quit
```

---

## Controls

### Maze
| Key | Action |
|-----|--------|
| `W` | Move up |
| `A` | Move left |
| `S` | Move down |
| `D` | Move right |
| `Q` | Quit to menu |

Reach `G` (the goal) to win.

---

## Project Structure

```
assembly-arcade/
    scripts/
        build.ps1           ← run this to build
    src/
        main.asm            ← menu and entry point
        games/
            maze.asm
            snake.asm
            hangman.asm
            tictactoe.asm
    bin/
        arcade.exe          ← generated after build
    docs/
    README.md
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Syntax error: ■` on line 1 | File saved with BOM | Run the BOM strip command above |
| `build.ps1 cannot be loaded` | PowerShell execution policy | Run `Set-ExecutionPolicy RemoteSigned` as Administrator |
| `SKIP (not found): x.asm` | Game not implemented yet | Safe to ignore, stub will be used |
| `undefined reference _x@0` | Stub `.asm` file missing from `src\games\` | Add a stub file for that game |
| `.obj: No such file or directory` | JWasm failed silently | Check the assembly error printed above the link step |

---

## Notes for Developers

- Save all `.asm` files as **UTF-8 without BOM** — check the bottom-right corner of VS Code before saving
- Add `*.obj` and `*.exe` to `.gitignore` — never commit generated files
- Each game is fully self-contained in its own `.asm` file
- To add a new game: create `src/games/newgame.asm`, add `PUBLIC newgame_start`, add it to `$files` in `build.ps1`, and add a `PROTO` + menu option in `main.asm`