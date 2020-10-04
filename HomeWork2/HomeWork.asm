format PE console
entry start

include 'win32a.inc'

;#######
; Попов Олег
; БПИ197
; Вариант - 18
;#######

;--------------------------------------------------------------------------
section '.data' data readable writable
        ; Переменные для форматирования
        strVecSize       db 'Array size = ', 0
        strVecAAnnounce  db 'Input array:', 10, 0
        strVecBAnnounce  db 'Output array:', 10, 0
        strIncorSize     db 'Incorrect size of array = %d (0 < size < 101)', 10, 0
        strVecElemI      db 'element %d = ', 0
        strScanInt       db '%d', 0
        strVecElemOut    db 'element %d = %d', 10, 0

        vec_size         dd 0   ; Размер вектора
        i                dd ?   ; Индекс элемента
        tmp              dd ?   ; Временная переменная для значения элементов массива
        tmpStack         dd ?   ; Временная переменная для значений стека
        nonNegativeFound rb 1   ; Флаг, обозначающий, встречали ли мы положительный элемент
        vecA             rd 100 ; Массив для ввода
        vecB             rd 100 ; Массив для вывода

        DECREASER = 5       ; Константа для уменьшения элементов массива

;--------------------------------------------------------------------------
section '.code' code readable executable
start:
        ; Вводим массив A
        call VectorInput
        ; Генерируем массив B на основе массива A
        call GenerateVector

        ; Выводим массив A
        push strVecAAnnounce
        call [printf]
        mov ebx, vecA
        call VectorOut

        ; Выводим массив B
        push strVecBAnnounce
        call [printf]
        mov ebx, vecB
        call VectorOut
finish:
        ; "Задержка" перед выходом из программы
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------
; Отмена ввода массива из-за некорректного размера массива
abortInput:
        ; Выводим сообщение о некорректном размере массива
        push [vec_size]
        push strIncorSize
        call [printf]

        jmp finish
; Ввод массива
VectorInput:
        push strVecSize
        call [printf]
        add esp, 4 ; Восстанавливаем значение стека

        push vec_size
        push strScanInt
        call [scanf]
        add esp, 8 ; Восстанавливаем значение стека

        ; Проверяем корректность vec_size
        mov eax, [vec_size]
        cmp eax, 0
        jle abortInput
        cmp eax, 100
        jg abortInput

; Переходим к вводу элементов
getVector:
        mov [tmpStack], esp ; Сохраняем значение "верхушки" стека
        mov ecx, 1          ; ecx - индекс элемента (начиная с 1)
        mov ebx, vecA       ; ebx - элементы входного массива
getVectorLoop:
        ; Если мы прошлись по всем индексам - выходим из метода
        cmp ecx, [vec_size]
        jg endGetVector

        ; Сохраняем значения регистров во временные переменные
        mov [tmp], ebx
        mov [i], ecx

        ; Считываем элемент
        push ecx
        push strVecElemI
        call [printf]

        push ebx
        push strScanInt
        call [scanf]

        ; Восстанавливаем значения регистров
        mov ecx, [i]
        mov ebx, [tmp]

        inc ecx    ; Увеличиваем индекс
        add ebx, 4 ; Сдвигаем адрес к следующему элементу

        jmp getVectorLoop

endGetVector:
        mov esp, [tmpStack] ; Восстанавливаем значение "верхушки" стека
        ret

;--------------------------------------------------------------------------
; Генерирует массив B согласно условиям задачи
GenerateVector:
        mov [tmpStack], esp     ; Сохраняем значение "верхушки" стека
        mov ecx, 1              ; ecx - индекс элемента (начиная с 1)
        mov ebx, vecA           ; ebx - элементы входного массива
        mov edx, vecB           ; edx - элементы выходного массива
generateVectorLoop:
        ; Если мы прошлись по всем индексам - выходим из метода
        cmp ecx, [vec_size]
        jg endSumVector

        ; Копируем значение элемента из входного массива в элемент выходного
        mov eax, dword [ebx]
        mov [edx], eax

        ; Если мы уже встречали положительный элемент,
        ; сразу переходим к следующему индексу
        cmp [nonNegativeFound], 1
        je generateVectorNext

        ; Проверяем положительность элемента
        mov eax, 0
        cmp [edx], eax
        jle decreaseElem

        ; Обозначаем флагом, что был встречен неотрицательный элемент
        mov [nonNegativeFound], 1

; Переходим к следующему элементу
generateVectorNext:
        inc ecx     ; Увеличиваем индекс
        ; Сдвигаем адреса к следующему элементу
        add edx, 4
        add ebx, 4
        jmp generateVectorLoop
; Уменьшаем значение элемента
decreaseElem:
        ; Вычитаем из элемента массива на 5
        mov eax, DECREASER
        sub [edx], eax

        jmp generateVectorNext
endSumVector:
        mov esp, [tmpStack]   ; Восстанавливаем значение "верхушки" стека
        ret

;--------------------------------------------------------------------------
; Выводим элементы массива
VectorOut:
        mov [tmpStack], esp ; Сохраняем значение "верхушки" стека
        mov ecx, 1          ; ecx - индекс элемента (начиная с 1)
        ; ebx - элементы выходного массива
outVecLoop:
        ; Если мы прошлись по всем индексам - выходим из метода
        cmp ecx, [vec_size]
        jg endOutputVector

        ; Сохраняем значения регистров во временные переменные
        mov [tmp], ebx
        mov [i], ecx

        ; Выводим элемент
        push dword [ebx]
        push ecx
        push strVecElemOut
        call [printf]

        ; Восстанавливаем значения регистров
        mov ecx, [i]
        mov ebx, [tmp]

        inc ecx    ; Увеличиваем индекс
        add ebx, 4 ; Сдвигаем адрес к следующему элементу

        jmp outVecLoop
endOutputVector:
        mov esp, [tmpStack]  ; Восстанавливаем значение "верхушки" стека
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