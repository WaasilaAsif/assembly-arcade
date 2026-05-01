;--------------------------------------------------------------
; TicTacToe.asm - Tic Tac Toe Game in x86 Assembly (MASM)
; Uses Irvine32 Library for I/O and Colors
; Two Players (X and O) with Optional Random AI for Player O
;--------------------------------------------------------------

.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

PUBLIC tictactoe_start

; Foreground colors
black        EQU 0
blue         EQU 1
green        EQU 2
cyan         EQU 3
red          EQU 4
magenta      EQU 5
brown        EQU 6
lightGray    EQU 7
darkGray     EQU 8
lightBlue    EQU 9
lightGreen   EQU 10
lightCyan    EQU 11
lightRed     EQU 12
lightMagenta EQU 13
yellow       EQU 14
white        EQU 15

bgBlack      EQU 0
bgBlue       EQU 16
bgGreen      EQU 32
bgRed        EQU 64
bgWhite      EQU 112

COLOR_X      EQU lightCyan  + bgBlack
COLOR_O      EQU yellow     + bgBlack
COLOR_WIN    EQU lightGreen + bgBlack
COLOR_ERR    EQU lightRed   + bgBlack
COLOR_GUIDE  EQU lightGray  + bgBlack
COLOR_NORM   EQU white      + bgBlack

.data

board           BYTE 9 DUP('-')
currentPlayer   BYTE 'X'
moveCount       BYTE 0
aiMode          BYTE 0
winLine         BYTE 3 DUP(0)

msgTitle        BYTE "==============================", 0Dh, 0Ah
BYTE "   TIC TAC TOE - MASM Game   ", 0Dh, 0Ah
BYTE "==============================", 0Dh, 0Ah, 0

msgGuideHead    BYTE "  Position Guide:", 0Dh, 0Ah, 0
msgGuide1       BYTE "  1 | 2 | 3", 0Dh, 0Ah, 0
msgGuide2       BYTE "  4 | 5 | 6", 0Dh, 0Ah, 0
msgGuide3       BYTE "  7 | 8 | 9", 0Dh, 0Ah, 0
msgDivider      BYTE "------------------------------", 0Dh, 0Ah, 0

msgModePrompt   BYTE "Select Mode:", 0Dh, 0Ah
BYTE "  1 = Two Players", 0Dh, 0Ah
BYTE "  2 = Player vs Computer (AI)", 0Dh, 0Ah
BYTE "Enter choice (1 or 2): ", 0

msgBoardTop     BYTE "  Current Board:", 0Dh, 0Ah, 0
msgRow1         BYTE "  ", 0
msgSep          BYTE " | ", 0
msgNewLine      BYTE 0Dh, 0Ah, 0
msgRowDiv       BYTE "  -----------", 0Dh, 0Ah, 0

msgTurnX        BYTE "  Player X's Turn. Enter position (1-9): ", 0
msgTurnO        BYTE "  Player O's Turn. Enter position (1-9): ", 0
msgAITurn       BYTE "  Computer (O) is thinking...", 0Dh, 0Ah, 0

msgInvRange     BYTE "  [!] Invalid! Enter a number from 1 to 9.", 0Dh, 0Ah, 0
msgOccupied     BYTE "  [!] That position is already taken!", 0Dh, 0Ah, 0

msgWinX         BYTE 0Dh, 0Ah, "  *** Player X WINS! Congratulations! ***", 0Dh, 0Ah, 0
msgWinO         BYTE 0Dh, 0Ah, "  *** Player O WINS! Congratulations! ***", 0Dh, 0Ah, 0
msgWinAI        BYTE 0Dh, 0Ah, "  *** Computer (O) WINS! Better luck next time! ***", 0Dh, 0Ah, 0
msgDraw         BYTE 0Dh, 0Ah, "  *** It's a DRAW! Well played! ***", 0Dh, 0Ah, 0

msgPlayAgain    BYTE 0Dh, 0Ah, "  Play again? (Y/N): ", 0
msgBye          BYTE "  Thanks for playing! Goodbye!", 0Dh, 0Ah, 0
msgInvMode      BYTE "  [!] Invalid choice. Defaulting to Two Players.", 0Dh, 0Ah, 0

.code

tictactoe_start PROC

call Randomize

mov  eax, COLOR_NORM
call SetTextColor
mov  edx, OFFSET msgTitle
call WriteString

call ShowGuide
call AskGameMode

GameLoop:
call Clrscr
call DisplayBoard

mov  bl, currentPlayer
cmp  bl, 'O'
jne  HumanTurn
mov  bl, aiMode
cmp  bl, 1
jne  HumanTurn
call AIMove
jmp  AfterInput

