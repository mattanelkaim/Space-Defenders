ifndef PLAYER_SHOTS
PLAYER_SHOTS equ 1
include player.inc
include gui.inc

initPlayerShot PROC
    ;Determine which shot to work on
    xor bx, bx ;Holds current shot
    
    mov ax, playerShots.max
    shl ax, 1 ;Multiple by 2 cuz referencing a dw array
    checkPlayerShots:
        cmp bx, ax ;No shots available
        jae initPlayerShotEnd
        
        cmp playerShots.xArr[bx], 0
        je setPlayerShot ;Shot NOT initialized
        
        add bx, 2
        jmp checkPlayerShots
    
    setPlayerShot:
    mov playerShots.xArr[bx], playerWidth + playerX ;Front of player (index)
    
    push ax
    mov ax, (playerHeight - shotHeight) / 2
    add ax, playerY
    mov playerShots.yArr[bx], ax ;Save y value
    pop ax

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

    lea bx, playerShotTrailColors
    mov cx, 3 ;Num of trail colors
    playerShotsTrails:
        mov dl, [bx]
        cmp drawOrErase, 0
        jne drawPlayerShotTrail
        mov dl, bgColor
        drawPlayerShotTrail:
        push cx
        DRAW_VERTICAL shotHeight
        sub di, windowWidth - 1
        DRAW_VERTICAL shotHeight
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
    mov cx, shotHeight
    drawPlayerShotRows:
        push cx
        DRAW_HORIZONTAL shotWidth-6 ;6 is trails, mustn't space between operator
        pop cx
        add di, windowWidth - shotWidth + 7 ;Next row
        loop drawPlayerShotRows

    pop di dx cx bx
    RET
drawPlayerShot ENDP


movePlayerShots PROC
    ;Go through all the shots
    
    mov ax, playerShots.max
    shl ax, 1  ;Multiple by 2 cuz referencing a dw array
    mov bx, -2 ;So loop can be started at 0
    handlePlayerShots:
        add bx, 2
        cmp bx, ax
        jae movePlayerShotsEnd ;No shots are available
        cmp playerShots.xArr[bx], 0
        je handlePlayerShots   ;Shot NOT initialized
    
    moveCurrentPlayerShot:
        ;Remove prev shot
        mov drawOrErase, 0
        call drawPlayerShot
        
        ;Check collisions
        call playerShotCollisions
        jnc movePlayerShotsDraw ;No collision detected
        
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
playerShotCollisions PROC
    push bx cx dx di
    clc ;Assume not collided
    
    ;Calculates pos of front to DI
    mov cx, playerShots.xArr[bx]
    add cx, shotWidth            ;X pos
    ;Is in border?
    cmp cx, windowWidth - borderWidth
    je detectedPlayerShotCollision

    mov dx, playerShots.yArr[bx] ;Y pos
    call getPosition
    
    ;Check top to bottom
    mov cx, shotHeight
    checkPlayerShotCollision:
        cmp byte ptr es:[di], bgColor
        je checkPlayerShotCollisionNext
        cmp byte ptr es:[di], starsColor
        je checkPlayerShotCollisionNext
        cmp byte ptr es:[di], blueEnemyColor
        je playerShotCollisionEnemy
        cmp byte ptr es:[di], yellowEnemyColor
        je playerShotCollisionEnemy
        jmp detectedPlayerShotCollision ;Other collission detected

        checkPlayerShotCollisionNext:
        add di, windowWidth
        loop checkPlayerShotCollision
    jmp playerShotCollisionsEnd ;No collisions
    
    playerShotCollisionEnemy:
    mov bx, currentEnemy ;Save enemy for points
    call killEnemy

    ;Update score
    xor cx, cx
    mov cl, enemyScores[bx]
    add playerScore, cx
    call updateScore
    
    detectedPlayerShotCollision:
        stc ;Collision true
    
    playerShotCollisionsEnd:
    pop di dx cx bx
    RET
playerShotCollisions ENDP

endif
