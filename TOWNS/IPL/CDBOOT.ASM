;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



BOOT_FROM_SCSI_CD		PROC

						CMP		BYTE PTR CS:[SCSI_ID_CDROM],0FFH
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

						CALL	PATCH_V21L20

						CALL	INJECT_YSSCSICD_INSTALL_CALLBACK
						JB		SHORT @f

						MOV		AX,0FFFFH	; Full RAM below 1MB
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

INJECT_YSSCSICD_INSTALL_CALLBACK	PROC
						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		CS:[IOSYS_ENTRY_CS],AX	; IO.SYS should start from this segment:0000.
						MOV		FS,AX
						CALL	FIND_JUMP_INSTRUCTION
						JB		SHORT INJECTION_POINT_NOT_FOUND	; Just keep CF=1 and return

						ADD 	SI,7	; Point to INT 21H

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

						TEXTLOCATION	01H,06H
						MOV		SI,OFFSET BOOT_SCSICD_FOUND_MSG
						CALL	PRINT_TALL

						POP		SI
						POP		FS

						MOV		AX,FS:[SI+1]
						MOV		CS:[IOSYS_RESUME_IP],AX
						MOV		AX,FS:[SI+3]
						MOV		CS:[IOSYS_RESUME_CS],AX

						MOV		BYTE PTR FS:[SI],9AH ; CALLF
						MOV		WORD PTR FS:[SI+1],OFFSET IOSYS_INTERCEPT
						MOV		FS:[SI+3],CS

						CLC
INJECTION_POINT_NOT_FOUND:
						RET

INJECT_YSSCSICD_INSTALL_CALLBACK	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



WAIT_SCSI_CD_READY		PROC

						TEXTLOCATION	00H,0AH
						MOV		SI,OFFSET WAIT_SCSI_CD_READY_MSG
						CALL	PRINT_TALL

@@:
						CALL	BUSY_WAIT_FFFFH

						MOV		CL,CS:[SCSI_ID_CDROM]
						CALL	SCSI_TEST_UNIT_READY
						AND		AH,AH
						JNE		@b

						TEXTLOCATION	00H,0AH
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
						JB		SHORT @f

						CMP		CL,4
						JB		SHORT @f
						CMP		CL,5
						JA		SHORT @f
						POP		AX	; Get CX value to AX

						XOR		CX,CX ; Fast-forward the counter to zero so that it breaks the loop.
						PUSH	CX
@@:
						POP		CX
						AND		CL,CL
						JE		ShORT @f
						DEC		CL
						JMP		FIND_LAST_SCSI_CD_LOOP
@@:
						CMP		AL,0FFH
						JE		SHORT @f
						PUSH	AX
						CALL	ITOX8
						MOV		[FIND_LAST_SCSI_CD_ID],AH
						MOV		[FIND_LAST_SCSI_CD_ID+1],AL
						TEXTLOCATION	01H,04H
						MOV		SI,OFFSET FIND_LAST_SCSI_CD_STR1
						CALL	PRINT_TALL
						POP		AX
						RET
@@:
						TEXTLOCATION	01H,04H
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
						JNE		SHORT @f

						CALL	SCSI_SENSE
@@:
						CALL	FIND_BIOS_DEBUG_OUT

						POP		EDX
						POP		ECX
						POP		EAX

						CMP		DWORD PTR FS:[0],4F494246H ; "FBIO"
   						JNE		SHORT @f
						CMP		BYTE PTR FS:[4],53H ; 'S'
						JE		FIND_FBIOS_SECTOR_FOUND
@@:
						ADD		EDX,1
						CMP		EDX,80	; Search up to this sector.
						JNE		FIND_FBIOS_SECTOR_LOOP
						TEXTLOCATION	01H,05H
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
						TEXTLOCATION	01H,05H
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
						JL		SHORT @f
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

; Pattern
; 8BD8                      MOV     BX,AX
; 83C310                    ADD     BX,10H
; B448                      MOV     AH,48H
; CD21                      INT     21H (DOS)         -> CALLF 8000:INJECT_YSSCSICD
; 051000                    ADD     AX,0010H          ->
; 2EA3????                  MOV     CS:[????],AX
; 8EC0                      MOV     ES,AX
; 33FF                      XOR     DI,DI

; +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F
; 8B D8 83 C3 10 B4 48 CD 21 05 10 00 2E A3 ?? ??
; 8E C0 33 FF

INT_21_AH_48_LEN	EQU	14
INT_21_AH_48_PTN	DB	08BH,0D8H,083H,0C3H,010H,0B4H,048H,0CDH,021H,005H,010H,000H,02EH,0A3H


; Input
;   FS    IO.SYS Start Segment
; Output
;   DS:SI Offset to the JMPF xxxx:0000
;   CF    Set if not found
FIND_JUMP_INSTRUCTION	PROC
						PUSH	DS
						PUSH	ES

						PUSH	FS
						POP		DS	; DS:SI  IO.SYS
						PUSH	CS
						POP		ES	; ES:DI  Pattern

						CLD

FIND_JUMP_INSTRUCTION_OUTER_LOOP:
						MOV		SI,0

FIND_JUMP_INSTRUCTION_INNER_LOOP:
						MOV		CX,INT_21_AH_48_LEN
						MOV		DI,OFFSET INT_21_AH_48_PTN
						PUSH	SI
						REPE	CMPSB
						POP		SI
						JNE		SHORT FIND_JUMP_INSTRUCTION_INNER_NEXT

						CMP		DWORD PTR [SI+010h],0FF33C08Eh
						JE		SHORT FIND_JUMP_INSTRUCTION_FOUND

FIND_JUMP_INSTRUCTION_INNER_NEXT:
						INC		SI
						CMP		SI,16
						JNE		FIND_JUMP_INSTRUCTION_INNER_LOOP

						MOV		SI,DS
						INC		SI
						MOV		DS,SI
						CMP		SI,04000h
						JB		FIND_JUMP_INSTRUCTION_OUTER_LOOP

						STC	; Not found
						JMP		SHORT FIND_JUMP_INSTRUCTION_EXIT

FIND_JUMP_INSTRUCTION_FOUND:
						CLC
						PUSH	DS
						POP		FS

FIND_JUMP_INSTRUCTION_EXIT:
						POP		ES
						POP		DS
						RET

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
						; YSSCSICD.SYS requires 6KB=01800H, or 0180H pages.
						MOV		BX,0180H
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


						MOV		ES,AX
						XOR		DI,DI

						MOV		DS,CS:[YSSCSICD_INSTALL_CS]
						XOR		SI,SI

						MOV		CX,1800H	; 6KB
						REP		MOVSB

						MOV		CS:[YSSCSICD_INSTALL_CS],ES

						MOV		AL,CS:[SCSI_ID_CDROM]

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

YSSCSICD_INSTALL_IP		DW		YSSCSICD_DIRECT_INSTALL
YSSCSICD_INSTALL_CS		DW		YSSCSICD_SEGMENT

IOSYS_RESUME_IP			DW		0
IOSYS_RESUME_CS			DW		0

IOSYS_INTERCEPTED_MSG	DB		"INTERCEPTED IO.SYS.",0
INSTALLED_HOOK_MSG		DB		"INSTALLED INT 93H HOOK.",0
CANNOT_MALLOC			DB		"MALLOC FAILED, CANNOT INSTALL YSSCSICD",0

SCSI_ID_CDROM			DB		0


IOSYS_INTERCEPT			ENDP
