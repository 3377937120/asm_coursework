; 输入 1900~2099 年、1~12 月，输出从星期日开始排列的月历。
DATA SEGMENT PARA PUBLIC 'DATA'
    PromptYear      DB 'Please input year (1900-2099): $'
    PromptMonth     DB 'Please input month (1-12): $'
    ErrorMessage    DB 'Invalid input. Please try again.', 0DH, 0AH, '$'
    CRLF            DB 0DH, 0AH, '$'
    HeaderGap       DB '  $'
    WeekHeader      DB 'Su Mo Tu We Th Fr Sa', 0DH, 0AH, '$'
    BlankCell       DB '   $'                 ; 每个日期位置严格占 3 个字符

    M_Jan DB 'January$'
    M_Feb DB 'February$'
    M_Mar DB 'March$'
    M_Apr DB 'April$'
    M_May DB 'May$'
    M_Jun DB 'June$'
    M_Jul DB 'July$'
    M_Aug DB 'August$'
    M_Sep DB 'September$'
    M_Oct DB 'October$'
    M_Nov DB 'November$'
    M_Dec DB 'December$'

    MonthNameTable DW OFFSET M_Jan, OFFSET M_Feb, OFFSET M_Mar
                   DW OFFSET M_Apr, OFFSET M_May, OFFSET M_Jun
                   DW OFFSET M_Jul, OFFSET M_Aug, OFFSET M_Sep
                   DW OFFSET M_Oct, OFFSET M_Nov, OFFSET M_Dec
    MonthDays      DB 31,28,31,30,31,30,31,31,30,31,30,31

    ; DOS INT 21H/AH=0AH 缓冲区：最大容量、实际长度、输入字符（含回车）。
    ; 最多接收 5 个可见字符，足以输入 4 位年份，也可检测更长的非法数字。
    InputBuffer     DB 6, 0, 6 DUP (0)

    CurrentYear     DW ?
    CurrentMonth    DW ?
    DaysCurrent     DB ?
    FirstWeekday    DB ?                       ; 0=Su, 1=Mo, ..., 6=Sa
    MinAllowed      DW ?
    MaxAllowed      DW ?
DATA ENDS

STACK SEGMENT PARA STACK 'STACK'
    DW 256 DUP (?)                             ; 512 字节栈，供嵌套调用使用
STACK ENDS

;  第一个代码段：主流程/显示
MAIN_CODE SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:MAIN_CODE, DS:DATA, SS:STACK

START:
    MOV AX, DATA
    MOV DS, AX                              ; DOS .EXE 入口不能假设 DS 已指向数据段

    ; 过程参数采用寄存器：DX=提示串偏移，CX=最小值，BX=最大值。
    MOV DX, OFFSET PromptYear
    MOV CX, 1900
    MOV BX, 2099
    CALL FAR PTR ReadNumber                 ; 跨代码段：CALL 保存 CS:IP
    MOV CurrentYear, AX

    MOV DX, OFFSET PromptMonth
    MOV CX, 1
    MOV BX, 12
    CALL FAR PTR ReadNumber
    MOV CurrentMonth, AX

    MOV AX, CurrentYear
    MOV BX, CurrentMonth
    CALL FAR PTR DaysInMonth                ; 返回 AL=本月天数（28~31）
    MOV DaysCurrent, AL

    MOV AX, CurrentYear
    MOV BX, CurrentMonth
    CALL FAR PTR WeekdayOfFirst             ; 返回 AL=1 号是星期几（0~6）
    MOV FirstWeekday, AL

    MOV DX, OFFSET CRLF
    CALL PrintString
    CALL PrintCalendar

    MOV AX, 4C00H                           ; DOS 正常退出，不能直接 RET 返回
    INT 21H

; 输出 DS:DX 指向的 '$' 结尾字符串；保留各通用寄存器。
PrintString PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV AH, 09H
    INT 21H
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintString ENDP

; 输出 DL 的一个字符；保留寄存器，避免破坏循环计数等状态。
PrintChar PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV AH, 02H
    INT 21H
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintChar ENDP

PrintCRLF PROC NEAR
    PUSH DX
    MOV DX, OFFSET CRLF
    CALL PrintString
    POP DX
    RET
PrintCRLF ENDP

; 输入 AX=0~65535，输出十进制字符。
; 用除以 10 后将余数压栈，再弹栈打印，解决数字位数逆序的问题。
PrintDecimalAX PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    XOR CX, CX
    MOV BX, 10
