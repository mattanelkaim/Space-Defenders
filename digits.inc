ifndef DIGITS ;Ensure only 1 compilation, like #pragma once
DIGITS equ 1
include screen.inc

;#################### LOGIC ####################

getPowerOf10 PROC
    ;Number is in AX, return in CX
    push ax bx
    
    ;Handle special case
    mov cx, 10 ;For special case 10
    cmp ax, 10
    je getPowerOf10End ;With CX = 10
    mov cx, 1  ;Assume 1 for later calculation
    cmp ax, 10
    jb getPowerOf10End ;With CX = 1
    
    mov bl, 10 ;Const of 10
    getPowerOf10Loop:
        div bl
        mov bh, al ;Save quotient
        
        ;Multiply by 10
        mov ax, cx
        mul bl
        mov cx, ax
        
        ;Move last quotient to AX
        xor ah, ah
        mov al, bh
        cmp bh, 10
        jae getPowerOf10Loop
    
    getPowerOf10End:
    pop bx ax
    RET
getPowerOf10 ENDP

;#################### DRAW SCORE ####################

drawDigit PROC
    ;Digit to draw in AL
    push cx dx di
    mov dl, 2Ch ;Yellow
    
    cmp al, 0
    je draw0Digit
    cmp al, 1
    je draw1Digit
    cmp al, 2
    je draw2Digit
    cmp al, 3
    je draw3Digit
    cmp al, 4
    je draw4Digit
    cmp al, 5
    je draw5Digit
    cmp al, 6
    je draw6Digit
    cmp al, 7
    je draw7Digit
    cmp al, 8
    je draw8Digit
    cmp al, 9
    je draw9Digit
    
    jmp drawDigitEnd
    
    draw0Digit:
        call draw0
        jmp drawDigitEnd
    draw1Digit:
        call draw1
        jmp drawDigitEnd
    draw2Digit:
        call draw2
        jmp drawDigitEnd
    draw3Digit:
        call draw3
        jmp drawDigitEnd
    draw4Digit:
        call draw4
        jmp drawDigitEnd
    draw5Digit:
        call draw5
        jmp drawDigitEnd
    draw6Digit:
        call draw6
        jmp drawDigitEnd
    draw7Digit:
        call draw7
        jmp drawDigitEnd
    draw8Digit:
        call draw8
        jmp drawDigitEnd
    draw9Digit:
        call draw9
        jmp drawDigitEnd
    
    drawDigitEnd:
    pop di dx cx
    RET
drawDigit ENDP

;IMPORTANT: Max score is 2559, since 2560 = A00 -> /10 = 256 (results in overflow)
drawScore PROC
    push ax bx cx dx di
    call deleteScore  ;Delete last score
    
    cmp playerScore, 2559
    jbe drawValidScore
    
    ;Reset score, it's invalid
    mov playerScore, 0
    
    drawValidScore:
    mov ax, playerScore
    call getPowerOf10 ;To CX
    
    mov bl, 10     ;Const of divisor
    mov di, 794    ;Position of score
    drawScoreLoop:
        xor dx, dx ;Divs change dx, necessary
        div cx     ;AX = quotient, DX = remainder
        
        ;Digit is in AL
        call drawDigit
        add di, 7
        
        ;Divisor CX /= 10
        mov ax, cx
        div bl     ;10
        xor ch, ch
        mov cl, al
        
        mov ax, dx ;Save remainder for next iteration
        cmp cx, 0  ;Check divisor
        jne drawScoreLoop
    
    pop di dx cx bx ax
    RET
drawScore ENDP

deleteScore PROC
    push cx di
    
    mov di, 794
    mov dl, bgColor ;Color
    
    mov cx, 7       ;Height of digits
    deleteScoreLoop:
        push cx
        DRAW_HORIZONTAL 21 ;Width to delete
        pop cx
        add di, windowWidth - 20
        loop deleteScoreLoop
    
    pop di cx
    RET
deleteScore ENDP

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
