;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



BOOT_FROM_SCSI_CD		PROC

						CALL	LISTSCSI
						CALL	FIND_LAST_SCSI_CD
						MOV		CS:[SCSI_ID_CDROM],AL
						CMP		AL,0FFH
						JE		@f

						CALL	WAIT_SCSI_CD_READY

						MOV		CL,CS:[SCSI_ID_CDROM]
						PUSH	CX
						CALL	FIND_FBIOS_SECTOR
						POP		CX
						JB		@f

						; CL=SCSI ID
						; EAX=Sector where FBIOS is written
						MOV		EDX,EAX
						MOV		BX,64
						MOV		EDI,0400H
						CALL	SCSI_READ_SECTOR
						JB		@f

						PUSH	DS
						PUSH	SI
						CALL	PATCH_V21L20
						POP		SI
						POP		DS

						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		FS,AX
						CALL	FIND_JUMP_INSTRUCTION
						JB		@f

						PUSH	FS
						PUSH	SI

						MOV		BP,SP
						MOV		AL,[BP+2]  ; Low Byte FS
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+16],AX

						MOV		AL,[BP+3]  ; High Byte FS
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+14],AX

						MOV		AL,[BP]  ; Low Byte SI
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+21],AX

						MOV		AL,[BP+1]  ; High Byte SI
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+19],AX

						MOV		AX,0106H
						CALL	LOCATE
						MOV		SI,OFFSET BOOT_SCSICD_FOUND_MSG
						CALL	PRINT_TALL

						POP		SI
						POP		FS

						MOV		AX,FS:[SI+1]
						MOV		CS:[IOSYS_RESUME_IP],AX
						MOV		AX,FS:[SI+3]
						MOV		CS:[IOSYS_RESUME_CS],AX

						MOV		WORD PTR FS:[SI+1],OFFSET IOSYS_INTERCEPT
						MOV		FS:[SI+3],CS

						MOV		CS:[IOSYS_ENTRY_CS],FS

						MOV		AX,0F7FFH	; Make IO.SYS think B0000H to BFFFFH block is inaccessible
						MOV		BX,0008H	; Pretend Booting from CD-ROM Drive
						MOV		CX,0280H
						MOV		DI,0
						MOV		DX,0

						; Cannot use direct jump because at the time of MOV CS:[IOSYS_ENTRY_CS]
						; This location is already in cache.
						; I'm not sure about the logic of MASM indirect jump, but if I make it
						; DWORD PTR it woks just fine.  
						; FWORD PTR looks to fetch 48 bytes, and doesn't work.
						; WORD PTR makes it near jump.
						JMP		DWORD PTR CS:[IOSYS_ENTRY_IP]

; As a reminder for myself, I first tried the following, which didn't work.
; 
; 				MOV		CS:[IOSYS_ENTRY_CS],FS
; 
; 				DB	0EAH   ; JMPF xxxx:xxxx
; 				DW	0
; IOSYS_ENTRY_CS	DW	0
; 
; However, when I copied FS to CS:[IOSYS_ENTRY_CS], the instruction was already
; in the 80486 cache.  Therefore, the jump destination segment was not updated.
; The code worked perfectly in Tsugaru, but it didn't work on actual TOWNS.
; It took a while to debug.

@@:
						
						RET
BOOT_FROM_SCSI_CD		ENDP

BOOT_SCSICD_ERROR_MSG	DB		"BOOT SEQUENCE FAILED",0
BOOT_SCSICD_FOUND_MSG	DB		"JMPF FOUND AT xxxx:xxxx",0

IOSYS_ENTRY_IP			DW		0000H ; Fixed
IOSYS_ENTRY_CS			DW		0000



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



WAIT_SCSI_CD_READY		PROC

						MOV		AX,000AH
						CALL	LOCATE
						MOV		SI,OFFSET WAIT_SCSI_CD_READY_MSG
						CALL	PRINT_TALL

@@:
						CALL	BUSY_WAIT_FFFFH

						MOV		CL,CS:[SCSI_ID_CDROM]
						CALL	SCSI_TEST_UNIT_READY
						AND		AH,AH
						JNE		@b

						MOV		AX,000AH
						CALL	LOCATE
						CALL	ERASE_LINE_TALL

						RET

