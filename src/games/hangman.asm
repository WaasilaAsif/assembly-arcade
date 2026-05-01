;  HANGMAN GAME  -  x86 32-bit Assembly
;  Assembler : JWasm + JWLink  (MASM-Runner VSCode extension)
;  Library   : Irvine32
;
;  Screen layout (0-based rows):
;    Row  0  : separator
;    Row  1  : H A N G M A N . A S M
;    Row  2  : Computer Organization Lab Project
;    Row  3  : separator
;    Row  4  : Category
;    Row  5  : Hint
;    Row  7  : gallows top bar
;    Row  8  : gallows rope
;    Row  9  : head (dynamic)
;    Row 10  : arms (dynamic)
;    Row 11  : legs (dynamic)
;    Row 12  : gallows ground
;    Row 13  : Lives left (dynamic)
;    Row 15  : Word display (dynamic)
;    Row 16  : Wrong letters (dynamic)
;    Row 17  : Score (dynamic)
;    Row 19  : Input prompt
;    Row 21  : Status message (dynamic)

INCLUDE Irvine32.inc

MAX_WRONG   = 6
NUM_WORDS   = 15
ENTRY_SIZE  = 14
HINT_SIZE   = 42

CLR_GREEN   = 0Ah
CLR_RED     = 0Ch
CLR_YELLOW  = 0Eh
CLR_WHITE   = 0Fh
CLR_CYAN    = 0Bh
CLR_GRAY    = 07h

.DATA

word_table LABEL BYTE
BYTE  8,'A','S','S','E','M','B','L','Y', 5 DUP(0)
BYTE  8,'R','E','G','I','S','T','E','R', 5 DUP(0)
BYTE  9,'P','R','O','C','E','S','S','O','R', 4 DUP(0)
BYTE  6,'M','E','M','O','R','Y', 7 DUP(0)
BYTE  9,'I','N','T','E','R','R','U','P','T', 4 DUP(0)
BYTE  5,'C','A','C','H','E', 8 DUP(0)
BYTE 11,'I','N','S','T','R','U','C','T','I','O','N', 2 DUP(0)
BYTE  9,'A','L','G','O','R','I','T','H','M', 4 DUP(0)
BYTE  6,'B','I','N','A','R','Y', 7 DUP(0)
BYTE  8,'C','O','M','P','I','L','E','R', 5 DUP(0)
BYTE  8,'O','V','E','R','F','L','O','W', 5 DUP(0)
BYTE  7,'P','O','I','N','T','E','R', 6 DUP(0)
BYTE  5,'S','T','A','C','K', 8 DUP(0)
BYTE  5,'Q','U','E','U','E', 8 DUP(0)
BYTE  9,'R','E','C','U','R','S','I','O','N', 4 DUP(0)

hint_table LABEL BYTE
BYTE "Low-level programming language",  12 DUP(0)
BYTE "CPU storage location",            22 DUP(0)
BYTE "Brain of the computer",           21 DUP(0)
BYTE "Stores data temporarily",         19 DUP(0)
BYTE "Signal that pauses the CPU",      16 DUP(0)
BYTE "Fast memory buffer",              24 DUP(0)
BYTE "Command executed by the CPU",     15 DUP(0)
BYTE "Step-by-step problem solution",   13 DUP(0)
BYTE "Base-2 number system",            22 DUP(0)
BYTE "Translates code to machine lang", 11 DUP(0)
BYTE "Value exceeds storage limit",     15 DUP(0)
BYTE "Variable holding memory address", 11 DUP(0)
BYTE "Last In First Out structure",     15 DUP(0)
BYTE "First In First Out structure",    14 DUP(0)
BYTE "A function that calls itself",    14 DUP(0)

secret_len   DWORD 0
secret_word  BYTE  13 DUP(0)
display_buf  BYTE  13 DUP(0)
guessed      BYTE  26 DUP(0)
wrong_count  DWORD 0
hint_used    BYTE  0
wins         DWORD 0
losses       DWORD 0
word_idx     DWORD 0
input_char   BYTE  0

