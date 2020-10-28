format PE console
entry start

include 'win32a.inc'

;#######
; Попов Олег
; БПИ197
; Вариант - 17
; Условие:
; Разработать программу вычисления даты католической Пасхалии для заданного года
;#######

;--------------------------------------------------------------------------
section '.data' data readable writable
        ; Переменные
        year dd ?   ; Год
        G    dd ?   ; Золотое число в Метоновом цикле — 19-летнем цикле полнолуний
        C    dd ?   ; Номер века
        X    dd ?   ; Поправка на изъятие трёх из четырёх високосных вековых лет, «солнечное уравнение»
        Z    dd ?   ; Поправка цикла Каллиппа, «лунное уравнение»
        D    dd ?   ; В марте день под номером D mod 7 - воскресенье
        E    dd ?   ; Эпакта — указывает на день наступления полнолуния
        N    dd ?   ; Номер дня в марте, являющегося календарным полнолунием
        temp dd ?   ; Переменная для промежуточных вычислений
        easterDay   dd ? ; Номер дня Пасхи
        easterMonth dd ? ; Номер месяца Пасхи

        ; Переменные для форматирования
        strYear       db 'Year = ', 0
        strIncorYear  db 'Incorrect year = %d (year must be > 0)', 10, 0
        strEasterDate db 'Easter date is %d.0%d.%d', 10, 0
        strScanInt    db '%d', 0
        strPrintInt   db '%d', 10, 0
;-----------------------------Макросы------------------------------------
section '.code' code readable executable
; Определяет частное деления
; dividend - делимое, divider - делитель
; quotient - переменная, куда будет записано частное
macro devide dividend, divider, quotient
{
        mov eax, dividend   ; делимое
        mov ebx, divider    ; делитель
        mov edx, 0          ; зануляем edx для верного вычислени
        ; Делим
        div ebx
        ; Записываем частное в переменную
        mov [quotient], eax
}
; Определяет остаток деления
; dividend - делимое, divider - делитель
; remainder - переменная, куда будет записан остаток
macro getRemainder dividend, divider, remainder
{
        mov eax, dividend   ; делимое
        mov ebx, divider    ; делитель
        mov edx, 0          ; зануляем edx для верного вычисления
        ; Делим
        div ebx
        ; Записываем остаток в переменную
        mov [remainder], edx
}
; Вычисляет произведение 2х чисел
; elem1 - 1е число, elem2 - 2е число
; res - переменная, куда будет записано произведение
macro multiply elem1, elem2, res
{
        mov eax, elem1   ; 1е число
        mov ebx, elem2   ; 2е число
        mov edx, 0       ; зануляем edx для верного вычисления
        ; Умножаем
        mul ebx
        ; Записываем произведение в переменную
        mov [res], eax
}
;--------------------------------------------------------------------------
start:
        ; Вводим год
        call YearInput
        ; Вычисляем дату на основе алгоритма Лилия — Клавия
        call CalculateDate
        ; Выводим дату Пасхи
        call PrintDate
finish:
        ; "Задержка" перед выходом из программы
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------
; Выход из прогрммы из-за некоррекного ввода года
abortInput:
        ; Выводим сообщение о некорректном году
        push [year]
        push strIncorYear
        call [printf]

        ; Завершаем выполнение программы
        jmp finish
; Ввод года
YearInput:
        push strYear
        call [printf]
        add esp, 4 ; Восстанавливаем значение стека

        push year
        push strScanInt
        call [scanf]
        add esp, 8 ; Восстанавливаем значение стека

        ; Проверяем корректность введенного года
        mov eax, [year]
        cmp eax, 0
        jle abortInput

        ret
;--------------------------------------------------------------------------
; Вычисление даты на основе алгоритма Лилия — Клавия
CalculateDate:
        ; Алгоритм Лилия — Клавия состоит из 11 этапов, выполним их один за другим
;1. G = (year % 19) + 1
stage1:
        ; Находим остаток от деления года на 19
        getRemainder [year], 19, G
        ; Прибавим 1
        inc [G]

;2. C = year/100 + 1
stage2:
        ; Делим год на 100
        devide [year], 100, C
        ; Прибавим 1
        inc [C]

;3. X = 3C/4 - 12
stage3:
        ; Умножим C на 3
        multiply [C], 3, X
        ; Поделим на 4
        devide [X], 4, X
        ; Вычтем 12
        sub [X], 12
;4. Z = (8C + 5)/25 - 5
stage4:
        ; Умножим C на 8
        multiply [C], 8, Z
        ; Прибавим 5
        add [Z], 5
        ; Разделим на 25
        devide [Z], 25, Z
        ; Вычтем 5
        sub [Z], 5
;5. D = 5*year/4 - X - 10
stage5:
        ; Умножим year на 5
        multiply [year], 5, D
        ; Разделим на 4
        devide [D], 4, D
        ; Вычтем X и 10
        mov eax, [X]
        sub [D], eax
        sub [D], 10

;6. E = ((11G + 20 + Z - X) % 30 + 30) % 30
stage6:
        ; Умножим G на 11
        multiply [G], 11, temp
        ; Прибавим 20 и Z, вычтем X
        mov eax, [temp]
        add eax, 20
        add eax, [Z]
        sub eax, [X]
        ; Найдем остаток от деления на 30
        getRemainder eax, 30, E
        ; Прибавим 30
        add [E], 30
        ; Еще раз определим остаток от деления на 30
        getRemainder [E], 30, E

;7. Если (E = 24) или (E = 25 и G > 11), то инкрементируем E
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
;9. Если N < 21, увеличим N на 30
stage9:
        cmp [N], 21
        ; Если  >= 21, сразу переходим на 10 этап
        jge stage10
        ; Иначе увеличиваем N
        add [N], 30

;10. N = N + 7 - (D + N) % 7
stage10:
        mov edx, 0 ; Обнулим edx для вычисления остатка

        ; Найдем (D + N) % 7
        mov eax, [D]
        add eax, [N]
        getRemainder eax, 7, temp
        ; Прибавим 7 к N , вычтем полученный остаток
        mov eax, [N]
        add eax, 7
        sub eax, [temp]
        mov [N], eax
;11. Если N > 31, тогда дата Пасхи = N - 31 апреля, иначе это N-ое марта
stage11:
        cmp [N], 31
        jg easterInApril
; Устанавлиает день и месяц (если март)
easterInMarch:
        mov eax, [N]
        mov [easterDay], eax
        mov [easterMonth], 3
        jmp finishCalculation
; Устанавлиает день и месяц (если апрель)
easterInApril:
        mov eax, [N]
        sub eax, 31
        mov [easterDay], eax
        mov [easterMonth], 4
; Завершает функцию подсчета дня Пасхи
finishCalculation:
        ret
; Инкрементирует E
incE:
        inc [E]
        jmp stage8

;--------------------------------------------------------------------------
; Выводим дату католической Пасхи
PrintDate:
        ; Выводим дату
        push [year]
        push [easterMonth]
        push [easterDay]
        push strEasterDate
        call [printf]
        add esp, 16 ; Восстанавливаем значение "верхушки" стека

        ret
;-------------------------Подключаем HeadApi------------------------------
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