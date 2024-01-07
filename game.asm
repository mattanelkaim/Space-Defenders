;NOTES:
;Anchor tile is at top-left (0,0)
;Max score = 9999
;Colors are from mode 13h VGA color palette
;DL/DX are affected by mul & div!
;XOR x, x resets x
;byte ptr to indicate byte-sized operand
;Order of includes matters
include draw.inc
include utils.inc
include digits.inc
include letters.inc
include pShots.inc
include player.inc
include gui.inc

MODEL small
STACK 100h
DATASEG

jmp main ;data & procs are compiled, no need to run them

enemy STRUC
    ;Must stay 8 bytes long
    x dw ?
    y db ?
    spawnCounter dw 0
    moveCounter db 0
    shootCounter dw 0
enemy ENDS

limitMaxShots equ 5

shots STRUC
    xArr dw limitMaxShots dup(0)
    yArr dw limitMaxShots dup(0)
    max dw ?        ;Actual current max = max/2, shots are dw arrays
    trailColors db 3 dup(?)
shots ENDS
shotWidth equ 10
shotHeight equ 2 ;DO NOT CHANGE!

;Player shots variables
playerShots shots {max=1} ;Upgradable
playerShotFrontColor equ 34h
playerShotTrailColors db 20h, 37h, 36h

;Global enemy variables
enemyVelocity equ 2
enemySpawnRate equ 180 ;180f/120fps = 1.5secs
enemyMoveRate equ 16   ;16f/120fps = 0.133secs
enemyShootRate equ 300 ;300f/120fps = 2.5secs
numOfEnemies equ 2
allEnemies dq numOfEnemies dup(enemy) ;Blue, yellow
currentEnemy dw 0      ;0=blue, 1=yellow
enemyScores db 3, 5    ;Blue & yellow

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

CODESEG

;--------------------------------------------------GLOBALS AND INITS-------------------------------------------------------------------------------------------------------------------


initializeGame PROC
    call initPlayer
    call initShop
    call initAllShots
    call drawBorder
    call drawStars
    call drawPlayerHP
    call drawCoin
    call updateScore
    ;Kill both enemies
    call killEnemy
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
    
    xor ah, ah ;AH=0 -> Get key ASCII to AL & BIOS code to AH
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
        call updateScore
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


initAllShots PROC
    ;Reset x & y values after welcome screen
    push ax cx di
    ;Move temporarily DS to ES
    mov ax, ds
    mov es, ax

    cld ;So that stosw will add 2 to DI
    xor ax, ax

    lea di, playerShots.xArr[0]
    mov cx, limitMaxShots
    rep stosw
    
    lea di, blueEnemyShots.xArr[0]
    mov cx, limitMaxShots
    rep stosw
    
    lea di, yellowEnemyShots.xArr[0]
    mov cx, limitMaxShots
    rep stosw

    mov ax, 0A000h
    mov es, ax ;Restore ES to video memory
    pop di cx ax
    RET
initAllShots ENDP


initEnemy PROC
    ;Current enemy index in BX
    push bx dx
    mov allEnemies[bx].x, windowWidth - blueEnemyWidth - 20  ;20 is offset
    ;y is random between 20-150
    push bx
    mov bl, 20     ;Min
    mov bh, 150    ;Max
    call randomize ;To DX
    pop bx
    mov allEnemies[bx].y, dl ;Must be 8 bits
    
    ;Shoot faster on init (by 75%)
    mov allEnemies[bx].shootCounter, enemyShootRate * 3 / 4
    pop dx bx
    RET
initEnemy ENDP


;--------------------------------------------------ENEMIES------------------------------------------------------------------------------------------------------------------------

handleEnemies PROC
    call moveBlueEnemyShots
    call moveYellowEnemyShots

    mov bx, currentEnemy
    call spawnEnemy
    call moveEnemy
    call fireEnemyShot
    RET
handleEnemies ENDP