HumanTurn:
call TakeInput

AfterInput:
call CheckWin
cmp  eax, 1
je   GameOver

call CheckDraw
cmp  eax, 1
je   DrawOver

call SwitchPlayer
jmp  GameLoop

GameOver:
call Clrscr
call DisplayBoard
call AnnounceWinner
call PlayAgainPrompt
jmp  DoneCheck

DrawOver:
call Clrscr
call DisplayBoard
mov  eax, COLOR_NORM
call SetTextColor
mov  edx, OFFSET msgDraw
call WriteString
call PlayAgainPrompt

DoneCheck:
cmp  eax, 1
je   RestartGame
jmp  ExitGame

RestartGame:
call ResetBoard
call ShowGuide
jmp  GameLoop

ExitGame:
mov  eax, COLOR_NORM
call SetTextColor
mov  edx, OFFSET msgBye
call WriteString
call WaitMsg

ret

tictactoe_start ENDP

; -----------------------------------------------
; PROC: ShowGuide
; Shows the position reference guide (1-9 layout)
; -----------------------------------------------
ShowGuide PROC USES eax edx
 
    mov  eax, COLOR_GUIDE
    call SetTextColor
 
    mov  edx, OFFSET msgGuideHead
    call WriteString
    mov  edx, OFFSET msgGuide1
    call WriteString
    mov  edx, OFFSET msgGuide2
    call WriteString
    mov  edx, OFFSET msgGuide3
    call WriteString
    mov  edx, OFFSET msgDivider
    call WriteString
 
    mov  eax, COLOR_NORM
    call SetTextColor
 
    ret
ShowGuide ENDP
 
;--------------------------------------------------
; PROC: AskGameMode
; Prompts user to select 1 (2 players) or 2 (vs AI)
; Sets aiMode variable accordingly
;--------------------------------------------------
AskGameMode PROC USES eax edx
 
    mov  eax, COLOR_NORM
    call SetTextColor
    mov  edx, OFFSET msgModePrompt
    call WriteString
 
    call ReadInt                
 
    cmp  eax, 1
    je   SetTwoPlayer
    cmp  eax, 2
    je   SetAI
 
    mov  eax, COLOR_ERR
    call SetTextColor
    mov  edx, OFFSET msgInvMode
    call WriteString
    mov  eax, COLOR_NORM
    call SetTextColor
 
SetTwoPlayer:
    mov  aiMode, 0
    jmp  ModeDone
 
SetAI:
    mov  aiMode, 1
 
ModeDone:
    ret
AskGameMode ENDP
 
; ---------------------------------------------
; PROC: DisplayBoard
; Prints the current 3x3 board state with colors
; Uses esi as the board index register (0to8)
; ---------------------------------------------
DisplayBoard PROC USES eax ebx ecx edx esi
 
    mov  eax, COLOR_NORM
    call SetTextColor
 
    mov  edx, OFFSET msgBoardTop
    call WriteString
 
    mov  esi, 0
    mov  ecx, 3                
 
RowLoop:
    push ecx                   
 
    mov  edx, OFFSET msgRow1
    call WriteString            
 
    mov  ecx, 3                 
 
ColLoop:
    mov  al, board[esi]
 
    cmp  al, 'X'
    je   PrintX
    cmp  al, 'O'
    je   PrintO
 
    push eax
    mov  eax, COLOR_NORM
    call SetTextColor
    pop  eax
    jmp  PrintChar
 
PrintX:
    push eax
    mov  eax, COLOR_X
    call SetTextColor
    pop  eax
    jmp  PrintChar
 
PrintO:
    push eax
    mov  eax, COLOR_O
    call SetTextColor
    pop  eax
 
PrintChar:
    call WriteChar
 
    push eax
    mov  eax, COLOR_NORM
    call SetTextColor
    pop  eax
 
    inc  esi                    
    dec  ecx
    jz   EndCol                 
 
    mov  edx, OFFSET msgSep
    call WriteString
    jmp  ColLoop
 
EndCol:
    mov  edx, OFFSET msgNewLine
    call WriteString
 
    pop  ecx                    
    dec  ecx
    jz   EndRows
 
    ; Divider line between rows
    mov  edx, OFFSET msgRowDiv
    call WriteString
    jmp  RowLoop
 
EndRows:
    mov  edx, OFFSET msgDivider
    call WriteString
 
    ret
DisplayBoard ENDP
 