; No CR/LF in any string to avoid messing up screen layout when printed
str_sep      BYTE "=========================================",0
str_title    BYTE "     H A N G M A N   .   A S M          ",0
str_subtitle BYTE "   Computer Organization Lab Project     ",0
str_category BYTE "Category : COMPUTER SCIENCE",0
str_hint_lbl BYTE "Hint     : ",0

gal_top      BYTE "  +-------+",0
gal_rope     BYTE "  |       |",0
gal_ground   BYTE " =+=========",0
gal_head     BYTE "  |      (O)   ",0
gal_no_head  BYTE "  |            ",0
gal_larm     BYTE "  |      /|    ",0
gal_arms     BYTE "  |      /|\   ",0
gal_no_arms  BYTE "  |            ",0
gal_lleg     BYTE "  |      /     ",0
gal_legs     BYTE "  |      / \   ",0
gal_no_legs  BYTE "  |            ",0

str_lives_lb BYTE "Lives left: ",0
str_slash    BYTE "/",0
str_word_lbl BYTE "Word     : ",0
str_wrng_lbl BYTE "Wrong    : ",0
str_score_w  BYTE "Score ->  Wins: ",0
str_score_l  BYTE "   Losses: ",0
str_prompt   BYTE "Guess (A-Z or ? for hint): ",0
str_clr_line BYTE "                                                  ",0
str_win      BYTE "*** YOU WIN! ACCESS GRANTED! :) ***      ",0
str_lose     BYTE "*** PROCESS TERMINATED - YOU LOST :( *** ",0
str_answer   BYTE "   The word was: ",0
str_again    BYTE "Play again? (Y/N): ",0
str_hint_ok  BYTE "Hint revealed! (-1 life)      ",0
str_hint_no  BYTE "Hint already used!            ",0
str_correct  BYTE "Correct!                      ",0
str_wrongmsg BYTE "Wrong guess!                  ",0
str_dup_msg  BYTE "Already guessed, try again!   ",0

.CODE

main PROC
    call Randomize              ; seed once at program start

new_game:
    call Clrscr
    mov  eax, CLR_WHITE
    call SetTextColor

    call init_round             ; pick word, reset state
    call draw_static_screen     ; draw fixed parts
    call update_gallows_parts   ; draw empty gallows body rows
    call update_word_line       ; draw all underscores
    call update_wrong_list      ; draw empty wrong list
    call update_score           ; draw current score

round_loop:
    call place_cursor
    call read_letter            ; saves to input_char

    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString

    mov  al, input_char

    cmp  al, '?'
    je   do_hint
    cmp  al, 'A'
    jb   round_loop
    cmp  al, 'Z'
    ja   round_loop

    call check_duplicate
    jz   is_dup

    call mark_guessed
    call search_letter          ; EAX = match count
    cmp  eax, 0
    je   guess_wrong

    call update_word_line
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_GREEN
    call SetTextColor
    mov  edx, OFFSET str_correct
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    call check_win
    cmp  eax, 1
    je   player_won
    jmp  round_loop

guess_wrong:
    inc  wrong_count
    call update_gallows_parts
    call update_wrong_list
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET str_wrongmsg
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  eax, wrong_count
    cmp  eax, MAX_WRONG
    jge  player_lost
    jmp  round_loop

is_dup:
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET str_dup_msg
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  round_loop

do_hint:
    cmp  hint_used, 1
    je   hint_already
    mov  hint_used, 1
    inc  wrong_count
    call update_gallows_parts
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET str_hint_ok
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  eax, wrong_count
    cmp  eax, MAX_WRONG
    jge  player_lost
    jmp  round_loop

hint_already:
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET str_hint_no
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  round_loop

player_won:
    call update_word_line
    inc  wins
    call update_score
    mov  dl, 0
    mov  dh, 19
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_GREEN
    call SetTextColor
    mov  edx, OFFSET str_win
    call WriteString
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  ask_again

