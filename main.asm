TITLE Homework 6				(main.asm)

; Description: Reverses a 32-bit signed number
; Author: David Paller
; Revision date: 3/4/17

INCLUDE Irvine32.inc

.data
	enterMessage	BYTE	"Enter a 32-bit number or a 0 to exit: ", 0
	revMessage		BYTE	"The reversed number is: ",  0
	noParamMsg		BYTE	"No parameter supplied", 0
	newLine			BYTE	" ", 0ah, 0



Reverse macro number
	local label

	ifB    <&number> 
        mov edx, noParamMsg
		call WriteString
		CALL WaitMsg
        exitm
	endif

	push ebx				; Save ebx - for storing number
	push ecx				; Save ecx - for forloop counter
	mov ebx, &number		; move the number to reverse into ebx

	mov ecx, 0				; initialize counter with 0
	fora&label: cmp ecx, 32	; Loop through 32 times
		jl dofora&label
		jmp endfora&label
	dofora&label:
		shl ebx, 1			; Move the msb of the number into the CF
		RCR eax, 1			; move the CF into the msb of the reversed number
		inc ecx				; increment the counter
		jmp fora&label
	endfora&label:

	pop ecx					; restore registers
	pop ebx
endm


.code
main PROC
	
	startprog:							; Start of program
		mov edx, offset enterMessage
		call WriteString
		call ReadInt

		ifcont: cmp eax, 0				; If the number entered is 0, end
			je endprog

		Reverse eax
		mov edx, offset revMessage
		call WriteString
		call WriteInt
		mov edx, offset newline
		call WriteString

		Reverse eax
		mov edx, offset revMessage
		call WriteString
		call WriteInt
		mov edx, offset newline
		call WriteString

		jmp startprog					; jump to the start
	endprog:							; end of program
    exit
main ENDP

END main

