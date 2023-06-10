;NOTES:
;Anchor tile is at top-left (0,0)
;Colors are from mode 13h VGA color palette
;DL/DX are affected by mul & div!
;byte ptr to indicate byte-sized operand
;Procs are grouped to sections

MODEL small
STACK 100h
DATASEG

enemy STRUC
    ;Must stay 8 bytes long
    x dw ?
    y db ?
    spawnCounter dw 0
    moveCounter db 0
    shootCounter dw 0
enemy ENDS

realMaxShots equ 5

shots STRUC
    xArr dw realMaxShots dup(0)
    yArr dw realMaxShots dup(0)
    max dw ?        ;Actual current max = max/2, shots are arrays
    trailColors db 3 dup(?)
shots ENDS

;Window variables
windowHeight equ 200
windowWidth equ 320
delayTime dw 8334   ;Microsonds
accelerationCounter dw 0
accelerationRate equ 600 ;600f/120fps = 5secs
minDelay equ 4167

;Border & bg variables
drawOrErase db 0
borderWidth equ 1   ;Do NOT change!
borderColor equ 13h ;MUST BE UNIQUE
bgColor equ 11h
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

;Player variables
playerX equ 20
playerY dw 0
playerWidth equ 31
playerHeight equ 21
playerColors db 18h, 1Bh ;Outer colors

;Player stats variables
playerVelocity equ 5
playerHP dw 3
playerScore dw 0       ;Max 2559 (drawScore limit)

;Player shots variables
playerShots shots {max=1} ;Upgradable
playerShotWidth equ 10
playerShotHeight equ 2 ;Do NOT change!
playerShotFrontColor equ 34h
playerShotTrailColors db 20h, 37h, 36h

;Global enemy variables
enemyVelocity equ 2
enemySpawnRate equ 180 ;180f/120fps = 1.5secs
enemyMoveRate equ 16   ;16f/120fps = 0.133secs
enemyShootRate equ 300 ;300f/120fps = 2.5secs
enemyShotWidth equ 10
enemyShotHeight equ 2  ;Max = max(enemyHeights)
numOfEnemies equ 2
allEnemies dq 2 dup(enemy) ;Blue, yellow
currentEnemy dw 0 ;0=blue, 1=yellow

;Blue enemy variables
blueEnemyWidth equ 23
blueEnemyHeight equ 20
blueEnemyColor equ 3Ah
blueEnemyShots shots {max=4}
blueEnemyShotFrontColor equ 24h ;Can join to 1 array
blueEnemyShotTrailColors db 5, 6Ch, 0B3h

;Yellow enemy variables
yellowEnemyWidth equ 21
yellowEnemyHeight equ 23
yellowEnemyColor equ 9
yellowEnemyShots shots {max=4}
yellowEnemyShotFrontColor equ 2Ch ;Can join to 1 array
yellowEnemyShotTrailColors db 2Bh, 2Ah, 29h

;Shop variables
shotPrices db 10, 15, 20, 25

CODESEG

;--------------------------------------------------HANDLE NUMS PRINTING----------------------------------------------------------------------------------------------------------------


draw0 PROC
    inc di
    mov cx, 3
    call horizontalLine
    add di, windowWidth + 1
    mov cx, 5
    call verticalLine
    add di, windowWidth - 3
    mov cx, 3
    call horizontalLine
    sub di, windowWidth*5 + 3
    mov cx, 5
    call verticalLine
    RET
draw0 ENDP

draw1 PROC
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    sub di, windowWidth - 1
    mov cx, 6
    call verticalLine
    add di, windowWidth - 2
    mov cx, 5
    call horizontalLine
    
    RET
draw1 ENDP

draw2 PROC
    inc di
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 3
    mov es:[di], dl
    add di, 4
    mov cx, 5
    draw2Loop1:
        mov es:[di], dl
        add di, windowWidth - 1
        loop draw2Loop1
    inc di
    mov cx, 5
    call horizontalLine
    RET
draw2 ENDP

draw3 PROC
    inc di
    mov cx, 3
    call horizontalLine
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
    mov cx, 3
    call horizontalLine
    RET
draw3 ENDP

draw4 PROC
    mov cx, 5
    call verticalLine
    inc di
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 2
    mov es:[di], dl
    sub di, windowWidth*4 + 1
    mov cx, 7
    call verticalLine
    RET
draw4 ENDP

draw5 PROC
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 4
    mov cx, 3
    call verticalLine
    inc di
    mov cx, 3
    call horizontalLine
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth - 4
    mov cx, 4
    call horizontalLine
    RET
draw5 ENDP

draw6 PROC
    inc di
    mov cx, 3 ;Number of lines
    draw6Middles:
        push cx
        mov cx, 3
        call horizontalLine
        pop cx
        add di, windowWidth*3 - 2
        loop draw6Middles
    sub di, windowWidth*8 - 3
    mov es:[di], dl
    sub di, 4
    mov cx, 5
    call verticalLine
    add di, 4
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    RET
draw6 ENDP

draw7 PROC
    mov cx, 5
    call horizontalLine
    inc di
    mov cx, 3
    draw7Loop1:
        add di, windowWidth - 1
        mov es:[di], dl
        loop draw7Loop1
    add di, windowWidth
    mov cx, 3
    call verticalLine
    RET
draw7 ENDP

draw8 PROC
    inc di
    mov cx, 3 ;Number of lines
    draw8Middles:
        push cx
        mov cx, 3
        call horizontalLine
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
        mov cx, 3
        call horizontalLine
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
    mov cx, 5
    call verticalLine
    RET
draw9 ENDP

drawDigit PROC
    ;Digit to draw in AL
    push di cx dx
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
    pop dx cx di
    RET
drawDigit ENDP

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
        mov ah, 0
        mov al, bh
        cmp bh, 10
        jae getPowerOf10Loop
    
    getPowerOf10End:
    pop bx ax
    RET
getPowerOf10 ENDP

;IMPORTANT: Max score is 2559, since 2560 = A00 -> /10 = 256 (results in overflow)
drawScore PROC
    push ax bx cx dx di
    call deleteScore  ;Delete last score
    
    cmp playerScore, 2559
    jbe drawValidScore
    
    ;Reset score, its invalid
    mov playerScore, 0
    
    drawValidScore:
    mov ax, playerScore
    call getPowerOf10 ;To CX
    
    mov bl, 10     ;Const of divisor
    mov di, 794    ;Position of score
    drawScoreLoop:
        mov dx, 0  ;Divs change dx, necessary
        div cx     ;AX = quotient, DX = remainder
        
        ;Digit is in AL
        mov ah, 0
        call drawDigit
        add di, 7
        
        ;Divisor CX /= 10
        mov ax, cx
        div bl
        mov ch, 0
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
        mov cx, 21  ;Width to delete
        call horizontalLine
        add di, windowWidth - 20
        pop cx
        loop deleteScoreLoop
    
    pop di cx
    RET
deleteScore ENDP

;--------------------------------------------------GLOBALS AND INITS-------------------------------------------------------------------------------------------------------------------


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
    mov ah, 0
    int 1Ah    ;Randomize number (up to 65355) to CX:DX
    
    ;Calc modulu divider: max - min + 1
    sub bh, bl
    inc bh

    ;Move minimum to CX
    mov ch, 0
    mov cl, bl ;Store minimum

    ;Move BH to BX
    mov bl, bh
    mov bh, 0

    mov ax, dx ;DX holds randomized num
    mov dx, 0  ;Reset for div instruction
    div bx     ;Modulu to get remainder (in DX)

    add dx, cx ;Add minimum, now stores final randomized
    RET
randomize ENDP


initializeGraphics PROC
    mov ax, 13h    ;Set graphic mode = 320 * 200
    int 10h
    mov ax, 0A000h ;Pointer of video memory
    mov es, ax     ;Can't move directly to ES
    call cls
    RET
initializeGraphics ENDP