drawBlueEnemy PROC
    push bx cx dx
    
    mov cx, allEnemies[0].x
    ;Move to DX
    xor dh, dh
    mov dl, allEnemies[0].y
    call getPosition
    mov bx, di ;Save anchor point
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyLightGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyLightGrey:
    add di, 5
    DRAW_HORIZONTAL 14
    add di, windowWidth - 14
    DRAW_HORIZONTAL 3
    add di, 10
    DRAW_HORIZONTAL 4
    add di, windowWidth - 16
    DRAW_HORIZONTAL 2
    add di, 14
    DRAW_HORIZONTAL 3
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth
    mov es:[di], dl
    sub di, windowWidth + 17
    DRAW_HORIZONTAL 2
    add di, windowWidth - 1
    mov es:[di], dl
    dec di
    DRAW_VERTICAL 7
    inc di
    DRAW_VERTICAL 3
    inc di
    mov es:[di], dl
    add di, windowWidth
    DRAW_HORIZONTAL 2
    add di, windowWidth
    DRAW_HORIZONTAL 4
    add di, windowWidth - 2
    DRAW_HORIZONTAL 11
    sub di, windowWidth + 2
    DRAW_HORIZONTAL 4
    sub di, windowWidth
    DRAW_HORIZONTAL 2
    sub di, windowWidth
    DRAW_HORIZONTAL 2
    sub di, windowWidth
    DRAW_HORIZONTAL 2
    sub di, windowWidth
    mov es:[di], dl
    sub di, 6*windowWidth - 1
    DRAW_VERTICAL 7
    
    mov dl, 15h     ;Dark grey
    cmp drawOrErase, 1
    je drawBlueEnemyDarkGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkGrey:
    mov di, bx ;Reset to anchor
    add di, windowWidth + 7
    DRAW_HORIZONTAL 9
    add di, windowWidth - 9
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 2
    add di, 8
    DRAW_HORIZONTAL 2
    add di, 2
    DRAW_VERTICAL 9
    sub di, 8*windowWidth - 1
    DRAW_VERTICAL 8
    sub di, 5*windowWidth - 1
    DRAW_VERTICAL 5
    add di, windowWidth - 3
    DRAW_VERTICAL 3
    dec di
    DRAW_VERTICAL 2
    dec di
    mov es:[di], dl
    sub di, 9
    DRAW_HORIZONTAL 2
    sub di, windowWidth + 1
    mov es:[di], dl
    sub di, 2*windowWidth + 1
    DRAW_VERTICAL 3
    sub di, 8*windowWidth + 1
    DRAW_VERTICAL 8
    sub di, 6*windowWidth + 1
    DRAW_VERTICAL 5
    
    mov dl, 0Eh     ;Yellow
    cmp drawOrErase, 1
    je drawBlueEnemyYellow
    mov dl, bgColor ;Erase
    
    drawBlueEnemyYellow:
    mov di, bx ;Reset to anchor
    add di, 2*windowWidth + 5
    DRAW_VERTICAL 4
    sub di, windowWidth - 1
    mov es:[di], dl
    add di, 10
    mov es:[di], dl
    sub di, 2*windowWidth - 1
    DRAW_VERTICAL 4
    
    mov dl, 36h     ;Blue
    cmp drawOrErase, 1
    je drawBlueEnemyBlue
    mov dl, bgColor ;Erase
    
    drawBlueEnemyBlue:
    mov di, bx ;Reset to anchor
    add di, 3*windowWidth + 8
    DRAW_HORIZONTAL 7
    add di, windowWidth - 7
    DRAW_HORIZONTAL 9
    add di, windowWidth - 9
    DRAW_HORIZONTAL 4
    add di, 4
    DRAW_HORIZONTAL 4
    add di, windowWidth - 11
    DRAW_HORIZONTAL 4
    add di, 6
    DRAW_HORIZONTAL 4
    add di, windowWidth - 12
    DRAW_HORIZONTAL 3
    add di, 8
    DRAW_HORIZONTAL 3
    add di, windowWidth - 12
    DRAW_HORIZONTAL 3
    add di, 8
    DRAW_HORIZONTAL 3
    add di, windowWidth - 12
    DRAW_HORIZONTAL 4
    add di, 6
    DRAW_HORIZONTAL 4
    add di, windowWidth - 11
    DRAW_HORIZONTAL 4
    add di, 4
    DRAW_HORIZONTAL 4
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, windowWidth - 9
    DRAW_HORIZONTAL 9
    add di, windowWidth - 7
    DRAW_HORIZONTAL 7
    add di, windowWidth - 5
    DRAW_HORIZONTAL 5    
    
    mov dl, 0Fh     ;White
    cmp drawOrErase, 1
    je drawBlueEnemyWhite
    mov dl, bgColor ;Erase
    
    drawBlueEnemyWhite:
    mov di, bx ;Reset to anchor
    add di, 5*windowWidth + 10
    DRAW_HORIZONTAL 3
    add di, windowWidth - 3
    DRAW_HORIZONTAL 5
    add di, windowWidth - 5
    DRAW_HORIZONTAL 2
    add di, 4
    DRAW_HORIZONTAL 2
    add di, windowWidth - 6
    DRAW_HORIZONTAL 2
    add di, 4
    DRAW_HORIZONTAL 2
    add di, windowWidth - 5
    DRAW_HORIZONTAL 5
    add di, windowWidth - 3
    DRAW_HORIZONTAL 3
        
    mov dl, 14h     ;Darker grey
    cmp drawOrErase, 1
    je drawBlueEnemyDarkerGrey
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkerGrey:
    mov di, bx ;Reset to anchor
    add di, 7*windowWidth + 10
    DRAW_HORIZONTAL 3
    add di, windowWidth - 2
    DRAW_HORIZONTAL 3
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyDarkPurple
    mov dl, bgColor ;Erase
    
    drawBlueEnemyDarkPurple:
    mov di, bx ;Reset to anchor
    add di, 15*windowWidth + 5
    mov es:[di], dl
    add di, 12
    DRAW_HORIZONTAL 2
    add di, windowWidth - 14
    DRAW_HORIZONTAL 15
    add di, windowWidth - 14
    DRAW_HORIZONTAL 15
    
    mov dl, blueEnemyColor ;Lilac
    cmp drawOrErase, 1
    je drawBlueEnemyLightPurple
    mov dl, bgColor ;Erase
    
    drawBlueEnemyLightPurple:
    mov di, bx ;Reset to anchor
    add di, 16*windowWidth + 3
    DRAW_VERTICAL 2
    dec di
    DRAW_VERTICAL 2
    dec di
    DRAW_VERTICAL 2
    dec di
    mov es:[di], dl
    sub di, 2*windowWidth - 11
    DRAW_VERTICAL 3
    sub di, 3*windowWidth - 8
    DRAW_VERTICAL 2
    inc di
    DRAW_VERTICAL 2
    inc di
    DRAW_VERTICAL 2
    inc di
    mov es:[di], dl
    
    pop dx cx bx
    RET
