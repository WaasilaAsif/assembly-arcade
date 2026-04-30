; ============================================================
;  snake.asm  --  Snake Game for Assembly Mini Arcade
;  Uses: Irvine32 (console, 32-bit protected mode)
;  Controls: WASD to move, Q to quit
; ============================================================

INCLUDE Irvine32.inc

; ---------- tuneable constants ----------
BOARD_LEFT   EQU  2          ; left edge column of play area
BOARD_TOP    EQU  4          ; top edge row of play area
BOARD_W      EQU  40         ; inner width  (columns of cells)
BOARD_H      EQU  20         ; inner height (rows of cells)
MAX_LEN      EQU  200        ; maximum snake length
TICK_MS      EQU  120        ; milliseconds per game tick

; directions
DIR_UP    EQU  0
DIR_DOWN  EQU  1
DIR_LEFT  EQU  2
DIR_RIGHT EQU  3

; colours (Irvine32 attribute nibbles: hi=bg lo=fg)
COL_BORDER  EQU  0Bh         ; bright cyan
COL_SNAKE   EQU  0Ah         ; bright green
COL_HEAD    EQU  0Eh         ; bright yellow
COL_FOOD    EQU  0Ch         ; bright red
COL_SCORE   EQU  0Fh         ; bright white
COL_TITLE   EQU  0Dh         ; bright magenta
COL_DEAD    EQU  04h         ; red on black
COL_NORMAL  EQU  07h         ; restore default

; -------------------------------------------------------
.data
; --- snake body stored as parallel byte arrays ----------
snakeRow   BYTE MAX_LEN DUP(0)
snakeCol   BYTE MAX_LEN DUP(0)
snakeLen   DWORD 4            ; starting length
snakeHead  DWORD 0            ; index of head in circular buffer
snakeTail  DWORD 0            ; index of tail

direction  BYTE  DIR_RIGHT
nextDir    BYTE  DIR_RIGHT

foodRow    BYTE  10
foodCol    BYTE  20

score      DWORD 0
gameOver   BYTE  0
randSeed   DWORD 12345h

; --- strings ---
titleStr   BYTE  "  ~~  SNAKE  ~~  ", 0
scoreLabel BYTE  "Score: ", 0
helpStr    BYTE  "WASD=move  Q=quit", 0
deadStr    BYTE  "  GAME OVER!  Press any key...", 0
newlineStr BYTE  0Dh, 0Ah, 0

snakeBodyCh  BYTE  0B2h       ; block character for body
snakeHeadCh  BYTE  0FEh       ; solid square for head
foodCh       BYTE  04h        ; diamond suit for food
borderH      BYTE  0CDh       ; double-line horizontal
borderV      BYTE  0BAh       ; double-line vertical
cornerTL     BYTE  0C9h
cornerTR     BYTE  0BBh
cornerBL     BYTE  0C8h
cornerBR     BYTE  0BCh

.code
PUBLIC snake_start

; ============================================================
;  snake_start  --  entry point called from main.asm
; ============================================================
snake_start PROC
    call  Clrscr
    call  HideCursor

    ; ---------- initialise state ----------
    mov   gameOver, 0
    mov   score,    0
    mov   snakeLen, 4
    mov   snakeHead, 3        ; head is at index 3 initially
    mov   snakeTail, 0

    ; place initial snake horizontally in the middle
    mov   snakeRow[0], BOARD_H/2
    mov   snakeCol[0], BOARD_W/2 - 3
    mov   snakeRow[1], BOARD_H/2
    mov   snakeCol[1], BOARD_W/2 - 2
    mov   snakeRow[2], BOARD_H/2
    mov   snakeCol[2], BOARD_W/2 - 1
    mov   snakeRow[3], BOARD_H/2
    mov   snakeCol[3], BOARD_W/2

    mov   direction, DIR_RIGHT
    mov   nextDir,   DIR_RIGHT

    call  PlaceFood
    call  DrawBorder
    call  DrawScore