welcomeScreen PROC
    push si
    mov drawOrErase, 1

    ;Player & shots
    mov playerY, 140
    call drawPlayer
    mov playerShots.xArr[0], 65
    mov playerShots.yArr[0], 148
    mov bx, 0
    call drawPlayerShot
    mov playerShots.xArr[1], 115
    mov playerShots.yArr[1], 151
    mov bx, 1
    call drawPlayerShot
    mov playerShots.xArr[2], 150
    mov playerShots.yArr[2], 149
    mov bx, 2
    call drawPlayerShot
    
    ;Blue enemy & shots
    mov allEnemies[0].x, 250
    mov allEnemies[0].y, 30
    call drawBlueEnemy
    mov blueEnemyShots.xArr[0], 200
    mov blueEnemyShots.yArr[0], 40
    mov si, 0
    call drawBlueEnemyShot
    mov blueEnemyShots.xArr[1], 100
    mov blueEnemyShots.yArr[1], 42
    mov si, 1
    call drawBlueEnemyShot

    ;Yellow enemy & shots
    mov allEnemies[1].x, 200
    mov allEnemies[1].y, 140
    call drawYellowEnemy
    mov yellowEnemyShots.xArr[0], 175
    mov yellowEnemyShots.yArr[0], 148
    mov si, 0
    call drawYellowEnemyShot

    call welcomeScreenName
    ;Wait for player input
    mov ah, 7
    int 21h
    call cls
    pop si
    RET
welcomeScreen ENDP


welcomeScreenName PROC
    mov cx, 95
    mov dx, 60
    call getPosition
    mov bx, di ;Save anchor

    mov dl, 0Fh
    call drawS

    add bx, 29
    mov di, bx
    call drawP

    add bx, 27
    mov di, bx
    call drawA

    add bx, 29
    mov di, bx
    call drawC

    add bx, 29
    mov di, bx
    call drawE
    
    add bx, windowWidth*35 - 155
    mov di, bx
    call drawS
    
    add bx, 29
    mov di, bx
    call drawH

    add bx, 29
    mov di, bx
    call drawO

    add bx, 29
    mov di, bx
    call drawO

    add bx, 28
    mov di, bx
    call drawT

    add bx, 28
    mov di, bx
    call drawE

    add bx, 29
    mov di, bx
    call drawR

    add bx, 29
    mov di, bx
    call drawS
    RET
welcomeScreenName ENDP


initializeGame PROC
    call initPlayer
    call initShop
    call initAllShots
    call drawBorder
    call drawStars
    call drawPlayerHP
    call drawCoin
    call drawScore
    mov bx, 0
    call killEnemy
    mov bx, 1
    call killEnemy
    
    mov drawOrErase, 1
    call drawPlayer
    RET
initializeGame ENDP


handleGameInput PROC
    ;If DH is 0, player is dead
    mov dh, 1 ;Assume alive

    ;Listen to keyboard input
    mov ah, 1 ;Check keyboard buffer status
    int 16h
    jz handleGameInputEnd ;If key not pressed
    
    mov ah, 0 ;Get key ASCII to AL & BIOS code to AH
    int 16h
    
    cmp al, 'w'
    je movePlayerLabel
    cmp al, 'W'
    je movePlayerLabel
    cmp ah, 48h ;Up arrow
    je movePlayerLabel
    
    cmp al, 's'
    je movePlayerLabel
    cmp al, 'S'
    je movePlayerLabel
    cmp ah, 50h ;Down arrow
    je movePlayerLabel

    cmp al, ' '
    je firePlayerShotLabel
    
    ;DEV CHEATS:
    cmp al, '1'
    je devCheat1
    cmp al, '2'
    je devCheat2
    cmp al, '3'
    je devCheat3
    cmp al, '4'
    je devCheat4
    
    jmp handleGameInputEnd ;Pressed non-functional key
    
    ;ACTUAL CONTROLS
    movePlayerLabel:
        call movePlayer
        jmp handleGameInputEnd
    
    firePlayerShotLabel:
        call initPlayerShot
        jmp handleGameInputEnd
    
    ;DEV CHEATS
    devCheat1:
        inc playerScore
        call drawScore
        jmp handleGameInputEnd
    devCheat2:
        call decPlayerHP
        jmp handleGameInputEnd
    devCheat3:
        call killEnemy
        jmp handleGameInputEnd
    devCheat4:
        call buyShots
        jmp handleGameInputEnd
    
    handleGameInputEnd:
    RET
handleGameInput ENDP


delay PROC
    ;Delay 8.334 ms between each frame = 120hz
    mov cx, 0
    mov dx, delayTime
    mov ah, 86h
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


initPlayer PROC
    ;x is constant
    mov playerY, (windowHeight - playerHeight) / 2
    RET
initPlayer ENDP


initAllShots PROC
    ;Reset x & y values after welcome screen
    lea bx, playerShots.xArr[0]
    mov cx, 5 ;# of real max player shots
    resetPlayerShots:
        mov word ptr [bx], 0
        inc bx
        loop resetPlayerShots
    
    lea bx, blueEnemyShots.xArr[0]
    mov cx, 5
    resetBlueEnemyShots:
        mov word ptr [bx], 0
        inc bx
        loop resetBlueEnemyShots
    
    lea bx, yellowEnemyShots.xArr[0]
    mov cx, 5
    resetYellowEnemyShots:
        mov word ptr [bx], 0
        inc bx
        loop resetYellowEnemyShots
    RET
initAllShots ENDP


initEnemy PROC
    ;Current enemy index in BX
    push dx
    mov allEnemies[bx].x, windowWidth - blueEnemyWidth - 20  ;20 is offset
    ;y is random between 20-150
    push bx
    mov bl, 20     ;Min
    mov bh, 150    ;Max
    call randomize ;To DX
    pop bx
    mov allEnemies[bx].y, dl ;Must be <8 bits
    
    ;Shoot faster on init (by 25%)
    mov allEnemies[bx].shootCounter, enemyShootRate * 3 / 4
    pop dx
    RET
initEnemy ENDP


cls PROC
    push cx di

    mov di, 0
    mov cx, windowWidth*windowHeight
    clsLoop:
        inc di
        mov byte ptr es:[di], bgColor
        loop clsLoop
    
    pop di cx
    RET
cls ENDP


horizontalLine PROC
    ;Position is in DI, color is in DL, length is in CX
    drawHorizontal:
        mov es:[di], dl
        inc di
        loop drawHorizontal
    dec di ;Last iteration doesn't draw
    
    RET
horizontalLine ENDP


verticalLine PROC
    ;Position is in DI, color is in DL, length is in CX
    drawVertical:
        mov es:[di], dl
        add di, windowWidth
        loop drawVertical
    sub di, windowWidth ;Last iteration doesn't draw
    
    RET
verticalLine ENDP


drawBorder PROC
    push cx dx di
    mov dl, borderColor

    mov di, 0
    mov cx, windowWidth
    call horizontalLine ;Top
    
    mov di, 0
    mov cx, windowHeight
    call verticalLine   ;Left
    
    mov di, (windowHeight - 1)*windowWidth ;(index)
    mov cx, windowWidth
    call horizontalLine ;Bottom
    
    mov di, windowWidth - 1 ;(index)
    mov cx, windowHeight
    call verticalLine   ;Right
    
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
        cmp byte ptr es:[di], bgColor  ;If star is not in background
        jne drawNextStar ;Skip drawing
        
        mov es:[di], dl  ;Draw star
        drawNextStar:
        add bx, 2
        loop drawStarsLoop
    
    pop di dx cx bx
    RET
drawStars ENDP


drawCoin PROC
    push bx cx dx di
    
    mov bx, 462    ;Anchor point
    
    ;Outer line
    mov dl, 2Bh    ;Light orange
    mov di, bx
    add di, 2
    mov cx, 5
    call horizontalLine
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth + 1
    mov cx, 5
    call verticalLine
    add di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth - 5
    mov cx, 5
    call horizontalLine
    sub di, windowWidth + 5
    mov es:[di], dl
    sub di, windowWidth*6
    mov es:[di], dl
    add di, windowWidth - 1
    mov cx, 5
    call verticalLine
    
    ;Inner part
    mov dl, 0Eh ;Light yellow
    mov di, bx
    add di, windowWidth + 2
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 5
    mov cx, 5
    drawCoinInnerLoop:
        push cx
        mov cx, 7
        call horizontalLine
        add di, windowWidth - 6
        pop cx
        loop drawCoinInnerLoop
    inc di
    mov cx, 5
    call horizontalLine
    
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


