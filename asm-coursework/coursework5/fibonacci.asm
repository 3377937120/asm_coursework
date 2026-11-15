DATA SEGMENT
    PROMPT      DB 'Enter n (1..100): $'
    BAD_MSG     DB 0DH,0AH,'Invalid input. Try 1..100.',0DH,0AH,'$'
    RESULT_L    DB 0DH,0AH,'F($'
    RESULT_R    DB ') = $'
    NEWLINE     DB 0DH,0AH,'$'

    ; DOS 0Ah 号功能：缓冲区最大长度、实际输入长度、输入字符及回车符
    INPUT_BUF   DB 8,0,8 DUP(0)
    INPUT_N     DW 0

    ; 共 101 项，每项由 5 个字（80 位）组成，采用低位字在前的存储方式
    ; 初始化 F(0)=0、F(1)=1，其余各项初始值为 0
    FIB_TABLE   DW 5 DUP(0), 1, 4 DUP(0), 495 DUP(0)
    KNOWN       DB 1,1,99 DUP(0)
    TEMP        DW 5 DUP(0)
DATA ENDS

STACK SEGMENT STACK
    DW 2048 DUP(?)             ; 栈空间共 4096 字节，即 1000H 字节
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    ; 显式初始化 SS:SP；修改 SS 寄存器期间关闭中断
    CLI
    MOV AX, STACK
    MOV SS, AX
    MOV SP, 1000H
    STI

    MOV AX, DATA
    MOV DS, AX

    CALL READ_N

    MOV AX, INPUT_N
    CALL FIB                   ; 计算结果保存在 FIB_TABLE[n] 中

    LEA DX, RESULT_L
    MOV AH, 09H
    INT 21H

    MOV AX, INPUT_N
    CALL PRINT_U16

    LEA DX, RESULT_R
    MOV AH, 09H
    INT 21H

    CALL PRINT_BIG

    LEA DX, NEWLINE
    MOV AH, 09H
    INT 21H

    MOV AX, 4C00H
    INT 21H

; READ_N：读取一个十进制整数，要求范围为 1..100
; 输出：将输入值保存到 INPUT_N；保护 AX、BX、CX、DX、SI 寄存器
READ_N PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

READ_AGAIN:
    LEA DX, PROMPT
    MOV AH, 09H
    INT 21H

    MOV BYTE PTR INPUT_BUF+1, 0
    LEA DX, INPUT_BUF
    MOV AH, 0AH
    INT 21H

    MOV CL, BYTE PTR INPUT_BUF+1
    XOR CH, CH
    JCXZ BAD_INPUT

    LEA SI, INPUT_BUF+2
    XOR BX, BX

PARSE_DIGIT:
    MOV AL, [SI]
    CMP AL, '0'
    JB BAD_INPUT
    CMP AL, '9'
    JA BAD_INPUT

    SUB AL, '0'
    XOR AH, AH
    PUSH AX                    ; 暂存当前读入的数字
    MOV AX, BX
    MOV BX, 10
    MUL BX                     ; AX = 之前已读取的数值 × 10
    POP DX                     ; DX = 当前读入的数字
    ADD AX, DX
    MOV BX, AX
    CMP BX, 100
    JA BAD_INPUT

    INC SI
    LOOP PARSE_DIGIT

    CMP BX, 1
    JB BAD_INPUT
    MOV INPUT_N, BX
    JMP READ_DONE

BAD_INPUT:
    LEA DX, BAD_MSG
    MOV AH, 09H
    INT 21H
    JMP READ_AGAIN

READ_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
READ_N ENDP