; -----------------------------------------------
; PROC: TakeInput
; Reads and validates a human player's move (1-9)
; Uses esi as board index register
; -----------------------------------------------
TakeInput PROC USES eax ebx ecx edx esi
 
GetInput:
    mov  eax, COLOR_NORM
    call SetTextColor
 
    mov  bl, currentPlayer
    cmp  bl, 'X'
    je   ShowXPrompt
 
    mov  edx, OFFSET msgTurnO
    call WriteString
    jmp  ReadMove
 
ShowXPrompt:
    mov  edx, OFFSET msgTurnX
    call WriteString
 
ReadMove:
    call ReadInt                
 
    cmp  eax, 1
    jl   BadRange
    cmp  eax, 9
    jg   BadRange
    jmp  RangeOK
 
BadRange:
    mov  eax, COLOR_ERR
    call SetTextColor
    mov  edx, OFFSET msgInvRange
    call WriteString
    mov  eax, COLOR_NORM
    call SetTextColor
    jmp  GetInput
 
RangeOK:
    dec  eax                  
 
    mov  esi, eax
   
    mov  bl, BYTE PTR board[esi]
    cmp  bl, '-'
    jne  AlreadyTaken
    jmp  PlaceMove
 
AlreadyTaken:
    mov  eax, COLOR_ERR
    call SetTextColor
    mov  edx, OFFSET msgOccupied
    call WriteString
    mov  eax, COLOR_NORM
    call SetTextColor
    jmp  GetInput
 
PlaceMove:
    ; esi still holds the validated 0-based index
    mov  bl, currentPlayer
    mov  BYTE PTR board[esi], bl        
 
    inc  moveCount              
    ret
TakeInput ENDP
 
; -----------------------------------------------
; PROC: AIMove
; Computer (O) picks a random empty cell (0 to 8)
; Retries until an empty cell is found
; Uses esi as board index register
; ----------------------------------------------
AIMove PROC USES eax ebx ecx edx esi
 
    mov  eax, COLOR_NORM
    call SetTextColor
    mov  edx, OFFSET msgAITurn
    call WriteString
 
AIPickLoop:
    mov  eax, 9
    call RandomRange
 
    mov  esi, eax
 
    mov  bl, board[esi]
    cmp  bl, '-'
    jne  AIPickLoop
 
    mov  board[esi], 'O'
    inc  moveCount
 
    ret
AIMove ENDP
 
; ------------------------------------------
; PROC: SwitchPlayer
; Toggles currentPlayer between 'X' and 'O'
; Uses bl to safely read/write byte variable
; -------------------------------------------
SwitchPlayer PROC USES ebx
 
    mov  bl, currentPlayer
    cmp  bl, 'X'
    je   SwitchToO
 
    mov  currentPlayer, 'X'
    jmp  SwitchDone
 
SwitchToO:
    mov  currentPlayer, 'O'
 
SwitchDone:
    ret
SwitchPlayer ENDP
 
; -------------------------------------------------
; PROC: CheckWin
; Checks all 8 winning lines for currentPlayer
; Returns: eax = 1 if win found, eax = 0 if no win
; -------------------------------------------------
CheckWin PROC USES ebx ecx edx

    mov  cl, currentPlayer
 
    mov  bl, board[0]
    cmp  bl, cl
    jne  CheckRow2
    mov  bl, board[1]
    cmp  bl, cl
    jne  CheckRow2
    mov  bl, board[2]
    cmp  bl, cl
    jne  CheckRow2
    mov  winLine[0], 0
    mov  winLine[1], 1
    mov  winLine[2], 2
    mov  eax, 1
    ret
 
CheckRow2:
    mov  bl, board[3]
    cmp  bl, cl
    jne  CheckRow3
    mov  bl, board[4]
    cmp  bl, cl
    jne  CheckRow3
    mov  bl, board[5]
    cmp  bl, cl
    jne  CheckRow3
    mov  winLine[0], 3
    mov  winLine[1], 4
    mov  winLine[2], 5
    mov  eax, 1
    ret
 
CheckRow3:
    mov  bl, board[6]
    cmp  bl, cl
    jne  CheckCol1
    mov  bl, board[7]
    cmp  bl, cl
    jne  CheckCol1
    mov  bl, board[8]
    cmp  bl, cl
    jne  CheckCol1
    mov  winLine[0], 6
    mov  winLine[1], 7
    mov  winLine[2], 8
    mov  eax, 1
    ret
 
CheckCol1:
    mov  bl, board[0]
    cmp  bl, cl
    jne  CheckCol2
    mov  bl, board[3]
    cmp  bl, cl
    jne  CheckCol2
    mov  bl, board[6]
    cmp  bl, cl
    jne  CheckCol2
    mov  winLine[0], 0
    mov  winLine[1], 3
    mov  winLine[2], 6
    mov  eax, 1
    ret
 
