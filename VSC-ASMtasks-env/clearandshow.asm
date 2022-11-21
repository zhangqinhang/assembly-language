;在屏幕的指令位置（8行8列处以指定颜色输出 data段中的字符串），可记录到Blog
assume cs:code
data segment
	db 'hello tongji!',0				;data段定义好要输出的字符串，以'0'作为结束标志
data ends

stack segment
	db 128 dup(0)
code segment
start:			mov ax,data
				mov ds,ax
				mov ax,stack
				mov ss,ax
				mov sp,128
				call init_data				;初始化数据
				call show_str				;显示的方法
				mov ax,4c00h
				int 21h

init_data:		mov ax,0B800h
				mov es,ax
				mov dh,8		;指定行号
				mov dl,8		;指定列号
				mov cl,00000011B;指定颜色
				mov si,0
				mov di,0
				ret

show_str:		call clear_screen			;清屏
				call getRow					;获取指定行号的字节偏移数
				call getCol					;获取指定列号
				call show_String			;真正的显示字符串方法
				ret

clear_screen:	push cx
				push dx
				push es
				push bx
				mov cx,2000     ;一页有2000字符，每个字符2个字节
				mov dx,0700h	;将屏幕上的双字用0700h代替
				mov bx,0
clearScreen:	mov es:[bx],dx
				add bx,2
				loop clearScreen
				
				pop bx
				pop es
				pop dx
				pop cx
				ret

show_String:	push cx     ;保存下面将要用到的寄存器
				push ds
				push es
				push dx
				push si
				push di
				
				mov dh,cl		;高位存颜色
				mov cx,0
showString:		mov cl,ds:[si]
				jcxz showStringRet
				mov dl,ds:[si]	;低位存字符
				mov es:[di],dx
				add di,2
				inc si
				jmp showString
				
showStringRet:	pop di		;还原寄存器
				pop si
				pop dx
				pop es
				pop ds
				pop cx
				ret				

getRow:			mov al,dh
				mov bl,160   ;一行80字符，160字节
				mul bl
				mov di,ax
				ret

getCol:			mov al,dl
				mov bl,2
				mul bl
				add di,ax
				ret
				
code ends
end start