drawHeart PROC
    ;DI holds position
    push cx dx di
    
    mov dl, 4       ;Dark red
    cmp drawOrErase, 1
    je drawHeartOuter
    mov dl, bgColor ;Erase
    
    drawHeartOuter:
    add di, 2
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 4
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth + 1
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    sub di, 2
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    sub di, windowWidth - 5
    mov es:[di], dl
    add di, 5
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
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
    sub di, windowWidth*3 - 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 4
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 7
    mov cx, 4
    call horizontalLine
    add di, 2
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 8
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 7
    mov cx, 7
    call horizontalLine
    add di, windowWidth - 5
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 3
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 1
    mov es:[di], dl
    
    pop di dx cx
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


;--------------------------------------------------PLAYER------------------------------------------------------------------------------------------------------------------------------


drawPlayer PROC
    push bx cx dx
    
    mov cx, playerX
    mov dx, playerY
    call getPosition
    mov bx, di ;Save anchor point
    
    mov dl, playerColors[0] ;Dark grey
    cmp drawOrErase, 1
    je drawPlayerDarkGrey
    mov dl, bgColor ;Erase
    
    drawPlayerDarkGrey:
    ;WINGS
    mov di, bx ;Reset to anchor
    add di, 3
    mov cx, 11
    call drawHorizontal
    
    add di, windowWidth - 10
    mov cx, 11
    call drawHorizontal
    add di, 9*windowWidth - 10
    mov cx, 11
    call drawHorizontal
    
    add di, 9*windowWidth - 10
    mov cx, 11
    call drawHorizontal
    add di, windowWidth - 10
    mov cx, 11
    call drawHorizontal
    
    
    ;ENGINE DARK GREYS
    mov di, bx ;Reset to anchor
    add di, 4*windowWidth + 5
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth - 1
    mov cx, 4
    call horizontalLine
    
    add di, 8*windowWidth - 3
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 2
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    
    
    ;COCKPIT DARK GREY
    mov di, bx ;Reset to anchor
    add di, 8*windowWidth + 16
    mov cx, 5  ;Num of rows
    drawCockpit:
        push cx
        mov cx, 10 ;Row width
        call horizontalLine
        pop cx
        add di, windowWidth - 9 ;Move to next row
        loop drawCockpit
    
    mov dl, 13h     ;Darker grey
    cmp drawOrErase, 1
    je drawPlayerDarkerGrey
    mov dl, bgColor ;Erase
    
    drawPlayerDarkerGrey:
    ;ENGINES DARKER GREY
    mov di, bx ;Reset to anchor
    add di, 4*windowWidth + 4
    mov es:[di], dl
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    add di, 8*windowWidth
    mov es:[di], dl
    add di, windowWidth + 1
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    
    ;COCKPIT DARKER GREY
    mov di, bx ;Reset to anchor
    add di, 9*windowWidth + 20
    mov cx, 3  ;Height of line
    call verticalLine
    
    
    mov dl, 0Ch ;Red
    cmp drawOrErase, 1
    je drawPlayerRed
    mov dl, bgColor ;Erase
    
    drawPlayerRed:
    ;ENGINE RED
    mov di, bx ;Reset to anchor
    add di, 5*windowWidth + 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 2
    mov es:[di], dl
    
    add di, 10*windowWidth
    mov es:[di], dl
    sub di, 2
    mov es:[di], dl
    dec di
    mov es:[di], dl
    
    
    mov dl, 0Eh     ;Yellow
    cmp drawOrErase, 1
    je drawPlayerYellow
    mov dl, bgColor ;Erase
    
    drawPlayerYellow:
    ;ENGINE YELLOW
    mov di, bx ;Reset to anchor
    add di, 4*windowWidth + 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 2
    mov es:[di], dl
    add di, windowWidth + 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    
    add di, 8*windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth + 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    
    
    mov dl, 36h     ;Blue
    cmp drawOrErase, 1
    je drawPlayerBlue
    mov dl, bgColor ;Erase
    
    drawPlayerBlue:
    ;COCKPIT BLUE
    mov di, bx ;Reset to anchor
    add di, 9*windowWidth + 16
    mov cx, 3
    call verticalLine
    sub di, 2*windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, 2*windowWidth - 2
    mov cx, 3
    call verticalLine
    sub di, 2*windowWidth - 2
    mov cx, 3
    call verticalLine
    sub di, windowWidth - 1
    mov es:[di], dl
    
    
    mov dl, playerColors[1] ;Grey
    cmp drawOrErase, 1
    je drawPlayerGrey
    mov dl, bgColor ;Erase
    
    drawPlayerGrey:
    ;SHIP BODY
    mov di, bx ;Reset to anchor
    add di, 2*windowWidth + 6
    mov cx, 10
    call drawHorizontal
    add di, windowWidth - 9
    mov cx, 10
    call drawHorizontal
    add di, windowWidth - 8
    mov cx, 11
    call drawHorizontal
    add di, windowWidth - 10
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 8
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 10
    mov cx, 11
    call horizontalLine
    
    add di, windowWidth - 12
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 8
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 1
    mov cx, 2
    call horizontalLine
    add di, windowWidth - 8
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 8
    mov cx, 9
    call horizontalLine
    
    add di, windowWidth - 6
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 10
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 12
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 10
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 11
    mov cx, 10
    call horizontalLine
    add di, windowWidth - 9
    mov cx, 10
    call horizontalLine
    
    mov di, bx ;Reset to anchor
    add di, 10*windowWidth + 26
    mov cx, 5
    call horizontalLine
    
    pop dx cx bx
    RET
drawPlayer ENDP


movePlayer PROC
    ;Key pressed ASCII value is in AL | AH for BIOS code!
    push cx

    cmp ah, 48h ;Up arrow
    je movePlayerUp
    cmp al, 'w'
    je movePlayerUp
    cmp al, 'W'
    je movePlayerUp
    
    cmp ah, 50h ;Down arrow
    je movePlayerDown
    cmp al, 's'
    je movePlayerDown
    cmp al, 'S'
    je movePlayerDown
    
    jmp movePlayerEnd ;'w'/'W' or 's'/'S' aren't pressed
    
    movePlayerUp:
        ;Skip if in border
        cmp playerY, borderWidth
        je movePlayerEnd
        
        ;Erase prev player
        mov drawOrErase, 0 ;Erase
        call drawPlayer
        
        sub playerY, playerVelocity
        cmp playerY, borderWidth ;Has reached top?
        jge movePlayerDraw       ;MUST BE jge and not jae, to handle signed
        ;Invalid y
        mov playerY, borderWidth ;Move to highest valid position
        jmp movePlayerDraw
    
    movePlayerDown:
        ;Get max valid y
        mov cx, windowHeight - playerHeight - borderWidth*2 + 1 ;+1 to get index

        ;Skip if in border
        cmp playerY, cx
        je movePlayerEnd
        
        ;Erase prev player
        mov drawOrErase, 0 ;Erase
        call drawPlayer
        
        add playerY, playerVelocity
        cmp playerY, cx ;Has reached bottom?
        jbe movePlayerDraw
        ;Invalid y
        mov playerY, cx ;Move to lowest valid position
        jmp movePlayerDraw
    
    movePlayerDraw:
        mov drawOrErase, 1 ;Draw
        call drawPlayer
        jmp movePlayerEnd
    
    movePlayerEnd:
    pop cx
    RET
movePlayer ENDP


checkPlayerCollisions PROC
    push cx dx di
    ;NOTE: top, middle and bottom sensors sub to x pos check
    mov cx, playerX
    mov dx, playerY
    call getPosition ;Calculates anchor tile to DI
    
    ;Top part
    add di, 13
    call handlePlayerCollisions
    cmp dh, 1
    je checkPlayerCollisionsEnd ;Collision detected
    
    inc di
    call handlePlayerCollisions
    cmp dh, 1
    je checkPlayerCollisionsEnd ;Collision detected
    
    ;Utilize the stairs-shaped wings of player
    mov cx, 3
    checkPlayerCollisionsLoop1:
        add di, windowWidth*2 + 2
        call handlePlayerCollisions
        cmp dh, 1
        je checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop1
    
    mov cx, 2
    checkPlayerCollisionsLoop2:
        add di, windowWidth*2 + 6
        call handlePlayerCollisions
        cmp dh, 1
        je checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop2
    
    dec di
    call handlePlayerCollisions
    cmp dh, 1
    je checkPlayerCollisionsEnd ;Collision detected
    
    ;Bottom part
    inc di
    ;Utilize the stairs-shaped wings of player
    mov cx, 2
    checkPlayerCollisionsLoop3:
        add di, windowWidth*2 - 6
        call handlePlayerCollisions
        cmp dh, 1
        je checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop3
    
    mov cx, 3
    checkPlayerCollisionsLoop4:
        add di, windowWidth*2 - 2
        call handlePlayerCollisions
        cmp dh, 1
        je checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop4
    
    dec di
    call handlePlayerCollisions
    cmp dh, 1
    je checkPlayerCollisionsEnd ;Collision detected
    
    checkPlayerCollisionsEnd:
    pop di dx cx
    RET
