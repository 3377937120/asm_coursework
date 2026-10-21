.MODEL SMALL
.STACK 100H

.DATA
prompt    DB 'Enter n (1-100): $'
resultMsg DB 13,10,'Sum from 1 to n = $'
errorMsg  DB 13,10,'Invalid input. Enter an integer from 1 to 100.',13,10,'$'
newLine   DB 13,10,'$'
; DOS function 0AH: max buffer size, actual length, then input characters.
inputBuf  DB 5, 0, 5 DUP(0)
nValue    DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    LEA DX, prompt
    MOV AH, 09H
    INT 21H

    LEA DX, inputBuf
    MOV AH, 0AH
    INT 21H

    MOV CL, [inputBuf+1]
    XOR CH, CH
    CMP CX, 1
    JB BAD_INPUT
    CMP CX, 3
    JA BAD_INPUT

    LEA SI, inputBuf+2
    XOR AX, AX
PARSE_DIGIT:
    MOV BL, [SI]
    CMP BL, '0'
    JB BAD_INPUT
    CMP BL, '9'
    JA BAD_INPUT
    SUB BL, '0'

    MOV DX, 10
    MUL DX
    XOR BH, BH
    ADD AX, BX

    INC SI
    LOOP PARSE_DIGIT

    CMP AX, 1
    JB BAD_INPUT
    CMP AX, 100
    JA BAD_INPUT
    MOV nValue, AX

    LEA DX, resultMsg
    MOV AH, 09H
    INT 21H

    MOV CX, nValue
    XOR AX, AX
    MOV BX, 1
SUM_LOOP:
    ADD AX, BX
    INC BX
    LOOP SUM_LOOP

    CALL PrintAX

    LEA DX, newLine
    MOV AH, 09H
    INT 21H

    MOV AX, 4C00H
    INT 21H

BAD_INPUT:
    LEA DX, errorMsg
    MOV AH, 09H
    INT 21H
    MOV AX, 4C01H
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