player_lost:
    call update_gallows_parts
    inc  losses
    call update_score
    mov  dl, 0
    mov  dh, 19
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 21
    call Gotoxy
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET str_lose
    call WriteString
    mov  edx, OFFSET str_answer
    call WriteString
    call reveal_word
    mov  eax, CLR_WHITE
    call SetTextColor

ask_again:
    mov  dl, 0
    mov  dh, 23
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 23
    call Gotoxy
    mov  edx, OFFSET str_again
    call WriteString
    call read_letter
    mov  al, input_char
    cmp  al, 'Y'
    je   new_game
    cmp  al, 'y'
    je   new_game
    call ExitProcess
main ENDP

;  init_round - clear state and pick a random word
init_round PROC
    mov  ecx, 26
    lea  edi, guessed
    xor  al, al
    rep  stosb

    mov  wrong_count, 0
    mov  hint_used, 0

    mov  ebx, word_idx          ; save previous index

pick_word:
    mov  eax, NUM_WORDS
    call RandomRange            ; EAX = 0..14
    cmp  eax, ebx               ; same as last round?
    je   pick_word              ; if yes, re-roll

    mov  word_idx, eax
    push edx                    ; protect EDX before mul
    mov  edx, 0
    mov  ebx, ENTRY_SIZE
    mul  ebx
    pop  edx

    lea  esi, word_table
    add  esi, eax               ; ESI -> chosen entry

    movzx ecx, BYTE PTR [esi]   ; first byte = word length
    mov  secret_len, ecx
    inc  esi                    ; skip length byte

    lea  edi, secret_word
    push ecx
    rep  movsb                  ; copy word chars
    mov  BYTE PTR [edi], 0
    pop  ecx

    mov  ecx, secret_len
    lea  edi, display_buf
init_dash:
    mov  BYTE PTR [edi], '_'
    inc  edi
    loop init_dash
    mov  BYTE PTR [edi], 0
    ret
init_round ENDP

;  draw_static_screen
;  Clears screen then draws everything that doesn't change
;  mid-round. Called once per new game.
draw_static_screen PROC
    call Clrscr

    mov  dl, 0
    mov  dh, 0
    call Gotoxy
    mov  eax, CLR_CYAN
    call SetTextColor
    mov  edx, OFFSET str_sep
    call WriteString

    mov  dl, 0
    mov  dh, 1
    call Gotoxy
    mov  edx, OFFSET str_title
    call WriteString

    mov  dl, 0
    mov  dh, 2
    call Gotoxy
    mov  edx, OFFSET str_subtitle
    call WriteString

    mov  dl, 0
    mov  dh, 3
    call Gotoxy
    mov  edx, OFFSET str_sep
    call WriteString

    mov  eax, CLR_WHITE
    call SetTextColor

    mov  dl, 0
    mov  dh, 4
    call Gotoxy
    mov  edx, OFFSET str_category
    call WriteString

    mov  dl, 0
    mov  dh, 5
    call Gotoxy
    mov  edx, OFFSET str_clr_line
    call WriteString
    mov  dl, 0
    mov  dh, 5
    call Gotoxy
    mov  edx, OFFSET str_hint_lbl
    call WriteString
    mov  eax, word_idx
    mov  ebx, HINT_SIZE
    mul  ebx                    ; EAX = offset into hint_table
    lea  edx, hint_table
    add  edx, eax
    call WriteString

    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  dl, 0
    mov  dh, 7
    call Gotoxy
    mov  edx, OFFSET gal_top
    call WriteString

    mov  dl, 0
    mov  dh, 8
    call Gotoxy
    mov  edx, OFFSET gal_rope
    call WriteString

    mov  dl, 0
    mov  dh, 12
    call Gotoxy
    mov  edx, OFFSET gal_ground
    call WriteString

    mov  eax, CLR_WHITE
    call SetTextColor

    mov  dl, 0
    mov  dh, 19
    call Gotoxy
    mov  edx, OFFSET str_prompt
    call WriteString

    ret
