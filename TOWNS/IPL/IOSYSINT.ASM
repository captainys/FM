						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; IO.SYS Intercept
; Intercept IO.SYS jump to MSDOS.SYS
IOSYS_INTERCEPT			PROC
						; Do what's replaced by CALLF 8000:IOSYS_INTERCEPT >>
						INT     21H
						ADD     AX,0010H
						; Do what's replaced by CALLF 8000:IOSYS_INTERCEPT <<

						PUSHF
						PUSH	DS
						PUSH	ES
						PUSHA

						PUSH	CS
						POP		DS

						CLD


						CALL	UNPATCH_V21L20

						TEXTLOCATION	28H,00H
						MOV		SI,OFFSET IOSYS_INTERCEPTED_MSG
						CALL	PRINT_TALL

						CALL	DEMOSPLASH_MESSAGE

						CALL	DRAW_AOMORI

						; Turned out MSDOS.SYS is copied to the conventional memory, but not installed yet.
						; It is possible to patch at this time, but not doing it any more.

						; At this time, it is safe to use MALLOC
						CALC_YSSCSICD_ALLOC_SIZE
						MOV		AH,48H
						INT		21H
						JNC		MALLOCED_SPACE_FOR_YSSCSICD

						TEXTLOCATION	28H,01H
						MOV		SI,OFFSET CANNOT_MALLOC
						CALL	PRINT_TALL
						JMP		SHORT IOSYS_INTERCEPT_EXIT

MALLOCED_SPACE_FOR_YSSCSICD:
						; AX is the segment.
						; IO.SYS assumes that the PSP owner of the memory control block allocated
						; during the initialization is this segment.
						DEC		AX
						MOV		ES,AX
						INC		AX
						MOV		ES:[0001h],AX
						; Unless doing it, IO.SYS will go into infinite loop for searching last MCB.

						PREP_YSSCSICD_INSTALL
						CALL	DWORD PTR CS:[YSSCSICD_INSTALL_IP]

						PUSH	CS
						POP		DS
						TEXTLOCATION	28H,01H
						MOV		SI,OFFSET INSTALLED_HOOK_MSG
						CALL	PRINT_TALL

IOSYS_INTERCEPT_EXIT:
						POPA
						POP		ES
						POP		DS
						POPF

						RETF

IOSYS_INTERCEPT			ENDP

IOSYS_INTERCEPTED_MSG	DB		"INTERCEPTED IO.SYS.",0
INSTALLED_HOOK_MSG		DB		"INSTALLED INT 93H HOOK.",0
CANNOT_MALLOC			DB		"MALLOC FAILED, CANNOT INSTALL YSSCSICD",0
