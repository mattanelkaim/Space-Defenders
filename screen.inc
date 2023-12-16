ifndef SCREEN ;Ensure only 1 compilation, like #pragma once
SCREEN equ 1

MODEL small
DATASEG

windowHeight equ 200
windowWidth equ 320

CODESEG

horizontalLine PROC
    ;Position is in DI, color is in DL, length is in CX
    drawHorizontal:
        mov es:[di], dl
        inc di
        loop drawHorizontal
    dec di ;Last iteration doesn't draw
    
    RET
horizontalLine ENDP

;Will reset CX!
DRAW_HORIZONTAL MACRO len:REQ
    mov cx, len
    call horizontalLine
    rep
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

endif
