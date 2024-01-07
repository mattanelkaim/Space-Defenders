ifndef LETTERS
LETTERS equ 1
include draw.inc

drawA PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    sub di, windowWidth + 15
    call drawH
    RET
drawA ENDP

drawC PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_VERTICAL 20
    sub di, windowWidth*19 - 1
    DRAW_VERTICAL 20
    add di, windowWidth - 1
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    RET
drawC ENDP

drawE PROC
    DRAW_VERTICAL 24
    sub di, windowWidth*23 - 1
    DRAW_VERTICAL 24
    inc di
    DRAW_HORIZONTAL 14
    sub di, windowWidth + 13
    DRAW_HORIZONTAL 14
    sub di, windowWidth*10 + 13
    DRAW_HORIZONTAL 13
    add di, windowWidth - 12
    DRAW_HORIZONTAL 13
    sub di, windowWidth*13 + 12
    DRAW_HORIZONTAL 14
    add di, windowWidth - 13
    DRAW_HORIZONTAL 14
    RET
drawE ENDP

drawG PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_VERTICAL 20
    sub di, windowWidth*19 - 1
    DRAW_VERTICAL 20
    add di, windowWidth - 1
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    sub di, windowWidth*11
    DRAW_VERTICAL 10
    sub di, windowWidth*9 + 1
    DRAW_VERTICAL 10
    sub di, windowWidth*9 + 5
    DRAW_HORIZONTAL 5
    add di, windowWidth - 4
    DRAW_HORIZONTAL 5
    RET
drawG ENDP

drawH PROC
    DRAW_VERTICAL 24
    sub di, windowWidth*23 - 1
    DRAW_VERTICAL 24
    sub di, windowWidth*12 - 1
    DRAW_HORIZONTAL 12
    add di, windowWidth - 11
    DRAW_HORIZONTAL 12
    sub di, windowWidth*12 - 1
    DRAW_VERTICAL 24
    sub di, windowWidth*23 - 1
    DRAW_VERTICAL 24
    RET
drawH ENDP

drawM PROC
    DRAW_VERTICAL 24
    sub di, windowWidth*23
    mov cx, 8
    mLoop1:
        add di, windowWidth + 1
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        loop mLoop1
    sub di, windowWidth
    mov cx, 7
    mLoop2:
        sub di, windowWidth - 1
        mov es:[di], dl
        sub di, windowWidth
        mov es:[di], dl
        loop mLoop2
    sub di, windowWidth - 1
    DRAW_VERTICAL 24
    RET
drawM ENDP

drawO PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth*22 - 15
    DRAW_HORIZONTAL 16
    sub di, windowWidth + 15
    DRAW_HORIZONTAL 16
    sub di, windowWidth*20 + 15
    DRAW_VERTICAL 20
    sub di, windowWidth*19 - 1
    DRAW_VERTICAL 20
    sub di, windowWidth*19 - 14
    DRAW_VERTICAL 20
    sub di, windowWidth*19 + 1
    DRAW_VERTICAL 20
    RET
drawO ENDP

drawP PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_VERTICAL 22
    sub di, windowWidth*21 - 1
    DRAW_VERTICAL 22
    sub di, windowWidth*22 - 13
    DRAW_VERTICAL 10
    sub di, windowWidth*9 - 1
    DRAW_VERTICAL 10
    add di, windowWidth - 13
    DRAW_HORIZONTAL 14
    add di, windowWidth - 13
    DRAW_HORIZONTAL 14
    RET
drawP ENDP

drawR PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_VERTICAL 22
    sub di, windowWidth*21 - 1
    DRAW_VERTICAL 22
    sub di, windowWidth*12 - 1
    DRAW_HORIZONTAL 14
    add di, windowWidth - 13
    DRAW_HORIZONTAL 14
    sub di, windowWidth*10
    DRAW_VERTICAL 9
    sub di, windowWidth*8 + 1
    DRAW_VERTICAL 9
    add di, windowWidth - 4
    mov cx, 6
    drawRLoop:
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        inc di
        loop drawRLoop
    RET
drawR ENDP

drawS PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_VERTICAL 10
    sub di, windowWidth*9 - 1
    DRAW_VERTICAL 10
    add di, windowWidth - 1
    DRAW_HORIZONTAL 16
    sub di, windowWidth + 14
    DRAW_HORIZONTAL 15
    add di, windowWidth*2
    DRAW_VERTICAL 11
    sub di, windowWidth*10 + 1
    DRAW_VERTICAL 11
    sub di, windowWidth + 14
    DRAW_HORIZONTAL 14
    add di, windowWidth - 13
    DRAW_HORIZONTAL 14
    RET
drawS ENDP

drawT PROC
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 16
    add di, windowWidth - 7
    DRAW_VERTICAL 22
    sub di, windowWidth*21 + 1
    DRAW_VERTICAL 22
    RET
drawT ENDP

drawV PROC
    mov cx, 8
    drawVLoop1:
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        add di, windowWidth
        mov es:[di], dl
        add di, windowWidth + 1
        loop drawVLoop1
    sub di, windowWidth
    mov cx, 8
    drawVLoop2:
        mov es:[di], dl
        sub di, windowWidth
        mov es:[di], dl
        sub di, windowWidth
        mov es:[di], dl
        sub di, windowWidth - 1
        loop drawVLoop2
    RET
drawV ENDP

drawEquals PROC
    add di, 2*windowWidth
    DRAW_HORIZONTAL 5
    add di, 2*windowWidth - 4
    DRAW_HORIZONTAL 5
    RET
drawEquals ENDP

endif
