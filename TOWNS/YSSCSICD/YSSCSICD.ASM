;/* ////////////////////////////////////////////////////////////
;
;File Name: YSSCSICD.ASM
;Copyright (c) 2019 Soji Yamakawa.  All rights reserved.
;http://www.ysflight.com
;
;Redistribution and use in source and binary forms, with or without modification, 
;are permitted provided that the following conditions are met:
;
;1. Redistributions of source code must retain the above copyright notice, 
;   this list of conditions and the following disclaimer.
;
;2. Redistributions in binary form must reproduce the above copyright notice, 
;   this list of conditions and the following disclaimer in the documentation 
;   and/or other materials provided with the distribution.
;
;THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
;AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
;THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
;PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
;BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
;CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
;GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
;HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
;LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
;OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;//////////////////////////////////////////////////////////// */


; Standard Usage:
; DEVICE=YSSCSICD.SYS
;
; DEVICE=YSSCSICD.SYS /M
;   Enable messages from SYSINIT.EXE
;
; DEVICE=YSSCSICD.SYS /D:Q
;   Change system drive to Q
;
; Options are disabled now.
; DISABLED: Debug Message to Console:
; DISABLED: DEVICE=YSSCSICD.SYS /V
; DISABLED: 
; DISABLED: Debug Message to RS232C (19200bps, No Parity, 1 stop bit)
; DISABLED: DEVICE=YSSCSICD.SYS /R

						.386p

						ORG		0
						ASSUME	CS:DATA_CODE,DS:DATA_CODE

						INCLUDE	DEF.ASM

DATA_CODE				SEGMENT	USE16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEVHDR_LINKINFO			DD		-1
DEVHDR_ATTRIB			DW		0C800H	; Just took from CDISC2.SYS.  Maybe wrong.
DEVHDR_STRATEGY			DW		STRATEGY
DEVHDR_INTERRUPT		DW		INITIALIZE
; Careful about DEVHDR_NAME
; If it is same as the basename of the driver file, driver file gets write-protected.
; Or, this DEVHDR_NAME will become a virtual file in the DOS.
DEVHDR_NAME				DB		'CPTYS_CD'
DEVHDR_NOT_USED			DW		0
DEVHDR_DRIVE_LETTER		DB		0
DEVHDR_NUM_DRIVE		DB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PACKET					DD		0
NOT_USED_AT_THIS_TIME	DD		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						ORG		0020H
DIRECT_INSTALL			PROC	FAR
						JMP		INSTALL_HOOK_DIRECT
DIRECT_INSTALL			ENDP

STRATEGY				PROC	FAR
						MOV		WORD PTR CS:[PACKET],BX
						MOV		WORD PTR CS:[PACKET+2],ES
						RET
STRATEGY				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INTERRUPT				PROC	FAR
						PUSH	ES
						PUSH	DS
						PUSHA
						PUSHF

						LES		DI,CS:[PACKET]

						MOV		AL,ES:[DI+2]
						MOV		WORD PTR ES:[DI+3],0100H  ; Stat=DONE

						CMP		AL,13
						JE		SHORT CMD_OPEN

						CMP		AL,14
						JE		SHORT CMD_CLOSE

						AND		AL,0FEH
						CMP		AL,8
						JE		SHORT CMD_WRITE	; 8=Write  9=Write with verify

CMD_OPEN:
CMD_CLOSE:
CMD_EXIT:

						POPF
						POPA
						POP		DS
						POP		ES
						RET

CMD_WRITE:
						; Source https://www.drdobbs.com/writing-ms-dos-device-drivers/184402277?pgno=2
						; Source https://sites.google.com/site/pcdosretro/dostables
						MOV		CX,ES:[DI+18]	; Transfer Size
						LDS		SI,ES:[DI+14]	; Data Pointer
						MOV		BL,CS:[YSSCSICD_FLAGS]

CMD_WRITE_LOOP:
						LODSB
						CMP		AL,'V'
						JNE		SHORT @f
						OR		BL,YSSCSICD_FLAGS_DEBUG_CONSOLE
						JMP		SHORT CMD_WRITE_LOOP_NEXT
@@:
						CMP		AL,'v'
						JNE		SHORT @f
						AND		BL,NOT YSSCSICD_FLAGS_DEBUG_CONSOLE
						JMP		SHORT CMD_WRITE_LOOP_NEXT

@@:
						CMP		AL,'R'
						JNE		SHORT @f
						OR		BL,YSSCSICD_FLAGS_DEBUG_RS232C
						JMP		SHORT CMD_WRITE_LOOP_NEXT

