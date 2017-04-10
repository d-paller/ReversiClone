include \masm32\include\masm32rt.inc
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
include logic.inc

.data

turnSyntax BYTE "x = 0, y = 0, turn = 1", 0Dh, 0Ah, 0

.code

logic:
JudgeInGrid PROC,
	x:DWORD, y:DWORD
;judge if (x, y) is in the grid
;if yes, eax = 1;
;else, eax = 0
	
	cmp x, 0 ; no negative positions possible
	jle elseifa

	cmp x, 7 ;outside the size of the grid (8)
	jg elseifa

	cmp y, 0 ; no negative positions possible
	jle elseifa

	cmp y, 7 ; outside the size of the grid (8)
	jg elseifa

	ifa: 
		mov eax, 0 ; coordinates valid
		jmp endifa
	elseifa:
		mov eax, 1 ; coordinates invalid
		jmp endifa
	endifa:

	ret
JudgeInGrid ENDP
;----------------------------------------------------
GetMapAddress PROC, 
	x:DWORD, y:DWORD, pmap:DWORD
;calculate the address of (x, y) in map
;the beginning address of map is pmap 
;return the result in eax

	push esi
	cmp x, 0 ; no negative positions possible
	jle elseifa

	cmp x, 7 ;outside the size of the grid (8)
	jg elseifa

	cmp y, 0 ; no negative positions possible
	jle elseifa

	cmp y, 7 ; outside the size of the grid (8)
	jg elseifa

	jmp ifa

	ifa:
		mov eax, pmap
		jmp endifa

	elseifa:
		mov eax, 8
		mul x
		add eax, y
		mov esi, 4
		mul esi
		add eax, pmap
		jmp endifa
	endifa:

	pop esi
	ret
GetMapAddress ENDP

;----------------------------------------------------
GetXYAddress PROC,
	mapAddress:DWORD, pmap:DWORD
;calculate the (x ,y) address of the point whose map address is mapAddress
;store x in eax, and y in edx
	mov eax, mapAddress
	sub eax, pmap
	cmp eax, 0
	jl ifa

	cmp eax, 252
	jg ifa

	jmp elsa

	ifa:
		mov eax, 0
		mov edx, 0
		ret
	elsea:
		mov edx, 0
		push esi 
		mov esi, 4
		div esi
		
		mov esi, 8
		mov edx, 0
		div esi
		pop esi
		ret
	endifa:
GetXYAddress ENDP

;used to check whether the step is valid, whose turn is equal to var turn
;have to check 8 different directions, which resutls in 8 checking functions

TryStep PROC USES esi edi edx ecx,
	x:DWORD, y:DWORD, pmap:DWORD, turn:DWORD

; if it is valid step, ebx = 1, else ebx = 0

	local opposite:DWORD
	local xystate:DWORD
	local delta_x:SDWORD
	local delta_y:SDWORD

	mov ebx, 3
	sub ebx, turn
	mov opposite, ebx

	INVOKE JudgeInGrid, x, y
	cmp eax, 0
	je ifa
	jmp endifa
	ifa:
		mov ebx, 0
		ret
	endifa:
	 
	INVOKE GetMapAddress, x, y, pmap
	mov esi, eax
	push ebx
	mov ebx, [esi]
	mov xystate, ebx
	pop ebx
	
	cmp xystate, 0
	jne ifa
	ifa:
		mov ebx, 0
		ret
	endifa:
	
	mov delta_x, -2
direction_loop_x:
	add delta_x, 1	
	cmp delta_x, 2
	je ifa
	jmp endifa
	ifa:
		mov ebx, 0
		ret
	endifa:
		mov delta_y, -2
direction_loop_y:
	add delta_y, 1	
	cmp delat_y, 2
	je ifa
	jmp endifa
	
	ifa:
		jmp direction_loop_x
	endifa:

	cmp delta_x, 0
	jne endifa

	cmp delta_y, 0
	jne endifa

	jmp ifa
	ifa:
		jmp direction_loop_y
	endifa:

	mov esi, x
	add esi, delta_x
	mov edi, y
	add edi, delta_y
	push esi
	push edi
	INVOKE GetMapAddress, esi, edi, pmap
	mov esi, eax
	push ebx
	mov ebx, [esi]
	mov xystate, ebx
	pop ebx
	pop edi
	pop esi

	
	mov ecx, xystate

	cmp ecx, turn
	jne ifa
	jmp direction_loop_y

	ifa:
		cmp xystate, 0
		je direction_loop_y
		jmp endifa
	endifa:

	mov esi, x
	mov edi, y
	mov eax, 1
	mov edx, 1
	add esi, delta_x
	add edi, delta_y
	
	doa:
		cmp edx, 1
		je whilea
		jmp endwhilea:
	whilea:
		INVOKE JudgeInGrid, esi, edi
		cmp eax, 0
		je ifa
		jmp endifa

		ifa:
			jmp direction_loop_y
		endifa:

		push esi
		push edi
		INVOKE GetMapAddress, esi, edi, pmap
		mov esi, eax
		push ebx
		mov ebx, [esi]
		mov xystate, ebx
		pop ebx
		pop edi
		pop esi
		
		mov ecx, xystate
		cmp ecx, opposite
		je ifa
		jmp elseifa

		ifa:
			mov edx, 1
			jmp endifa
		elseifa:
			mov edx, 0
			jmp endifa
		endifa:

		add esi, delta_x
		add edi, delta_y
		jmp doa

	endwhilea:

	mov ecx, xystate
	cmp edx, 0
	jne endifa

	cmp ecx, 0
	jne endifa
	ifa:
		mov ebx, 1
		ret
	endifa:

	jmp direction_loop_y
TryStep ENDP

CheckTurnEnd PROC, pmap: DWORD, turn: DWORD
;Check if the player has a valid grid to place their piece, retval in eax, 0 means not valid, 1 means calid

	local next_turn: DWORD
	pushad
	mov eax, turn
	mov ebx, 3
	sub ebx, eax
	mov next_turn, ebx
	mov esi, pmap
	mov ecx, 64
check_loop:
	INVOKE GetXYAddress, esi, pmap
	INVOKE TryStep, eax, edx, pmap, next_turn
	cmp ebx, 0
	je ifa
	jmp endifa

	ifa:
		popad
		mov eax, 1
		ret
	endifa:

	add esi, 4
	loop check_loop
	popad
	mov eax, 0
	ret
CheckTurnEnd ENDP

CheckEnd PROC USES ebx ecx edx esi, 
	pmap: DWORD, black_count: DWORD, white_count: DWORD
;check if the game is finished, retval in eax, 0 means not finished, 1 means finished
	mov ebx, black_count
	add ebx, white_count
	cmp ebx, 64 ; max number of squares in board
	je ifa
	jmp endifa

	ifa:
		mov eax, 1
		ret
	endifa:

	INVOKE CheckTurnEnd, pmap, 1
	cmp eax,1
	je ifa
	jmp endifa

	ifa:
		mov eax, 0
		ret

	endifa:

	INVOKE CheckTurnEnd, pmap, 2
	cmp eax, 1

	je ifa
	jmp endifa
	if:
		mov eax, 0
		ret

	endifa:

	mov eax, 1
	ret
CheckEnd ENDP

END logic
