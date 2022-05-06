; DS:0000h				Target Location
; DX					Target Length in number of 16-byte pages
; CX					Pattern Length
; ES:DI					Source Pattern
; ES:BX					Write Pattern
APPLY_PATCH				PROC

APPLY_PATCH_OUTSIDE_LOOP:
						XOR		SI,SI
APPLY_PATCH_INSIDE_LOOP:
						PUSH	CX
						PUSH	SI
						PUSH	DI
						REPE	CMPSB
						POP		DI
						POP		SI
						POP		CX
						JE		SHORT APPLY_PATCH_FOUND

						INC		SI
						CMP		SI,16
						JNE		APPLY_PATCH_INSIDE_LOOP

						MOV		AX,DS
						INC		AX
						MOV		DS,AX

						DEC		DX
						JNE		APPLY_PATCH_OUTSIDE_LOOP

						JMP		SHORT APPLY_PATCH_EXIT

APPLY_PATCH_FOUND:
						PUSH	DS
						PUSH	ES
						POP		DS
						POP		ES

						MOV		DI,SI  ; DS:SI becomes destination ES:DI
						MOV		SI,BX  ; ES:BX becomes source DS:SI

						REP		MOVSB

APPLY_PATCH_EXIT:

						RET

APPLY_PATCH				ENDP



; CX					Pattern Length
; CS:DI					Source Pattern
; CS:BX					Write Pattern
PATCH_IOSYS				PROC
						; DS:0000h				Target Location
						; DX					Target Length in number of 16-byte pages
						; CX					Pattern Length
						; ES:DI					Source Pattern
						; ES:BX					Write Pattern
						MOV		AX,0040H
						MOV		DS,AX			; Target 0040:0000
						MOV		DX,2000H		; 16 times 2000h = 128KB target size
						PUSH	CS
						POP		ES
						CALL	APPLY_PATCH
						RET
PATCH_IOSYS				ENDP



; 75h JNE -> EBh JMP
IO_SYS_ICM_BUG			DB		0BAh,08Ah,004h,0ECh,0A8h,006h,075h,044h,060h,0BBh,000h,0C0h
IO_SYS_ICM_NOBUG		DB		0BAh,08Ah,004h,0ECh,0A8h,006h,0EBh,044h,060h,0BBh,000h,0C0h


; Force boot-time console to use 31KHz mode.
CRTC_31K:				DW	0060H,02C0H,0000H,0000H,031FH,0000H,0004H,0000H
						DW	0419H,008AH,030AH,008AH,030AH,0046H,0406H,0046H
						DW	0406H,0000H,008AH,0000H,0050H,0000H,008AH,0000H
						DW	0080H,0058H,0001H,0000H,801FH,0002H,0000H,0192H
CRTC_24K:				DW	0040H,0320H,0000H,0000H,035FH,0000H,0010H,0000H
						DW	036FH,009CH,031CH,009CH,031CH,0040H,0360H,0040H
						DW	0360H,0000H,009CH,0000H,0050H,0000H,009CH,0000H
						DW	0080H,004AH,0001H,0000H,001FH,0003H,0000H,0150H




; IO.SYS of Towns OS V2.1L20 is bugged and it crashes if an IC memory card is inserted.
; It needs to bypass IC Memory-Card check on INT 93H AX=0240H, otherwise it won't
; read from OS-ROM.  It tries to load from IC Memory Card.  (Was it intentional?)
; To make it start TownsO OS V2.1L20, IO.SYS can be patched before loading MSDOS.SYS,
; and restored after MSDOS.SYS is loaded.
; Turned out V1.1L30 as well.  Then probably V2.1L10, too.
PATCH_V21L20			PROC
						PUSH	DS
						PUSH	ES
						PUSHA
						MOV		CX,12
						MOV		DI,OFFSET IO_SYS_ICM_BUG
						MOV		BX,OFFSET IO_SYS_ICM_NOBUG
						CALL	PATCH_IOSYS
						MOV		CX,64
						MOV		DI,OFFSET CRTC_24K
						MOV		BX,OFFSET CRTC_31K
						CALL	PATCH_IOSYS
						POPA
						POP		ES
						POP		DS
						RET

PATCH_V21L20			ENDP

UNPATCH_V21L20			PROC
						PUSH	DS
						PUSH	ES
						PUSHA
						MOV		CX,12
						MOV		DI,OFFSET IO_SYS_ICM_NOBUG
						MOV		BX,OFFSET IO_SYS_ICM_BUG
						CALL	PATCH_IOSYS
						POPA
						POP		ES
						POP		DS
						RET
UNPATCH_V21L20			ENDP
