ifndef PLAYER
PLAYER equ 1
include draw.inc
include utils.inc

playerX equ 20
playerY dw 0
playerWidth equ 31
playerHeight equ 21
playerColors db 18h, 1Bh  ;Outer colors
playerVelocity equ 5


initPlayer PROC
    ;x is constant
    mov playerY, (windowHeight - playerHeight) / 2
    RET
initPlayer ENDP


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
    DRAW_HORIZONTAL 11
    
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, 9*windowWidth - 10
    DRAW_HORIZONTAL 11
    
    add di, 9*windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    
    ;ENGINE DARK GREYS
    mov di, bx ;Reset to anchor
    add di, 4*windowWidth + 5
    DRAW_HORIZONTAL 2
    add di, windowWidth
    mov es:[di], dl
    add di, windowWidth - 1
    DRAW_HORIZONTAL 4
    
    add di, 8*windowWidth - 3
    DRAW_HORIZONTAL 4
    add di, windowWidth - 2
    DRAW_VERTICAL 2
    dec di
    mov es:[di], dl
    
    ;COCKPIT DARK GREY
    mov di, bx ;Reset to anchor
    add di, 8*windowWidth + 16
    mov cx, 5  ;Num of rows
    drawCockpit:
        push cx
        DRAW_HORIZONTAL 10 ;Row width
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
    mov di, bx      ;Reset to anchor
    add di, 9*windowWidth + 20
    DRAW_VERTICAL 3 ;Height of line
        
    mov dl, 2Ch     ;Yellow
    cmp drawOrErase, 1
    je drawPlayerYellow
    mov dl, bgColor ;Erase
    
    drawPlayerYellow:
    ;ENGINE YELLOW
    mov di, bx ;Reset to anchor
    add di, 5*windowWidth
    DRAW_HORIZONTAL 3
    add di, 10*windowWidth - 2
    DRAW_HORIZONTAL 3
    
    mov dl, 2Ah ;Orange
    cmp drawOrErase, 1
    je drawPlayerOrange
    mov dl, bgColor ;Erase
    
    drawPlayerOrange:
    ;FLAMES ORANGE
    mov di, bx
    add di, 4*windowWidth
    DRAW_HORIZONTAL 2
    add di, windowWidth - 2
    mov es:[di], dl
    add di, windowWidth + 1
    DRAW_HORIZONTAL 2
    
    add di, 8*windowWidth - 1
    DRAW_HORIZONTAL 2
    add di, windowWidth - 2
    mov es:[di], dl
    add di, windowWidth + 1
    DRAW_HORIZONTAL 2

    mov dl, 29h ;Red
    cmp drawOrErase, 1
    je drawPlayerRed
    mov dl, bgColor ;Erase
    
    drawPlayerRed:
    ;ENGINE RED
    mov di, bx ;Reset to anchor
    add di, 3*windowWidth - 1
    DRAW_HORIZONTAL 3
    add di, windowWidth + 1
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    dec di
    DRAW_VERTICAL 3
    inc di
    mov es:[di], dl
    add di, windowWidth
    DRAW_HORIZONTAL 3
    sub di, 2*windowWidth + 4
    mov es:[di], dl
    add di, 7
    mov es:[di], dl
    add di, windowWidth - 2
    mov es:[di], dl
    
    add di, 7*windowWidth - 3
    DRAW_HORIZONTAL 3
    add di, windowWidth + 1
    mov es:[di], dl
    sub di, 3
    mov es:[di], dl
    dec di
    DRAW_VERTICAL 3
    inc di
    mov es:[di], dl
    add di, windowWidth
    DRAW_HORIZONTAL 3
    sub di, 2*windowWidth + 4
    mov es:[di], dl
    add di, 7
    mov es:[di], dl
    add di, windowWidth - 2
    mov es:[di], dl
    
    mov dl, 36h     ;Blue
    cmp drawOrErase, 1
    je drawPlayerBlue
    mov dl, bgColor ;Erase
    
    drawPlayerBlue:
    ;COCKPIT BLUE
    mov di, bx ;Reset to anchor
    add di, 9*windowWidth + 16
    DRAW_VERTICAL 3
    sub di, 2*windowWidth - 1
    DRAW_VERTICAL 3
    sub di, 2*windowWidth - 2
    DRAW_VERTICAL 3
    sub di, 2*windowWidth - 2
    DRAW_VERTICAL 3
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
    DRAW_HORIZONTAL 10
    add di, windowWidth - 9
    DRAW_HORIZONTAL 10
    add di, windowWidth - 8
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, windowWidth - 8
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    
    add di, windowWidth - 12
    DRAW_HORIZONTAL 9
    add di, windowWidth - 8
    DRAW_HORIZONTAL 9
    add di, windowWidth - 1
    DRAW_HORIZONTAL 2
    add di, windowWidth - 8
    DRAW_HORIZONTAL 9
    add di, windowWidth - 8
    DRAW_HORIZONTAL 9
    
    add di, windowWidth - 6
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, windowWidth - 12
    DRAW_HORIZONTAL 11
    add di, windowWidth - 10
    DRAW_HORIZONTAL 11
    add di, windowWidth - 11
    DRAW_HORIZONTAL 10
    add di, windowWidth - 9
    DRAW_HORIZONTAL 10
    
    mov di, bx ;Reset to anchor
    add di, 10*windowWidth + 26
    DRAW_HORIZONTAL 5
    
    pop dx cx bx
    RET