WAIT_SCSI_CD_READY		ENDP

WAIT_SCSI_CD_READY_MSG	DB		"WAITING SCSI CD READY",0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;    DS=CS
LISTSCSI				PROC

						MOV			CL,0
@@:
						PUSH		CX

						POP			AX
						PUSH		AX
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [LISTSCSI_STR+5],AX

						POP			CX
						PUSH		CX
						CALL		IDENTIFY_SCSI_DEVICE

						MOV			AL,CL
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [LISTSCSI_STR+14],AX

						POP			AX
						PUSH		AX
						MOV			AH,1
						ADD			AL,10
						CALL		LOCATE
						MOV			SI,OFFSET LISTSCSI_STR
						CALL		PRINT_TALL

						POP			CX
						INC			CL
						CMP			CL,7
						JB			@b

						RET

LISTSCSI				ENDP

LISTSCSI_STR			DB			"SCSI:  H TYPE:  H",0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   DS=CS
; Output
;   AL  Last SCSI CD ID (0FFH means no CD)
FIND_LAST_SCSI_CD		PROC
						MOV		CL,6
						MOV		AL,0FFH
FIND_LAST_SCSI_CD_LOOP:
						PUSH	CX

						PUSH	AX
						CALL	IDENTIFY_SCSI_DEVICE
						POP		AX
						JB		@f

						CMP		CL,4
						JB		@f
						CMP		CL,5
						JA		@f
						POP		AX	; Get CX value to AX

						XOR		CX,CX ; Fast-forward the counter to zero so that it breaks the loop.
						PUSH	CX
@@:
						POP		CX
						AND		CL,CL
						JE		@f
						DEC		CL
						JMP		FIND_LAST_SCSI_CD_LOOP
@@:
						CMP		AL,0FFH
						JE		@f
						PUSH	AX
						CALL	ITOX8
						MOV		[FIND_LAST_SCSI_CD_ID],AH
						MOV		[FIND_LAST_SCSI_CD_ID+1],AL
						MOV		AX,0104H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_LAST_SCSI_CD_STR1
						CALL	PRINT_TALL
						POP		AX
						RET
@@:
						MOV		AX,0104H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_LAST_SCSI_CD_STR2
						CALL	PRINT_TALL
						MOV		AL,0FFH
						RET

FIND_LAST_SCSI_CD		ENDP

FIND_LAST_SCSI_CD_STR1	DB	"CD DRIVE FOUND AT SCSI ID="
FIND_LAST_SCSI_CD_ID	DB	0,0,'H',0
FIND_LAST_SCSI_CD_STR2	DB	"SCSI CD DRIVE NOT FOUND",0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   CL  SCSI ID
; Output
;   EAX Sector starting with "FBIOS"
;   CF  Set if not found
FIND_FBIOS_SECTOR		PROC

						MOV		AX,0040H
						MOV		FS,AX

						MOV		WORD PTR CS:[FIND_BIOS_DEBUG_POS],000AH

						MOV		EDX,8	; I think starting sector 10 is good enough, but just in case start from 8
FIND_FBIOS_SECTOR_LOOP:
						PUSH	EAX
						PUSH	ECX
						PUSH	EDX

						MOV		EDI,0400H
						MOV		BX,1
						CALL	SCSI_READ_SECTOR

						MOV		CS:[FIND_BIOS_SCSI_RETURN],AX
						MOV		AL,CS:[SCSI_PHASE_FLAG]
						MOV		CS:[FIND_BIOS_SCSI_PHASE_FLAG],AL
						CMP		AH,SCSI_STATUS_CHECK_CONDITION
						JNE		@f

						CALL	SCSI_SENSE
@@:
						CALL	FIND_BIOS_DEBUG_OUT

						POP		EDX
						POP		ECX
						POP		EAX

						CMP		DWORD PTR FS:[0],4F494246H ; "FBIO"
   						JNE		@f
						CMP		BYTE PTR FS:[4],53H ; 'S'
						JE		FIND_FBIOS_SECTOR_FOUND
