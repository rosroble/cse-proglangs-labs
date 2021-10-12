%define DQ_SIZE 8

global find_word
extern string_length
extern string_equals

	


find_word:
	xor rax, rax
	mov r8, rdi					; pointer to a key searched
	mov r9, rsi					; pointer to a dictionary start address
	.loop:
		add r9, DQ_SIZE			; dictionary element starts with a dq pointer to the next element -> shift to get the key address
		mov rsi, r9 			; move this pointer to a key to rsi
		mov rdi, r8	
		push r8
		push r9
		call string_equals		; compare 2 keys
		pop r9
		pop r8
		cmp rax, 1
		je .finish
		mov r9, [r9 - DQ_SIZE]	; r9 - DQ_SIZE points to the pointer to the next element
		cmp r9, 0				; if element points to null and we still haven't found the match we failed
		je .fail
		jmp .loop
	.finish:	
		sub r9, DQ_SIZE			; sub what we added in .loop to point exactly at the beginning of the element
		mov rax, r9
		ret
	.fail:
		xor rax, rax
		ret
		
	
		