draw_static_screen ENDP

;  update_gallows_parts - rows 9, 10, 11, 13
update_gallows_parts PROC
    mov  eax, CLR_YELLOW
    call SetTextColor

    mov  dl, 0
    mov  dh, 9
    call Gotoxy
    mov  eax, wrong_count
    cmp  eax, 1
    jb   ugp_no_head
    mov  edx, OFFSET gal_head
    call WriteString
    jmp  ugp_arms
ugp_no_head:
    mov  edx, OFFSET gal_no_head
    call WriteString

ugp_arms:
    mov  dl, 0
    mov  dh, 10
    call Gotoxy
    mov  eax, wrong_count
    cmp  eax, 3
    jae  ugp_both_arms
    cmp  eax, 2
    jae  ugp_left_arm
    mov  edx, OFFSET gal_no_arms
    call WriteString
    jmp  ugp_legs
ugp_left_arm:
    mov  edx, OFFSET gal_larm
    call WriteString
    jmp  ugp_legs
ugp_both_arms:
    mov  edx, OFFSET gal_arms
    call WriteString

ugp_legs:
    mov  dl, 0
    mov  dh, 11
    call Gotoxy
    mov  eax, wrong_count
    cmp  eax, 6
    jae  ugp_both_legs
    cmp  eax, 5
    jae  ugp_left_leg
    mov  edx, OFFSET gal_no_legs
    call WriteString
    jmp  ugp_lives
ugp_left_leg:
    mov  edx, OFFSET gal_lleg
    call WriteString
    jmp  ugp_lives
ugp_both_legs:
    mov  edx, OFFSET gal_legs
    call WriteString

ugp_lives:
    mov  dl, 0
    mov  dh, 13
    call Gotoxy
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET str_lives_lb
    call WriteString
    mov  eax, MAX_WRONG
    sub  eax, wrong_count
    call WriteDec
    mov  edx, OFFSET str_slash
    call WriteString
    mov  eax, MAX_WRONG
    call WriteDec
    mov  edx, OFFSET str_clr_line
    call WriteString
    ret
update_gallows_parts ENDP

;  update_word_line - row 15
update_word_line PROC
    mov  dl, 0
    mov  dh, 15
    call Gotoxy
    mov  edx, OFFSET str_word_lbl
    call WriteString
    lea  esi, display_buf
    mov  ecx, secret_len
uwl_loop:
    mov  al, BYTE PTR [esi]
    cmp  al, '_'
    je   uwl_dash
    mov  eax, CLR_GREEN
    call SetTextColor
    mov  al, BYTE PTR [esi]
    jmp  uwl_print
uwl_dash:
    mov  eax, CLR_GRAY
    call SetTextColor
    mov  al, '_'
uwl_print:
    call WriteChar
    mov  al, ' '
    call WriteChar
    mov  eax, CLR_WHITE
    call SetTextColor
    inc  esi
    loop uwl_loop
    mov  edx, OFFSET str_clr_line
    call WriteString
    ret
update_word_line ENDP

;  update_wrong_list - row 16
update_wrong_list PROC
    mov  dl, 0
    mov  dh, 16
    call Gotoxy
    mov  edx, OFFSET str_wrng_lbl
    call WriteString
    lea  esi, guessed
    mov  ecx, 26
    mov  ebx, 0
uwrl_loop:
    push ebx
    push ecx
    push esi
    cmp  BYTE PTR [esi], 1
    jne  uwrl_skip
    mov  al, bl
    add  al, 'A'
    call is_in_word             ; CF=1 means it IS in word -> skip
    jc   uwrl_skip
    pop  esi
    pop  ecx
    pop  ebx
    push ebx
    push ecx
    push esi
    mov  eax, CLR_RED
    call SetTextColor
    mov  al, bl
    add  al, 'A'
    call WriteChar
    mov  al, ' '
    call WriteChar
    mov  eax, CLR_WHITE
    call SetTextColor