drawPlayer ENDP


movePlayer PROC
    ;Key pressed ASCII value is in AL | AH for BIOS code!

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
        jge movePlayerDraw       ;MUST be jge and NOT jae, to handle signed
        ;Invalid y
        mov playerY, borderWidth ;Move to max valid position
        jmp movePlayerDraw
    
    movePlayerDown:
        ;Skip if in border
        cmp playerY, windowHeight - playerHeight - borderWidth*2 + 1
        je movePlayerEnd
        
        ;Erase prev player
        mov drawOrErase, 0 ;Erase
        call drawPlayer
        
        add playerY, playerVelocity
        ;Has reached bottom?
        cmp playerY, windowHeight - playerHeight - borderWidth*2 + 1
        jbe movePlayerDraw
        ;Invalid y - move to min valid y
        mov playerY, windowHeight - playerHeight - borderWidth*2 + 1
    
    movePlayerDraw:
        mov drawOrErase, 1 ;Draw
        call drawPlayer
    
    movePlayerEnd:
    RET
movePlayer ENDP


;#################### COLLISIONS ####################

checkPlayerCollisions PROC
    push cx dx di
    ;NOTE: top, middle and bottom sensors sub to x pos check
    mov cx, playerX
    mov dx, playerY
    call getPosition ;Calculates anchor tile to DI
    
    ;Top part
    add di, 13
    call handlePlayerCollisions
    jc checkPlayerCollisionsEnd ;Collision detected
    
    inc di
    call handlePlayerCollisions
    jc checkPlayerCollisionsEnd ;Collision detected

    ;Utilize the stairs-shaped wings of player
    mov cx, 3
    checkPlayerCollisionsLoop1:
        add di, windowWidth*2 + 2
        call handlePlayerCollisions
        jc checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop1
    
    mov cx, 2
    checkPlayerCollisionsLoop2:
        add di, windowWidth*2 + 6
        call handlePlayerCollisions
        jc checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop2
    
    dec di
    call handlePlayerCollisions
    jc checkPlayerCollisionsEnd ;Collision detected
    
    ;Bottom part
    inc di
    ;Utilize the stairs-shaped wings of player
    mov cx, 2
    checkPlayerCollisionsLoop3:
        add di, windowWidth*2 - 6
        call handlePlayerCollisions
        jc checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop3
    
    mov cx, 3
    checkPlayerCollisionsLoop4:
        add di, windowWidth*2 - 2
        call handlePlayerCollisions
        jc checkPlayerCollisionsEnd ;Collision detected
        loop checkPlayerCollisionsLoop4
    
    dec di
    call handlePlayerCollisions
    
    checkPlayerCollisionsEnd:
    pop di dx cx
    RET
checkPlayerCollisions ENDP


;Return boolean isCollided in CF
;Note: enemies shots collisions are handled in their own functions
handlePlayerCollisions PROC
    ;DI is parameter = position to handle
    clc ;Assume not collided
    
    ;Check for enemy collision
    cmp byte ptr es:[di], blueEnemyColor
    je playerCollisionBlueEnemy
    cmp byte ptr es:[di], yellowEnemyColor
    je playerCollisionYellowEnemy
    
    jmp handlePlayerCollisionsEnd

    ;Enemy collision:
    playerCollisionBlueEnemy:
        xor bx, bx ;Enemy to kill
        jmp playerCollisionEnemy
    playerCollisionYellowEnemy:
        mov bx, 1
    
    playerCollisionEnemy:
        call killEnemy
        call decPlayerHP
        ;Restore player sprite
        mov drawOrErase, 1
        call drawPlayer
        stc ;CF 1=collision
    
    handlePlayerCollisionsEnd:
    RET
handlePlayerCollisions ENDP

endif