checkPlayerCollisions ENDP


;Return boolean isCollided in DH
handlePlayerCollisions PROC
    ;DI is parameter = position to handle
    mov dh, 0 ;Assume not collided
    
    ;Check for enemy collision
    cmp byte ptr es:[di], blueEnemyColor
    je playerCollisionBlueEnemy
    cmp byte ptr es:[di], yellowEnemyColor
    je playerCollisionYellowEnemy
    
    jmp handlePlayerCollisionsEnd

    ;Enemy collision:
    ;Reset blue enemy
    playerCollisionBlueEnemy:
        mov bx, 0
        jmp playerCollisionEnemy
    playerCollisionYellowEnemy:
        mov bx, 1
        jmp playerCollisionEnemy
    
    playerCollisionEnemy:
        call killEnemy
        call decPlayerHP
        ;Restore player sprite
        mov drawOrErase, 1
        call drawPlayer
    
    handlePlayerCollisionsEnd:
    RET
handlePlayerCollisions ENDP


decPlayerHP PROC
    ;There are 2 checks for player death to erase last heart
    push ax cx dx

    dec playerHP
    cmp playerHP, 0
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


;--------------------------------------------------PLAYER SHOTS------------------------------------------------------------------------------------------------------------------------


initPlayerShot PROC
    ;Determine which shot to work on
    mov bx, 0 ;Holds current shot
    
    checkPlayerShots:
        mov ax, playerShots.max
        shl ax, 1 ;Multiple by 2 cuz referencing a dw array
        dec ax ;Can't do in 1 line
        cmp bx, ax ;No shots available
        ja initPlayerShotEnd
        
        cmp playerShots.xArr[bx], 0
        je setPlayerShot ;Shot NOT initialized
        
        add bx, 2
        jmp checkPlayerShots
    
    setPlayerShot:
    mov ax, (playerHeight - playerShotHeight) / 2
    add ax, playerY

    mov playerShots.yArr[bx], ax ;Save y value
    mov playerShots.xArr[bx], playerWidth + playerX ;Front of player (index)
    mov drawOrErase, 1
    call drawPlayerShot ;Draw
    
    initPlayerShotEnd:
    RET
initPlayerShot ENDP


;Param BX holds current shot index
drawPlayerShot PROC
    push bx cx dx di
    
    ;Get drawing position
    mov cx, playerShots.xArr[bx]
    mov dx, playerShots.yArr[bx]
    call getPosition

    lea bx, playerShotTrailColors[0]
    mov cx, 3 ;Num of trail colors
    playerShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawPlayerShotTrail
        mov dl, bgColor
        drawPlayerShotTrail:
        push cx
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        pop cx
        inc bx ;Get next color
        loop playerShotsTrails

    ;Draw front part of shot
    mov dl, playerShotFrontColor
    cmp drawOrErase, 0
    jne drawPlayerShotFront
    mov dl, bgColor

    drawPlayerShotFront:
    mov cx, playerShotHeight
    drawPlayerShotRows:
        push cx
        mov cx, playerShotWidth - 6 ;6 is trails
        call horizontalLine
        pop cx
        add di, windowWidth - playerShotWidth + 7 ;Next row
        loop drawPlayerShotRows

    pop di dx cx bx
    RET
drawPlayerShot ENDP


movePlayerShots PROC
    ;Go through all the shots
    mov bx, -2 ;So we can start at 0 in loop
    handlePlayerShots:
        add bx, 2
        mov ax, playerShots.max
        shl ax, 1 ;Multiple by 2 cuz referencing a dw array
        dec ax ;Can't do in 1 line
        
        cmp bx, ax
        ja movePlayerShotsEnd ;No shots are available
        
        cmp playerShots.xArr[bx], 0
        jne moveCurrentPlayerShot ;Shot initialized
        
        jmp handlePlayerShots ;Shot NOT initialized
    
    jmp movePlayerShotsEnd ;Handled all shots
    
    moveCurrentPlayerShot:
        ;Remove prev shot
        mov drawOrErase, 0
        call drawPlayerShot
        
        ;Check collisions
        call playerShotCollisions
        cmp dh, 0 ;Return is boolean
        je movePlayerShotsDraw ;No collision detected
        
        ;DH is 1, collosion detected: reset shot
        mov playerShots.xArr[bx], 0
        jmp handlePlayerShots
        
    movePlayerShotsDraw:
        inc playerShots.xArr[bx]
        mov drawOrErase, 1
        call drawPlayerShot ;Draw
        jmp handlePlayerShots
    
    movePlayerShotsEnd:
    RET
movePlayerShots ENDP


;Param BX holds current shot index
;Return in DH, 1 if collision else 0
playerShotCollisions PROC
    push bx cx
    ;Assume no collision
    mov dh, 0
    
    ;Calculates pos of front to DI
    mov cx, playerShots.xArr[bx]
    add cx, playerShotWidth      ;X pos
    mov dx, playerShots.yArr[bx] ;Y pos
    call getPosition
    
    ;Is in border?
    cmp cx, windowWidth - borderWidth
    je detectedPlayerShotCollision
    
    ;Check top, then bottom
    mov cx, 2
    checkPlayerShotCollision:
        cmp byte ptr es:[di], bgColor
        je checkPlayerShotCollisionNext
        cmp byte ptr es:[di], starsColor
        je checkPlayerShotCollisionNext
        cmp byte ptr es:[di], blueEnemyColor
        je playerShotCollisionBlueEnemy
        cmp byte ptr es:[di], yellowEnemyColor
        je playerShotCollisionYellowEnemy
        jmp detectedPlayerShotCollision ;Collision detected

        checkPlayerShotCollisionNext:
        add di, (playerShotHeight-1)*windowWidth
        loop checkPlayerShotCollision
    jmp playerShotCollisionsEnd ;No collisions
    
    playerShotCollisionBlueEnemy:
        mov bx, 0
        jmp playerShotCollisionEnemy
    playerShotCollisionYellowEnemy:
        mov bx, 1
        jmp playerShotCollisionEnemy
    
    playerShotCollisionEnemy:
    call killEnemy

    ;Update score
    cmp currentEnemy, 1
    je killedBlue

    ;Each enemy gives different score
    add playerScore, 5
    jmp updateScore
    killedBlue:
        add playerScore, 3
    updateScore:
        call drawScore
        mov drawOrErase, 0
        call drawPlayerShot
    
    detectedPlayerShotCollision:
        mov dh, 1  ;Collision true
    
    playerShotCollisionsEnd:
    ;No collision - DH is already 0
    pop cx bx
    RET
playerShotCollisions ENDP


;--------------------------------------------------ENEMIES------------------------------------------------------------------------------------------------------------------------


handleEnemies PROC
    call moveBlueEnemyShots
    call moveYellowEnemyShots

    mov bx, currentEnemy
    call spawnEnemy
    mov bx, currentEnemy
    call moveEnemy
    mov bx, currentEnemy
    call fireEnemyShot
    RET
handleEnemies ENDP


