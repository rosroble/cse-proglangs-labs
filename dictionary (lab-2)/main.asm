%include "words.inc"
%include "lib.inc"
%define BUFF_SIZE 256
%define DQ_SIZE 8

extern find_word


global _start

section .data

not_found:
	db "Key not found!", 0
buffer_overflow:
	db "Buffer read failure.", 0
string_buffer:
	times BUFF_SIZE db 0

section .text

; try to read string into buffer
; using read_word function from lib.inc
_start:
	xor rax, rax
	mov rdi, string_buffer
	mov rsi, BUFF_SIZE
	call read_word
	test rax, rax				; if read error is encountered -> rax=0
	jne .success_read_buffer
	mov rdi, buffer_overflow
	call print_err
	call print_newline
	call exit
; if succeed -> we have buffer address in rax
; and length of word in rdx	
.success_read_buffer:
	mov rdi, rax
	mov rsi, first
	push rdx					; we might need to know the length - save it
	call find_word
	test rax, rax				; if key hasn't been found rax=0
	jne .success_key_found		
	mov rdi, not_found
	call print_err
	call print_newline
	call exit	
.success_key_found:
	pop rdx						; pop the key-string length we saved before
	add rax, DQ_SIZE			; add DQ offset (pointer to the next element)
	add rax, rdx				; add key-string length
	add rax, 1					; add 1 for null-terminator 
	mov rdi, rax				; now rax points directly to the value string
	call print_string
	call print_newline
	call exit

print_err:
	xor rax, rax
	mov rsi, rdi
	call string_length
	mov rdx, rax
	mov rdi, 2
	mov rax, 1
	syscall
	ret
	
	
	

	
	