PD_Divide:
    XOR DX, DX                             ; 16 位 DIV BX 的被除数是 DX:AX
    DIV BX
    PUSH DX                                ; 保存余数（个位先得到，所以先压栈）
    INC CX
    OR AX, AX
    JNZ PD_Divide
PD_Output:
    POP DX
    ADD DL, '0'
    CALL PrintChar
    LOOP PD_Output
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintDecimalAX ENDP

; 输入 AL=1~31，固定输出 3 列：" 1 " / "10 "，使所有日期对齐。
PrintDay PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    XOR AH, AH
    MOV BL, 10
    DIV BL                                 ; AL=十位, AH=个位
    MOV BH, AH                             ; 暂存个位，防止后续输出影响它
    OR AL, AL
    JNZ DayTwoDigits
    MOV DL, ' '
    CALL PrintChar
    JMP DayOnes
DayTwoDigits:
    MOV DL, AL
    ADD DL, '0'
    CALL PrintChar
DayOnes:
    MOV DL, BH
    ADD DL, '0'
    CALL PrintChar
    MOV DL, ' '
    CALL PrintChar
    POP DX
    POP BX
    POP AX
    RET
PrintDay ENDP

; 日历显示。BX=当前列号(0~6)，SI=日期，DI=本月总天数。
PrintCalendar PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV AX, CurrentYear
    CALL PrintDecimalAX
    MOV DX, OFFSET HeaderGap
    CALL PrintString

    MOV BX, CurrentMonth
    DEC BX                                 ; 月份 1~12 -> 表索引 0~11
    SHL BX, 1                              ; DW 指针表：每项占 2 字节
    MOV DX, MonthNameTable[BX]
    CALL PrintString
    CALL PrintCRLF

    MOV DX, OFFSET WeekHeader
    CALL PrintString

    XOR CX, CX
    MOV CL, FirstWeekday
    MOV BX, CX                              ; 第一行开始前已占用的星期列数
PadBeforeFirst:
    JCXZ StartDates
    MOV DX, OFFSET BlankCell
    CALL PrintString
    DEC CX
    JMP PadBeforeFirst

StartDates:
    MOV SI, 1
    XOR AX, AX
    MOV AL, DaysCurrent
    MOV DI, AX
DateLoop:
    CMP SI, DI
    JA CalendarDone
    MOV AX, SI
    CALL PrintDay
    INC BX                                 ; 每打印一个日期，星期列右移一格
    CMP BX, 7
    JNE NoLineBreak
    CALL PrintCRLF                          ; 星期六之后换行
    XOR BX, BX
NoLineBreak:
    INC SI
    JMP DateLoop

CalendarDone:
    CMP BX, 0
    JE CalendarReturn                       ; 正好打印到星期六时已换过行
    CALL PrintCRLF
CalendarReturn:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintCalendar ENDP

MAIN_CODE ENDS

; 第二个代码段：输入/日期计算
UTIL_CODE SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:UTIL_CODE, DS:DATA, SS:STACK

; 读取范围内的十进制数：DX=提示串地址, CX=最小值, BX=最大值；返回 AX。
; FAR 过程必须以 RETF 返回（同时恢复调用者的 IP 和 CS）。
ReadNumber PROC FAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV MinAllowed, CX
    MOV MaxAllowed, BX
    MOV SI, DX                              ; 保留提示串地址，非法输入时重复使用

InputRetry:
    MOV DX, SI
    MOV AH, 09H
    INT 21H

    MOV BYTE PTR [InputBuffer+1], 0
    MOV DX, OFFSET InputBuffer
    MOV AH, 0AH
    INT 21H                                 ; DOS 读入到缓冲区（不含数字转换）

    MOV DX, OFFSET CRLF
    MOV AH, 09H
    INT 21H

    MOV CL, InputBuffer+1                   ; 实际字符个数，不包括回车
    XOR CH, CH
    JCXZ InputInvalid                      ; 空输入不合法
    MOV DI, OFFSET InputBuffer+2
    XOR AX, AX                             ; 累计数值，初始 0

