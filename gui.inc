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

    mov playerShots.xArr[0], 147
    mov playerShots.yArr[0], 193
    xor bx, bx ;Draw first shot
    call drawPlayerShot

    mov di, windowWidth*191+161
    mov dl, 0Fh
    call drawEquals

    call updateShotPrice

    RET
initShop ENDP


updateShotPrice PROC
    push ax bx

    mov bx, playerShots.max
    cmp bx, limitMaxShots
    jl validNextMax
    ;Fade out equals and shot
    DRAW_NUMBER bx, windowWidth*191+140, 18h
    call fadeShotInShop
    mov dl, 18h
    mov di, windowWidth*191+161
    call drawEquals
    jmp updatePrice

    validNextMax:
    DRAW_NUMBER bx, windowWidth*191+140, bgColor
    inc bx
    DRAW_NUMBER bx, windowWidth*191+140, 0Fh
    dec bx ;Restore from prior commands, get original

    updatePrice:
    ;Move price to AX
    xor ax, ax
    mov al, shotPrices[bx - 2] ;1 is initial real max

    cmp bx, limitMaxShots
    jl validNextPrice
    DRAW_NUMBER ax, windowWidth*191+169, 74h
    jmp updateShotPriceEnd

    validNextPrice:
    DRAW_NUMBER ax, windowWidth*191+169, bgColor
    mov al, shotPrices[bx - 1] ;1 is initial real max
    DRAW_NUMBER ax, windowWidth*191+169, SCORE_COLOR ;44h is decayed

    updateShotPriceEnd:
    pop bx ax
    RET
updateShotPrice ENDP


fadeShotInShop PROC
    push ax bx cx

    ;Fade colors
    mov bx, 3
    fadePlayerShots:
        add playerShotTrailColors[bx], 90h ;Offset in VGA table to fade colors
        dec bx
        jns fadePlayerShots ;As long as index positive/zero

    ;Backup position
    mov ax, playerShots.xArr[0]
    mov cx, playerShots.yArr[0]

    ;Draw shot
    mov playerShots.xArr[0], 147
    mov playerShots.yArr[0], 193
    xor bx, bx ;Draw first shot
    call drawPlayerShot

    ;Restore position
    mov playerShots.xArr[0], ax
    mov playerShots.yArr[0], cx

    ;Fade colors
    mov bx, 3
    unfadePlayerShots:
        sub playerShotTrailColors[bx], 90h ;Offset in VGA table to fade colors
        dec bx
        jns unfadePlayerShots ;As long as index positive/zero

    pop cx bx ax
    RET
fadeShotInShop ENDP


buyShots PROC
    push ax bx
    
    mov bx, playerShots.max
    
    ;Can extend max shots?
    cmp bx, limitMaxShots
    jge buyShotsEnd

    ;Move price to AX
    xor ax, ax
    mov al, shotPrices[bx - 1] ;1 is initial real max
    cmp playerScore, ax
    jl buyShotsEnd

    ;Buy new shot
    sub playerScore, ax
    call updateScore
    inc playerShots.max
    
    call updateShotPrice

    buyShotsEnd:
    pop bx ax
    RET
buyShots ENDP

endif
