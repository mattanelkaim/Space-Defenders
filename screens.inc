ifndef SCREENS
SCREENS equ 1

;#################### WELCOME SCREEN ####################

welcomeScreen PROC
    push si
    mov drawOrErase, 1

    ;Player & shots
    mov playerY, 140
    call drawPlayer
    mov playerShots.xArr[0], 65
    mov playerShots.yArr[0], 148
    xor bx, bx
    call drawPlayerShot
    mov playerShots.xArr[1], 115
    mov playerShots.yArr[1], 151
    inc bx
    call drawPlayerShot
    mov playerShots.xArr[2], 150
    mov playerShots.yArr[2], 149
    inc bx
    call drawPlayerShot
    
    ;Blue enemy & shots
    mov allEnemies[0].x, 250
    mov allEnemies[0].y, 30
    call drawBlueEnemy
    mov blueEnemyShots.xArr[0], 200
    mov blueEnemyShots.yArr[0], 40
    xor si, si ;SI = 0
    call drawBlueEnemyShot
    mov blueEnemyShots.xArr[1], 100
    mov blueEnemyShots.yArr[1], 42
    inc si     ;SI = 1
    call drawBlueEnemyShot

    ;Yellow enemy & shots
    mov allEnemies[1].x, 200
    mov allEnemies[1].y, 140
    call drawYellowEnemy
    mov yellowEnemyShots.xArr[0], 175
    mov yellowEnemyShots.yArr[0], 148
    xor si, si
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
    call getPosition ;To DI

    mov dl, 0Fh
    mov bx, di       ;Save anchor
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


;#################### DEATH SCREEN ####################

printDeathScreen PROC
    call cls
    mov dl, 0Fh
    ;Letters are 16*24
    
    mov bx, windowWidth*48 + 100
    mov di, bx
    call drawG
    
    add bx, 29
    mov di, bx
    call drawA
    
    add bx, 29
    mov di, bx
    call drawM
    
    add bx, 29
    mov di, bx
    call drawE
    
    add bx, windowWidth*37 - 87
    mov di, bx
    call drawO
    
    add bx, 29
    mov di, bx
    call drawV
    
    add bx, 29
    mov di, bx
    call drawE
    
    add bx, 29
    mov di, bx
    call drawR
    RET
printDeathScreen ENDP

endif
