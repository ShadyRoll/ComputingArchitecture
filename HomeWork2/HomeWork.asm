format PE console
entry start

include 'win32a.inc'

;#######
; ����� ����
; ���197
; ������� - 18
;#######

;--------------------------------------------------------------------------
section '.data' data readable writable
        ; ���������� ��� ��������������
        strVecSize       db 'Array size = ', 0
        strVecAAnnounce  db 'Input array:', 10, 0
        strVecBAnnounce  db 'Output array:', 10, 0
        strIncorSize     db 'Incorrect size of array = %d (0 < size < 101)', 10, 0
        strVecElemI      db 'element %d = ', 0
        strScanInt       db '%d', 0
        strVecElemOut    db 'element %d = %d', 10, 0

        vec_size         dd 0   ; ������ �������
        i                dd ?   ; ������ ��������
        tmp              dd ?   ; ��������� ���������� ��� �������� ��������� �������
        tmpStack         dd ?   ; ��������� ���������� ��� �������� �����
        nonNegativeFound rb 1   ; ����, ������������, ��������� �� �� ������������� �������
        vecA             rd 100 ; ������ ��� �����
        vecB             rd 100 ; ������ ��� ������

        DECREASER = 5       ; ��������� ��� ���������� ��������� �������

;--------------------------------------------------------------------------
section '.code' code readable executable
start:
        ; ������ ������ A
        call VectorInput
        ; ���������� ������ B �� ������ ������� A
        call GenerateVector

        ; ������� ������ A
        push strVecAAnnounce
        call [printf]
        mov ebx, vecA
        call VectorOut

        ; ������� ������ B
        push strVecBAnnounce
        call [printf]
        mov ebx, vecB
        call VectorOut
finish:
        ; "��������" ����� ������� �� ���������
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------
; ������ ����� ������� ��-�� ������������� ������� �������
abortInput:
        ; ������� ��������� � ������������ ������� �������
        push [vec_size]
        push strIncorSize
        call [printf]

        jmp finish
; ���� �������
VectorInput:
        push strVecSize
        call [printf]
        add esp, 4 ; ��������������� �������� �����

        push vec_size
        push strScanInt
        call [scanf]
        add esp, 8 ; ��������������� �������� �����

        ; ��������� ������������ vec_size
        mov eax, [vec_size]
        cmp eax, 0
        jle abortInput
        cmp eax, 100
        jg abortInput

; ��������� � ����� ���������
getVector:
        mov [tmpStack], esp ; ��������� �������� "��������" �����
        mov ecx, 1          ; ecx - ������ �������� (������� � 1)
        mov ebx, vecA       ; ebx - �������� �������� �������
getVectorLoop:
        ; ���� �� �������� �� ���� �������� - ������� �� ������
        cmp ecx, [vec_size]
        jg endGetVector

        ; ��������� �������� ��������� �� ��������� ����������
        mov [tmp], ebx
        mov [i], ecx

        ; ��������� �������
        push ecx
        push strVecElemI
        call [printf]

        push ebx
        push strScanInt
        call [scanf]

        ; ��������������� �������� ���������
        mov ecx, [i]
        mov ebx, [tmp]

        inc ecx    ; ����������� ������
        add ebx, 4 ; �������� ����� � ���������� ��������

        jmp getVectorLoop

endGetVector:
        mov esp, [tmpStack] ; ��������������� �������� "��������" �����
        ret

;--------------------------------------------------------------------------
; ���������� ������ B �������� �������� ������
GenerateVector:
        mov [tmpStack], esp     ; ��������� �������� "��������" �����
        mov ecx, 1              ; ecx - ������ �������� (������� � 1)
        mov ebx, vecA           ; ebx - �������� �������� �������
        mov edx, vecB           ; edx - �������� ��������� �������
generateVectorLoop:
        ; ���� �� �������� �� ���� �������� - ������� �� ������
        cmp ecx, [vec_size]
        jg endSumVector

        ; �������� �������� �������� �� �������� ������� � ������� ���������
        mov eax, dword [ebx]
        mov [edx], eax

        ; ���� �� ��� ��������� ������������� �������,
        ; ����� ��������� � ���������� �������
        cmp [nonNegativeFound], 1
        je generateVectorNext

        ; ��������� ��������������� ��������
        mov eax, 0
        cmp [edx], eax
        jle decreaseElem

        ; ���������� ������, ��� ��� �������� ��������������� �������
        mov [nonNegativeFound], 1

; ��������� � ���������� ��������
generateVectorNext:
        inc ecx     ; ����������� ������
        ; �������� ������ � ���������� ��������
        add edx, 4
        add ebx, 4
        jmp generateVectorLoop
; ��������� �������� ��������
decreaseElem:
        ; �������� �� �������� ������� �� 5
        mov eax, DECREASER
        sub [edx], eax

        jmp generateVectorNext
endSumVector:
        mov esp, [tmpStack]   ; ��������������� �������� "��������" �����
        ret

;--------------------------------------------------------------------------
; ������� �������� �������
VectorOut:
        mov [tmpStack], esp ; ��������� �������� "��������" �����
        mov ecx, 1          ; ecx - ������ �������� (������� � 1)
        ; ebx - �������� ��������� �������
outVecLoop:
        ; ���� �� �������� �� ���� �������� - ������� �� ������
        cmp ecx, [vec_size]
        jg endOutputVector

        ; ��������� �������� ��������� �� ��������� ����������
        mov [tmp], ebx
        mov [i], ecx

        ; ������� �������
        push dword [ebx]
        push ecx
        push strVecElemOut
        call [printf]

        ; ��������������� �������� ���������
        mov ecx, [i]
        mov ebx, [tmp]

        inc ecx    ; ����������� ������
        add ebx, 4 ; �������� ����� � ���������� ��������

        jmp outVecLoop
endOutputVector:
        mov esp, [tmpStack]  ; ��������������� �������� "��������" �����
        ret

;-------------------------------third act - including HeapApi--------------------------
                                                 
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