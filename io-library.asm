section .text
 
 
; Принимает код возврата и завершает текущий процесс
exit: 
    xor rax, rax,
    ret 

end:
	ret		
	

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax
	.loop:
		cmp byte [rdi+rax], 0	; compare current symbol (start address + offset) with null
		je end					; if it is null -> finish
		inc rax					; if not -> increase counter (offset)
		jmp .loop				; repeat
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    xor rax, rax
	mov rsi, rdi				; copy start address to rsi 
	call string_length
	mov rdx, rax
	mov rdi, 1
	mov rax, 1
	syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:
    xor rax, rax
	push rdi 		; syscall uses address as argument -> 
	mov rsi, rsp 	; -> push the symbol code and ->
	pop rdi 		; -> pass the stack pointer as argument
	mov rax, 1 ; system call number
	mov rdx, 1 ; how many bytes to write (1 symbol)
	mov rdi, 1 ; where to write (stdout descriptor)
	syscall
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
	mov rax, 1
	mov rdx, 1
	mov rdi, 1
	mov rsi, 0xA
	syscall
    ret

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    xor rax, rax
	xor rdx, rdx
	mov r8, 0 ; counter
	mov r9, 10 ; divisor (radix)
	mov rax, rdi ; move argument to rax for further division
	.loop:
		div r9	
		mov rsi, rdx ; move remainder to rcx
		add rsi, 48 ; "0" digit in ASCII
		inc r8		; increase counter
		dec rsp		; allocate 1 byte for a digit symbol
		mov [rsp], sil	; push ASCII-digit onto the stack
		xor rdx, rdx ; clear the remainder
		cmp rax, 0	; check if dividend is 0
		jne .loop	; if it's not -> continue
	mov rsi, rsp	; string starts at stack pointer
	mov rax, 1		; syscall number
	mov rdx, r8		; counter = number of bytes to write
	mov rdi, 1		; writing to stdout
	syscall
	add rsp, r8		; return stack pointer to its initial state
    ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    xor rax, rax
	xor rdx, rdx
	mov r8, 0 ; counter
	mov r9, 10 ; divisor (radix)
	mov rax, rdi
	cmp rax, 0
	jge .loop
	neg rax
	.loop:
		div r9	
		mov rsi, rdx ; move remainder to rcx
		add rsi, 48 ; "0" digit in ASCII
		inc r8		; increase counter
		dec rsp		; allocate 1 byte for a digit symbol
		mov [rsp], sil	; push ASCII-digit onto the stack
		xor rdx, rdx ; clear the remainder
		cmp rax, 0	; check if dividend is 0
		jne .loop	; if it's not -> continue
	cmp rdi, 0		; is the number negative?
	jge .syscall	; no -> proceed to syscall
	inc r8			; yes ->
	dec rsp			; add minus sign 
	mov byte [rsp], 45 ; minus sign
	.syscall:
		mov rsi, rsp	; string starts at stack pointer
		mov rax, 1		; syscall number
		mov rdx, r8		; counter = number of bytes to write
		mov rdi, 1		; writing to stdout
		syscall
		add rsp, r8		; return stack pointer to its initial state
		ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    mov rax, 1		; answer
	mov r8, rdi		; pointer to str1
	mov r9, rsi 	; pointer to str2
	xor rcx, rcx	; iterator
	xor rdi, rdi
	xor rsi, rsi
	.loop:
		mov dil, [r9+rcx]	; move symbol from str1 to rdi lower byte
		mov sil, [r8+rcx]	; move symbol from str2 to rsi lower byte
		cmp sil, dil		
		jne .nequal	
		cmp byte dil, 0		; if both symbols are equal to null we stop
		je end
		inc rcx
		jmp .loop
	.nequal:
		mov rax, 0
		ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    xor rax, rax
	dec rsp			; allocate 1 byte on stack for reading 
	mov rdi, 0		; stdin descriptor
	mov rdx, 1		; read 1 byte
	mov rax, 0 		; read syscall
	mov rsi, rsp	; read to rsp
	syscall
	cmp rax, 0
	je .zero
	mov rax, [rsp]
	inc rsp
    ret 
	.zero:
		mov rax, 0
		inc rsp
		ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
	mov r8, rdi
	mov r9, rsi
	
	.skip_whitespaces:
		call read_char
		cmp al, 0x20
		je .skip_whitespaces
		cmp al, 0x9
		je .skip_whitespaces
		cmp al, 0xA
		je .skip_whitespaces
	xor rdx, rdx ; counter	
	jmp .write
	.loop:
		push rdx
		call read_char 	; save rdx and read the next char
		pop rdx
	.write:	
		cmp al, 0xA
		je .finish
		cmp al, 0x20
		je .finish
		cmp al, 4
		je .finish
		cmp al, 0x9
		je .finish
		cmp al, 0
		je .finish	
		inc rdx
		cmp rdx, r9
		jge .overflow
		dec rdx
		mov [r8+rdx], al
		inc rdx
		jmp .loop
	.finish:
		mov byte [r8+rdx], 0
		mov rax, r8
		ret
	.overflow:
		xor rax, rax
		ret
 

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
	xor r8, r8 ; counter
	xor rax, rax
	xor rdx, rdx
	xor rsi, rsi
	mov r9, 10 ;radix
	.loop:
		mov sil, [rdi+r8] 	; we work with symbols (bytes) -> use sil (lower byte of rsi)
		cmp sil, 48			; -- check
		jl .finish			; -- if the symbol
		cmp sil, 57			; -- is 
		jg .finish			; -- numeric
		inc r8
		sub sil, 48			; subtract 48 from ascii code to get pure digit value
		mul r9				; multiply by radix (10) ->
		add rax, rsi		; -> add the digit
		jmp .loop	
	.finish:
		mov rdx, r8
		ret
	




; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax
	xor r8, r8	; counter
	xor rsi, rsi
	mov r9, 10 ; radix
	cmp byte [rdi], 45
	jne .loop
	inc r8
	.loop:
		mov sil, [rdi+r8]
		cmp sil, 48			; -- check
		jl .finish			; -- if the symbol
		cmp sil, 57			; -- is 
		jg .finish			; -- numeric
		inc r8
		sub sil, 48			; subtract 48 from ascii code to get pure digit value
		mul r9				; multiply by radix (10) ->
		add rax, rsi		; -> add the digit
		jmp .loop	
	.finish:
		mov rdx, r8
		cmp byte [rdi], 45
		jne end
		neg rax
		ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
	xor rcx, rcx 			; offset
	xor r8, r8				; auxiliary register (mov from mem to mem)
	call string_length 		; check for buffer-overflow
	cmp rax, rdx
	jle .loop
	xor rax, rax
	ret
	.loop:
		mov r8b, [rdi+rcx] 
		mov [rsi+rcx], r8b
		inc rcx
		cmp byte [rsi+rcx], 0
		jne .loop
	mov rax, rdx
	ret