@@:
						CMP		AL,'r'
						JNE		SHORT @f
						AND		BL,NOT YSSCSICD_FLAGS_DEBUG_RS232C
@@:
CMD_WRITE_LOOP_NEXT:
						LOOP	CMD_WRITE_LOOP

						MOV		CS:[YSSCSICD_FLAGS],BL

						JMP		CMD_EXIT

INTERRUPT				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; Memo to myself.
						; Avoid forward references as much as possible.
						; MASM writes extra NOPs for forward reference.

						INCLUDE	DATABUF.ASM

						INCLUDE SCSIUTIL.ASM
						INCLUDE	FMR_SCSI.ASM	; Keep FMR_SCSI.ASM before REDRFUNC.ASM
						INCLUDE	PRINT.ASM
						INCLUDE	RS232C.ASM
						INCLUDE FMR_TIMR.ASM
						INCLUDE	HOOKBIOS.ASM
						INCLUDE YS_EXT.ASM
						INCLUDE	REDRFUNC.ASM
						INCLUDE	..\SCSILIB\SCSIIO.ASM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SCSI_DATA_BUF:

; >>>>
; >>>>
; >>>>
; >>>>
; This area will be destroyed as soon as SCAN_SCSI_CDROM is called from INITIALIZE.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_OF_INIT			PROC

						LDS		DI,CS:[PACKET]
						MOV		WORD PTR [DI+3],0100H		; Status
						MOV		BYTE PTR [DI+13],0			; Number of Drives
						MOV		WORD PTR [DI+14],OFFSET DEVICE_END
						MOV		WORD PTR [DI+16],CS

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES

						MOV		DI,OFFSET MSG_INTRO
						CALL	PRINT_CSTR

						CALL	RECOGNIZE_COMMAND_PARAMETER

						CALL	INSTALL_HOOK

						MOV		WORD PTR CS:[DEVHDR_INTERRUPT],OFFSET INTERRUPT

						RET

INIT_OF_INIT			ENDP

; I realized that if you set /R option in the CONFIG.SYS and if you don't have an RS232C connected to a computer,
; The driver freezes just waiting for the TX Ready, which is dangerous.
; I disabled command parameter.  Instead you can use:
;   ECHO R > CPTYS_CD
; for enabling RS232C debugging,
;   ECHO V > CPTYS_CD
; for enabling Console debugging,
;   ECHO r > CPTYS_CD
; for disabling RS232C debugging, and
;   ECHO v > CPTYS_CD
; for disabling Console debugging.

RECOGNIZE_COMMAND_PARAMETER	PROC
						PUSH	ES
						PUSHA

						LES		SI,CS:[PACKET]	; ES:SI=Pointer to Command Struct
						LES		SI,ES:[SI+18]	; ES:SI=Command String

						; Debugging of CDSD.SYS told that the line may terminate by 00H, 0DH, or 0AH
						; Probably MS-DOS V5 and newer 0DH.  V3 (like TownsOS) 00.

						MOV		DH,0	; State 0:In Param   1:Out Param

						; Don't break ES, SI and DH in this loop.
CMD_PARAM_LOOP:
						MOV		AL,ES:[SI]
						CALL	IS_ZERO_0DH_OR_0AH
						JNC		@f
						JMP		CMD_PARAM_EXIT
@@:
						CMP		DH,0
						JNE		CMD_PARAM_IN_PARAM
						JMP		CMD_PARAM_OUT_PARAM

CMD_PARAM_IN_PARAM:
						; SYSINIT Message
						CMP		AL,'M'
						JNE		@f

						CALL	CMD_ENABLE_SYSINIT_MESSAGE
						XOR		DH,DH   ; State=Out Param
						JMP		CMD_PARAM_NEXT

@@:
						CMP		AL,'D'
						JNE		@f
						CALL	CMD_SET_SYSTEM_DRIVE
						XOR		DH,DH   ; State=Out Param
						JMP		CMD_PARAM_NEXT

@@:
						PUSH	ES
						PUSH	DX
						PUSH	SI
						LEA		DI,[MSG_ERR_PARAM]
						CALL	PRINT_CSTR
						CALL	PUTC
						CALL	PRINT_CRLF
						POP		SI
						POP		DX
						POP		ES
						XOR		DH,DH

						JMP		CMD_PARAM_NEXT


CMD_PARAM_OUT_PARAM:
						CMP		AL,'/'
						JNE		CMD_PARAM_NEXT
						MOV		DH,1

CMD_PARAM_NEXT:
						INC		SI
						JMP		CMD_PARAM_LOOP
CMD_PARAM_EXIT:


						POPA
						POP		ES
						RET

