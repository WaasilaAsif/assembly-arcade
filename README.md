# Assembly Mini Arcade (Terminal Edition)

Overview
--------
Assembly Mini Arcade is a modular collection of console-based games written in x86 assembly (JWasm / JWLink, MASM-like syntax) that run in a terminal using ASCII rendering. The repository provides a simple menu-driven host (`src/main.asm`) and several game implementations. The code targets a Windows console environment using the `Irvine32` helper library provided by the MASM Runner extension.

What this project contains
-------------------------
- A menu and entry point: `src/main.asm` — provides a simple text menu to select games.
- Game implementations in `src/games/`: currently present are `snake.asm`, `maze.asm`, `hangman.asm`, and `tictactoe.asm`.
- A build helper script: `scripts/build.ps1` — assembles and links either the full arcade (`arcade.exe`) or a single game executable.
- Output directory for built binaries: `scripts/bin/` (created by the build script).

Current status notes
--------------------
- The `src/games/` directory contains working game implementations (Snake, Maze, Hangman, Tic-Tac-Toe).
- Several expected core modules and documentation files are present as placeholders (for example `src/core/*.asm` and `docs/*.md`) and appear to be empty or not implemented yet. The build script assembles files listed in its configuration and will skip missing files.

Key features
------------
- Multiple independent game implementations that can be built together or individually.
- Central menu (`main.asm`) that dispatches into game entry points.
- Build automation via `scripts/build.ps1` that detects the MASM Runner extension and its bundled JWasm/JWlink tools.
- Console-based ASCII rendering and keyboard input using the `Irvine32` helper library.

Prerequisites
-------------
1. Windows with PowerShell (tested on modern Windows versions).
2. Visual Studio Code (recommended) with the MASM Runner extension installed. The build script locates JWasm and JWlink under the MASM Runner extension folder and uses its `Irvine32` helper files.

Installing MASM Runner
----------------------
1. Open VS Code and install the MASM Runner extension (author: istareatscreens).
2. Confirm the extension folder exists under `%USERPROFILE%\.vscode\extensions` and contains `native\JWASM\JWASM.EXE` and `native\JWLINK\JWlink.exe`.

Notes on file encoding
----------------------
All `.asm` source files should be saved without a UTF-8 BOM. JWasm can produce a `Syntax error: ■` if files contain a BOM. A PowerShell snippet is included in `how_to_run.md` to strip BOMs from files if needed.

Building
--------
Open a PowerShell prompt and run the build script from the repository root. Example (from repository root):

```powershell
cd .\scripts
.\build.ps1            # builds the full arcade (arcade.exe)
.\build.ps1 -Target snake      # builds only snake.exe
.\build.ps1 -Target maze       # builds only maze.exe
```

What the script does
- Locates MASM Runner extension and resolves `JWASM.EXE` and `JWlink.exe`.
- Assembles each listed `.asm` into an `.obj` using JWasm.
- Links `.obj` files with `JWlink` and `Irvine32.lib` to produce a Windows PE executable in `scripts/bin`.
- If a per-game target is requested, the script auto-generates a small stub `src/stubs/<game>_main.asm` that calls the game's public entry point so the game can be built and run standalone.

Running
-------
After a successful build the default executable is `scripts/bin/arcade.exe`. Run it from PowerShell or Explorer:

```powershell
.\scripts\bin\arcade.exe
```

The menu will present options to launch individual games. Games typically accept WASD movement and `Q` to quit back to the menu. See `how_to_run.md` for per-game control summaries.

Common issues and troubleshooting
---------------------------------
- "Syntax error: ■" on line 1: source file contains a BOM. Remove BOMs (see `how_to_run.md`).
- `masm-runner extension not found`: install the MASM Runner extension in VS Code.
- `build.ps1 cannot be loaded`: adjust PowerShell execution policy (e.g., `Set-ExecutionPolicy RemoteSigned` as Administrator).
- `SKIP (not found): x.asm`: the build script skips files not present; verify the expected files exist in `src/`.

Project structure
-----------------
Top-level layout (relevant files/directories):

```
assembly-arcade/
	scripts/
		build.ps1        # build script (creates scripts/bin)
	src/
		main.asm         # menu and entry point
		games/
			snake.asm
			maze.asm
			hangman.asm
			tictactoe.asm
		core/             # core modules (placeholders)
		include/          # shared includes (placeholders)
	scripts/bin/        # generated executables
	docs/                # project docs (placeholders)
	how_to_run.md        # additional run/build instructions
```

Developer notes
---------------
- Save `.asm` sources as UTF-8 without BOM.
- The build script will generate stub main files in `src/stubs/` when building per-game targets; these stubs are safe to commit or ignore as needed.
- When adding a new game:
	- Create `src/games/newgame.asm` and expose a public entry point (for example `PUBLIC newgame_start`).
	- Update `$allFiles` in `scripts/build.ps1` if you want the game to be included in the full `arcade` build.

Contributing
------------
- Fixes and improvements are welcome. Please ensure consistent file encoding and follow the repository convention of pushing only source files; do not commit generated binaries or object files.

License
-------
This repository includes a `LICENSE` file at the project root. Refer to that file for license terms.

Contact / Maintainers
---------------------
Check the project `README` or project metadata for maintainers. If none are available, open an issue in the repository to request changes or report problems.

------
Updated to match repository contents as of current scan. If you want, I can also:
- consolidate the empty core modules into a TODO list and add a short developer roadmap in `docs/`;
- run a build and report any build-time errors on this machine (requires MASM Runner installed).
