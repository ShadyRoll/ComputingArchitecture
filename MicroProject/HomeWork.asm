format PE console
entry start

include 'win32a.inc'

;#######
; ����� ����
; ���197
; ������� - 17
; �������:
; ����������� ��������� ���������� ���� ������������ �������� ��� ��������� ����
;#######

;--------------------------------------------------------------------------
section '.data' data readable writable
        ; ����������
        year dd ?   ; ���
        G    dd ?   ; ������� ����� � ��������� ����� � 19-������ ����� ����������
        C    dd ?   ; ����� ����
        X    dd ?   ; �������� �� ������� ��� �� ������ ���������� ������� ���, ���������� ���������
        Z    dd ?   ; �������� ����� ��������, ������� ���������
        D    dd ?   ; � ����� ���� ��� ������� D mod 7 - �����������
        E    dd ?   ; ������ � ��������� �� ���� ����������� ����������
        N    dd ?   ; ����� ��� � �����, ����������� ����������� �����������
        temp dd ?   ; ���������� ��� ������������� ����������
        easterDay   dd ? ; ����� ��� �����
        easterMonth dd ? ; ����� ������ �����

        ; ���������� ��� ��������������
        strYear       db 'Year = ', 0
        strIncorYear  db 'Incorrect year = %d (year must be > 0)', 10, 0
        strEasterDate db 'Easter date is %d.0%d.%d', 10, 0
        strScanInt    db '%d', 0
        strPrintInt   db '%d', 10, 0
;-----------------------------�������------------------------------------
section '.code' code readable executable
; ���������� ������� �������
; dividend - �������, divider - ��������
; quotient - ����������, ���� ����� �������� �������
macro devide dividend, divider, quotient
{
        mov eax, dividend   ; �������
        mov ebx, divider    ; ��������
        mov edx, 0          ; �������� edx ��� ������� ���������
        ; �����
        div ebx
        ; ���������� ������� � ����������
        mov [quotient], eax
}
; ���������� ������� �������
; dividend - �������, divider - ��������
; remainder - ����������, ���� ����� ������� �������
macro getRemainder dividend, divider, remainder
{
        mov eax, dividend   ; �������
        mov ebx, divider    ; ��������
        mov edx, 0          ; �������� edx ��� ������� ����������
        ; �����
        div ebx
        ; ���������� ������� � ����������
        mov [remainder], edx
}
; ��������� ������������ 2� �����
; elem1 - 1� �����, elem2 - 2� �����
; res - ����������, ���� ����� �������� ������������
macro multiply elem1, elem2, res
{
        mov eax, elem1   ; 1� �����
        mov ebx, elem2   ; 2� �����
        mov edx, 0       ; �������� edx ��� ������� ����������
        ; ��������
        mul ebx
        ; ���������� ������������ � ����������
        mov [res], eax
}
;--------------------------------------------------------------------------
start:
        ; ������ ���
        call YearInput
        ; ��������� ���� �� ������ ��������� ����� � ������
        call CalculateDate
        ; ������� ���� �����
        call PrintDate
finish:
        ; "��������" ����� ������� �� ���������
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------
; ����� �� �������� ��-�� ������������ ����� ����
abortInput:
        ; ������� ��������� � ������������ ����
        push [year]
        push strIncorYear
        call [printf]

        ; ��������� ���������� ���������
        jmp finish
; ���� ����
YearInput:
        push strYear
        call [printf]
        add esp, 4 ; ��������������� �������� �����

        push year
        push strScanInt
        call [scanf]
        add esp, 8 ; ��������������� �������� �����

        ; ��������� ������������ ���������� ����
        mov eax, [year]
        cmp eax, 0
        jle abortInput

        ret
;--------------------------------------------------------------------------
; ���������� ���� �� ������ ��������� ����� � ������
CalculateDate:
        ; �������� ����� � ������ ������� �� 11 ������, �������� �� ���� �� ������
;1. G = (year % 19) + 1
stage1:
        ; ������� ������� �� ������� ���� �� 19
        getRemainder [year], 19, G
        ; �������� 1
        inc [G]