IS_ZERO_0DH_OR_0AH:
						CMP		AL,0
						JE		@f
						CMP		AL,0DH
						JE		@f
						CMP		AL,0AH
						JE		@f
						CLC
						RET
@@:
						STC
						RET



CMD_ENABLE_SYSINIT_MESSAGE:
						MOV		AL,'R'
						MOV		DX,3A34H
						OUT		DX,AL

						MOV		AL,'A'
						MOV		DX,3A36H
						OUT		DX,AL

						LEA		DI,[MSG_ENABLE_SYSINIT_MSG]
						CALL	PRINT_CSTR

						RET


CMD_SET_SYSTEM_DRIVE:
						PUSH	SI
						PUSH	DX

						MOV		AL,BYTE PTR CS:[CMD_SYSDRV_LETTER]

						CMP		BYTE PTR ES:[SI+1],':'
						JNE		@f
						MOV		AL,ES:[SI+2]
@@:

						; Small letter?
						CMP		AL,'a'
						JB		@f
						CMP		AL,'z'
						JA		@f
						; Need capitalize
						ADD		AL,'A'-'a'
@@:

						CMP		AL,'A'
						JB		CMD_SYSDRV_BAD_DRIVE_LETTER
						CMP		AL,'Z'
						JA		CMD_SYSDRV_BAD_DRIVE_LETTER

						MOV		BYTE PTR CS:[CMD_SYSDRV_LETTER],AL
						LEA		DI,[MSG_SYSDRV]
						CALL	PRINT_CSTR

						MOV		BL,CS:[CMD_SYSDRV_LETTER]
						SUB		BL,'A'
						AND		BL,1FH
						SHL		BL,2

						MOV		DX,3C32H
						IN		AL,DX

						AND		AL,083H
						OR		AL,BL

						OUT		DX,AL

CMD_SET_SYSTEM_DRIVE_EXIT:
						POP		DX
						POP		SI
						RET

CMD_SYSDRV_BAD_DRIVE_LETTER:
						LEA		DI,[MSG_SYSDRV_BADDRV]
						CALL	PRINT_CSTR
						JMP		CMD_SET_SYSTEM_DRIVE_EXIT

RECOGNIZE_COMMAND_PARAMETER	ENDP

						INCLUDE	HOOKINST.ASM

MSG_INTRO				DB		"YS SCSI BIOS REDIRECTOR",0DH,0AH
						DB		"Ver 0.97 2022/04/27",0DH,0AH
						DB		"By CaptainYS (http://www.ysflight.com)",0DH,0AH,0
MSG_ERR_PARAM			DB		"UNRECOGNIZED COMMAND OPTION:",0

MSG_SYSDRV				DB		"SET SYSTEM DRIVE TO ["
CMD_SYSDRV_LETTER		DB		'Q'
						DB		']',0DH,0AH,0

MSG_SYSDRV_BADDRV		DB		"BAD DRIVE LETTER",0DH,0AH,0

MSG_ENABLE_SYSINIT_MSG	DB		"ENABLED SYSINIT.EXE MESSAGES",0DH,0AH,0

; This area will be destroyed as soon as SCAN_SCSI_CDROM is called from INITIALIZE.
; <<<<
; <<<<
; <<<<
; <<<<

DESTROYED_ON_INSTALLATION_END:
						DB		SCSI_DATA_BUF_LENGTH-(DESTROYED_ON_INSTALLATION_END-SCSI_DATA_BUF) dup(077h)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEVICE_END				DB		'DEVICE END',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INITIALIZE				PROC	FAR
						PUSH	ES
						PUSH	DS
						PUSHA

						CALL	INIT_OF_INIT

						CALL	SCAN_SCSI_CDROM
						MOV		BYTE PTR [YSSCSICD_SCSI_ID],AL
						CMP		AL,07H
						JA		SHORT INIT_SCSI_NOT_FOUND

						MOV		DI,OFFSET MSG_FOUND_CDROM_AT
						CALL	PRINT_CSTR
						CALL	PRINT_AL
						JMP		SHORT INIT_SCSI_SCAN_DONE

INIT_SCSI_NOT_FOUND:
						MOV		DI,OFFSET MSG_CDROM_NOT_FOUND
						CALL	PRINT_CSTR
INIT_SCSI_SCAN_DONE:
						CALL	PRINT_CRLF

						POPA
						POP		DS
						POP		ES
						RET

INITIALIZE				ENDP

MSG_FOUND_CDROM_AT		DB		"Found CD-ROM Drive SCSI-ID:",0
MSG_CDROM_NOT_FOUND		DB		"SCSI CD-ROM Drive not found.",0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DATA_CODE				ENDS

						END
