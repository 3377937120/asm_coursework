.MODEL SMALL
.STACK 100H

.DATA
CRLF DB 0DH, 0AH, '$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    MOV BL, 'a'            ; 当前字母
    MOV CX, 26             ; 总共输出 26 个字母
    MOV SI, 0              ; 当前行已经输出的字母数

PRINT_CHAR:
    MOV DL, BL
    MOV AH, 02H
    INT 21H                ; 输出当前字母

    INC BL                 ; 下一个字母
    INC SI                 ; 当前行的字母数加 1

    CMP SI, 13             ; 当前行是否输出了 13 个字母
    JE NEW_LINE            ; 如果是，则换行

    ; 未达到 13 个字母，输出一个空格
    MOV DL, ' '
    MOV AH, 02H
    INT 21H

    JMP CHECK_REMAIN       ; 跳过换行处理

NEW_LINE:
    MOV DX, OFFSET CRLF
    MOV AH, 09H
    INT 21H                ; 输出回车换行

    MOV SI, 0              ; 新的一行，计数清零

CHECK_REMAIN:
    DEC CX                 ; 剩余字母数减 1
    JNZ PRINT_CHAR         ; CX 不为 0，继续输出

    MOV AX, 4C00H
    INT 21H                ; 返回 DOS

MAIN ENDP
END MAIN