GameLoop:
    call  DrawFrame
    call  CheckInput          ; non-blocking key read
    call  MoveSnake
    cmp   gameOver, 1
    je    DeadScreen

    ; sleep for one tick
    mov   eax, TICK_MS
    call  Delay
    jmp   GameLoop

DeadScreen:
    call  DrawDeadMsg
    call  ReadChar            ; wait for any key
    call  ShowCursor
    call  Clrscr
    ret
snake_start ENDP

; ============================================================
;  DrawBorder  --  draw the double-line box once
; ============================================================
DrawBorder PROC
    ; title above box
    mov   eax, COL_TITLE
    call  SetTextColor
    mov   dh, BOARD_TOP - 2
    mov   dl, BOARD_LEFT
    call  Gotoxy
    mov   edx, OFFSET titleStr
    call  WriteString

    mov   eax, COL_BORDER
    call  SetTextColor

    ; top edge
    mov   dh, BOARD_TOP - 1
    mov   dl, BOARD_LEFT - 1
    call  Gotoxy
    mov   al, cornerTL
    call  WriteChar
    mov   ecx, BOARD_W
@@topLoop:
    mov   al, borderH
    call  WriteChar
    loop  @@topLoop
    mov   al, cornerTR
    call  WriteChar

    ; side edges
    mov   ecx, BOARD_H
    mov   bl, BOARD_TOP        ; row counter
@@sideLoop:
    mov   dh, bl
    mov   dl, BOARD_LEFT - 1
    call  Gotoxy
    mov   al, borderV
    call  WriteChar
    mov   dh, bl
    mov   dl, BOARD_LEFT + BOARD_W
    call  Gotoxy
    mov   al, borderV
    call  WriteChar
    inc   bl
    loop  @@sideLoop

    ; bottom edge
    mov   dh, BOARD_TOP + BOARD_H
    mov   dl, BOARD_LEFT - 1
    call  Gotoxy
    mov   al, cornerBL
    call  WriteChar
    mov   ecx, BOARD_W
@@botLoop:
    mov   al, borderH
    call  WriteChar
    loop  @@botLoop
    mov   al, cornerBR
    call  WriteChar

    ; help text below box
    mov   eax, COL_NORMAL
    call  SetTextColor
    mov   dh, BOARD_TOP + BOARD_H + 1
    mov   dl, BOARD_LEFT - 1
    call  Gotoxy
    mov   edx, OFFSET helpStr
    call  WriteString

    ret
DrawBorder ENDP

; ============================================================
;  DrawScore  --  update score line
; ============================================================
DrawScore PROC
    mov   eax, COL_SCORE
    call  SetTextColor
    mov   dh, BOARD_TOP - 2
    mov   dl, BOARD_LEFT + 20
    call  Gotoxy
    mov   edx, OFFSET scoreLabel
    call  WriteString
    mov   eax, score
    call  WriteDec
    ret
DrawScore ENDP

; ============================================================
;  DrawFrame  --  erase tail, draw food, draw head
;  (incremental -- only touch changed cells)
; ============================================================
DrawFrame PROC
    ; erase old tail position (snakeTail index)
    mov   esi, snakeTail
    movzx eax, snakeRow[esi]
    movzx ebx, snakeCol[esi]
    call  GotoCell
    mov   eax, COL_NORMAL
    call  SetTextColor
    mov   al, ' '
    call  WriteChar

    ; draw food
    movzx eax, foodRow
    movzx ebx, foodCol
    call  GotoCell
    mov   eax, COL_FOOD
    call  SetTextColor
    mov   al, foodCh
    call  WriteChar

    ; draw entire visible snake body (green blocks)
    mov   eax, COL_SNAKE
    call  SetTextColor
    mov   ecx, snakeLen
    mov   esi, snakeTail