drawBlueEnemy PROC
    push bx cx dx
    
    mov cx, allEnemies[0].x
    ;Move to DX
    mov dh, 0
    mov dl, allEnemies[0].y
    call getPosition
    mov bx, di ;Save anchor point
    
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyLightGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyLightGrey:
    add di, 5
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 14
    mov cx, 3
    call horizontalLine
    add di, 10
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 16
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 14
    mov cx, 3
    call horizontalLine
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    sub di, windowWidth + 17
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    dec di
    mov cx, 7
    call verticalLine
    inc di
    mov cx, 3
    call verticalLine
    inc di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth
    mov cx, 4
    call drawHorizontal
    add di, windowWidth - 2
    mov cx, 11
    call horizontalLine
    sub di, windowWidth + 2
    mov cx, 4
    call drawHorizontal
    sub di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    sub di, 6*windowWidth - 1
    mov cx, 7
    call verticalLine
    
    mov dl, 15h     ;Dark grey
    cmp drawOrErase, 1
    je drawBlueEnemyDarkGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkGrey:
    mov di, bx ;Reset to anchor
    add di, windowWidth + 7
    mov cx, 9
    call drawHorizontal
    add di, windowWidth - 9
    mov cx, 11
    call drawHorizontal
    add di, windowWidth - 10
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 8
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 2
    mov cx, 9
    call verticalLine
    sub di, 8*windowWidth - 1
    mov cx, 8
    call verticalLine
    sub di, 5*windowWidth - 1
    mov cx, 5
    call verticalLine
    add di, windowWidth - 3
    mov cx, 3
    call verticalLine
    dec di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    sub di, 8
    mov es:[di], dl
    dec di
    mov es:[di], dl
    sub di, windowWidth
    mov es:[di], dl
    sub di, 2*windowWidth + 1
    mov cx, 3
    call verticalLine
    sub di, 8*windowWidth + 1
    mov cx, 8
    call verticalLine
    sub di, 6*windowWidth + 1
    mov cx, 5
    call verticalLine
    
    mov dl, 0Eh     ;Yellow
    cmp drawOrErase, 1
    je drawBlueEnemyYellow
    mov dl, bgColor ;Erase
    
    drawBlueEnemyYellow:
    mov di, bx ;Reset to anchor
    add di, 2*windowWidth + 5
    mov cx, 4
    call verticalLine
    sub di, windowWidth - 1
    mov es:[di], dl
    add di, 10
    mov es:[di], dl
    sub di, 2*windowWidth - 1
    mov cx, 4
    call verticalLine
    
    
    mov dl, 36h     ;Blue
    cmp drawOrErase, 1
    je drawBlueEnemyBlue
    mov dl, bgColor ;Erase
    
    drawBlueEnemyBlue:
    mov di, bx ;Reset to anchor
    add di, 3*windowWidth + 8
    mov cx, 7
    call horizontalLine
    add di, windowWidth - 7
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 9
    mov cx, 4
    call horizontalLine
    add di, 4
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 11
    mov cx, 4
    call horizontalLine
    add di, 6
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 12
    mov cx, 3
    call horizontalLine
    add di, 8
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 12
    mov cx, 3
    call horizontalLine
    add di, 8
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 12
    mov cx, 4
    call horizontalLine
    add di, 6
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 11
    mov cx, 4
    call horizontalLine
    add di, 4
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 10
    mov cx, 11
    call horizontalLine
    add di, windowWidth - 9
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 7
    mov cx, 7
    call horizontalLine
    add di, windowWidth - 5
    mov cx, 5
    call horizontalLine
    
    
    mov dl, 0Fh     ;White
    cmp drawOrErase, 1
    je drawBlueEnemyWhite
    mov dl, bgColor ;Erase
    
    drawBlueEnemyWhite:
    mov di, bx ;Reset to anchor
    add di, 5*windowWidth + 10
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 3
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 5
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 4
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 6
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, 4
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 5
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 3
    mov cx, 3
    call horizontalLine
    
    
    mov dl, 14h     ;Darker grey
    cmp drawOrErase, 1
    je drawBlueEnemyDarkerGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkerGrey:
    mov di, bx ;Reset to anchor
    add di, 7*windowWidth + 10
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 2
    mov cx, 3
    call horizontalLine
    
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyDarkPurple
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkPurple:
    mov di, bx ;Reset to anchor
    add di, 15*windowWidth + 5
    mov es:[di], dl
    add di, 12
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 14
    mov cx, 15
    call horizontalLine
    add di, windowWidth - 14
    mov cx, 15
    call horizontalLine
    
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyLightPurple
    mov dl, bgColor ;Erase
    
    drawBlueEnemyLightPurple:
    mov di, bx ;Reset to anchor
    add di, 16*windowWidth + 3
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    dec di
    mov es:[di], dl
    sub di, 2*windowWidth - 11
    mov cx, 3
    call verticalLine
    sub di, 3*windowWidth - 8
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    inc di
    mov es:[di], dl
    
    pop dx cx bx
    RET
drawBlueEnemy ENDP


drawYellowEnemy PROC
    push bx cx dx
    
    mov cx, allEnemies[1].x
    ;Move to DX
    mov dh, 0
    mov dl, allEnemies[1].y
    call getPosition
    mov bx, di ;Save anchor point

    mov dl, yellowEnemyColor
    cmp drawOrErase, 1
    je drawYellowEnemyOuter
    mov dl, bgColor ;Erase
    
    drawYellowEnemyOuter:
    add di, 7
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 10
    mov cx, 13
    call horizontalLine
    mov cx, 3
    yellowEnemyOuterLoop:
        push cx
        mov cx, 3
        add di, windowWidth - 1
        call horizontalLine
        pop cx
        loop yellowEnemyOuterLoop
    add di, windowWidth - 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    inc di
    mov cx, 9
    call verticalLine
    sub di, windowWidth*8 - 1
    mov cx, 8
    call verticalLine
    sub di, 2
    mov es:[di], dl
    add di, windowWidth - 1
    mov es:[di], dl
    inc di
    mov es:[di], dl
    add di, windowWidth - 3
    mov cx, 4
    call horizontalLine
    add di, windowWidth - 16
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 4
    call horizontalLine
    add di, 3
    mov cx, 6
    call horizontalLine
    add di, 3
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 7
    call horizontalLine
    add di, 3
    mov cx, 7
    call horizontalLine
    add di, windowWidth - 14
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 14
    mov cx, 3
    call horizontalLine
    add di, 3
    mov cx, 5
    call horizontalLine
    add di, 3
    mov cx, 2
    call horizontalLine
    add di, windowWidth - 1
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 1
    mov cx, 2
    call horizontalLine
    sub di, 15
    mov cx, 2
    call horizontalLine
    sub di, windowWidth + 1
    mov cx, 3
    call horizontalLine
    sub di, windowWidth + 1
    mov cx, 3
    call horizontalLine
    sub di, windowWidth*5 + 2
    mov cx, 3
    call horizontalLine
    sub di, windowWidth + 3
    mov cx, 2
    call horizontalLine
    sub di, windowWidth + 2
    mov cx, 2
    call horizontalLine
    sub di, windowWidth*7 + 2
    mov cx, 7
    call verticalLine
    sub di, windowWidth*8 - 1
    mov cx, 9
    call verticalLine
    sub di, windowWidth*9 - 1
    mov cx, 4
    call verticalLine
    sub di, windowWidth*4 - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth*2 - 1
    mov cx, 2
    call verticalLine
    sub di, windowWidth - 1
    mov es:[di], dl

    mov dl, 15h
    cmp drawOrErase, 1
    je drawYellowEnemyInner
    mov dl, bgColor ;Erase

    drawYellowEnemyInner:
    mov di, bx ;Anchor
    add di, windowWidth*2 + 7
    mov cx, 9
    call horizontalLine
    mov cx, 3
    yellowEnemyInnerLoop1:
        push cx
        add di, windowWidth - 1
        mov cx, 3
        call horizontalLine
        pop cx
        loop yellowEnemyInnerLoop1
    add di, windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth*2 - 1
    mov cx, 4
    call verticalLine
    sub di, windowWidth*2 - 1
    mov cx, 6
    call verticalLine
    sub di, windowWidth + 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth + 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth*12 + 8
    mov cx, 3
    yellowEnemyInnerLoop2:
        push cx
        mov cx, 3
        add di, windowWidth - 3
        call horizontalLine
        pop cx
        loop yellowEnemyInnerLoop2
    add di, windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth*2 + 1
    mov cx, 4
    call verticalLine
    sub di, windowWidth*2 + 1
    mov cx, 6
    call verticalLine
    sub di, windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth - 1
    mov cx, 3
    call verticalLine

    mov dl, 2Ch
    cmp drawOrErase, 1
    je drawYellowEnemyAlien
    mov dl, bgColor ;Erase

    drawYellowEnemyAlien:
    mov di, bx
    add di, windowWidth*3 + 9
    mov cx, 5
    call horizontalLine
    add di, windowWidth - 5
    mov cx, 7
    call horizontalLine
    add di, windowWidth - 7
    mov cx, 9
    call horizontalLine
    add di, windowWidth - 7
    mov es:[di], dl
    sub di, 2
    mov cx, 9
    call verticalLine
    sub di, windowWidth*8 - 1
    mov cx, 9
    call verticalLine
    sub di, windowWidth*5 - 1
    mov cx, 3
    call verticalLine
    add di, windowWidth*3
    mov es:[di], dl
    add di, windowWidth - 1
    mov cx, 9
    call horizontalLine
    sub di, windowWidth*5 + 11
    mov es:[di], dl
    sub di, windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth - 4
    mov cx, 5
    call horizontalLine
    sub di, windowWidth - 1
    mov cx, 3
    call verticalLine
    sub di, windowWidth*2 - 3
    mov cx, 3
    call verticalLine
    sub di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth*4 - 4
    mov es:[di], dl
    sub di, windowWidth*8
    mov es:[di], dl
    inc di
    mov cx, 9
    call verticalLine
    sub di, windowWidth*8 - 1
    mov cx, 9
    call verticalLine
    
    mov dl, 0Fh
    cmp drawOrErase, 1
    je drawYellowEnemyEyes
    mov dl, bgColor ;Erase

    drawYellowEnemyEyes:
    mov di, bx
    add di, windowWidth*6 + 9
    mov cx, 2
    yellowEnemyEyesLoop:
        push cx
        mov cx, 5
        call horizontalLine
        add di, windowWidth - 5
        mov cx, 2
        call horizontalLine
        add di, windowWidth - 1
        mov cx, 2
        call horizontalLine
        add di, windowWidth
        mov cx, 5
        call horizontalLine
        sub di, windowWidth
        mov cx, 2
        call horizontalLine
        sub di, windowWidth + 1
        mov cx, 2
        call horizontalLine
        add di, windowWidth*4 - 5
        pop cx
        loop yellowEnemyEyesLoop
    
    mov dl, 14h
    cmp drawOrErase, 1
    je drawYellowEnemyPupils
    mov dl, bgColor ;Erase

    drawYellowEnemyPupils:
    mov di, bx
    add di, windowWidth*7 + 10
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 2
    mov cx, 3
    call horizontalLine
    add di, windowWidth*4 - 2
    mov cx, 3
    call horizontalLine
    add di, windowWidth - 2
    mov cx, 3
    call horizontalLine

    mov dl, 0Ch
    cmp drawOrErase, 1
    je drawYellowEnemyLights
    mov dl, bgColor ;Erase
    
    drawYellowEnemyLights:
    mov di, bx
    add di, windowWidth*17 + 7
    mov cx, 2
    call horizontalLine
    add di, 7
    mov cx, 2
    call horizontalLine
    add di, windowWidth - 5
    mov cx, 2
    call horizontalLine

    pop dx cx bx
    RET