drawBlueEnemy ENDP


drawYellowEnemy PROC
    push bx cx dx
    
    mov cx, allEnemies[1].x
    ;Move to DX
    xor dh, dh
    mov dl, allEnemies[1].y
    call getPosition
    mov bx, di ;Save anchor point

    mov dl, yellowEnemyColor
    cmp drawOrErase, 1
    je drawYellowEnemyOuter
    mov dl, bgColor ;Erase
    
    drawYellowEnemyOuter:
    add di, 7
    DRAW_HORIZONTAL 9
    add di, windowWidth - 10
    DRAW_HORIZONTAL 13
    mov cx, 3
    yellowEnemyOuterLoop:
        push cx
        add di, windowWidth - 1
        DRAW_HORIZONTAL 3
        pop cx
        loop yellowEnemyOuterLoop
    add di, windowWidth - 1
    DRAW_HORIZONTAL 2
    add di, windowWidth - 1
    mov es:[di], dl
    inc di
    DRAW_VERTICAL 9
    sub di, windowWidth*8 - 1
    DRAW_VERTICAL 8
    sub di, 2
    mov es:[di], dl
    add di, windowWidth - 1
    DRAW_HORIZONTAL 2
    add di, windowWidth - 3
    DRAW_HORIZONTAL 4
    add di, windowWidth - 16
    DRAW_HORIZONTAL 16
    add di, windowWidth - 15
    DRAW_HORIZONTAL 4
    add di, 3
    DRAW_HORIZONTAL 6
    add di, 3
    DRAW_HORIZONTAL 3
    add di, windowWidth - 15
    DRAW_HORIZONTAL 7
    add di, 3
    DRAW_HORIZONTAL 7
    add di, windowWidth - 14
    DRAW_HORIZONTAL 14
    add di, windowWidth - 14
    DRAW_HORIZONTAL 3
    add di, 3
    DRAW_HORIZONTAL 5
    add di, 3
    DRAW_HORIZONTAL 2
    add di, windowWidth - 1
    DRAW_HORIZONTAL 3
    add di, windowWidth - 1
    DRAW_HORIZONTAL 2
    sub di, 15
    DRAW_HORIZONTAL 2
    sub di, windowWidth + 1
    DRAW_HORIZONTAL 3
    sub di, windowWidth + 1
    DRAW_HORIZONTAL 3
    sub di, windowWidth*5 + 2
    DRAW_HORIZONTAL 3
    sub di, windowWidth + 3
    DRAW_HORIZONTAL 2
    sub di, windowWidth + 2
    DRAW_HORIZONTAL 2
    sub di, windowWidth*7 + 2
    DRAW_VERTICAL 7
    sub di, windowWidth*8 - 1
    DRAW_VERTICAL 9
    sub di, windowWidth*9 - 1
    DRAW_VERTICAL 4
    sub di, windowWidth*4 - 1
    DRAW_VERTICAL 3
    sub di, windowWidth*2 - 1
    DRAW_VERTICAL 2
    sub di, windowWidth - 1
    mov es:[di], dl

    mov dl, 15h
    cmp drawOrErase, 1
    je drawYellowEnemyInner
    mov dl, bgColor ;Erase

    drawYellowEnemyInner:
    mov di, bx ;Anchor
    add di, windowWidth*2 + 7
    DRAW_HORIZONTAL 9
    mov cx, 3
    yellowEnemyInnerLoop1:
        push cx
        add di, windowWidth - 1
        DRAW_HORIZONTAL 3
        pop cx
        loop yellowEnemyInnerLoop1
    add di, windowWidth - 1
    DRAW_VERTICAL 3
    sub di, windowWidth*2 - 1
    DRAW_VERTICAL 4
    sub di, windowWidth*2 - 1
    DRAW_VERTICAL 6
    sub di, windowWidth + 1
    DRAW_VERTICAL 3
    sub di, windowWidth + 1
    DRAW_VERTICAL 3
    sub di, windowWidth*12 + 8
    mov cx, 3
    yellowEnemyInnerLoop2:
        push cx
        add di, windowWidth - 3
        DRAW_HORIZONTAL 3
        pop cx
        loop yellowEnemyInnerLoop2
    add di, windowWidth - 1
    DRAW_VERTICAL 3
    sub di, windowWidth*2 + 1
    DRAW_VERTICAL 4
    sub di, windowWidth*2 + 1
    DRAW_VERTICAL 6
    sub di, windowWidth - 1
    DRAW_VERTICAL 3
    sub di, windowWidth - 1
    DRAW_VERTICAL 3

    mov dl, 2Ch
    cmp drawOrErase, 1
    je drawYellowEnemyAlien
    mov dl, bgColor ;Erase

    drawYellowEnemyAlien:
    mov di, bx
    add di, windowWidth*3 + 9
    DRAW_HORIZONTAL 5
    add di, windowWidth - 5
    DRAW_HORIZONTAL 7
    add di, windowWidth - 7
    DRAW_HORIZONTAL 9
    add di, windowWidth - 7
    mov es:[di], dl
    sub di, 2
    DRAW_VERTICAL 9
    sub di, windowWidth*8 - 1
    DRAW_VERTICAL 9
    sub di, windowWidth*5 - 1
    DRAW_VERTICAL 3
    add di, windowWidth*3
    mov es:[di], dl
    add di, windowWidth - 1
    DRAW_HORIZONTAL 9
    sub di, windowWidth*5 + 11
    mov es:[di], dl
    sub di, windowWidth - 1
    DRAW_VERTICAL 3
    sub di, windowWidth - 4
    DRAW_HORIZONTAL 5
    sub di, windowWidth - 1
    DRAW_VERTICAL 3
    sub di, windowWidth*2 - 3
    DRAW_VERTICAL 3
    sub di, windowWidth - 1
    mov es:[di], dl
    add di, windowWidth*4 - 4
    mov es:[di], dl
    sub di, windowWidth*8
    mov es:[di], dl
    inc di
    DRAW_VERTICAL 9
    sub di, windowWidth*8 - 1
    DRAW_VERTICAL 9
    
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
        DRAW_HORIZONTAL 5
        add di, windowWidth - 5
        DRAW_HORIZONTAL 2
        add di, windowWidth - 1
        DRAW_HORIZONTAL 2
        add di, windowWidth
        DRAW_HORIZONTAL 5
        sub di, windowWidth
        DRAW_HORIZONTAL 2
        sub di, windowWidth + 1
        DRAW_HORIZONTAL 2
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
    DRAW_HORIZONTAL 3
    add di, windowWidth - 2
    DRAW_HORIZONTAL 3
    add di, windowWidth*4 - 2
    DRAW_HORIZONTAL 3
    add di, windowWidth - 2
    DRAW_HORIZONTAL 3

    mov dl, 0Ch
    cmp drawOrErase, 1
    je drawYellowEnemyLights
    mov dl, bgColor ;Erase
    
    drawYellowEnemyLights:
    mov di, bx
    add di, windowWidth*17 + 7
    DRAW_HORIZONTAL 2
    add di, 7
    DRAW_HORIZONTAL 2
    add di, windowWidth - 5
    DRAW_HORIZONTAL 2

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
    jb spawnEnemyEnd
    
    call initEnemy
    mov allEnemies[bx].spawnCounter, 0
    RET
         
    spawnEnemyEnd:
    inc allEnemies[bx].spawnCounter
    RET