@@:
						ADD		EDX,1
						CMP		EDX,80	; Search up to this sector.
						JNE		FIND_FBIOS_SECTOR_LOOP
						MOV		AX,0105H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_FBIOS_SECTOR_NOT_FOUND_MESSAGE
						CALL	PRINT_TALL
						STC
						RET

FIND_FBIOS_SECTOR_FOUND:
						MOV		EAX,EDX
						PUSH	EAX
						CALL	ITOX8
						XCHG	AH,AL
						MOV		WORD PTR [FIND_FBIOS_SECTOR_FOUND_MESSAGE+30],AX
						MOV		AX,0105H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_FBIOS_SECTOR_FOUND_MESSAGE
						CALL	PRINT_TALL
						POP		EAX
						CLC
						RET

FIND_BIOS_DEBUG_OUT:
						PUSH	DS
						MOV		AL,BYTE PTR CS:[FIND_BIOS_SCSI_RETURN]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR CS:[FIND_BIOS_ERROR_MSG],AX

						MOV		AL,BYTE PTR CS:[FIND_BIOS_SCSI_RETURN+1]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR CS:[FIND_BIOS_ERROR_MSG+2],AX

						MOV		AL,CS:[FIND_BIOS_SCSI_PHASE_FLAG]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR CS:[FIND_BIOS_ERROR_MSG+4],AX

						MOV		AL,CS:[SCSI_DATABUF]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR CS:[FIND_BIOS_ERROR_MSG+6],AX


						MOV		AX,CS:[FIND_BIOS_DEBUG_POS]
						CALL	LOCATE
						MOV		SI,OFFSET FIND_BIOS_ERROR_MSG
						CALL	PRINT_TALL

						MOV		AX,CS:[FIND_BIOS_DEBUG_POS]
						ADD		AH,16
						CMP		AH,80
						JL		@f
						INC		AL
						XOR		AH,AH
@@:
						MOV		CS:[FIND_BIOS_DEBUG_POS],AX

						POP		DS
						RET


FIND_FBIOS_SECTOR_FOUND_MESSAGE		DB	"IO.SYS(FBIOS) FOUND AT SECTOR   H",0 ; 30,31
FIND_FBIOS_SECTOR_NOT_FOUND_MESSAGE		DB	"IO.SYS(FBIOS) NOT FOUND",0

FIND_BIOS_DEBUG_POS		DW		0
FIND_BIOS_SCSI_RETURN	DW		0
FIND_BIOS_SCSI_PHASE_FLAG	DB		0
FIND_BIOS_ERROR_MSG		DB		"00000000        ",0

FIND_FBIOS_SECTOR		ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   FS    IO.SYS Start Segment
; Output
;   SI    Offset to the JMPF xxxx:0000
;   CF    Set if not found
FIND_JUMP_INSTRUCTION	PROC
						MOV		SI,0

FIND_JUMP_INSTRUCTION_LOOP:
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		FIND_JUMP_INSTRUCTION_NEXT

						MOV		CX,10
						PUSH	SI
@@:
						ADD		SI,3
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		@f
						LOOP	@b

						ADD		SI,3
						MOV		AL,FS:[SI]
						CMP		AL,0EAH		; JMPF
						JNE		@f

						; Found it!
						ADD		SP,2
						JMP		FIND_JUMP_INSTRUCTION_FOUND

@@:
						POP		SI

FIND_JUMP_INSTRUCTION_NEXT:
						INC		SI
						CMP		SI,0FF00H	; Must not be that late in the segment
						JNE		FIND_JUMP_INSTRUCTION_LOOP
						STC
						RET

FIND_JUMP_INSTRUCTION_FOUND:
						CLC
						RET

; Return ZF=1 if AL==E8 or BE
E8_OR_BE:
						CMP		AL,0E8H	; CALL
						JE		@f
						CMP		AL,0BEH ; MOV SI,
@@:						RET


FIND_JUMP_INSTRUCTION	ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



