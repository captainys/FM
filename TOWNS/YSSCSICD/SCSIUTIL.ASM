;/* ////////////////////////////////////////////////////////////
;
;File Name: SCSIUTIL.ASM
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



; HSG=60*MIN+75*SEC+FRM  ->  60 seconds/min,   75 frames/sec   -> 60*75 frames/min
; Input:
;	DX:AX	HSG
; Output:
;	DL		MIN
;	AH		SEC
;	AL		FRM
HSG2MSF					PROC
						PUSH	CX

						MOV		CX,60*75
						DIV		CX
						; AX minutes, DX sub-minute

						XOR		AH,AH
						PUSH	AX		; MIN in stack

						MOV		AX,DX
						XOR		DX,DX
						MOV		CX,75
						DIV		CX
						; AL seconds, DL frames

						MOV		AH,AL
						MOV		AL,DL

						POP		DX
						POP		CX
						RET
HSG2MSF					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HSG=60*MIN+75*SEC+FRM  ->  60 seconds/min,   75 frames/sec   -> 60*75 frames/min
; Input:
;	DL		MIN
;	AH		SEC
;	AL		FRM
; Output:
;	DH		0
;	DL		High-byte of HSG
;	AH		Mid-byte of HSG
;	AL		Low-byte of HSG

MSF2HSG					PROC
						PUSH	CX
						PUSH	BX

						XOR		DH,DH
						; DX=MIN
						PUSH	DX

						MOV		CL,AL
						XOR		CH,CH
						; CX=FRM

						MOV		AL,AH
						XOR		AH,AH
						; AX=SEC

						MOV		BX,75
						MUL		BX
						; AX=SEC*75

						ADD		CX,AX
						; CX=SEC*75+FRM

						POP		DX
						; DX=MIN
						MOV		AX,60*75
						MUL		DX

						ADD		AX,CX
						ADC		DX,0

						POP		BX
						POP		CX
						RET
MSF2HSG					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;   None
; Output
;   AL  FF:                   No CD-ROM drive found.
;       0 to 7(probably six): SCSI ID
SCAN_SCSI_CDROM			PROC

						PUSHF
						CLI
						MOV		AL,7

SCAN_SCSI_CDROM_LOOP:
						PUSH	AX

						MOV		DI,OFFSET MSG_SCANNING_SCSI_ID
						CALL	PRINT_CSTR
						CALL	PRINT_AL

						CALL	SCSI_INQUIRE

						MOV		DI,OFFSET MSG_SCSI_DEVICE_TYPE
						CALL	PRINT_CSTR
						MOV		AL,BYTE PTR [SCSI_DATA_BUF]
						CALL	PRINT_AL
						CALL	PRINT_CRLF

						POP		AX

						CMP		CH,0
						JNE		SCAN_SCSI_CDROM_NEXT

						CMP		BYTE PTR [SCSI_DATA_BUF],05H
						JE		SCAN_SCSI_CDROM_FOUND
						CMP		BYTE PTR [SCSI_DATA_BUF],04H
						JE		SCAN_SCSI_CDROM_FOUND

SCAN_SCSI_CDROM_NEXT:
						DEC		AL
						CMP		AL,0FFH
						JNE		SCAN_SCSI_CDROM_LOOP

SCAN_SCSI_CDROM_FOUND:

						POPF
						RET
SCAN_SCSI_CDROM			ENDP

MSG_SCANNING_SCSI_ID	DB		"TESTING SCSI-ID:",0
MSG_SCSI_DEVICE_TYPE	DB		"  TYPE:",0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