ParseDigit:
    MOV DL, [DI]
    CMP DL, '0'
    JB InputInvalid
    CMP DL, '9'
    JA InputInvalid

    MOV BX, 10
    MUL BX                                 ; DX:AX = AX * 10
    OR DX, DX
    JNZ InputInvalid                       ; 高 16 位非零，说明溢出
    MOV DL, [DI]
    SUB DL, '0'
    XOR DH, DH
    ADD AX, DX
    JC InputInvalid                        ; 加新数字产生进位，同样视为溢出

    INC DI
    LOOP ParseDigit

    CMP AX, MinAllowed
    JB InputInvalid
    CMP AX, MaxAllowed
    JA InputInvalid
    JMP InputAccepted

InputInvalid:
    MOV DX, OFFSET ErrorMessage
    MOV AH, 09H
    INT 21H
    JMP InputRetry                          ; 无条件 JMP 可编码为近跳转

InputAccepted:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RETF                                   ; 与 CALL FAR PTR 配对，不可用 RETN
ReadNumber ENDP

; (year%400==0) || (year%4==0 && year%100!=0) 为闰年
; 输入 AX=年份；输出 AL=1(闰年)或 0(平年)；近过程只返回 IP。
IsLeapYear PROC NEAR
    PUSH BX
    PUSH DX
    PUSH SI
    MOV SI, AX                              ; DIV 会改写 AX，原年份先留在 SI

    MOV BX, 400
    XOR DX, DX
    DIV BX
    OR DX, DX
    JZ LeapYes

    MOV AX, SI
    MOV BX, 100
    XOR DX, DX
    DIV BX
    OR DX, DX
    JZ LeapNo

    MOV AX, SI
    MOV BX, 4
    XOR DX, DX
    DIV BX
    OR DX, DX
    JZ LeapYes

LeapNo:
    XOR AL, AL
    JMP LeapEnd
LeapYes:
    MOV AL, 1
LeapEnd:
    POP SI
    POP DX
    POP BX
    RET
IsLeapYear ENDP

; 输入 AX=年份、BX=月份；输出 AL=当月天数。
DaysInMonth PROC FAR
    PUSH BX
    PUSH DX
    PUSH SI
    MOV DX, AX                              ; 保留年份
    MOV SI, BX
    DEC SI
    MOV AL, MonthDays[SI]
    CMP BX, 2
    JNE DaysEnd
    MOV AX, DX
    CALL IsLeapYear                         ; 同一代码段中的 NEAR 调用
    ADD AL, 28                             ; 2 月 = 28 + 是否闰年
DaysEnd:
    POP SI
    POP DX
    POP BX
    RETF
DaysInMonth ENDP

; 输入 AX=年份、BX=月份；输出 AL=本月 1 号的星期 (Su=0, ..., Sa=6)。
; 基准：1900-01-01 是星期一(1)。每过一个平年 +1 天，闰年再 +1 天。
; 计算全程只累积星期余数 0~6，不会出现总天数超出 16 位的问题。
WeekdayOfFirst PROC FAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV DI, AX                              ; 目标年份
    MOV SI, BX                              ; 目标月份
    MOV BX, 1                               ; 1900-01-01 = Monday
    MOV CX, 1900

YearLoop:
    CMP CX, DI
    JAE MonthLoopInit
    INC BX                                 ; 平年 365 mod 7 = 1
    CMP BX, 7
    JB YearChecked
    SUB BX, 7
YearChecked:
    MOV AX, CX
    CALL IsLeapYear                         ; 闰年多的一天再加 1
    OR AL, AL
    JZ NextYear
    INC BX
    CMP BX, 7
    JB NextYear
    SUB BX, 7
NextYear:
    INC CX
    JMP YearLoop

MonthLoopInit:
    MOV CX, 1
MonthLoop:
    CMP CX, SI
    JAE WeekdayReady

    ; 调用前把当前星期暂压栈；BX 临时改为待查询的月份参数。
    PUSH BX
    MOV AX, DI
    MOV BX, CX
    CALL FAR PTR DaysInMonth
    MOV DL, AL                              ; 取本月天数（不超过 31）
    POP BX
    XOR DH, DH
    ADD BX, DX                              ; 只算今年目标月之前的月份

    ; 将小整数(至多 37)除以 7，余数 DX 即下一月 1 号的星期。
    MOV AX, BX
    XOR DX, DX
    MOV BX, 7
    DIV BX
    MOV BX, DX
    INC CX
    JMP MonthLoop

WeekdayReady:
    MOV AX, BX
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RETF
WeekdayOfFirst ENDP

UTIL_CODE ENDS
END START
