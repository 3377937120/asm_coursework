.MODEL SMALL
.STACK 100H

.DATA
prompt   DB 'Please input a Hex number (1-2 digits): $'
resultMsg DB 13,10,'The Dec number: $'
errorMsg DB 13,10,'Invalid input. Enter 1 or 2 hex digits (00-FF).',13,10,'$'
newLine  DB 13,10,'$'
; Buffer allows up to 3 typed characters so extra digits can be rejected.
inputBuf DB 4, 0, 4 DUP(0)

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
    CMP CX, 2
    JA BAD_INPUT

    LEA SI, inputBuf+2
    XOR BX, BX
HEX_LOOP:
    MOV AL, [SI]

    CMP AL, '0'
    JB BAD_INPUT
    CMP AL, '9'
    JBE HEX_DIGIT
    CMP AL, 'A'
    JB HEX_LOWER
    CMP AL, 'F'
    JBE HEX_UPPER
    CMP AL, 'a'
    JB BAD_INPUT
    CMP AL, 'f'
    JA BAD_INPUT
    SUB AL, 'a'-10
    JMP NIBBLE_READY

HEX_LOWER:
    CMP AL, 'a'
    JB BAD_INPUT
    CMP AL, 'f'
    JA BAD_INPUT
    SUB AL, 'a'-10
    JMP NIBBLE_READY

HEX_UPPER:
    SUB AL, 'A'-10
    JMP NIBBLE_READY

HEX_DIGIT:
    SUB AL, '0'

NIBBLE_READY:
    XOR AH, AH
    SHL BX, 1
    SHL BX, 1
    SHL BX, 1
    SHL BX, 1
    ADD BX, AX
    INC SI
    LOOP HEX_LOOP

    LEA DX, resultMsg
    MOV AH, 09H
    INT 21H
    MOV AX, BX
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
