.MODEL SMALL
.STACK 100H

.DATA
msgReg   DB 'Register result (AX): $'
msgData  DB 13,10,'Data segment result: $'
msgStack DB 13,10,'Stack result: $'
newLine  DB 13,10,'$'
sumData  DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; 1) Keep the result in AX.
    LEA DX, msgReg
    MOV AH, 09H
    INT 21H

    MOV CX, 100
    XOR AX, AX
    MOV BX, 1
REG_LOOP:
    ADD AX, BX
    INC BX
    LOOP REG_LOOP
    CALL PrintAX

    LEA DX, newLine
    MOV AH, 09H
    INT 21H

    ; 2) Keep the running result in a data-segment variable.
    LEA DX, msgData
    MOV AH, 09H
    INT 21H

    MOV sumData, 0
    MOV CX, 100
    MOV BX, 1
DATA_LOOP:
    MOV AX, sumData
    ADD AX, BX
    MOV sumData, AX
    INC BX
    LOOP DATA_LOOP

    MOV AX, sumData
    CALL PrintAX

    LEA DX, newLine
    MOV AH, 09H
    INT 21H

    ; 3) Save the result on the stack and read a copy through BP.
    LEA DX, msgStack
    MOV AH, 09H
    INT 21H

    MOV CX, 100
    XOR AX, AX
    MOV BX, 1
STACK_LOOP:
    ADD AX, BX
    INC BX
    LOOP STACK_LOOP

    PUSH BP
    PUSH AX
    MOV BP, SP
    MOV AX, SS:[BP]
    CALL PrintAX
    POP AX
    POP BP

    LEA DX, newLine
    MOV AH, 09H
    INT 21H

    MOV AX, 4C00H
    INT 21H
MAIN ENDP

; Print the unsigned decimal value in AX. Preserve registers.
PrintAX PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    XOR CX, CX
    MOV BX, 10
    CMP AX, 0
    JNE PA_DIVIDE

    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP PA_DONE

PA_DIVIDE:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE PA_DIVIDE

PA_OUTPUT:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP PA_OUTPUT

PA_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintAX ENDP

END MAIN
