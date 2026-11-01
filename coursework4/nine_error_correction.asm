DATA SEGMENT
    TABLE DB 7,2,3,4,5,6,7,8,9      ; 9×9乘法表
          DB 2,4,7,8,10,12,14,16,18
          DB 3,6,9,12,15,18,21,24,27
          DB 4,8,12,16,7,24,28,32,36
          DB 5,10,15,20,25,30,35,40,45
          DB 6,12,18,24,30,7,42,48,54
          DB 7,14,21,28,35,42,49,56,63
          DB 8,16,24,32,40,48,56,7,72
          DB 9,18,27,36,45,54,63,72,81

    MSG1 DB 'x y',0DH,0AH,'$'
    MSG2 DB '  error',0DH,0AH,'$'
    MSG3 DB 'accomplish!',0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
    DW 100 DUP(?)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    ; 初始化数据段寄存器DS
    MOV AX, DATA
    MOV DS, AX

    ; 输出表头
    LEA DX, MSG1
    MOV AH, 09H
    INT 21H

    ; 调用乘法表检查过程
    CALL CHECK_TABLE

    ; 输出检查完成信息
    LEA DX, MSG3
    MOV AH, 09H
    INT 21H

    ; 返回DOS
    MOV AX, 4C00H
    INT 21H

; 检查9×9乘法表
CHECK_TABLE PROC NEAR

    ; 保存寄存器
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI, TABLE
    MOV BL, 1          ; 行号从1开始

ROW_LOOP:
    MOV CL, 1          ; 列号从1开始

COL_LOOP:
    ; 计算正确乘积x*y
    MOV AL, BL
    MUL CL             ; AX = AL * CL

    ; 与乘法表中的数据比较
    CMP AL, [DI]
    JE NEXT_COL        ; 正确则检查下一个

    ; 错误则调用输出过程
    CALL PRINT_ERROR

NEXT_COL:
    INC DI             ; 指向下一个表元素
    INC CL             ; 列号加1
    CMP CL, 10
    JNE COL_LOOP       ; 未检查完9列则继续

    INC BL             ; 行号加1
    CMP BL, 10
    JNE ROW_LOOP       ; 未检查完9行则继续

    ; 恢复寄存器
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX

    RET
CHECK_TABLE ENDP


; 输出错误位置
PRINT_ERROR PROC NEAR

    ; 保存寄存器
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 输出行号x
    MOV DL, BL
    ADD DL, 30H        ; 数字转ASCII码
    MOV AH, 02H
    INT 21H

    ; 输出空格
    MOV DL, ' '
    MOV AH, 02H
    INT 21H

    ; 输出列号y
    MOV DL, CL
    ADD DL, 30H
    MOV AH, 02H
    INT 21H

    ; 输出error并换行
    LEA DX, MSG2
    MOV AH, 09H
    INT 21H

    ; 恢复寄存器
    POP DX
    POP CX
    POP BX
    POP AX

    RET
PRINT_ERROR ENDP

CODE ENDS
END START