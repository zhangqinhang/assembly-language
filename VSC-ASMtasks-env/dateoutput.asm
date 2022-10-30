Code Segment
Assume CS:Code,DS:Code
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：显示指定地址（Str_Addr）的字符串
; 入口：
; Str_Addr＝字符串地址（要求在数据段）
; 用法: Output Str_Addr
; 用法举例：Output PromptStr
Output MACRO Str_Addr
lea dx,Str_Addr
mov ah,9
int 21h
EndM
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：输出一个字符
; 入口：dl=要显示的字符
Output_Chr proc Near
push ax
mov ah,02h
int 21h
pop ax
ret
Output_Chr endp
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：取光标位置
; 入口：无
; 出口：DH=行号，DL=列号
GetCursor Proc Near
PUSH DS
PUSH AX
PUSH BX
PUSH CX
PUSH DX
PUSH CS
POP DS
XOR BX,BX
MOV AH,3
INT 10H
MOV Cursor_Row,DH
MOV Cursor_Col,DL
POP DX
POP CX
POP BX
POP AX
POP DS
RET
Cursor_Row DB ?
Cursor_Col DB ?
GetCursor EndP
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：置光标位置
; 入口：Cursor_Row=行坐标; Cursor_Col: 列坐标)
SetCursor Proc Near
PUSH DS
PUSH DX
PUSH CX
PUSH BX
PUSH AX
PUSH CS
POP DS
MOV DH,Cursor_Row
MOV DL,Cursor_Col
XOR BX,BX
MOV AH,2
INT 10H
POP AX
POP BX
POP CX
POP DX
POP DS
RET
SetCursor EndP
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：键盘输入一个指定位数(N)的十进制数字，将其转换成二进制数并保存在指定的内存单元。
; 输足N位的，自动结束输入；不足N位的，空格结束输入。
; 由于限定最大数据类型为字，所以，数字位数最多：5，最大无符号数：65536
; 约定：直接回车，视为数字0
; 入口：cs:@@Digits=数字位数；es:di=保存输入的数字首地址
; cs:@@Type_Data=保存的数据类型，B=字节类型，W=字类型。
; 出口：转换后的二进制数保存在di所指的单元
Input_Dec Proc Near
CR equ 0DH
LF equ 0AH
KBBack equ 08H
push ds
push dx
push cx
push bx
push di
push cs
pop ds
call GetCursor ;取光标位置
mov dx,WORD PTR Cursor_Row
mov @@Tmp_Cursor,dx ;保存起始光标位置
lea di,@@Save_Tmp
push di
cld
mov cl,@@Digits
xor ch,ch
push cx
@@Input_Dec: call GetCursor ;取光标位置
mov ah,1 ;从键盘接受一个字符
int 21h
cmp al,CR ;若键入的是空格，已经键入的数字不足N位
jz @@ASC_Dec ;转去处理已经键入的数字
cmp al,KBBack
jz @@KB_Back ;若是回空键，重新输入
cmp al,'0'
jb @@KBBack ;若低于数字'0'，重新输入
cmp al,'9'
ja @@KBBack ;若高于数字'9'，重新输入
jmp @@Save_Dig
@@KB_Back: cmp cl,cs:@@Digits ;十进制数字位数
jz @@Input_Dec
inc cx
dec di
dec Cursor_Col
@@KBBack: call SetCursor ;置光标位置
jmp @@Input_Dec
@@Save_Dig: and al,0fh ;转换成二进制数
stosb ;保存
loop @@Input_Dec ;接受下一个数字
@@ASC_Dec: mov ax,cx
pop cx
pop si
sub cx,ax ;实际输入的数字位数
xor bp,bp
xor dx,dx
xor ax,ax
jcxz @@Save_Ret ;若直接空格，没有输入任何数字，按输入'0'处理
dec cx ;实际输入的数字位数减1，准备把输入的这一串数字转换成二进制数
jcxz @@One_Digit ;若输入的数字只有一位，转去直接保存这个二进制数
mov bx,10
@@Mul_Ten: lodsb
xor ah,ah
add ax,bp
mul bx
mov bp,ax
loop @@Mul_Ten
@@One_Digit: lodsb
xor ah,ah
add ax,bp
@@Save_Ret: pop di
cmp @@Type_Data,'B' ;字节类型？
jz $+5
stosw
jmp $+3
stosb
pop bx
pop cx
pop dx
pop ds
ret
@@Tmp_Cursor dw ? ;起始光标位置
@@Digits db ? ;十进制数字位数
@@Type_Data db 'B' ;保存的数据类型。B=字节类型，W=字类型
@@Save_Tmp db 7 dup(?)
Input_Dec EndP
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：把AX中的二进制无符号数转换成显式的十进制ASCII码，并送显示屏显示
; 入口：AX=二进制数
; 出口：在当前光标位置显示转换后的ASCII码数字
Unsi_Dec_ASCII Proc Near
push dx
push bx
push di
mov bx,10
lea di,@@Temp_Save[5]
mov BYTE PTR [di],'$'
dec di
cld
@@Divide: xor dx,dx
div bx
or dl,30h
mov [di],dl
dec di
test ax,0ffffh
jnz @@Divide
inc di
push di
pop dx
mov ah,9
int 21h
pop di
pop bx
pop dx
ret
@@Temp_Save db 6 dup(?)
Unsi_Dec_ASCII EndP
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
; 功能：判断指定年份是否闰年，修改2月份天数
; 入口参数：AX=年份值
; 出口参数：DL=2月份天数
Leap_Year Proc Near
push dx
push bx
mov dx,ax
mov bx,100 ;用于判断年份是否是整世纪年份
div bl
mov bx,4
test ah,ah ;看能否被100整除
jz @@Century ;能被100整除，说明是世纪年份，转去看能否被4整除
mov ax,dx
xor dx,dx
div bx ;除以4
test dx,dx ;能整除？
jz @@Leap_Year ;能，闰年
@@Not_Leap: mov Dates_Table[1],28 ;非闰年，2月份28天
pop bx
pop dx
ret
@@Century: div bl ;除以4
test ah,ah ;看能否被4整除
jnz @@Not_Leap ;非闰年
@@Leap_Year: mov Dates_Table[1],29 ;闰年，2月份29天
pop bx
pop dx
ret
Leap_Year EndP
; －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
Dates_Table db 31,28,31,30,31,30,31,31,30,31,30,31 ;月份天数表
Prompt_Date1 db 'what is the date(MM/DD/YY)? / / $'
Prompt_Date2 db 7,13,10,13,10,'The date is $'
Prompt_Error1 db 7,13,10,'Error month!',13,10,13,10,'$'
Prompt_Error2 db 7,13,10,'Error date!',13,10,13,10,'$'
@@Month db ? ;月份
@@Date db ? ;日
@@Year db ? ;年份
Press_Key db 7,13,10,13,10,'The complated. Press any key to exit...$'
Start: push cs
pop ds
push cs
pop es ;使数据段、附加段与代码段同段
mov @@Digits,2 ;十进制数字位数
mov @@Type_Data,'B' ;保存的数据类型。B=字节类型，W=字类型
Input_Date: Output Prompt_Date1 ;提示输入：月/日/年
call GetCursor ;取当前光标位置
sub Cursor_Col,8
mov dx,WORD ptr Cursor_Row
call SetCursor ;置光标位置
lea di,@@Month ;月份
call Input_Dec ;键盘输入一个指定位数(N)的十进制数字，将其转换成二进制数并保存在指定的内存单元
add dh,3
mov WORD ptr Cursor_Row,dx
call SetCursor ;置光标位置
lea di,@@Date ;日
call Input_Dec
add dh,3
mov WORD ptr Cursor_Row,dx
call SetCursor ;置光标位置
lea di,@@Year ;年份
call Input_Dec
mov al,@@Year ;取年份数
xor ah,ah
add ax,2000 ;加上2000，假定输入的年份默认为二十一世纪
call Leap_Year ;判断指定年份是否闰年，修改2月份天数
mov al,@@Month ;取月份值
cmp al,1
jb Month_Error
cmp al,12
ja Month_Error
dec al
lea bx,Dates_Table ;月份天数表地址
xlat ;查表取得对应月份天数
mov ah,@@Date ;取日值
cmp ah,1
jb Date_Error
cmp ah,al
ja Date_Error
Output Prompt_Date2 ;提示输入：年-月-日
mov al,@@Year ;取年份数
xor ah,ah
add ax,2000 ;加上2000，假定输入的年份默认为二十一世纪
call Unsi_Dec_ASCII ;把AX中的二进制无符号数转换成显式的十进制ASCII码，并送显示屏显示
mov dl,'.'
call Output_Chr ;显示一个字符
mov al,@@Month ;取月份值
xor ah,ah
call Unsi_Dec_ASCII
mov dl,'.'
call Output_Chr ;显示一个字符
mov al,@@Date ;取日值
xor ah,ah
call Unsi_Dec_ASCII
Exit_Proc: Output Press_Key ;提示操作完成，按任意键结束程序
mov ah,1
int 21h
mov ah,4ch ;结束程序
int 21h
Month_Error: Output Prompt_Error1 ;提示月份错误
jmp Input_Date ;重新输入
Date_Error: Output Prompt_Error2 ;提示日期错误
jmp Input_Date ;重新输入
Code ENDS
END Start ;编译到此结束