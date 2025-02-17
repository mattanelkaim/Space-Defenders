ifndef DIGITS ;Ensure only 1 compilation, like #pragma once
DIGITS equ 1
include draw.inc

digitsProcsTable dw draw0, draw1, draw2, draw3, draw4, draw5, draw6, draw7, draw8, draw9
maxScore equ 9999
digitColor db ? ;Parameter


;#################### LOGIC ####################

;Number is in AX, return in CX
calcPowerOf10 PROC
    mov cx, 1
    cmp ax, 10
    jb getPowerOf10End
    mov cx, 10
    cmp ax, 100
    jb getPowerOf10End
    mov cx, 100
    cmp ax, 1000
    jb getPowerOf10End
    mov cx, 1000
    cmp ax, 10000
    jb getPowerOf10End
    mov cx, 10000 ;Max - further comparisons result in overflow
    
    getPowerOf10End:
    RET
calcPowerOf10 ENDP

GET_POWER_OF_10 MACRO num:REQ
    push ax
    mov ax, num
    call calcPowerOf10
    pop ax
ENDM


;#################### HANDLE DIGIT ####################

;Digit is in BX
;Color is in DL
drawDigit PROC
    push cx di ;CX & DI are used in digits-drawing functions
    
    shl bx, 1     ;Procs table is defined in words (2 bytes)
    call [digitsProcsTable + bx]
    
    pop di cx
    RET
drawDigit ENDP

DRAW_DIGIT MACRO digit:REQ
    push bx dx
    ;Move digit to BL
    xor bh, bh
    mov bl, digit
    mov dl, digitColor
    call drawDigit
    pop dx bx
ENDM


;#################### DRAW NUMBER ####################

;Number is in AX
;Position is in DI
;Color is in BH
drawNumber PROC
    push ax bx cx dx di

    GET_POWER_OF_10 ax ;To CX
    mov bl, 10     ;Const of divisor
    drawNumberLoop:
        xor dx, dx ;Div by word, DX should be 0
        div cx     ;AX = quotient, DX = remainder
        
        DRAW_DIGIT al,digitColor
        add di, 7
        
        ;Divisor CX /= 10
        mov ax, cx
        div bl     ;10
        xor ch, ch
        mov cl, al ;Update CX
        
        mov ax, dx ;Save remainder for next iteration
        cmp cx, 0  ;Check divisor
        jne drawNumberLoop
    
    pop di dx cx bx ax
    RET
drawNumber ENDP

DRAW_NUMBER MACRO num:REQ, pos:REQ, color:REQ
    push ax bx di
    mov ax, num
    mov di, pos
    mov digitColor, color
    call drawNumber
    pop di bx ax
ENDM


;#################### DRAW DIGITS ####################

draw0 PROC
    inc di
    DRAW_HORIZONTAL 3
    add di, windowWidth + 1
    DRAW_VERTICAL 5
    add di, windowWidth - 3
    DRAW_HORIZONTAL 3
    sub di, windowWidth*5 + 3
    DRAW_VERTICAL 5
    RET
draw0 ENDP

draw1 PROC
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    sub di, windowWidth - 1
    DRAW_VERTICAL 6
    add di, windowWidth - 2
    DRAW_HORIZONTAL 5    
    RET
draw1 ENDP

draw2 PROC
    inc di
    DRAW_HORIZONTAL 3
    add di, windowWidth - 3
    mov es:[di], dl
    add di, 4
    mov cx, 5
    draw2Loop1:
        mov es:[di], dl
        add di, windowWidth - 1
        loop draw2Loop1
    inc di
    DRAW_HORIZONTAL 5
    RET
draw2 ENDP

draw3 PROC
    inc di
    DRAW_HORIZONTAL 3
    add di, windowWidth - 3
    mov es:[di], dl
    add di, 4
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    dec di
    mov es:[di], dl
    add di, windowWidth + 2
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    sub di, 4
    mov es:[di], dl
    add di, windowWidth + 1
    DRAW_HORIZONTAL 3
    RET
draw3 ENDP

draw4 PROC
    DRAW_VERTICAL 5
    inc di
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 2
    mov es:[di], dl
    sub di, windowWidth*4 + 1
    DRAW_VERTICAL 7
    RET
draw4 ENDP

draw5 PROC
    DRAW_HORIZONTAL 5
    add di, windowWidth - 4
    DRAW_VERTICAL 3
    inc di
    DRAW_HORIZONTAL 3
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth - 4
    DRAW_HORIZONTAL 4
    RET
draw5 ENDP

draw6 PROC
    inc di
    mov cx, 3 ;Number of lines
    draw6Middles:
        push cx
        DRAW_HORIZONTAL 3
        pop cx
        add di, windowWidth*3 - 2
        loop draw6Middles
    sub di, windowWidth*8 - 3
    mov es:[di], dl
    sub di, 4
    DRAW_VERTICAL 5
    add di, 4
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    RET
draw6 ENDP

draw7 PROC
    DRAW_HORIZONTAL 5
    inc di
    mov cx, 3
    draw7Loop1:
        add di, windowWidth - 1
        mov es:[di], dl
        loop draw7Loop1
    add di, windowWidth
    DRAW_VERTICAL 3
    RET
draw7 ENDP

draw8 PROC
    inc di
    mov cx, 3 ;Number of lines
    draw8Middles:
        push cx
        DRAW_HORIZONTAL 3
        pop cx
        add di, windowWidth*3 - 2
        loop draw8Middles
    sub di, windowWidth*8 + 1
    mov cx, 2
    draw8Loop1:
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        add di, windowWidth*2
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        sub di, windowWidth*4 - 4
        loop draw8Loop1
    RET
draw8 ENDP

draw9 PROC
    inc di
    mov cx, 3 ;Number of lines
    draw9Middles:
        push cx
        DRAW_HORIZONTAL 3
        pop cx
        add di, windowWidth*3 - 2
        loop draw9Middles
    sub di, windowWidth*8 + 1
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth*3
    mov es:[di], dl
    sub di, windowWidth*4 - 4
    DRAW_VERTICAL 5
    RET
draw9 ENDP


endif

;Unused functions

;getPowerOf10 PROC
;    ;Number is in AX, return in CX
;    push ax bx dx
;    
;    mov cx, 1
;    
;    ;Handle edge case
;    cmp ax, 10
;    jb getPowerOf10End ;With CX = 1
;    
;    mov bl, 10     ;Const for mul/div
;    getPowerOf10Loop:
;        div bl
;        mov bh, al ;Save quotient
;        
;        ;Multiply by 10
;        mov ax, cx
;        mul bl
;        mov cx, ax
;        
;        ;Move last quotient to AX
;        xor ah, ah
;        mov al, bh
;        cmp bh, 10
;        jae getPowerOf10Loop
;    
;    getPowerOf10End:
;    pop dx bx ax
;    RET
;getPowerOf10 ENDP
