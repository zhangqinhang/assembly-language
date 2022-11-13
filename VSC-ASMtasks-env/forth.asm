DATA SEGMENT 
    STR1 DB 0AH,0DH ,'THE RESULT IS : $' ;0AH,0DH 为换行 将 bl 和 cl 中的数字相加并输出结果
DATA ENDS 

CODE SEGMENT 
    ASSUME CS:CODE,DS:DATA 
START:
PRINT MACRO STR  ; MACRO 为宏
    MOV AX,DATA 
    MOV DS,AX
    MOV DX,OFFSET STR 
    MOV AH,09H ; 打印STR
    INT 21H 
ENDM

ADDBLCL MACRO R1,R2 ;
    MOV AL,R1 
    ADD AL,R2
    DAA  ; 压缩型BCD码加法调整指令 ，默认调整 al

    PUSH AX 
    MOV CL,4
    SHR AL,CL ; 逻辑右移指令
    CALL PRINT_DL ;子程序调用

    POP AX  
    AND AL,0FH
    CALL PRINT_DL 
ENDM 

    PRINT STR1
    ADDBLCL 25H,48H
    PRINT STR1
    ADDBLCL 15H,15H 

    MOV BL,78H
    MOV CL,20H
    PRINT STR1
    CALL TT ;子程序调用

    MOV BL,11H
    MOV CL,22H
    PRINT STR1
    CALL TT

    MOV AX ,4C00H
    INT 21H ;return dos 

PRINT_DL  PROC ;子程序的实现与声明
    ADD AL,30H
    MOV DL,AL 
    MOV AH,02H
    INT 21H
    RET 
PRINT_DL ENDP 

TT PROC 
    MOV AL,CL 
    ADD AL,BL
    DAA  
    PUSH AX 
    MOV CL,4
    SHR AL,CL ;
    CALL PRINT_DL ;
    POP AX  
    AND AL,0FH
    CALL PRINT_DL 
    RET 
TT ENDP

    CODE ENDS 
END START