;2. C = year/100 + 1
stage2:
        ; ����� ��� �� 100
        devide [year], 100, C
        ; �������� 1
        inc [C]

;3. X = 3C/4 - 12
stage3:
        ; ������� C �� 3
        multiply [C], 3, X
        ; ������� �� 4
        devide [X], 4, X
        ; ������ 12
        sub [X], 12
;4. Z = (8C + 5)/25 - 5
stage4:
        ; ������� C �� 8
        multiply [C], 8, Z
        ; �������� 5
        add [Z], 5
        ; �������� �� 25
        devide [Z], 25, Z
        ; ������ 5
        sub [Z], 5
;5. D = 5*year/4 - X - 10
stage5:
        ; ������� year �� 5
        multiply [year], 5, D
        ; �������� �� 4
        devide [D], 4, D
        ; ������ X � 10
        mov eax, [X]
        sub [D], eax
        sub [D], 10

;6. E = ((11G + 20 + Z - X) % 30 + 30) % 30
stage6:
        ; ������� G �� 11
        multiply [G], 11, temp
        ; �������� 20 � Z, ������ X
        mov eax, [temp]
        add eax, 20
        add eax, [Z]
        sub eax, [X]
        ; ������ ������� �� ������� �� 30
        getRemainder eax, 30, E
        ; �������� 30
        add [E], 30
        ; ��� ��� ��������� ������� �� ������� �� 30
        getRemainder [E], 30, E

;7. ���� (E = 24) ��� (E = 25 � G > 11), �� �������������� E
stage7:
        cmp [E], 24
        je incE
        cmp [E], 25
        jne stage8
        cmp [G], 11
        jg incE
;8. N = 44 - E
stage8:
        mov eax, 44
        sub eax, [E]
        mov [N], eax
;9. ���� N < 21, �������� N �� 30
stage9:
        cmp [N], 21
        ; ����  >= 21, ����� ��������� �� 10 ����
        jge stage10
        ; ����� ����������� N
        add [N], 30

;10. N = N + 7 - (D + N) % 7
stage10:
        mov edx, 0 ; ������� edx ��� ���������� �������

        ; ������ (D + N) % 7
        mov eax, [D]
        add eax, [N]
        getRemainder eax, 7, temp
        ; �������� 7 � N , ������ ���������� �������
        mov eax, [N]
        add eax, 7
        sub eax, [temp]
        mov [N], eax
;11. ���� N > 31, ����� ���� ����� = N - 31 ������, ����� ��� N-�� �����
stage11:
        cmp [N], 31
        jg easterInApril
; ������������ ���� � ����� (���� ����)
easterInMarch:
        mov eax, [N]
        mov [easterDay], eax
        mov [easterMonth], 3
        jmp finishCalculation
; ������������ ���� � ����� (���� ������)
easterInApril:
        mov eax, [N]
        sub eax, 31
        mov [easterDay], eax
        mov [easterMonth], 4
; ��������� ������� �������� ��� �����
finishCalculation:
        ret
; �������������� E
incE:
        inc [E]
        jmp stage8

;--------------------------------------------------------------------------
; ������� ���� ������������ �����
PrintDate:
        ; ������� ����
        push [year]
        push [easterMonth]
        push [easterDay]
        push strEasterDate
        call [printf]
        add esp, 16 ; ��������������� �������� "��������" �����

        ret
;-------------------------���������� HeadApi------------------------------
section '.idata' import data readable
    library kernel, 'kernel32.dll',\
            msvcrt, 'msvcrt.dll',\
            user32,'USER32.DLL'

include 'api\user32.inc'
include 'api\kernel32.inc'
    import kernel,\
           ExitProcess, 'ExitProcess',\
           HeapCreate,'HeapCreate',\
           HeapAlloc,'HeapAlloc'
include 'api\kernel32.inc'
    import msvcrt,\
           printf, 'printf',\
           scanf, 'scanf',\
           getch, '_getch'