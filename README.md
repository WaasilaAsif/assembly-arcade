# 🕹️ Assembly Mini Arcade (Terminal Edition)

A modular 8086 Assembly project implementing 4 classic games:

* Snake 🐍
* Maze 🧩
* Hangman 🔤
* Tic-Tac-Toe ❌⭕

This version runs in a **terminal environment** using ASCII rendering.

---

## 🎯 Project Goal

* Learn low-level programming concepts
* Understand memory and control flow in Assembly
* Build a modular multi-game system
* Simulate a game engine using terminal rendering

---

## ⚙️ Tech Stack
* Output: Terminal (ASCII rendering)
* Platform: Linux / Windows (via terminal)

---

## 🚀 How to Run

## 🧠 Architecture Overview

### 🔹 Core Modules

| File       | Responsibility      |
| ---------- | ------------------- |
| render.asm | All screen drawing  |
| input.asm  | Keyboard handling   |
| loop.asm   | Game loop structure |
| utils.asm  | Delay, helpers      |

---

### 🔹 Games

Each game is independent:

* snake.asm
* maze.asm
* hangman.asm
* tictac.asm

Each game must expose:

```asm
start_game:
```

---

## 🔥 CRITICAL TEAM RULES

### 1. No Direct Printing

❌ DO NOT:

```asm
; direct syscall / printf-like behavior
```

✅ DO:

```asm
call draw_char
call draw_string
```

---

### 2. Game Loop Standard

Every game MUST follow:

```text
Input → Update → Render → Delay
```

---

### 3. Register Safety

Every procedure MUST:

```asm
push all used registers
...
pop all registers
ret
```

Breaking this = breaking the whole program.

---

### 4. Separation of Concerns

| Layer | Responsibility    |
| ----- | ----------------- |
| Game  | Logic only        |
| Core  | Rendering + Input |

---

### 5. Shared Constants

Use:

```asm
include/common.inc
```

Example:

```asm
SCREEN_WIDTH  equ 80
SCREEN_HEIGHT equ 25
```

---

## 🧱 Rendering System (Terminal)

We simulate a grid using ASCII characters.

### Example:

* Snake head → 'O'
* Snake body → 'o'
* Food → '*'
* Wall → '#'

---

## 🎮 Controls (Standardized)

| Key | Action |
| --- | ------ |
| W   | Up     |
| S   | Down   |
| A   | Left   |
| D   | Right  |
| Q   | Quit   |

---

## 👥 Team Roles

| Role       | Responsibility         |
| ---------- | ---------------------- |
| Core Dev   | render.asm + input.asm |
| Game Dev 1 | Snake                  |
| Game Dev 2 | Maze                   |
| Game Dev 3 | Hangman                |
| Game Dev 4 | TicTacToe              |

---

## 📌 Development Plan

### Phase 1

* Setup repo
* Build menu system

### Phase 2

* Implement render + input systems

### Phase 3

* Build games independently

### Phase 4

* Integrate into main menu

---

## 💡 Future Upgrade (Optional)

The system is designed so that:

* render.asm can be replaced
* allowing graphical version later

---

## 🧠 Debugging Tips

If something breaks:

1. Check registers
2. Check memory
3. Check control flow

Assembly is unforgiving — be precise.

---

## 🏁 Final Goal

A clean, modular, terminal-based arcade system in Assembly.

Not just games — a system.
