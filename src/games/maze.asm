INCLUDE Irvine32.inc

ROWS EQU 11
COLS EQU 20

; Color constants (Irvine32 expects color in EAX)
COLOR_YELLOW EQU 14
COLOR_CYAN   EQU 11
COLOR_GREEN  EQU 10
COLOR_RED    EQU 12
COLOR_WHITE  EQU 15

.data
maze BYTE \
    "+---+-----+---+----+",\
    "|   |     |   |    |",\
    "| | | +-- | | | +- |",\
    "| |   |   | |   |  |",\
    "| +-+ | --+ +-+ +- |",\
    "|   | |   |   |    |",\
    "+-- | +-+ | --+ ---+",\
    "|   |   | |   |    |",\
    "| --+ | | +-- | -- |",\
    "|     |       |    |",\
    "+-----+-------+----+"

playerRow BYTE 1
playerCol BYTE 1
goalRow   BYTE 9
goalCol   BYTE 18
currentRow BYTE 0
currentCol BYTE 0

msgTitle    BYTE "****** Mini Maze Game *******", 0Dh, 0Ah
            BYTE " ----------------------------", 0Dh, 0Ah, 0
msgHelp     BYTE "> Move with W A S D. Press Q to quit. <",0
msgWin      BYTE "You reached the goal!",0
msgQuit     BYTE "Goodbye!",0

.code
PUBLIC maze_start
maze_start PROC
    mov playerRow, 1
    mov playerCol, 1
    call Clrscr
    call maze_HideCursor

GameLoop:
    call DrawMaze
    call ReadChar

    cmp al, 'q'
    je QuitGame
    cmp al, 'Q'
    je QuitGame
    cmp al, 'w'
    je MoveUp
    cmp al, 'W'
    je MoveUp
    cmp al, 's'
    je MoveDown
    cmp al, 'S'
    je MoveDown
    cmp al, 'a'
    je MoveLeft
    cmp al, 'A'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp al, 'D'
    je MoveRight
    jmp GameLoop

MoveUp:
    movzx eax, playerRow
    cmp eax, 0
    je GameLoop
    dec eax
    movzx ebx, playerCol
    call CanMove
    cmp al, 0
    jne GameLoop
    dec playerRow
    jmp CheckWin

MoveDown:
    movzx eax, playerRow
    inc eax
    cmp eax, ROWS         ; ADD bounds check
    jge GameLoop
    movzx ebx, playerCol
    call CanMove
    cmp al, 0
    jne GameLoop
    inc playerRow
    jmp CheckWin

MoveLeft:
    movzx eax, playerRow
    movzx ebx, playerCol
    cmp ebx, 0
    je GameLoop
    dec ebx
    call CanMove
    cmp al, 0
    jne GameLoop
    dec playerCol
    jmp CheckWin

MoveRight:
    movzx eax, playerRow
    movzx ebx, playerCol
    inc ebx
    cmp ebx, COLS         ; ADD bounds check
    jge GameLoop
    call CanMove
    cmp al, 0
    jne GameLoop
    inc playerCol
    jmp CheckWin

CheckWin:
    mov al, playerRow
    cmp al, goalRow
    jne GameLoop
    mov al, playerCol
    cmp al, goalCol
    jne GameLoop
    jmp WinGame

WinGame:
    call Clrscr
    ; Color win message (green), then reset
    mov eax, COLOR_GREEN
    call SetTextColor
    mov edx, OFFSET msgWin
    call WriteString
    call Crlf
    mov eax, COLOR_WHITE
    call SetTextColor
    call maze_ShowCursor
    call WaitMsg
    ret

QuitGame:
    call Clrscr
    ; Color quit message (cyan), then reset
    mov eax, COLOR_CYAN
    call SetTextColor
    mov edx, OFFSET msgQuit
    call WriteString
    call Crlf
    mov eax, COLOR_WHITE
    call SetTextColor
    call maze_ShowCursor
    ret
maze_start ENDP

DrawMaze PROC
    mov dh, 0
    mov dl, 0
    call Gotoxy
    ; Title in yellow
    mov eax, COLOR_YELLOW
    call SetTextColor
    mov edx, OFFSET msgTitle
    call WriteString
    call Crlf

    ; Help in cyan
    mov eax, COLOR_CYAN
    call SetTextColor
    mov edx, OFFSET msgHelp
    call WriteString
    call Crlf
    call Crlf

    ; Reset to default (white) for maze rendering
    mov eax, COLOR_WHITE
    call SetTextColor

    mov esi, OFFSET maze
    mov currentRow, 0

RowLoop:
    mov currentCol, 0
    mov ecx, COLS

ColLoop:
    mov al, [esi]
    mov bl, currentRow
    cmp bl, playerRow
    jne CheckGoal
    mov bl, currentCol
    cmp bl, playerCol
    jne CheckGoal
    mov al, 'P'
    jmp PrintCell

CheckGoal:
    mov bl, currentRow
    cmp bl, goalRow
    jne PrintCell
    mov bl, currentCol
    cmp bl, goalCol
    jne PrintCell
    mov al, 'G'

PrintCell:
    push ecx
    call WriteChar
    pop ecx
    inc esi
    inc currentCol
    loop ColLoop
    call Crlf
    inc currentRow
    mov al, currentRow
    cmp al, ROWS
    jl RowLoop
    ; Move cursor below the maze to avoid the blinking cursor jumping across
    mov dh, ROWS
    add dh, 3
    mov dl, 0
    call Gotoxy
    ret
DrawMaze ENDP

CanMove PROC
    mov esi, OFFSET maze
    mov ecx, eax
    imul ecx, COLS
    add ecx, ebx
    add esi, ecx
    mov al, [esi]
    cmp al, '|'
    je WallCell
    cmp al, '-'
    je WallCell
    cmp al, '+'       ; ADD THIS
    je WallCell
    jmp OpenCell
WallCell:
    mov al, 1
    ret
OpenCell:
    mov al, 0
    ret
CanMove ENDP

; ---------------------------
; Hide/Show console cursor
; ---------------------------
maze_HideCursor PROC
    pushad
    push -11
    call GetStdHandle
    mov ebx, eax
    sub esp, 8
    mov dword ptr [esp], 100
    mov dword ptr [esp+4], 0
    lea eax, [esp]
    push eax
    push ebx
    call SetConsoleCursorInfo
    add esp, 8
    popad
    ret
maze_HideCursor ENDP

maze_ShowCursor PROC
    pushad
    push -11
    call GetStdHandle
    mov ebx, eax
    sub esp, 8
    mov dword ptr [esp], 100
    mov dword ptr [esp+4], 1
    lea eax, [esp]
    push eax
    push ebx
    call SetConsoleCursorInfo
    add esp, 8
    popad
    ret
maze_ShowCursor ENDP

END 