; FIB：采用记忆化方式递归计算斐波那契数列
; 输入：AX = n，取值范围为 0..100
; 输出：FIB_TABLE[n]，由低位到高位排列的 5 个字（共 80 位）
; 栈帧结构：返回 IP（2 字节）+ 保存的 BP（2 字节）+ 局部变量 n（2 字节）
; + 保存的 6 个寄存器（12 字节），每层栈帧共 18 字节
FIB PROC NEAR
    PUSH BP
    MOV BP, SP
    SUB SP, 2
    MOV [BP-2], AX             ; 将参数 n 保存到局部变量中

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV BX, [BP-2]
    CMP BYTE PTR KNOWN[BX], 1
    JE FIB_DONE

    MOV AX, [BP-2]
    DEC AX
    CALL FIB                   ; 递归计算 F(n-1)

    MOV AX, [BP-2]
    SUB AX, 2
    CALL FIB                   ; 递归计算 F(n-2)

    MOV AX, [BP-2]
    MOV BX, 10
    MUL BX                     ; AX = n × 10，得到第 n 项在表中的字节偏移量
    MOV DI, AX                 ; 目的地址：F(n) 在表中的偏移量
    MOV SI, DI
    SUB SI, 10                 ; 源地址：F(n-1) 在表中的偏移量
    MOV BX, DI
    SUB BX, 20                 ; 源地址：F(n-2) 在表中的偏移量

    MOV CX, 5
    CLC                        ; 初始化进位标志，为 80 位加法做准备
ADD_WORDS:
    MOV AX, WORD PTR FIB_TABLE[SI]
    ADC AX, WORD PTR FIB_TABLE[BX]
    MOV WORD PTR FIB_TABLE[DI], AX

    ; LEA 和 LOOP 指令不会修改进位标志 CF，因此进位可以传递到下一个字
    LEA SI, [SI+2]
    LEA BX, [BX+2]
    LEA DI, [DI+2]
    LOOP ADD_WORDS

    MOV BX, [BP-2]
    MOV BYTE PTR KNOWN[BX], 1

FIB_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    MOV SP, BP
    POP BP
    RET
FIB ENDP

; 将 AX 中的无符号整数转换为十进制并输出（用于输出 n）
PRINT_U16 PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX
U16_DIV:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    OR AX, AX
    JNZ U16_DIV

U16_OUT:
    POP DX
    ADD DL, '0'
    PUSH CX
    MOV AH, 02H
    INT 21H
    POP CX
    LOOP U16_OUT

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_U16 ENDP

; PRINT_BIG：将 F(INPUT_N) 中的 80 位整数转换为十进制并输出
; 对数值的临时副本逐字进行除以 10 的运算，每次处理一个 16 位字，
; 处理顺序为从最高位字到最低位字
PRINT_BIG PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV AX, INPUT_N
    MOV BX, 10
    MUL BX
    LEA SI, FIB_TABLE
    ADD SI, AX
    LEA DI, TEMP
    MOV CX, 5

COPY_VALUE:
    MOV AX, [SI]
    MOV [DI], AX
    ADD SI, 2
    ADD DI, 2
    LOOP COPY_VALUE

    MOV BX, 10
    XOR CX, CX                 ; CX 用于记录十进制数字的位数

BIG_DIV:
    XOR DX, DX                 ; 处理最高位字时，初始余数为 0
    MOV SI, 8                  ; 设置最高位字的偏移量

DIV_WORD:
    MOV AX, WORD PTR TEMP[SI]
    DIV BX                     ; DX:AX 除以 10，商存入 AX，余数存入 DX
    MOV WORD PTR TEMP[SI], AX
    SUB SI, 2
    JNS DIV_WORD

    PUSH DX                    ; 将当前得到的一位十进制数字压入栈中（范围为 0..9）
    INC CX

    ; 重复除法，直到 5 个字中的商全部变为 0
    MOV AX, WORD PTR TEMP
    OR AX, WORD PTR TEMP+2
    OR AX, WORD PTR TEMP+4
    OR AX, WORD PTR TEMP+6
    OR AX, WORD PTR TEMP+8
    JNZ BIG_DIV

BIG_OUT:
    POP DX
    ADD DL, '0'
    PUSH CX
    MOV AH, 02H
    INT 21H
    POP CX
    LOOP BIG_OUT

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_BIG ENDP

CODE ENDS
END START
