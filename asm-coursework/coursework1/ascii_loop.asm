.MODEL SMALL
.STACK 100H

.DATA
CRLF DB 0DH, 0AH, '$'     ; 回车换行字符串

.CODE
MAIN PROC
    ; 初始化数据段
    MOV AX, @DATA
    MOV DS, AX

    MOV BL, 'a'            ; BL 保存当前要输出的字母
    MOV CX, 2              ; 外层循环：共输出两行

NEXT_LINE:
    PUSH CX                ; 保存外层循环的 CX

    MOV CX, 13             ; 内层循环：每行输出 13 个字母

PRINT_CHAR:
    MOV DL, BL             ; 将当前字母放入 DL
    MOV AH, 02H
    INT 21H                ; 输出一个字符

    INC BL                 ; 转到下一个字母

    CMP CX, 1              ; 是否为本行最后一个字母
    JE NO_SPACE            ; 是则不输出空格

    MOV DL, ' '
    MOV AH, 02H
    INT 21H                ; 输出字母之间的空格

NO_SPACE:
    LOOP PRINT_CHAR        ; CX 减 1，不为 0 则继续

    ; 输出回车和换行
    MOV DX, OFFSET CRLF
    MOV AH, 09H
    INT 21H

    POP CX                 ; 恢复外层循环的 CX
    LOOP NEXT_LINE         ; 输出下一行

    ; 返回 DOS
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

END MAIN