%define NEXT_NODE 0					; last dictionary element points to null
%macro colon 2
	
	%ifid %2						; verify 2nd argument is an identifier			
		%2: dq NEXT_NODE			; store a pointer to the next (actually - previous) node
		%define NEXT_NODE %2		; define this label as a pointer for the next (previous) dictionary element
	%else
		%fatal "arg2: label identifier expected."
	%endif

	%ifstr %1						; verify 1st argument is a string
		db %1, 0					; create a null-terminated key string
	%else
		%fatal "arg1: string expected as a key value"
	%endif

%endmacro 