@@bodyLoop:
    movzx eax, snakeRow[esi]
    movzx ebx, snakeCol[esi]
    call  GotoCell
    mov   al, snakeBodyCh
    call  WriteChar
    inc   esi
    cmp   esi, MAX_LEN
    jl    @@noWrap1
    mov   esi, 0
@@noWrap1:
    loop  @@bodyLoop

    ; draw head in different colour
    mov   esi, snakeHead
    movzx eax, snakeRow[esi]
    movzx ebx, snakeCol[esi]
    call  GotoCell
    mov   eax, COL_HEAD
    call  SetTextColor
    mov   al, snakeHeadCh
    call  WriteChar

    ret
DrawFrame ENDP

; ============================================================
;  GotoCell  --  position cursor at board cell (row=eax, col=ebx)
;  Both 0-based relative to board interior
; ============================================================
GotoCell PROC
    add   eax, BOARD_TOP
    add   ebx, BOARD_LEFT
    mov   dh, al
    mov   dl, bl
    call  Gotoxy
    ret
GotoCell ENDP

; ============================================================
;  CheckInput  --  non-blocking key poll
;  GetNumberOfConsoleInputEvents avoids blocking (no CheckKeystroke needed)
; ============================================================
GetStdHandle                  PROTO STDCALL :DWORD
GetNumberOfConsoleInputEvents PROTO STDCALL :DWORD, :PTR DWORD

.data?
hStdin_s  DWORD ?
evtCount  DWORD ?

.code
CheckInput PROC
    cmp   hStdin_s, 0
    jne   @@haveHandle
    INVOKE GetStdHandle, -10          ; STD_INPUT_HANDLE = -10
    mov   hStdin_s, eax
@@haveHandle:
    INVOKE GetNumberOfConsoleInputEvents, hStdin_s, ADDR evtCount
    cmp   evtCount, 0
    je    @@noKey
    call  ReadChar            ; consume the key -> AL
    cmp   al, 'q'
    je    @@quit
    cmp   al, 'Q'
    je    @@quit
    cmp   al, 'w'
    je    @@up
    cmp   al, 'W'
    je    @@up
    cmp   al, 's'
    je    @@down
    cmp   al, 'S'
    je    @@down
    cmp   al, 'a'
    je    @@left
    cmp   al, 'A'
    je    @@left
    cmp   al, 'd'
    je    @@right
    cmp   al, 'D'
    je    @@right
    jmp   @@noKey

@@up:
    cmp   direction, DIR_DOWN  ; can't reverse
    je    @@noKey
    mov   nextDir, DIR_UP
    jmp   @@noKey
@@down:
    cmp   direction, DIR_UP
    je    @@noKey
    mov   nextDir, DIR_DOWN
    jmp   @@noKey
@@left:
    cmp   direction, DIR_RIGHT
    je    @@noKey
    mov   nextDir, DIR_LEFT
    jmp   @@noKey
@@right:
    cmp   direction, DIR_LEFT
    je    @@noKey
    mov   nextDir, DIR_RIGHT
    jmp   @@noKey
@@quit:
    mov   gameOver, 1
@@noKey:
    ret
CheckInput ENDP

; ============================================================
;  MoveSnake  --  advance snake one step
; ============================================================
MoveSnake PROC
    ; commit buffered direction
    mov   al, nextDir
    mov   direction, al

    ; compute new head position
    mov   esi, snakeHead
    movzx eax, snakeRow[esi]   ; current head row
    movzx ebx, snakeCol[esi]   ; current head col

    cmp   direction, DIR_UP
    jne   @@notUp
    dec   eax
    jmp   @@moved
@@notUp:
    cmp   direction, DIR_DOWN
    jne   @@notDown
    inc   eax
    jmp   @@moved
@@notDown:
    cmp   direction, DIR_LEFT
    jne   @@notLeft
    dec   ebx
    jmp   @@moved
@@notLeft:
    inc   ebx                  ; DIR_RIGHT
