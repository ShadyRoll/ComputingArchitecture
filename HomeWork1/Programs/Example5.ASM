format PE console
entry start

include 'win32a.inc'

section '.text' code executable
start:
        push msg1
        call [printf]
        push msg2
        call [printf]
        push msg3
        call [printf]
        pop ecx

        call [_getch]
        push 0
        ;call [ExitProcess]

section '.data' data readable
        msg1 db 'Hello world!', 10, 0
        msg2 db 'It is multiple lines example made by my own.', 10, 0
        msg3 db "It is so hard to find many examples in the net, most of them don't work!", 10, 0

section '.idata' data readable import
        library kernel32, 'kernel32.dll', \
                msvcrt,   'msvcrt.dll'
        import kernel32, ExitProcess, 'ExitProcess'
        import msvcrt,\
         printf,'printf',\
         _getch,'_getch'