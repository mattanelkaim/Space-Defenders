ifndef UTILS
UTILS equ 1

delayTime dw 8334        ;Microseconds
accelerationCounter dw 0
accelerationRate equ 600 ;600f/120fps = 5secs
minDelay equ 4167

getPosition PROC
    ;X POS IN CX, Y POS IN DX, RETURNS POS IN DI
    push ax
    
    mov ax, windowWidth
    mul dx
    add ax, cx
    mov di, ax
    
    pop ax
    RET
getPosition ENDP

randomize PROC
    ;Randomizes between range in BL(min) -> BH(max)
    ;Returns number in DX
    xor ah, ah
    int 1Ah    ;Randomize number (up to 65355) to CX:DX
    
    ;Calc modulu divider: max - min + 1
    sub bh, bl
    inc bh

    ;Move minimum to CX
    xor ch, ch
    mov cl, bl ;Store minimum

    ;Move BH to BX
    mov bl, bh
    xor bh, bh

    mov ax, dx ;DX holds randomized num
    xor dx, dx ;Reset for div instruction
    div bx     ;Modulu to get remainder (in DX)

    add dx, cx ;Add minimum, now stores final randomized
    RET
randomize ENDP

delay PROC
    ;Delay 8.334 ms between each frame = 120hz
    xor cx, cx
    mov dx, delayTime
    mov ah, 86h ;Delays by CX:DX microseconds
    int 15h
    RET
delay ENDP

accelerateGame PROC
    cmp delayTime, minDelay
    jbe accelerateGameEnd

    cmp accelerationCounter, accelerationRate
    jge validToAccelerate

    ;Not valid to accelerate
    inc accelerationCounter
    jmp accelerateGameEnd
    
    validToAccelerate:
        mov accelerationCounter, 0
        sub delayTime, 150

    accelerateGameEnd:
    RET
accelerateGame ENDP

endif