CheckCol2:
    mov  bl, board[1]
    cmp  bl, cl
    jne  CheckCol3
    mov  bl, board[4]
    cmp  bl, cl
    jne  CheckCol3
    mov  bl, board[7]
    cmp  bl, cl
    jne  CheckCol3
    mov  winLine[0], 1
    mov  winLine[1], 4
    mov  winLine[2], 7
    mov  eax, 1
    ret
 
CheckCol3:
    mov  bl, board[2]
    cmp  bl, cl
    jne  CheckDiag1
    mov  bl, board[5]
    cmp  bl, cl
    jne  CheckDiag1
    mov  bl, board[8]
    cmp  bl, cl
    jne  CheckDiag1
    mov  winLine[0], 2
    mov  winLine[1], 5
    mov  winLine[2], 8
    mov  eax, 1
    ret
 
CheckDiag1:
    mov  bl, board[0]
    cmp  bl, cl
    jne  CheckDiag2
    mov  bl, board[4]
    cmp  bl, cl
    jne  CheckDiag2
    mov  bl, board[8]
    cmp  bl, cl
    jne  CheckDiag2
    mov  winLine[0], 0
    mov  winLine[1], 4
    mov  winLine[2], 8
    mov  eax, 1
    ret
 
CheckDiag2:
    mov  bl, board[2]
    cmp  bl, cl
    jne  NoWin
    mov  bl, board[4]
    cmp  bl, cl
    jne  NoWin
    mov  bl, board[6]
    cmp  bl, cl
    jne  NoWin
    mov  winLine[0], 2
    mov  winLine[1], 4
    mov  winLine[2], 6
    mov  eax, 1
    ret
 
NoWin:
    mov  eax, 0
    ret
 
CheckWin ENDP
 
; ---------------------------------------------------------
; PROC: CheckDraw
; Returns eax=1 if all 9 moves made (draw), else eax=0
; ---------------------------------------------------------
CheckDraw PROC USES ebx
 
    ; Use bl to read byte variable moveCount
    ; Keeps eax free and clean for the return value
    mov  bl, moveCount
    cmp  bl, 9
    je   IsDraw
 
    mov  eax, 0
    ret
 
IsDraw:
    mov  eax, 1
    ret
 
CheckDraw ENDP
 
; ----------------------------------------
; PROC: AnnounceWinner
; Prints the win message with green color
; ----------------------------------------
AnnounceWinner PROC USES eax ebx edx
 
    mov  eax, COLOR_WIN
    call SetTextColor
 
    mov  bl, currentPlayer
    cmp  bl, 'X'
    je   AnnounceX
 
    ; O wins-we will check if it was AI
    mov  bl, aiMode
    cmp  bl, 1
    je   AnnounceAI
 
    mov  edx, OFFSET msgWinO
    call WriteString
    jmp  AnnounceDone
 
AnnounceAI:
    mov  edx, OFFSET msgWinAI
    call WriteString
    jmp  AnnounceDone
 
AnnounceX:
    mov  edx, OFFSET msgWinX
    call WriteString
 
AnnounceDone:
    mov  eax, COLOR_NORM
    call SetTextColor
    ret
AnnounceWinner ENDP
 
; --------------------------------------------------------
; PROC: ResetBoard
; Fills board with '-', resets moveCount, sets player to X
; --------------------------------------------------------
ResetBoard PROC USES eax ecx edi
 
    mov  edi, OFFSET board
    mov  ecx, 9
    mov  al, '-'
    rep  stosb
 
    mov  moveCount, 0
    mov  currentPlayer, 'X'
 
    ret
ResetBoard ENDP
 
; -----------------------------------------
; PROC: PlayAgainPrompt
; Asks "Play again? (Y/N)"
; Returns: eax = 1 if yes, eax = 0 if no
; -----------------------------------------
PlayAgainPrompt PROC USES ebx edx
 
    mov  eax, COLOR_NORM
    call SetTextColor
    mov  edx, OFFSET msgPlayAgain
    call WriteString
 
    call ReadChar
 
    call WriteChar
    mov  edx, OFFSET msgNewLine
    call WriteString
 
    cmp  al, 'Y'
    je   SayYes
    cmp  al, 'y'
    je   SayYes
 
    mov  eax, 0
    ret
 
SayYes:
    call AskGameMode            
    mov  eax, 1
    ret
 
PlayAgainPrompt ENDP
END