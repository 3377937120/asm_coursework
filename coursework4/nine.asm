.MODEL SMALL
.STACK 100H

.DATA
TITLE_MSG DB 'The 9x9 table:',0DH,0AH,'$'
SPACE4    DB '    $'
NEWLINE   DB 0DH,0AH,'$'

.CODE

MAIN PROC
    ; 初始化数据段
    MOV AX, @DATA
    MOV DS, AX

    ; 输出标题
    MOV DX, OFFSET TITLE_MSG
    MOV AH, 09H
    INT 21H

    ; 外层循环：控制行数，9 到 1
    MOV SI, 9

ROW_LOOP:
    ; 每行从 1 开始
    MOV DI, 1

COL_LOOP:
    ; 输出第一个乘数 SI
    MOV AX, SI
    CALL PRINT_NUM

    ; 输出乘号
    MOV DL, '*'
    MOV AH, 02H
    INT 21H

    ; 输出第二个乘数 DI
    MOV AX, DI
    CALL PRINT_NUM

    ; 输出等号 =
    MOV DL, '='
    MOV AH, 02H
    INT 21H

    ; 计算 SI * DI
    MOV AX, SI
    MUL DI                 ; DX:AX = AX * DI

    ; 输出乘积
    CALL PRINT_NUM

    ; 判断当前行是否输出完毕
    CMP DI, SI
    JE ROW_END

    ; 未输出完，输出四个空格
    MOV DX, OFFSET SPACE4
    MOV AH, 09H
    INT 21H

    ; 列计数加 1
    INC DI
    JMP COL_LOOP

ROW_END:
    ; 当前行结束，输出回车换行
    MOV DX, OFFSET NEWLINE
    MOV AH, 09H
    INT 21H

    ; 行计数减 1
    DEC SI
    JNZ ROW_LOOP

    ; 返回 DOS
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

PRINT_NUM PROC NEAR
    ; 保存主程序可能使用的寄存器
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX

    ; 特殊处理数字 0
    CMP AX, 0
    JNE PN_DIVIDE

    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP PN_DONE

PN_DIVIDE:
    ; 不断除以 10，取得各位数字
    XOR DX, DX
    DIV BX                 ; AX = 商，DX = 余数

    PUSH DX                ; 暂存当前数字
    INC CX                 ; 记录数字位数

    CMP AX, 0
    JNE PN_DIVIDE

PN_OUTPUT:
    ; 逆序弹出，按高位到低位输出
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H

    LOOP PN_OUTPUT

PN_DONE:
    ; 恢复寄存器
    POP DX
    POP CX
    POP BX
    POP AX

    RET                    ; 返回 CALL 的下一条指令

PRINT_NUM ENDP

END MAIN