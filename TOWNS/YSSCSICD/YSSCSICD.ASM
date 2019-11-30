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
; Debug Message to Console:
; DEVICE=YSSCSICD.SYS /V
;
; Debug Message to RS232C (19200bps, No Parity, 1 stop bit)
; DEVICE=YSSCSICD.SYS /R

						.186

						ORG		0
						ASSUME	CS:DATA_CODE,DS:DATA_CODE


DATA_CODE				SEGMENT

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
ORIGINAL_CDROM_BIOS		DD		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STRATEGY				PROC	FAR
						MOV		WORD PTR CS:[PACKET],BX
						MOV		WORD PTR CS:[PACKET+2],ES
						RET
STRATEGY				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INITIALIZE				PROC	FAR
						PUSH	ES
						PUSH	DS
						PUSHA

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES

						LEA		DI,[MSG_INTRO]
						CALL	PRINT_CSTR

						CALL	RECOGNIZE_COMMAND_PARAMETER

						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_CONSOLE
						LEA		DI,[MSG_DEBUG_OUT_CON]
						CALL	PRINT_CSTR
						JE		@f
@@:

						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						LEA		DI,[MSG_DEBUG_OUT_RS232C]
						CALL	PRINT_CSTR
						JE		@f
@@:

						CALL	INSTALL_HOOK


						MOV		WORD PTR CS:[DEVHDR_INTERRUPT],OFFSET INTERRUPT

						CALL	SCAN_SCSI_CDROM
						MOV		BYTE PTR [YSSCSICD_SCSI_ID],AL
						CMP		AL,07H
						JA		INIT_SCSI_NOT_FOUND

						LEA		DI,[MSG_FOUND_CDROM_AT]
						CALL	PRINT_CSTR
						CALL	PRINT_AL
						CALL	PRINT_CRLF
						JMP		INIT_SCSI_SCAN_DONE

INIT_SCSI_NOT_FOUND:
						LEA		DI,[MSG_CDROM_NOT_FOUND]
						CALL	PRINT_CSTR
INIT_SCSI_SCAN_DONE:


						LES		DI,CS:[PACKET]

						MOV		WORD PTR ES:[DI+3],0100H		; Status
						MOV		BYTE PTR ES:[DI+13],0			; Number of Drives
						MOV		WORD PTR ES:[DI+14],OFFSET DEVICE_END
						MOV		WORD PTR ES:[DI+16],CS

						POPA
						POP		DS
						POP		ES
						RET

INITIALIZE				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INTERRUPT				PROC	FAR
						RET
INTERRUPT				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


						INCLUDE	PRINT.ASM
						INCLUDE	RS232C.ASM
						INCLUDE FMR_TIMR.ASM
						INCLUDE	HOOKBIOS.ASM
						INCLUDE	REDRFUNC.ASM
						INCLUDE SCSIUTIL.ASM
						INCLUDE	FMR_SCSI.ASM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MSG_FOUND_CDROM_AT		DB		"Found CD-ROM Drive SCSI-ID:",0
MSG_CDROM_NOT_FOUND		DB		"SCSI CD-ROM Drive not found.",0DH,0AH,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						INCLUDE	DATABUF.ASM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEVICE_END				DB		'DEVICE END',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RECOGNIZE_COMMAND_PARAMETER	PROC
						PUSH	ES
						PUSHA

						LES		SI,CS:[PACKET]	; ES:SI=Pointer to Command Struct
						LES		SI,ES:[SI+18]	; ES:SI=Command String

						; Debugging of CDSD.SYS told that the line may terminate by 00H, 0DH, or 0AH
						; Probably MS-DOS V5 and newer 0DH.  V3 (like TownsOS) 00.

						MOV		DH,0	; State 0:In Param   1:Out Param
CMD_PARAM_LOOP:
						MOV		AL,ES:[SI]
						CALL	IS_ZERO_0DH_OR_0AH
						JNC		@f
						JMP		CMD_PARAM_EXIT
@@:
						CMP		DH,0
						JE		CMD_PARAM_OUT_PARAM

CMD_PARAM_IN_PARAM:
						CMP		AL,'V'
						JNE		@f
						OR		BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_CONSOLE
						XOR		DH,DH
						JMP		CMD_PARAM_NEXT
@@:
						CMP		AL,'R'
						JNE		@f
						OR		BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						XOR		DH,DH
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
						LEA		SI,[SI+1]
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

RECOGNIZE_COMMAND_PARAMETER	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MSG_INTRO				DB		"YS SCSI BIOS REDIRECTOR",0DH,0AH
						DB		"Ver 0.5 2019/11/27",0DH,0AH
						DB		"By CaptainYS (http://www.ysflight.com)",0DH,0AH,0
MSG_ERR_PARAM			DB		"UNRECOGNIZED COMMAND OPTION:",0
MSG_DEBUG_OUT_CON		DB		"DEBUG MESSAGE TO CONSOLE",0DH,0AH,0
MSG_DEBUG_OUT_RS232C	DB		"DEBUG MESSAGE TO RS232C",0DH,0AH,0

DATA_CODE				ENDS

						END