uwrl_skip:
    pop  esi
    pop  ecx
    pop  ebx
    inc  esi
    inc  ebx
    loop uwrl_loop
    mov  edx, OFFSET str_clr_line
    call WriteString
    ret
update_wrong_list ENDP

;  update_score - row 17
update_score PROC
    mov  dl, 0
    mov  dh, 17
    call Gotoxy
    mov  edx, OFFSET str_score_w
    call WriteString
    mov  eax, wins
    call WriteDec
    mov  edx, OFFSET str_score_l
    call WriteString
    mov  eax, losses
    call WriteDec
    mov  edx, OFFSET str_clr_line
    call WriteString
    ret
update_score ENDP

;  place_cursor - positions cursor at input spot on row 19
place_cursor PROC
    mov  dl, 28
    mov  dh, 19
    call Gotoxy
    mov  al, ' '
    call WriteChar
    mov  dl, 28
    mov  dh, 19
    call Gotoxy
    ret
place_cursor ENDP

;  read_letter - blocks until A-Z or ? pressed
;  Uppercases, saves to input_char, echoes to screen
read_letter PROC
rl_again:
    call ReadChar
    cmp  al, 'a'
    jb   rl_no_lower
    cmp  al, 'z'
    ja   rl_no_lower
    sub  al, 20h
rl_no_lower:
    cmp  al, '?'
    je   rl_accept
    cmp  al, 'A'
    jb   rl_again
    cmp  al, 'Z'
    ja   rl_again
rl_accept:
    mov  input_char, al
    call WriteChar
    ret
read_letter ENDP

;  check_duplicate - ZF=1 if input_char already guessed
check_duplicate PROC
    movzx ebx, input_char
    sub   ebx, 'A'
    cmp   BYTE PTR guessed[ebx], 1
    ret
check_duplicate ENDP

;  mark_guessed - marks input_char in guessed[]
mark_guessed PROC
    movzx ebx, input_char
    sub   ebx, 'A'
    mov   BYTE PTR guessed[ebx], 1
    ret
mark_guessed ENDP

;  search_letter - finds input_char in secret_word
;  Returns EAX = number of matches found
;  Side effect: reveals matched positions in display_buf
search_letter PROC
    mov  bl, input_char
    xor  ecx, ecx
    xor  esi, esi
sl_loop:
    cmp  esi, secret_len
    jae  sl_done
    cmp  BYTE PTR secret_word[esi], bl
    jne  sl_next
    mov  BYTE PTR display_buf[esi], bl
    inc  ecx
sl_next:
    inc  esi
    jmp  sl_loop
sl_done:
    mov  eax, ecx
    ret
search_letter ENDP

;  check_win - EAX=1 if no underscores remain in display_buf
check_win PROC
    lea  esi, display_buf
    mov  ecx, secret_len
cw_loop:
    cmp  BYTE PTR [esi], '_'
    je   cw_no
    inc  esi
    loop cw_loop
    mov  eax, 1
    ret
cw_no:
    mov  eax, 0
    ret
check_win ENDP

;  is_in_word - CF=1 if AL exists anywhere in secret_word
is_in_word PROC
    push ebx
    push ecx
    mov  bl, al
    xor  ecx, ecx
iiw_loop:
    cmp  ecx, secret_len
    jae  iiw_no
    cmp  BYTE PTR secret_word[ecx], bl
    je   iiw_yes
    inc  ecx
    jmp  iiw_loop
iiw_yes:
    pop  ecx
    pop  ebx
    stc
    ret
iiw_no:
    pop  ecx
    pop  ebx
    clc
    ret
is_in_word ENDP

;  reveal_word - prints secret_word character by character
reveal_word PROC
    push ecx
    push esi
    lea  esi, secret_word
    mov  ecx, secret_len
rv_loop:
    movzx eax, BYTE PTR [esi]
    call WriteChar
    inc  esi
    loop rv_loop
    pop  esi
    pop  ecx
    ret
reveal_word ENDP

END main