drawYellowEnemy ENDP


drawCurrentEnemy PROC
    ;Current enemy index in BX
    cmp bx, 0
    je drawCurrentBlueEnemy
    cmp bx, 1
    je drawCurrentYellowEnemy
    
    jmp drawCurrentEnemyEnd

    drawCurrentBlueEnemy:
        call drawBlueEnemy
        jmp drawCurrentEnemyEnd
    drawCurrentYellowEnemy:
        call drawYellowEnemy
        jmp drawCurrentEnemyEnd

    drawCurrentEnemyEnd:
    RET
drawCurrentEnemy ENDP


spawnEnemy PROC
    ;Current enemy index in BX
    cmp allEnemies[bx].x, 0
    jne spawnEnemyEnd
    
    cmp allEnemies[bx].spawnCounter, enemySpawnRate
    jge validToSpawnEnemy

    ;Not valid to spawn enemy
    inc allEnemies[bx].spawnCounter
    jmp spawnEnemyEnd
    
    validToSpawnEnemy:
        mov allEnemies[bx].spawnCounter, 0
        call initEnemy
         
    spawnEnemyEnd:
    RET
spawnEnemy ENDP


moveEnemy PROC
    cmp allEnemies[bx].moveCounter, enemyMoveRate
    je validToMoveEnemy
    
    ;Not valid to spawn enemy
    inc allEnemies[bx].moveCounter
    jmp moveEnemyEnd
    
    validToMoveEnemy:
    mov allEnemies[bx].moveCounter, 0
    cmp allEnemies[bx].x, 0
    je moveEnemyEnd ;Not initialized
    
    ;Erase previous drawing
    mov drawOrErase, 0
    call drawCurrentEnemy
    
    sub allEnemies[bx].x, enemyVelocity
    
    ;Has not reached border? (index)
    cmp allEnemies[bx].x, borderWidth + 1
    jge moveEnemyDraw
    
    ;Reached border
    resetEnemy:
        mov allEnemies[bx].x, 0
        ;Insta-kill player
        mov cx, playerHP
        instaKillPlayer:
            call decPlayerHP
            loop instaKillPlayer
        jmp moveEnemyEnd
    
    moveEnemyDraw:
        mov drawOrErase, 1 ;Draw
        call drawCurrentEnemy
        jmp moveEnemyEnd
    
    moveEnemyEnd:
    RET
moveEnemy ENDP


killEnemy PROC
    ;Enemy to kill in BX
    mov bx, currentEnemy
    mov drawOrErase, 0
    call drawCurrentEnemy ;Erase
    mov allEnemies[bx].x, 0
    mov allEnemies[bx].y, 0
    xor currentEnemy, 1 ;Switch 1 and 0

    ;Reset their spawn counter & fix bug
    mov bx, currentEnemy
    mov allEnemies[bx].spawnCounter, 0
    RET
killEnemy ENDP


fireEnemyShot PROC
    ;BX holds current enemy index
    cmp allEnemies[bx].x, 0
    je fireEnemyShotEnd
    
    cmp allEnemies[bx].shootCounter, enemyShootRate
    jae validToShoot

    ;Not valid to shoot
    inc allEnemies[bx].shootCounter
    jmp fireEnemyShotEnd

    validToShoot:
        mov allEnemies[bx].shootCounter, 0
        ;Init shot
        cmp bx, 0
        je callInitBlueShot
        cmp bx, 1
        je callInitYellowShot

        jmp fireEnemyShotEnd

        callInitBlueShot:
            call initBlueEnemyShot
            jmp fireEnemyShotEnd
        callInitYellowShot:
            call initYellowEnemyShot
            jmp fireEnemyShotEnd
    
    fireEnemyShotEnd:
    RET
fireEnemyShot ENDP


;--------------------------------------------------BLUE ENEMY SHOTS------------------------------------------------------------------------------------------------------------------------


initBlueEnemyShot PROC
    push si
    ;Determine which shot to work on
    mov si, 0 ;Current shot
    mov ax, blueEnemyShots.max
    dec ax ;Can't do in 1 line
    checkBlueEnemyShots:
        cmp si, ax ;No shots available
        ja initBlueEnemyShotEnd
        
        cmp blueEnemyShots.xArr[si], 0
        je setBlueEnemyShot ;Shot NOT initialized
        
        add si, 2
        jmp checkBlueEnemyShots
    
    setBlueEnemyShot:
    mov ax, (blueEnemyHeight - enemyShotHeight) / 2
    ;Move to CX
    mov ch, 0
    mov cl, allEnemies[0].y
    add ax, cx

    mov blueEnemyShots.yArr[si], ax ;Save y value
    ;Calc X since allEnemies[0].x isn't a const
    mov ax, allEnemies[0].x
    sub ax, enemyShotWidth - 2 ;2 to shoot from body
    mov blueEnemyShots.xArr[si], ax
    
    mov drawOrErase, 1
    call drawBlueEnemyShot ;Draw
    
    initBlueEnemyShotEnd:
    pop si
    RET
initBlueEnemyShot ENDP