BUSY_WAIT_FFFFH			PROC
						PUSH	CX
						MOV		CX,0FFFFH
@@:
						LOOP	@b
						POP		CX
						RET
BUSY_WAIT_FFFFH			ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Secondary Loader tells IO.SYS that memory B0000H to BFFFFH does not exist to protect YSSCSICD.SYS.
; However, it will set DOS's ENEMEM to B0000H, and 64KB is blocked just for 7KB YSSCSICD.SYS.
; To free up as much memory as possible, this procedure patches MSDOS.SYS so that ENDMEM will become YSSCSICD_SEGMENT (BA00H)
; This procedure first searches for MSDOS.SYS copy in the RAM, and then:
; (1) Writes YSSCSICD_SEGMENT to DOSSEG:[02F2H] (ENDMEM)
; (2) MOV CS:[02F2H],DX -> MOV DX,YSSCSICD_SEGMENT / NOP / NOP in MSINIT.
PATCH_MSDOS_SYS			PROC
						MOV		DX,0100H

PATCH_MSDOS_LOOP:
						MOV		ES,DX
						CMP		BYTE PTR ES:[0000h],0E9H	; JMP
						JNE		PATCH_MSDOS_LOOP_NEXT
						CMP		WORD PTR ES:[0001H],6A9EH	; 6AA1H
						JNE		PATCH_MSDOS_LOOP_NEXT

						CMP		BYTE PTR ES:[0006H],42H		; 'B'
						JNE		PATCH_MSDOS_LOOP_NEXT
						CMP		WORD PTR ES:[0007H],4755H	; 'UG'
						JNE		PATCH_MSDOS_LOOP_NEXT

						CMP		DWORD PTR ES:[6AA3H],0F216892EH	; MOV	CS:[02F2H],DX
						JNE		PATCH_MSDOS_LOOP_NEXT
						CMP		BYTE PTR ES:[6AA7H],02H
						JE		PATCH_MSDOS_FOUND
PATCH_MSDOS_LOOP_NEXT:
						INC		DX
						CMP		DX,6000H
						JNE		PATCH_MSDOS_LOOP
						CLC
						RET

PATCH_MSDOS_FOUND:
						; Yes, it is MSDOS.SYS V3.1
						MOV		WORD PTR ES:[02F2H],YSSCSICD_SEGMENT
						MOV		BYTE PTR ES:[6AA3H],0BAH	; MOV DX,imm
						MOV		WORD PTR ES:[6AA4H],YSSCSICD_SEGMENT
						MOV		WORD PTR ES:[6AA6H],9090H	; NOP NOP
						STC
						RET

PATCH_MSDOS_SYS			ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Intercept IO.SYS jump to MSDOS.SYS
IOSYS_INTERCEPT			PROC
						PUSHF
						PUSH	DS
						PUSH	ES
						PUSH	AX
						PUSH	BX
						PUSH	CX
						PUSH	DX
						PUSH	SI
						PUSH	DI
						PUSH	BP

						PUSH	CS
						POP		DS

						CLD


						PUSH	DS
						PUSH	SI
						CALL	UNPATCH_V21L20
						POP		SI
						POP		DS


						MOV		AX,2800H
						CALL	LOCATE
						MOV		SI,OFFSET IOSYS_INTERCEPTED_MSG
						CALL	PRINT_TALL

						CALL	DEMOSPLASH_MESSAGE

						CALL	DRAW_AOMORI

						; Turned out MSDOS.SYS is copied to the conventional memory, but not installed yet.
			; CALL	TSUGARU_DEBUG_BREAK

						MOV		AL,CS:[SCSI_ID_CDROM]

						CALL	DWORD PTR CS:[YSSCSICD_INSTALL_IP]

			; CALL	TSUGARU_DEBUG_BREAK

						MOV		AX,2801H
						CALL	LOCATE
						MOV		SI,OFFSET INSTALLED_HOOK_MSG
						CALL	PRINT_TALL

						CALL	PATCH_MSDOS_SYS
						JAE		MSDOS_SYS_NOT_FOUND

						MOV		AX,2802H
						CALL	LOCATE
						MOV		SI,OFFSET PATCHED_MSDOS_SYS
						CALL	PRINT_TALL