@@moved:

    ; --- wall collision ---
    cmp   eax, 0
    jl    @@dead
    cmp   eax, BOARD_H
    jge   @@dead
    cmp   ebx, 0
    jl    @@dead
    cmp   ebx, BOARD_W
    jge   @@dead

    ; --- self collision (check every body segment) ---
    mov   ecx, snakeLen
    mov   edi, snakeTail
@@selfLoop:
    movzx edx, snakeRow[edi]
    cmp   edx, eax
    jne   @@selfNext
    movzx edx, snakeCol[edi]
    cmp   edx, ebx
    je    @@dead
@@selfNext:
    inc   edi
    cmp   edi, MAX_LEN
    jl    @@noWrap2
    mov   edi, 0
@@noWrap2:
    loop  @@selfLoop

    ; --- advance head pointer ---
    inc   esi
    cmp   esi, MAX_LEN
    jl    @@noWrapHead
    mov   esi, 0
@@noWrapHead:
    mov   snakeHead, esi
    mov   snakeRow[esi], al    ; store new row (al = eax low byte)
    push  eax
    mov   eax, ebx
    mov   snakeCol[esi], al    ; store new col
    pop   eax

    ; --- food eaten? ---
    cmp   al, foodRow
    jne   @@noFood
    push  eax
    mov   eax, ebx
    cmp   al, foodCol
    pop   eax
    jne   @@noFood

    ; grow: don't advance tail
    inc   snakeLen
    add   score, 10
    call  DrawScore
    call  PlaceFood
    jmp   @@done

@@noFood:
    ; advance tail
    mov   esi, snakeTail
    inc   esi
    cmp   esi, MAX_LEN
    jl    @@noWrapTail
    mov   esi, 0
@@noWrapTail:
    mov   snakeTail, esi
    jmp   @@done

@@dead:
    mov   gameOver, 1
@@done:
    ret
MoveSnake ENDP

; ============================================================
;  PlaceFood  --  pseudo-random position not on snake
; ============================================================
PlaceFood PROC
@@tryAgain:
    ; LCG: seed = seed * 1664525 + 1013904223
    mov   eax, randSeed
    imul  eax, 1664525
    add   eax, 1013904223
    mov   randSeed, eax

    ; row = seed mod BOARD_H
    mov   edx, 0
    mov   ecx, BOARD_H
    div   ecx
    mov   foodRow, dl

    ; col from upper bits
    mov   eax, randSeed
    shr   eax, 8
    mov   edx, 0
    mov   ecx, BOARD_W
    div   ecx
    mov   foodCol, dl

    ; make sure it's not on the snake
    mov   ecx, snakeLen
    mov   esi, snakeTail
@@checkLoop:
    movzx eax, snakeRow[esi]
    cmp   al, foodRow
    jne   @@checkNext
    movzx eax, snakeCol[esi]
    cmp   al, foodCol
    je    @@tryAgain
@@checkNext:
    inc   esi
    cmp   esi, MAX_LEN
    jl    @@noWrap3
    mov   esi, 0
@@noWrap3:
    loop  @@checkLoop
    ret
PlaceFood ENDP

; ============================================================
;  DrawDeadMsg  --  flash "GAME OVER" in the centre
; ============================================================
DrawDeadMsg PROC
    mov   eax, COL_DEAD
    call  SetTextColor
    mov   dh, BOARD_TOP + BOARD_H/2
    mov   dl, BOARD_LEFT + BOARD_W/2 - 15
    call  Gotoxy
    mov   edx, OFFSET deadStr
    call  WriteString
    mov   eax, COL_NORMAL
    call  SetTextColor
    ret
DrawDeadMsg ENDP

; ============================================================
;  HideCursor / ShowCursor helpers
; ============================================================
HideCursor PROC
    ; move cursor off-screen so it doesn't blink on the board
    mov   dh, 40
    mov   dl, 0
    call  Gotoxy
    ret
HideCursor ENDP

ShowCursor PROC
    mov   dh, 0
    mov   dl, 0
    call  Gotoxy
    ret
ShowCursor ENDP

END