;Param SI holds current shot index
drawBlueEnemyShot PROC
    push bx cx dx
    
    ;Get drawing position
    mov cx, blueEnemyShots.xArr[si]
    mov dx, blueEnemyShots.yArr[si]
    call getPosition

    ;Draw main part of shot
    mov dl, blueEnemyShotFrontColor
    cmp drawOrErase, 0
    jne drawBlueEnemyShotMain
    mov dl, bgColor
    
    drawBlueEnemyShotMain:
    mov cx, enemyShotHeight
    drawBlueEnemyShotRows:
        push cx
        mov cx, enemyShotWidth - 6 ;6 is trails
        call horizontalLine
        pop cx
        add di, windowWidth - enemyShotWidth + 7 ;Next row
        loop drawBlueEnemyShotRows

    sub di, windowWidth*2 - enemyShotWidth + 6   ;Start of trails

    lea bx, blueEnemyShotTrailColors[0]
    mov cx, 3 ;Num of trail colors
    blueEnemyShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawBlueEnemyShotTrail
        mov dl, bgColor
        drawBlueEnemyShotTrail:
        push cx
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        pop cx
        inc bx ;Get next color
        loop blueEnemyShotsTrails

    pop dx cx bx
    RET
drawBlueEnemyShot ENDP


moveBlueEnemyShots PROC
    push si
    ;Go through all the shots
    mov si, -2 ;So we can start at 0 in loop
    handleBlueEnemyShots:
        add si, 2
        mov ax, blueEnemyShots.max
        dec ax ;Can't do in 1 line
        
        cmp si, ax
        ja moveBlueEnemyShotsEnd ;No shots are available
        
        cmp blueEnemyShots.xArr[si], 0
        jne moveCurrentBlueEnemyShot ;Shot initialized
        
        jmp handleBlueEnemyShots ;Shot NOT initialized
    
    jmp moveBlueEnemyShotsEnd ;Handled all shots
    
    moveCurrentBlueEnemyShot:
        ;Remove prev shot
        mov drawOrErase, 0
        call drawBlueEnemyShot
        
        ;Check collisions
        call blueEnemyShotCollisions
        cmp dh, 0 ;Return is boolean
        je moveBlueEnemyShotsDraw ;No collision detected
        
        ;DH is 1, collosion detected: reset shot
        mov blueEnemyShots.xArr[si], 0
        jmp handleBlueEnemyShots
            
        moveBlueEnemyShotsDraw:
            dec blueEnemyShots.xArr[si]
            mov drawOrErase, 1
            call drawBlueEnemyShot ;Draw
            jmp handleBlueEnemyShots
    
    moveBlueEnemyShotsEnd:
    pop si
    RET
moveBlueEnemyShots ENDP


;Param SI holds current shot index
;Return in DH, 1 if collision else 0
blueEnemyShotCollisions PROC
    push cx
    ;Assume no collision
    mov dh, 0
    
    ;Calculates pos of front to DI
    mov cx, blueEnemyShots.xArr[si]
    dec cx                      ;X pos
    mov dx, blueEnemyShots.yArr[si] ;Y pos
    call getPosition
    
    ;Is in border?
    cmp cx, borderWidth
    je detectedBlueEnemyShotCollision
    
    ;Check top, then bottom
    mov cx, 2
    checkBlueEnemyShotCollision:
        cmp byte ptr es:[di], bgColor
        je checkBlueEnemyShotCollisionNext
        cmp byte ptr es:[di], starsColor
        je checkBlueEnemyShotCollisionNext
        cmp byte ptr es:[di], playerShotFrontColor
        je checkBlueEnemyShotCollisionNext
        mov dl, playerColors[0]
        cmp es:[di], dl
        je blueEnemyShotCollidedPlayer
        mov dl, playerColors[1]
        cmp es:[di], dl
        je blueEnemyShotCollidedPlayer
        jmp detectedBlueEnemyShotCollision ;Collision detected

        checkBlueEnemyShotCollisionNext:
        add di, (enemyShotHeight-1)*windowWidth
        loop checkBlueEnemyShotCollision
    jmp blueEnemyShotCollisionsEnd ;No collisions
    
    blueEnemyShotCollidedPlayer:
        call decPlayerHP
    
    detectedBlueEnemyShotCollision:
        mov dh, 1  ;Collision true
    
    blueEnemyShotCollisionsEnd:
    ;No collision - DH is already 0
    pop cx
    RET
blueEnemyShotCollisions ENDP


;--------------------------------------------------YELLOW ENEMY SHOTS------------------------------------------------------------------------------------------------------------------------


initYellowEnemyShot PROC
    push si
    ;Determine which shot to work on
    mov si, 0 ;Current shot
    mov ax, yellowEnemyShots.max
    dec ax ;Can't do in 1 line
    checkYellowEnemyShots:
        cmp si, ax ;No shots available
        ja initYellowEnemyShotEnd
        
        cmp yellowEnemyShots.xArr[si], 0
        je setYellowEnemyShot ;Shot NOT initialized
        
        add si, 2
        jmp checkYellowEnemyShots
    
    setYellowEnemyShot:
    mov ax, (yellowEnemyHeight - enemyShotHeight) / 2
    ;Move to CX
    mov ch, 0
    mov cl, allEnemies[1].y
    add ax, cx

    mov yellowEnemyShots.yArr[si], ax ;Save y value
    ;Calc X since allEnemies[0].x isn't a const
    mov ax, allEnemies[1].x
    sub ax, enemyShotWidth
    mov yellowEnemyShots.xArr[si], ax
    
    mov drawOrErase, 1
    call drawYellowEnemyShot ;Draw
    
    initYellowEnemyShotEnd:
    pop si
    RET
initYellowEnemyShot ENDP


;Param SI holds current shot index
drawYellowEnemyShot PROC
    push bx cx dx
    
    ;Get drawing position
    mov cx, yellowEnemyShots.xArr[si]
    mov dx, yellowEnemyShots.yArr[si]
    call getPosition

    ;Draw main part of shot
    mov dl, yellowEnemyShotFrontColor
    cmp drawOrErase, 0
    jne drawYellowEnemyShotMain
    mov dl, bgColor
    
    drawYellowEnemyShotMain:
    mov cx, enemyShotHeight
    drawYellowEnemyShotRows:
        push cx
        mov cx, enemyShotWidth - 6 ;6 is trails
        call horizontalLine
        pop cx
        add di, windowWidth - enemyShotWidth + 7 ;Next row
        loop drawYellowEnemyShotRows

    sub di, windowWidth*2 - enemyShotWidth + 6   ;Start of trails

    lea bx, yellowEnemyShotTrailColors[0]
    mov cx, 3 ;Num of trail colors
    yellowEnemyShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawYellowEnemyShotTrail
        mov dl, bgColor
        drawYellowEnemyShotTrail:
        push cx
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        mov cx, 2
        call verticalLine
        sub di, windowWidth - 1
        pop cx
        inc bx ;Get next color
        loop yellowEnemyShotsTrails

    pop dx cx bx
    RET
drawYellowEnemyShot ENDP


moveYellowEnemyShots PROC
    push si
    ;Go through all the shots
    mov si, -2 ;So we can start at 0 in loop
    handleYellowEnemyShots:
        add si, 2
        mov ax, yellowEnemyShots.max
        dec ax ;Can't do in 1 line
        
        cmp si, ax
        ja moveYellowEnemyShotsEnd ;No shots are available
        
        cmp yellowEnemyShots.xArr[si], 0
        jne moveCurrentYellowEnemyShot ;Shot initialized
        
        jmp handleYellowEnemyShots ;Shot NOT initialized
    
    jmp moveYellowEnemyShotsEnd ;Handled all shots
    
    moveCurrentYellowEnemyShot:
        ;Remove prev shot
        mov drawOrErase, 0
        call drawYellowEnemyShot
        
        ;Check collisions
        call yellowEnemyShotCollisions
        cmp dh, 0 ;Return is boolean
        je moveYellowEnemyShotsDraw ;No collision detected
        
        ;DH is 1, collosion detected: reset shot
        mov yellowEnemyShots.xArr[si], 0
        jmp handleYellowEnemyShots
            
        moveYellowEnemyShotsDraw:
            dec yellowEnemyShots.xArr[si]
            mov drawOrErase, 1
            call drawYellowEnemyShot ;Draw
            jmp handleYellowEnemyShots
    
    moveYellowEnemyShotsEnd:
    pop si
    RET
moveYellowEnemyShots ENDP


