ifndef DRAW ;Ensure only 1 compilation, like #pragma once
DRAW equ 1

MODEL small
DATASEG

windowHeight equ 200
windowWidth equ 320
bgColor equ 11h
borderWidth equ 1   ;Do NOT change!
borderColor equ 13h ;MUST BE UNIQUE
starsColor equ 1Ch  ;MUST BE UNIQUE
starsPositions dw 970,   1811,  1856,  2459,  2864,  3447,  3459,  3692,  4770,  6150
               dw 6162,  6302,  6666,  7138,  7550,  10654, 11967, 12734, 12812, 13033
               dw 13432, 13977, 15074, 15805, 16175, 16739, 17083, 17826, 18240, 18474
               dw 20408, 20862, 21051, 21111, 21476, 22250, 23842, 23844, 23881, 24373
               dw 25046, 26216, 26840, 28344, 29155, 29583, 29678, 31531, 31728, 32122
               dw 33119, 33356, 34606, 35269, 36466, 36846, 37896, 38219, 38893, 39385
               dw 39496, 40473, 40758, 40853, 40982, 42045, 42685, 44010, 44509, 45073
               dw 45347, 45512, 46469, 47674, 47945, 48779, 49515, 49699, 51889, 51958
               dw 52456, 54510, 54517, 55100, 55453, 55810, 56660, 56879, 57702, 57780
               dw 57817, 57944, 58068, 58073, 59952, 60521, 61700, 62686, 63088, 63348
drawOrErase db ?


CODESEG


initializeGraphics PROC
    mov ax, 13h    ;Set graphic mode = 320 * 200
    int 10h
    mov ax, 0A000h ;Pointer of video memory
    mov es, ax     ;Can't move directly to ES
    call cls
    RET
initializeGraphics ENDP


;Position is in DI, color is in DL, length is in CX
horizontalLine PROC
    push ax

    cld       ;So stosb will inc di
    mov al, dl
    rep stosb ;mov es:[di], al && inc di, CX times
    dec di    ;Last iteration doesn't draw
    
    pop ax
    RET
horizontalLine ENDP

;Will reset CX!
DRAW_HORIZONTAL MACRO len:REQ
    mov cx, len
    call horizontalLine
ENDM


verticalLine PROC
    ;Position is in DI, color is in DL, length is in CX
    drawVertical:
        mov es:[di], dl
        add di, windowWidth
        loop drawVertical
    sub di, windowWidth ;Last iteration doesn't draw
    RET
verticalLine ENDP

;Will reset CX!
DRAW_VERTICAL MACRO len:REQ
    mov cx, len
    call verticalLine
ENDM


cls PROC
    push ax cx di

    cld        ;So stosb will inc di
    mov cx, windowWidth*windowHeight
    xor di, di ;Start from first pixel
    mov ax, bgColor
    rep stosb  ;mov es:[di], al && inc di, CX times

    pop di cx ax
    RET
cls ENDP


drawBorder PROC
    push cx dx di
    mov dl, borderColor

    xor di, di
    DRAW_HORIZONTAL windowWidth ;Top
    
    add di, windowWidth
    DRAW_VERTICAL windowHeight-2  ;Right
    
    mov di, windowWidth
    DRAW_VERTICAL windowHeight-1  ;Left
    
    DRAW_HORIZONTAL windowWidth ;Bottom
    
    pop di dx cx
    RET
drawBorder ENDP


drawStars PROC
    push bx cx dx di
    
    mov dl, starsColor
    lea bx, starsPositions
    mov cx, 100 ;Num of stars
    drawStarsLoop:
        mov di, [bx]
        cmp byte ptr es:[di], bgColor ;If star is not in background
        jne drawNextStar ;Skip drawing to avoid drawing over other objects
        
        mov es:[di], dl  ;Draw star
        drawNextStar:
        add bx, 2
        loop drawStarsLoop
    
    pop di dx cx bx
    RET
drawStars ENDP

endif
