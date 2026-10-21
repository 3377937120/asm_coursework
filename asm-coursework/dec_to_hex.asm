.MODEL SMALL
.STACK 100H

.DATA
prompt    DB 'Please input a decimal number (0-65535): $'
resultMsg DB 13,10,'The Hex number: $'
errorMsg  DB 13,10,'Invalid input. Enter a decimal integer from 0 to 65535.',13,10,'$'
newLine   DB 13,10,'$'
decValue  DW 0
; Buffer allows up to 6 typed characters; the program accepts at most 5 digits.
inputBuf  DB 7, 0, 7 DUP(0)

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
    CMP CX, 5
    JA BAD_INPUT

    LEA SI, inputBuf+2
    XOR AX, AX
DEC_LOOP:
    MOV BL, [SI]
    CMP BL, '0'
    JB BAD_INPUT
    CMP BL, '9'
    JA BAD_INPUT
    SUB BL, '0'

    MOV DX, 10
    MUL DX
    OR DX, DX
    JNZ BAD_INPUT
    XOR BH, BH
    ADD AX, BX
    JC BAD_INPUT

    INC SI
    LOOP DEC_LOOP

     ; 保存转换结果，避免 AH 被覆盖
    MOV decValue, AX
    ; 输出提示字符串
    LEA DX, resultMsg
    MOV AH, 09H
    INT 21H
    ; 恢复原始数值，再转换为十六进制输出
    MOV AX, decValue
    CALL PrintHexAX

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

; Print the unsigned 16-bit value in AX in uppercase hexadecimal.
PrintHexAX PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    XOR CX, CX
    MOV BX, 16
    CMP AX, 0
    JNE PH_DIVIDE

    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP PH_DONE

PH_DIVIDE:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE PH_DIVIDE

PH_OUTPUT:
    POP DX
    CMP DL, 9
    JBE PH_DIGIT
    ADD DL, 55
    JMP PH_EMIT

PH_DIGIT:
    ADD DL, '0'

PH_EMIT:
    MOV AH, 02H
    INT 21H
    LOOP PH_OUTPUT

PH_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintHexAX ENDP

END MAIN