;Param SI holds current shot index
;Return in DH, 1 if collision else 0
yellowEnemyShotCollisions PROC
    push cx
    ;Assume no collision
    mov dh, 0
    
    ;Calculates pos of front to DI
    mov cx, yellowEnemyShots.xArr[si]
    dec cx                      ;X pos
    mov dx, yellowEnemyShots.yArr[si] ;Y pos
    call getPosition
    
    ;Is in border?
    cmp cx, borderWidth
    je detectedYellowEnemyShotCollision
    
    ;Check top, then bottom
    mov cx, 2
    checkYellowEnemyShotCollision:
        cmp byte ptr es:[di], bgColor
        je checkYellowEnemyShotCollisionNext
        cmp byte ptr es:[di], starsColor
        je checkYellowEnemyShotCollisionNext
        cmp byte ptr es:[di], playerShotFrontColor
        je checkYellowEnemyShotCollisionNext
        mov dl, playerColors[0]
        cmp es:[di], dl
        je yellowEnemyShotCollidedPlayer
        mov dl, playerColors[1]
        cmp es:[di], dl
        je yellowEnemyShotCollidedPlayer
        jmp detectedYellowEnemyShotCollision ;Collision detected

        checkYellowEnemyShotCollisionNext:
        add di, (enemyShotHeight-1)*windowWidth
        loop checkYellowEnemyShotCollision
    jmp yellowEnemyShotCollisionsEnd ;No collisions
    
    yellowEnemyShotCollidedPlayer:
        call decPlayerHP
    
    detectedYellowEnemyShotCollision:
        mov dh, 1  ;Collision true
    
    yellowEnemyShotCollisionsEnd:
    ;No collision - DH is already 0
    pop cx
    RET
yellowEnemyShotCollisions ENDP


;--------------------------------------------------DEATH SCREEN------------------------------------------------------------------------------------------------------------------------


drawA PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    sub di, windowWidth + 15
    call drawH
    RET
drawA ENDP

drawC PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 20
    call verticalLine
    sub di, windowWidth*19 - 1
    mov cx, 20
    call verticalLine
    add di, windowWidth - 1
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    RET
drawC ENDP

drawE PROC
    mov cx, 24
    call verticalLine
    sub di, windowWidth*23 - 1
    mov cx, 24
    call verticalLine
    inc di
    mov cx, 14
    call horizontalLine
    sub di, windowWidth + 13
    mov cx, 14
    call horizontalLine
    sub di, windowWidth*10 + 13
    mov cx, 13
    call horizontalLine
    add di, windowWidth - 12
    mov cx, 13
    call horizontalLine
    sub di, windowWidth*13 + 12
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 13
    mov cx, 14
    call horizontalLine
    RET
drawE ENDP

drawG PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 20
    call verticalLine
    sub di, windowWidth*19 - 1
    mov cx, 20
    call verticalLine
    add di, windowWidth - 1
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    sub di, windowWidth*11
    mov cx, 10
    call verticalLine
    sub di, windowWidth*9 + 6
    mov cx, 6
    call horizontalLine
    RET
drawG ENDP

drawH PROC
    mov cx, 24
    call verticalLine
    sub di, windowWidth*23 - 1
    mov cx, 24
    call verticalLine
    sub di, windowWidth*12 - 1
    mov cx, 12
    call horizontalLine
    add di, windowWidth - 11
    mov cx, 12
    call horizontalLine
    sub di, windowWidth*12 - 1
    mov cx, 24
    call verticalLine
    sub di, windowWidth*23 - 1
    mov cx, 24
    call verticalLine
    RET
drawH ENDP

drawO PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth*22 - 15
    mov cx, 16
    call horizontalLine
    sub di, windowWidth + 15
    mov cx, 16
    call horizontalLine
    sub di, windowWidth*20 + 15
    mov cx, 20
    call verticalLine
    sub di, windowWidth*19 - 1
    mov cx, 20
    call verticalLine
    sub di, windowWidth*19 - 14
    mov cx, 20
    call verticalLine
    sub di, windowWidth*19 + 1
    mov cx, 20
    call verticalLine
    RET
drawO ENDP

drawP PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 22
    call verticalLine
    sub di, windowWidth*21 - 1
    mov cx, 22
    call verticalLine
    sub di, windowWidth*22 - 13
    mov cx, 10
    call verticalLine
    sub di, windowWidth*9 - 1
    mov cx, 10
    call verticalLine
    add di, windowWidth - 13
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 13
    mov cx, 14
    call horizontalLine
    RET
drawP ENDP

drawR PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 22
    call verticalLine
    sub di, windowWidth*21 - 1
    mov cx, 22
    call verticalLine
    sub di, windowWidth*12 - 1
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 13
    mov cx, 14
    call horizontalLine
    sub di, windowWidth*10
    mov cx, 9
    call verticalLine
    sub di, windowWidth*8 + 1
    mov cx, 9
    call verticalLine
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
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 10
    call verticalLine
    sub di, windowWidth*9 - 1
    mov cx, 10
    call verticalLine
    add di, windowWidth - 1
    mov cx, 16
    call horizontalLine
    sub di, windowWidth + 14
    mov cx, 15
    call horizontalLine
    add di, windowWidth*2
    mov cx, 11
    call verticalLine
    sub di, windowWidth*10 + 1
    mov cx, 11
    call verticalLine
    sub di, windowWidth + 14
    mov cx, 14
    call horizontalLine
    add di, windowWidth - 13
    mov cx, 14
    call horizontalLine
    RET
drawS ENDP

drawT PROC
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 15
    mov cx, 16
    call horizontalLine
    add di, windowWidth - 7
    mov cx, 22
    call verticalLine
    sub di, windowWidth*21 + 1
    mov cx, 22
    call verticalLine
    RET
drawT ENDP


printDeathScreen PROC
    call cls
    mov dl, 0Fh
    mov bx, windowWidth*48 + 100
    ;Letters are 16*24
    
    ;Draw G
    mov di, bx
    call drawG
    
    add bx, 29
    mov di, bx
    call drawA
    
    ;Draw M
    add bx, 29
    mov di, bx
    mov cx, 24
    call verticalLine
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
    mov cx, 24
    call verticalLine
    
    add bx, 29
    mov di, bx
    call drawE
    
    add bx, windowWidth*37 - 87
    mov di, bx
    call drawO
    
    ;Draw V
    add bx, 29
    mov di, bx
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
    
    ;Draw E
    add bx, 29
    mov di, bx
    call drawE
    
    add bx, 29
    mov di, bx
    call drawR
    RET
printDeathScreen ENDP


;--------------------------------------------------SHOP---------------------------------------------------------------------------------------------------------------------------------


initShop PROC
    ;Shop border
    mov dl, borderColor
    mov di, windowWidth*189 + 80
    mov cx, 10
    call verticalLine
    mov di, windowWidth*189 + 240
    mov cx, 10
    call verticalLine
    mov di, windowWidth*189 + 81
    mov cx, 159
    call horizontalLine

    mov di, windowWidth*191 + 120
    call drawPlus

    mov playerShots.xArr[0], 130
    mov playerShots.yArr[0], 194
    mov bx, 0
    call drawPlayerShot

    RET
initShop ENDP


drawPlus PROC
    push cx dx di
    mov dl, 2
    add di, 3
    mov cx, 7
    call verticalLine
    sub di, windowWidth*3 + 3
    mov cx, 7
    call horizontalLine
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
    mov ah, 0
    mov al, shotPrices[bx - 1] ;1 is initial real max
    cmp playerScore, ax
    jl buyShotsEnd

    ;Buy new shot
    sub playerScore, ax
    call drawScore
    inc playerShots.max
    
    buyShotsEnd:
    pop bx ax
    RET
buyShots ENDP


;----------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------


main:
    mov ax, @data
    mov ds, ax
    
    call initializeGraphics
    call welcomeScreen
    call initializeGame

    ;Each iteration is a frame
    game:
        call delay
        call accelerateGame

        call checkPlayerCollisions
        call movePlayerShots
        call handleEnemies
        call drawStars
    
        call handleGameInput
        cmp playerHP, 0 ;Check if player died
        jg game

        ;End of game loop
    
    call printDeathScreen

    sof: ;Terminate program
    mov ah, 4Ch
    int 21h
end main
