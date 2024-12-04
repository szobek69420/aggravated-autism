section .rodata
	print_float_format db "%.3f",10,0
	F0p1 dd 0.1
	
	ONE_PER_CLOCKS_PER_SECOND dd 0.000001
	
	kuba1_scale dd 1.0, 3.0, 1.0
	kuba2_position dd -1.0, -2.0, 0.0
	kuba3_position dd 1.0, -2.0, 0.0
	
section .bss
	window resb 60
	event_buffer resb 16
	camera resb 36
	kuba1 resb 84
	kuba2 resb 84
	kuba3 resb 84
	pplayer resb 4	
	pv_matrix resb 64
	
	lastFrame resb 4		;clock_t
	frameHelper resb 4		;clock_t
	deltaTime resb 4		;float
	
section .text
	extern clock
	extern memcpy

	extern window_create
	extern window_pendingEvent
	extern window_consumeEvent
	extern window_clearDrawBuffer
	extern window_showFrame
	extern window_onResize
	extern WindowResizeEvent

	extern player_init
	extern player_update
	
	extern camera_init
	extern camera_viewProjection
	extern camera_view
	
	extern input_init
	extern input_update
	extern input_processEvent
	
	extern renderable_render
	extern renderable_createKuba
	
	global _start
	
_start:
	push ebp
	mov ebp, esp
	
	finit
	
	;open window
	push window
	call window_create
	add esp, 4
	
	;init input
	call input_init
	
	;init camera
	push camera
	call camera_init
	add esp, 4
	
	;create player
	push camera
	call player_init
	mov dword[pplayer], eax
	add esp, 4
	
	;create kubak
	push kuba1
	call renderable_createKuba
	mov dword[esp], kuba2
	call renderable_createKuba
	mov dword[esp], kuba3
	call renderable_createKuba
	add esp, 4
	
	mov eax, kuba1
	add eax, 72
	push 12
	push kuba1_scale
	push eax
	call memcpy
	add esp, 12
	
	mov eax, kuba2
	add eax, 48
	push 12
	push kuba2_position
	push eax
	call memcpy
	add esp, 12
	
	mov eax, kuba3
	add eax, 48
	push 12
	push kuba3_position
	push eax
	call memcpy
	add esp, 12
	
	call clock
	mov dword[lastFrame], eax
	
_game_loop:
	;calculate fps start
	call clock
	mov dword[frameHelper], eax
	mov ecx, eax
	sub eax, dword[lastFrame]
	mov dword[lastFrame], ecx
	mov dword[frameHelper], eax
	fild dword[frameHelper]
	fld dword[ONE_PER_CLOCKS_PER_SECOND]
	fmulp
	fstp dword[deltaTime]
	;calculate fps end

	call input_update
	call processEvents
	
	push dword[deltaTime]
	push dword[pplayer]
	call player_update
	add esp, 8
	
	;clear buffer
	push 0xFF000000
	push window
	call window_clearDrawBuffer
	add esp, 8
	
	;calculate pv matrix
	push pv_matrix
	push camera
	call camera_viewProjection
	add esp, 8
	
	;render kuba
	push pv_matrix
	push window
	push kuba1
	call renderable_render
	mov dword[esp], kuba2
	call renderable_render
	mov dword[esp], kuba3
	call renderable_render
	add esp, 12
	
	;draw buffer
	push window
	call window_showFrame
	add esp, 4
	
	jmp _game_loop
	
	;call exit()
_game_exit:
	mov esp, ebp
	pop ebp
	
	xor ebx, ebx
	mov eax, 1
	int 0x80
	

processEvents:		;void processEvents(void) //processes the incoming events
	push ebp
	mov ebp, esp
	
_processEvent_loop_start:
	push window
	call window_pendingEvent
	add esp, 4
	cmp eax, 0
	je _processEvent_done
	
	push event_buffer
	push window
	call window_consumeEvent
	add esp, 8
	
	mov eax, dword[event_buffer]
	cmp eax, WindowResizeEvent
	jne _processEvent_not_window_event
	call onWindowResize
	
_processEvent_not_window_event:
	push event_buffer
	call input_processEvent
	add esp, 4
	
	jmp _processEvent_loop_start
	
_processEvent_done:
	mov esp, ebp
	pop ebp
	ret
	
onWindowResize:		;void onWindowResize(void)
	push ebp
	mov ebp, esp
	
	;calculate aspect ratio
	mov eax, event_buffer
	mov ecx, camera
	fild dword[eax+4]
	fild dword[eax+8]
	fdivp
	fstp dword[ecx+32]
	
	;update window
	mov eax, event_buffer
	mov ecx, window
	mov edx, dword[event_buffer+4]
	mov dword[ecx+40], edx
	mov edx, dword[event_buffer+8]
	mov dword[ecx+44], edx
	
	push window
	call window_onResize
	add esp, 4
	
	
	mov esp, ebp
	pop ebp
	ret