MSDOS_SYS_NOT_FOUND:
						POP		BP
						POP		DI
						POP		SI
						POP		DX
						POP		CX
						POP		BX
						POP		AX
						POP		ES
						POP		DS
						POPF

						JMP		DWORD PTR CS:[IOSYS_RESUME_IP]

YSSCSICD_INSTALL_IP		DW		YSSCSICD_DIRECT_INSTALL
YSSCSICD_INSTALL_CS		DW		YSSCSICD_SEGMENT

IOSYS_RESUME_IP			DW		0
IOSYS_RESUME_CS			DW		0

IOSYS_INTERCEPTED_MSG	DB		"INTERCEPTED IO.SYS.",0
INSTALLED_HOOK_MSG		DB		"INSTALLED INT 93H HOOK.",0
PATCHED_MSDOS_SYS		DB		"PATCHED MSDOS.SYS",0

SCSI_ID_CDROM			DB		0


IOSYS_INTERCEPT			ENDP



; IO.SYS of Towns OS V2.1L20 is bugged and it crashes if an IC memory card is inserted.
; It needs to bypass IC Memory-Card check on INT 93H AX=0240H, otherwise it won't
; read from OS-ROM.  It tries to load from IC Memory Card.  (Was it intentional?)
; To make it start TownsO OS V2.1L20, IO.SYS can be patched before loading MSDOS.SYS,
; and restored after MSDOS.SYS is loaded.
; Turned out V1.1L30 as well.  Then probably V2.1L10, too.
PATCH_V21L20			PROC

						MOV		SI,0040H	; Beginning IO.SYS
						MOV		DS,SI

PATCH_V21L20_OUTER_LOOP:
						XOR		SI,SI

PATCH_V21L20_INNER_LOOP:
						CMP		DWORD PTR DS:[SI  ],0EC048ABAh
						JNE		PATCH_V21L20_INNER_LOOP_NEXT
						CMP		DWORD PTR DS:[SI+4],0447506A8h
						JNE		PATCH_V21L20_INNER_LOOP_NEXT
						CMP		DWORD PTR DS:[SI+8],0C000BB60h
						JNE		PATCH_V21L20_INNER_LOOP_NEXT

						; Found
						MOV		BYTE PTR DS:[SI+6],0EBh	; JNE -> JMP
						RET

PATCH_V21L20_INNER_LOOP_NEXT:
						INC		SI
						CMP		SI,16
						JNE		PATCH_V21L20_INNER_LOOP

						MOV		SI,DS
						INC		SI
						MOV		DS,SI
						CMP		SI,1000h	; Scan first 64KB.
						JNE		PATCH_V21L20_OUTER_LOOP

						RET

PATCH_V21L20			ENDP


UNPATCH_V21L20			PROC
						MOV		SI,0040H	; Beginning IO.SYS
						MOV		DS,SI

UNPATCH_V21L20_OUTER_LOOP:
						XOR		SI,SI

UNPATCH_V21L20_INNER_LOOP:
						CMP		DWORD PTR DS:[SI  ],0EC048ABAh
						JNE		UNPATCH_V21L20_INNER_LOOP_NEXT
						CMP		DWORD PTR DS:[SI+4],044EB06A8h
						JNE		UNPATCH_V21L20_INNER_LOOP_NEXT
						CMP		DWORD PTR DS:[SI+8],0C000BB60h
						JNE		UNPATCH_V21L20_INNER_LOOP_NEXT

						; Found
						MOV		BYTE PTR DS:[SI+6],075h	; JMP -> JNE
						RET

UNPATCH_V21L20_INNER_LOOP_NEXT:
						INC		SI
						CMP		SI,16
						JNE		UNPATCH_V21L20_INNER_LOOP

						MOV		SI,DS
						INC		SI
						MOV		DS,SI
						CMP		SI,1000h	; Scan first 64KB.
						JNE		UNPATCH_V21L20_OUTER_LOOP

						RET

UNPATCH_V21L20			ENDP
