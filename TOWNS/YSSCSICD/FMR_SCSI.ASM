;/* ////////////////////////////////////////////////////////////
;
;File Name: FMR_SCSI.ASM
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

BIOS_DIRECT_COMMAND			EQU		0FDH	; From CDSD.SYS.  How did this guy find out?



SCSI2_CMD_TEST_UNIT_READY	EQU		00H

SCSI2_CMD_SENSE				EQU		03H
SCSI2_CMD_SENSE_LENGTH		EQU		17

SCSI2_CMD_READ				EQU		08H ; Limited up to 255 blocks.  Use 28H instead.

SCSI2_CMD_INQUIRY			EQU		12H
SCSI2_CMD_INQUIRY_LENGTH	EQU		8

SCSI2_CMD_STOP				EQU		1BH	; Maybe I can also eject it.

SCSI2_CMD_READ_SECTOR_HSG	EQU		28H

SCSI2_CMD_SEEK				EQU		2BH

SCSI2_CMD_READ_SUBCHANNEL	EQU		42H

SCSI2_CMD_READTOC			EQU		43H

SCSI2_CMD_PLAY_AUDIO_MSF	EQU		47H

SCSI2_CMD_PAUSE_RESUME		EQU		4BH

SCSI2_CMD_STOP_PLAY			EQU		4EH	; Seems to be SCSI-3 command.



SCSI_ID					DB		0



BIOSERR_DEVICE_ID			EQU		02H
BIOSERR_ALREADY_PLAYING		EQU		10H
BIOSERR_ALREADY_PAUSED		EQU		22H
BIOSERR_NOT_PAUSED			EQU		23H
BIOSERR_HARDERROR			EQU		80H

BIOSERR_DETAIL_NOT_READY	EQU		1
BIOSERR_DETAIL_PARAMETER	EQU		2
BIOSERR_DETAIL_DISCONNECTED	EQU		4
BIOSERR_DETAIL_ERROR_CMD	EQU		8
BIOSERR_DETAIL_MEDIAERROR	EQU		16
BIOSERR_DETAIL_HARDWARE		EQU		32
BIOSERR_DETAIL_UNDEFINED	EQU		64
BIOSERR_DETAIL_MEDIACHANGED	EQU		128


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Make SCSI command buf
; Also tentatively set destination address to internal data buffer
MAKE_CMD_BUF			PROC

						PUSH	SI

						LEA		SI,[SCSI_DATA_BUF]
						MOV		WORD PTR [SCSI_DATABUF_PTR  ],SI
						MOV		WORD PTR [SCSI_DATABUF_PTR+2],CS

						MOV		[SCSI_CMD  ],AL
						MOV		BYTE PTR [SCSI_CMD+1],0
						MOV		WORD PTR [SCSI_CMD+2],0
						MOV		WORD PTR [SCSI_CMD+4],0
						MOV		WORD PTR [SCSI_CMD+6],0
						MOV		WORD PTR [SCSI_CMD+8],0
						MOV		WORD PTR [SCSI_CMD+10],0

						POP		SI

						RET
MAKE_CMD_BUF			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ISSUE_SCSI_CMD			PROC

; Input
;    AL   SCSI ID
;    ES:DI Destination
; Output
;    CH   0:No Error   Non-Zero:Real Bad Error
;    AH   SCSI Error Code, probably
;    AL   Still no idea what it is.
;
; If CH=0 and AH!=0 is returned, data buffer is sense data.
ISSUE_SCSI_CMD_ES_DI:
						MOV		WORD PTR [SCSI_DATABUF_PTR],DI
						MOV		WORD PTR [SCSI_DATABUF_PTR+2],ES


; Input
;    AL   SCSI ID
; Output
;    CH   0:No Error   Non-Zero:Real Bad Error
;    AH   SCSI Error Code, probably
;    AL   Still no idea what it is.
;
; If CH=0 and AH!=0 is returned, data buffer is sense data.
ISSUE_SCSI_CMD_OWN_BUFFER:
						MOV		CS:[SCSI_ID],AL
						CALL	FIRE_INT_93H

						; Observation suggests that CH=2, AH=0 also needs sense.
						; With more understanding of FM-R BIOS, AH=0 means the command was successful.
						; In this case, Disk BIOS successfully communicated with the SCSI device.
						; CH must be the status code returned from the SCSI device.
						; 2 means CHECK_CONDITION.
						CMP		CH,2
						JNE		@f
						CMP		AH,0
						JE		ISSUE_SCSI_CMD_NEED_SENSE
@@:

						CMP		CH,0
						JNE		ISSUE_SCSI_CMD_EXIT	; Jump if unrecoverable, like device doesn't exist.
						CMP		AH,0
						JE		ISSUE_SCSI_CMD_EXIT	; Jump if no error.

						; FM TOWNS BIOS disassembly strongly suggests that CH is the error code.
						; The meaning of CH is still unknown, but 0 means no error.  -> See above.  CH must be the STATUS code from the SCSI device.

ISSUE_SCSI_CMD_NEED_SENSE:
						PUSH	CX
						PUSH	AX

						MOV		AL,SCSI2_CMD_SENSE
						CALL	MAKE_CMD_BUF
						MOV		AL,SCSI2_CMD_SENSE_LENGTH
						MOV		[SCSI_CMD+4],AL
						MOV		AL,CS:[SCSI_ID]
						CALL	FIRE_INT_93H

						POP		CX
						POP		AX
ISSUE_SCSI_CMD_EXIT:

						RET

ISSUE_SCSI_CMD			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FIRE_INT_93H			PROC
; Using Disk BIOS Hidden Function
;						PUSH	SI
;						LEA		DI,[SCSI_DATABUF_PTR]
;						; LEA		SI,[SCSI_DATA_BUF]	; Probably SI doesn't matter in this function.
;						XOR		CX,CX			; CH LUN (Must be zero)
;						MOV		AH,BIOS_DIRECT_COMMAND
;						AND		AL,7
;						OR		AL,10110000b	; SCSI devices.  Confirmed FM TOWNS Technical Guidebook.
;						INT		93H
;						POP		SI
; Output  CH=2, AH=0  means nead sense
;         CH=0, AH=0  no error
;         CH!=0 && CH!=2  Unrecoverable error
; FIRE_INT_93H			ENDP


; Output
;    CH   0:No Error   Non-Zero:Real Bad Error
;    AH   SCSI Error Code, probably
;    AL   Still no idea what it is.
FIRE_INT_93H			PROC
						PUSH	BP
						MOV		BP,SP
						PUSH	AX	; [BP-2]
						PUSH	BX	; [BP-4]
						PUSH	CX	; [BP-6]
						PUSH	DX
						PUSH	SI
						PUSH	DI
						PUSH	DS

						ROL		ECX,16
						PUSH	CX
						ROL		EDI,16
						PUSH	DI

						ROL		ECX,16
						ROL		EDI,16

			; Use SCSI I/O
						; SCSI_COMMAND
						;Input
						; CL		SCSI ID
						; DS:[SI]   SCSI Command
						; EDI       Data Return Buffer Physical Address
						;Output
						; AH		0       : No Error
						;           80H     : Failed to talk to the SCSI device
						;			Non-Zero: SCSI Status
						; AL        SCSI Message
						; Carry     0       : No Error
						;           1       : Error

						MOVZX	ECX,WORD PTR [SCSI_DATABUF_PTR]
						MOVZX	EDI,WORD PTR [SCSI_DATABUF_PTR+2]
						SHL		EDI,4
						ADD		EDI,ECX

						MOV		CL,AL
						AND		CL,7

						LEA		SI,[SCSI_CMD]
						PUSH	CS
						POP		DS

						CALL	SCSI_COMMAND

						MOV		CX,AX
						AND		AH,0FDH		; 2 means CHECK_STATUS
						JE		FIRE_INT_93H_CHK_COND_OR_NOERR	; Jump if 0 or 2
						MOV		AH,080H
FIRE_INT_93H_CHK_COND_OR_NOERR:
						MOV		[BP-6],CX
						MOV		[BP-2+1],AH

						POP		DI
						ROL		EDI,16
						POP		CX
						ROL		ECX,16

						POP		DS
						POP		DI
						POP		SI
						POP		DX
						POP		CX	; [BP-6]
						POP		BX	; [BP-4]
						POP		AX	; [BP-2]
						POP		BP
						RET

FIRE_INT_93H			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CLEAR_DATA_BUF			PROC
						PUSH	ES
						PUSH	AX
						PUSH	CX
						PUSH	DI

						PUSH	CS
						POP		ES

						LEA		DI,[SCSI_DATA_BUF]
						MOV		AL,0
						MOV		CX,SCSI_DATA_BUF_LENGTH
						REP		STOSB
						POP		DI
						POP		CX
						POP		AX
						POP		ES
						RET
CLEAR_DATA_BUF			ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;   AH, CX    Returned from previous SCSI call
;   SCSI_DATA_BUF  Last reading
; Output
;   Carry Flag   On if it is a sense data
;   AH             0 if not a sense data
;                 80H if it is a sense data
;   CX            CD-ROM BIOS Error Code
IS_SCSI_ERROR			PROC
						CMP		CH,2
						JNE		@f
						CMP		AH,0
						JNE		@f
						JMP		IS_SCSI_ERROR_YES

@@:
						CMP		CH,0
						JE		@f
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_DISCONNECTED
						STC
						RET

@@:
						TEST	AH,7	; CDSD is ignoring bit 4 to 7.  Maybe it should be.
						JNE		@f
						MOV		AH,0
						MOV		CX,0
						CLC
						RET

@@:
IS_SCSI_ERROR_YES:
						MOV		AH,BIOSERR_HARDERROR

						MOV		AL,[SCSI_DATA_BUF+2]
						AND		AL,0FH

; Sense key
;  0 no sense
;  1 recovered error
;  2 not ready
;  3 media error
;  4 hardware error
;  5 illegal request
;  6 media changed/reset
;  7 data protected
;  8 blank check what is it?

						MOV		CX,BIOSERR_DETAIL_NOT_READY
						CMP		AL,2
						JE		@f
						MOV		CX,BIOSERR_DETAIL_MEDIAERROR
						CMP		AL,3
						JE		@f
						MOV		CX,BIOSERR_DETAIL_HARDWARE
						CMP		AL,4
						JE		@f
						MOV		CX,BIOSERR_DETAIL_PARAMETER
						CMP		AL,5
						JE		@f
						MOV		CX,BIOSERR_DETAIL_MEDIACHANGED
						CMP		AL,6
						JE		@f

						; If not know what to do, just say not ready :-P
						MOV		CX,BIOSERR_DETAIL_NOT_READY
@@:
						STC
						RET


IS_SCSI_ERROR			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;	AL		Play State
; Output
;   Carry   1:Playing   0:Not Playing
IS_AUDIO_STATE_PLAYING	PROC

						CMP		AL,11H
						JE		@f
						CMP		AL,12H
						JE		@f
						CLC
						RET
@@:
						STC
						RET
IS_AUDIO_STATE_PLAYING	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;    AL   SCSI ID
; Output
;    CH   0:No Error   Non-Zero:Real Bad Error
;    AH   SCSI Error Code, probably
;    AL   Still no idea what it is.
;
; If CH=0 and AH!=0 is returned, data buffer is sense data.
SCSI_INQUIRE			PROC
						PUSH	AX

						CALL	CLEAR_DATA_BUF

						MOV		AL,SCSI2_CMD_INQUIRY
						CALL	MAKE_CMD_BUF
						MOV		AL,SCSI2_CMD_INQUIRY_LENGTH
						MOV		[SCSI_CMD+4],AL

						POP		AX

						; For Inqury, it is used for identifying CD-ROM drive SCSI ID.
						; Do not want contaminate the data buffer by sense data if something gone wrong.
						; Therefore it uses FIRE_INT_93H instead of ISSUE_SCSI_CMD_OWN_BUFFER
						CALL	FIRE_INT_93H

						RET

SCSI_INQUIRE			ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
; AL SCSI ID
; ES:DI  Destination
; BX     Read sector count
; CL|DX  HSG address
SCSI_READ_SECTOR_HSG	PROC
						PUSH	AX

						MOV		AL,SCSI2_CMD_READ_SECTOR_HSG
						CALL	MAKE_CMD_BUF
						MOV		[SCSI_CMD+3],CL
						MOV		[SCSI_CMD+4],DH
						MOV		[SCSI_CMD+5],DL
						MOV		[SCSI_CMD+7],BH
						MOV		[SCSI_CMD+8],BL

						POP		AX

						CALL	ISSUE_SCSI_CMD_ES_DI

						RET

SCSI_READ_SECTOR_HSG	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;    AL   SCSI ID

SCSI_RESTORE			PROC
						PUSH	AX

						MOV		AL,SCSI2_CMD_SEEK
						CALL	MAKE_CMD_BUF
						; Keep all zero for seek to cylinder 0

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET

SCSI_RESTORE			ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;    AL   SCSI ID

SCSI_TEST_UNIT_READY	PROC
						PUSH	AX

						CALL	CLEAR_DATA_BUF

						MOV		AL,SCSI2_CMD_TEST_UNIT_READY
						CALL	MAKE_CMD_BUF

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET

SCSI_TEST_UNIT_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;    AL   SCSI ID
; Why is it called read sub channel?  It's just play state inqury, isn't it?
SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS	PROC
						PUSH	AX

						CALL	CLEAR_DATA_BUF

						MOV		AL,SCSI2_CMD_READ_SUBCHANNEL
						CALL	MAKE_CMD_BUF

						MOV		BYTE PTR [SCSI_CMD+1],02H  ; MSF bit
						MOV		BYTE PTR [SCSI_CMD+2],40H  ; Return SubQ info. What is it?
						MOV		BYTE PTR [SCSI_CMD+3],01H  ; Return format is CD-ROM Current Position
						MOV		BYTE PTR [SCSI_CMD+8],16;  
						; I have a feeling that the size [SCSI_CMD+8] needs to be 48, but
						; I just follow CDSD source.

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET

SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;    AL   	SCSI ID
;    ES:DI-	Play Info

SCSI_START_PLAY			PROC
						PUSH	AX

						MOV		AL,SCSI2_CMD_PLAY_AUDIO_MSF
						CALL	MAKE_CMD_BUF

						MOV		AX,ES:[DI]
						MOV		WORD PTR [SCSI_CMD+3],AX
						MOV		AX,ES:[DI+2]
						MOV		WORD PTR [SCSI_CMD+5],AX
						MOV		AX,ES:[DI+4]
						MOV		WORD PTR [SCSI_CMD+7],AX

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET
SCSI_START_PLAY			ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SCSI_STOP_PLAY			PROC
;x3_304_1997.pdf
; STOP PLAY/SCAN Command Descriptor BlockIssuing a STOP PLAY/SCAN command 
; while the drive is scanning shall result in continuation of the PLAYcommand.  Issuing  a  STOP  PLAY/SCAN  
; command  while  the  drive  is  paused  shall  stop  the  PLAY  command.
;
; Issuing a STOP PLAY/SCAN command when no play operation is in progress shall not be considered anerror.

						PUSH	AX

						; SCSI2_CMD_STOP_PLAY looks to be a SCSI-3 command.
						; The best thing I can do here is to PAUSE.
						; MOV		AL,SCSI2_CMD_STOP_PLAY
						MOV		AL,SCSI2_CMD_PAUSE_RESUME
						CALL	MAKE_CMD_BUF

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET
SCSI_STOP_PLAY			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input	AL SCSI ID
;       CL 0AAH    : Get min max track.
;       CL Non 0AAH: Get Track Info

; Observation:
;   Wrong parameter -> INT 93H AH=0FDH returned AX=0200, CH=0
;               AX=0200H seem to mean go get sense data?

; Redbook INT 93H AH=54H (pp.440) tells bit7 of starting position (Minute) should be on for a data track.
; Then, the question is how can I get a data track info?

SCSI_READTOC			PROC

						PUSH	AX

						CALL	CLEAR_DATA_BUF

						MOV		AL,SCSI2_CMD_READTOC
						CALL	MAKE_CMD_BUF
						MOV		BYTE PTR [SCSI_CMD+1],2	; CDSD.SYS tells MSF flag.
						MOV		BYTE PTR [SCSI_CMD+6],CL
						MOV		BYTE PTR [SCSI_CMD+8],12 ; CDSD.SYS tells allocation length.fs
						; MOV	BYTE PTR [SCSI_CMD+9],040H; CDSD.SYS tells it updates session???

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET

SCSI_READTOC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input	AL SCSI ID
SCSI_PAUSE				PROC

						PUSH	AX

						MOV		AL,SCSI2_CMD_PAUSE_RESUME
						CALL	MAKE_CMD_BUF

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET
SCSI_PAUSE				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input	AL SCSI ID
SCSI_UNPAUSE			PROC

						PUSH	AX

						MOV		AL,SCSI2_CMD_PAUSE_RESUME
						CALL	MAKE_CMD_BUF
						MOV		AL,01H
						MOV		BYTE PTR [SCSI_CMD+8],AL	; Resume flag

						POP		AX

						CALL	ISSUE_SCSI_CMD_OWN_BUFFER

						RET
SCSI_UNPAUSE			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