spawnEnemy ENDP


moveEnemy PROC
    cmp allEnemies[bx].moveCounter, enemyMoveRate
    jae validToMoveEnemy
    
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
    
    ;Has reached border?
    cmp allEnemies[bx].x, borderWidth
    jg moveEnemyDraw
    
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
    
    moveEnemyEnd:
    RET
moveEnemy ENDP


killEnemy PROC
    ;Enemy to kill in BX
    push bx
    mov bx, currentEnemy
    mov drawOrErase, 0
    call drawCurrentEnemy ;Erase
    mov allEnemies[bx].x, 0
    mov allEnemies[bx].y, 0
    xor bx, 1             ;Toggle 1 and 0
    mov currentEnemy, bx
    
    ;Reset their spawn counter & fix bug
    mov allEnemies[bx].spawnCounter, 0
    pop bx
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
    RET

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
    xor si, si ;0 = Current shot
    mov ax, blueEnemyShots.max
    checkBlueEnemyShots:
        cmp si, ax
        jae initBlueEnemyShotEnd ;No shots available
        
        cmp blueEnemyShots.xArr[si], 0
        je setBlueEnemyShot      ;Shot NOT initialized
        
        add si, 2
        jmp checkBlueEnemyShots
    
    setBlueEnemyShot:
    mov ax, (blueEnemyHeight - shotHeight) / 2
    ;Move to CX
    xor cx, cx
    mov cl, allEnemies[0].y
    add ax, cx

    mov blueEnemyShots.yArr[si], ax ;Save y value
    ;Calc X since allEnemies[0].x isn't a const
    mov ax, allEnemies[0].x
    sub ax, shotWidth - 2 ;2 to shoot from body
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
    mov cx, shotHeight
    drawBlueEnemyShotRows:
        push cx
        DRAW_HORIZONTAL shotWidth-6 ;6 is trails, mustn't space between operator
        pop cx
        add di, windowWidth - shotWidth + 7 ;Next row
        loop drawBlueEnemyShotRows

    sub di, windowWidth*2 - shotWidth + 6   ;Start of trails

    lea bx, blueEnemyShotTrailColors[0]
    mov cx, 3 ;Num of trail colors
    blueEnemyShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawBlueEnemyShotTrail
        mov dl, bgColor
        drawBlueEnemyShotTrail:
        push cx
        DRAW_VERTICAL 2
        sub di, windowWidth - 1
        DRAW_VERTICAL 2
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
    xor dh, dh
    
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
        add di, (shotHeight-1)*windowWidth
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
    xor si, si ;0 = Current shot
    mov ax, yellowEnemyShots.max
    checkYellowEnemyShots:
        cmp si, ax
        jae initYellowEnemyShotEnd ;No shots available
        
        cmp yellowEnemyShots.xArr[si], 0
        je setYellowEnemyShot ;Shot NOT initialized
        
        add si, 2
        jmp checkYellowEnemyShots
    
    setYellowEnemyShot:
    mov ax, (yellowEnemyHeight - shotHeight) / 2
    ;Move to CX
    xor cx, cx
    mov cl, allEnemies[1].y
    add ax, cx

    mov yellowEnemyShots.yArr[si], ax ;Save y value
    ;Calc X since allEnemies[0].x isn't a const
    mov ax, allEnemies[1].x
    sub ax, shotWidth
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
    mov cx, shotHeight
    drawYellowEnemyShotRows:
        push cx
        DRAW_HORIZONTAL shotWidth-6 ;6 is trails, mustn't space between operator
        pop cx
        add di, windowWidth - shotWidth + 7 ;Next row
        loop drawYellowEnemyShotRows

    sub di, windowWidth*2 - shotWidth + 6   ;Start of trails

    lea bx, yellowEnemyShotTrailColors[0]
    mov cx, 3 ;Num of trail colors
    yellowEnemyShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawYellowEnemyShotTrail
        mov dl, bgColor
        drawYellowEnemyShotTrail:
        push cx
        DRAW_VERTICAL 2
        sub di, windowWidth - 1
        DRAW_VERTICAL 2
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
    xor dh, dh
    
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
        add di, (shotHeight-1)*windowWidth
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
