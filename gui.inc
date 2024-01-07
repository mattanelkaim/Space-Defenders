ifndef GUI
GUI equ 1
include draw.inc
include utils.inc
include digits.inc
include player.inc
include screens.inc

;Player stats
playerHP dw 3
playerScore dw 0 ;Max 9999

;Shop variables
shotPrices db 10, 15, 20, 25
SCORE_COLOR equ 2Ch

;#################### HP ####################

drawHeart PROC
    ;DI holds position
    push bx cx dx di
    
    mov bx, di      ;Store for later
    mov dl, 4       ;Dark red
    cmp drawOrErase, 1
    je drawHeartOuter
    mov dl, bgColor ;Erase
    jmp drawHeartInner
    
    drawHeartOuter:
    add di, 2
    DRAW_HORIZONTAL 2
    add di, 4
    DRAW_HORIZONTAL 2
    add di, windowWidth + 1
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    sub di, 2
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    add di, windowWidth - 1
    DRAW_VERTICAL 2
    sub di, windowWidth - 5
    mov es:[di], dl
    add di, 5
    DRAW_VERTICAL 2
    mov cx, 5
    outerHeartLoop1:
        add di, windowWidth - 1
        mov es:[di], dl
        loop outerHeartLoop1
    mov cx, 4
    outerHeartLoop2:
        sub di, windowWidth + 1
        mov es:[di], dl
        loop outerHeartLoop2
    
    mov dl, 28h     ;Light red
    cmp drawOrErase, 1
    je drawHeartInner
    mov dl, bgColor ;Erase
    
    drawHeartInner:
    mov di, bx
    add di, windowWidth + 2
    DRAW_HORIZONTAL 2
    add di, 4
    DRAW_HORIZONTAL 2
    add di, windowWidth - 7
    DRAW_HORIZONTAL 4
    add di, 2
    DRAW_HORIZONTAL 4
    add di, windowWidth - 8
    DRAW_HORIZONTAL 9
    add di, windowWidth - 7
    DRAW_HORIZONTAL 7
    add di, windowWidth - 5
    DRAW_HORIZONTAL 5
    add di, windowWidth - 3
    DRAW_HORIZONTAL 3
    add di, windowWidth - 1
    mov es:[di], dl
    
    pop di dx cx bx
    RET
drawHeart ENDP


;Called once to initialize GUI
drawPlayerHP PROC
    push cx dx di
    ;Heart size is 11*9
    mov cx, windowWidth - 14 ;X value
    mov dx, 1                ;Y value
    call getPosition
    
    mov drawOrErase, 1
    mov cx, playerHP
    drawPlayerHPLoop:
        call drawHeart
        sub di, 14 ;Space for next heart
        loop drawPlayerHPLoop
    
    pop di dx cx
    RET
drawPlayerHP ENDP


decPlayerHP PROC
    ;There are 2 checks for player death to erase last heart
    push ax cx dx

    dec playerHP
    ;cmp playerHP, 0
    jl decPlayerHPEnd ;No hearts to erase
    
    ;Get x value of heart to erase
    ;CX = (windowWidth - 14) - 14*playerHP
    mov cx, windowWidth - 14
    mov ax, 14
    mul playerHP
    sub cx, ax ;Holds x position
    
    mov dx, 1  ;Y position
    call getPosition
    
    mov drawOrErase, 0 ;Erase
    call drawHeart
    
    decPlayerHPEnd:
    pop dx cx ax
    RET
decPlayerHP ENDP


;#################### SCORE ####################

updateScore PROC
    cmp playerScore, maxScore
    jbe drawValidScore
    
    ;Set to max valid score
    mov playerScore, maxScore
    jmp updateScoreEnd

    drawValidScore:
    call deleteScore  ;Delete last score
    ;Draw playerScore at pos 794
    DRAW_NUMBER playerScore, 794, SCORE_COLOR
    
    updateScoreEnd:
    RET
updateScore ENDP


deleteScore PROC
    push cx dx di
    
    mov dl, bgColor ;Color
    mov di, 794
    
    mov cx, 7       ;Height of digits
    deleteScoreLoop:
        push cx
        DRAW_HORIZONTAL 5*7 ;Width to delete (maxDigits*digitWidth)
        pop cx
        add di, windowWidth - 5*7 + 1
        loop deleteScoreLoop
    
    pop di dx cx
    RET
deleteScore ENDP


;#################### SHOP ####################

drawCoin PROC
    push bx cx dx di
    
    mov bx, 462    ;Anchor point
    
    ;Outer line
    mov dl, 2Bh    ;Light orange
    mov di, bx
    add di, 2
    DRAW_HORIZONTAL 5
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth + 1
    DRAW_VERTICAL 5
    add di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth - 5
    DRAW_HORIZONTAL 5
    sub di, windowWidth + 5
    mov es:[di], dl
    sub di, windowWidth*6
    mov es:[di], dl
    add di, windowWidth - 1
    DRAW_VERTICAL 5
    
    ;Inner part
    mov dl, 0Eh ;Light yellow
    mov di, bx
    add di, windowWidth + 2
    DRAW_HORIZONTAL 5
    add di, windowWidth - 5
    mov cx, 5
    drawCoinInnerLoop:
        push cx
        DRAW_HORIZONTAL 7
        pop cx
        add di, windowWidth - 6
        loop drawCoinInnerLoop
    inc di
    DRAW_HORIZONTAL 5
    
    ;Coin shine
    mov dl, 0Fh ;White
    mov di, bx
    add di, windowWidth*2 + 3
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    
    pop di dx cx bx
    RET
drawCoin ENDP


initShop PROC
    ;Shop border
    mov dl, borderColor
    mov di, windowWidth*189 + 80
    DRAW_VERTICAL 10
    mov di, windowWidth*189 + 240
    DRAW_VERTICAL 10
    mov di, windowWidth*189 + 81
    DRAW_HORIZONTAL 159

    mov dx, playerShots.max
    inc dx
    DRAW_NUMBER dx, windowWidth*191+144, 0Fh

    mov playerShots.xArr[0], 152
    mov playerShots.yArr[0], 194
    xor bx, bx ;Draw first shot
    call drawPlayerShot

    RET
initShop ENDP


drawPlus PROC
    push cx dx di
    mov dl, 2
    add di, 3
    DRAW_VERTICAL 7
    sub di, windowWidth*3 + 3
    DRAW_HORIZONTAL 7
    pop di dx cx
    RET
drawPlus ENDP


buyShots PROC
    push ax bx
    
    mov bx, playerShots.max
    
    ;Can extend max shots?
    cmp bx, realMaxShots
    jge buyShotsEnd

    ;Move to AX
    xor ax, ax
    mov al, shotPrices[bx - 1] ;1 is initial real max
    cmp playerScore, ax
    jl buyShotsEnd

    ;Buy new shot
    sub playerScore, ax
    call updateScore
    inc playerShots.max
    
    buyShotsEnd:
    pop bx ax
    RET
buyShots ENDP

endif
