;/* ////////////////////////////////////////////////////////////
;
;File Name: REDRFUNC.ASM
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

;	BP+0    EFLAGS 
;	BP+2    AX 
;	BP+4    BX 
;	BP+6    CX 
;	BP+8    DX 
;	BP+10   BP 
;	BP+12   SI 
;	BP+14   DI 
;	BP+16   DS 
;	BP+18   ES

INCOMING_EFLAGS				EQU		0
INCOMING_AX					EQU		2
INCOMING_BX					EQU		4
INCOMING_CX					EQU		6
INCOMING_DX					EQU		8
INCOMING_BP					EQU		10
INCOMING_SI					EQU		12
INCOMING_DI					EQU		14
INCOMING_DS					EQU		16
INCOMING_ES					EQU		18

BIOSFLAG_MEDIA_CHANGE_CACHE		DB		0		; 0x564
BIOSFLAG_0X565					DB		0		; 0x566 Usage Unknown
BIOSFLAG_0X566					DB		0		; 0x566 Usage Unknown
BIOSFLAG_0X567					DB		0		; 0x567 Usage Unknown
BIOSFLAG_PAUSE_STATE			DB		0		; 0x568
BIOSCACHE_DRIVEMODE				DB		4		; Drive-mode cache

CDPLAY_INFO_CACHE				DB		6 dup(0)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Output
;   Carry Set if processed
;   Carry Clear if not processed
REDIRECT_CDROM_BIOSCALL	PROC
						PUSH	ES
						PUSH	DS
						PUSH	DI
						PUSH	SI
						PUSH	BP
						PUSH	DX
						PUSH	CX
						PUSH	BX
						PUSH	AX
						CLC
						PUSHF
						CLD
						MOV		BP,SP

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES


						; 00 to 05?
						CMP		AH,05H
						JA		SHORT @f
						MOVZX	DI,AH
						ADD		DI,DI
						CALL	WORD PTR CS:[REDIRECT_BIOS_CALLTABLE_00_05+DI]
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						; 50h to 58h?
						CMP		AH,50h
						JB		SHORT @f
						CMP		AH,58h
						JA		SHORT @f
						MOVZX	DI,AH
						SUB		DI,50h
						ADD		DI,DI
						CALL	WORD PTR CS:[REDIRECT_BIOS_CALLTABLE_50_58+DI]
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT

@@:
						CMP		AH,0EH
						JNE		SHORT @f
						CALL	CDROM_BIOS_0EH_TEST_UNIT_READY
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,0FH
						JNE		SHORT @f
						CALL	CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,15H
						JNE		SHORT @f
						CALL	CDROM_BIOS_15H_READ_SECTOR_MSF
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT

@@:

						CMP		AH,14H
						JE		SHORT REDIRECT_CDROM_BIOSCALL_IGNORE ; CDISC2.SYS suggests do nothing for this function
						CMP		AH,060H
						JE		REDIRECT_CDROM_BIOSCALL_IGNORE
						CMP		AH,061H
						JE		SHORT REDIRECT_CDROM_BIOSCALL_IGNORE
						CMP		AH,0FCH
						JE		SHORT REDIRECT_CDROM_BIOSCALL_IGNORE

						; Undefined Request
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_PARAMETER
						JMP		SHORT REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT

REDIRECT_CDROM_BIOSCALL_IGNORE:
						XOR		AH,AH

REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT:
						MOV		BYTE PTR [BP+INCOMING_AX+1],AH
						CMP		AH,80H
						JNE		SHORT REDIRECT_CDROM_BIOSCALL_EXIT
						MOV		WORD PTR [BP+INCOMING_CX],CX
REDIRECT_CDROM_BIOSCALL_EXIT:
						POPF
						POP		AX
						POP		BX
						POP		CX
						POP		DX
						POP		BP
						POP		SI
						POP		DI
						POP		DS
						POP		ES
						RET

REDIRECT_BIOS_CALLTABLE_00_05:
						DW	OFFSET CDROM_BIOS_00H_SET_DRIVE_MODE
						DW	OFFSET CDROM_BIOS_01H_GET_DRIVE_MODE
						DW	OFFSET CDROM_BIOS_02H_GET_DRIVE_STATUS
						DW	OFFSET CDROM_BIOS_03H_RESTORE
						DW	OFFSET CDROM_BIOS_PRETEND_NO_ERROR  ; CDISC2.SYS suggests do nothing for this function
						DW	OFFSET CDROM_BIOS_05H_READ_SECTOR_HSG

REDIRECT_BIOS_CALLTABLE_50_58:
						DW	OFFSET CDROM_BIOS_050H_START_PLAY
						DW	OFFSET CDROM_BIOS_051H_GET_PLAY_INFO
						DW	OFFSET CDROM_BIOS_052H_STOP_PLAY
						DW	OFFSET CDROM_BIOS_053H_GET_PLAY_STATE
						DW	OFFSET CDROM_BIOS_054H_GET_DISC_INFO_TOC
						DW	OFFSET CDROM_BIOS_055H_PAUSE
						DW	OFFSET CDROM_BIOS_056H_UNPAUSE
						DW	OFFSET CDROM_BIOS_057H_SET_ELEVOL
						DW	OFFSET CDROM_BIOS_058H_GET_ELEVOL



REDIRECT_CDROM_BIOSCALL	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_IS_SCSI_ERROR	PROC
						CALL	IS_SCSI_ERROR
						PUSHF
						CMP		AH,BIOSERR_HARDERROR
						JNE		SHORT @f
						CMP		CX,BIOSERR_DETAIL_MEDIACHANGED
						JNE		SHORT @f

						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],1
@@:

						POPF
						RET
CDROM_BIOS_IS_SCSI_ERROR	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_00H_SET_DRIVE_MODE	PROC
						CMP		DL,4
						JE		SHORT @f

						MOV		AH,BIOSERR_HARDERROR
						MOV		DX,BIOSERR_DETAIL_PARAMETER
						RET
@@:
						MOV		BYTE PTR [BIOSCACHE_DRIVEMODE],DL

CDROM_BIOS_PRETEND_NO_ERROR:			; <<  These 3 lines are used from outside this PROC.
						XOR		AH,AH	; <<  Keep it XOR AH,AH / RET
						RET				; << 

CDROM_BIOS_00H_SET_DRIVE_MODE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_01H_GET_DRIVE_MODE	PROC
						MOV		DL,BYTE PTR [BIOSCACHE_DRIVEMODE]
						MOV		BYTE PTR [BP+INCOMING_DX],DL
						JMP		SHORT CDROM_BIOS_PRETEND_NO_ERROR
						; This JMP saves one byte than XOR AH,AH / RET.
						; Now I see why IO.SYS was doing it everywhere.
CDROM_BIOS_01H_GET_DRIVE_MODE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_03H_RESTORE	PROC
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_RESTORE
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						RET
CDROM_BIOS_03H_RESTORE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_02H_GET_DRIVE_STATUS	PROC
						MOV		CL,0AAH		; Get min-max track
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READTOC
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JC		SHORT CDROM_BIOS_02H_RET	; Return what's returned by Read ToC

						MOVZX	DX,BYTE PTR [SCSI_DATA_BUF+9]	; MIN
						MOV		AX,WORD PTR [SCSI_DATA_BUF+10]	; SEC,FRM
						XCHG	AH,AL	; SCSI is big-endian.  Make it little-endian.

						CALL	MSF2HSG	; -> Max Sector is DX|AX

						MOV		[BP+INCOMING_BX],DX	; Return BX is HIWORD
						MOV		[BP+INCOMING_DX],AX	; Return DX is LOWORD

						MOV		AL,BYTE PTR [BIOSCACHE_DRIVEMODE]
						MOV		[BP+INCOMING_AX],AL
						XOR		AH,AH
CDROM_BIOS_02H_RET:
						RET
CDROM_BIOS_02H_GET_DRIVE_STATUS	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;   CH   0 -> BX is segment   FF -> BX is high word of physical address
;   CL|DX   HSG address
;   BX   Read-sector count
;   SI   Destination address high word (if CH==FF)
;   ES   Destination segment (if CH==0)
;   DI   Destination address or destination physical address low word
CDROM_BIOS_05H_READ_SECTOR_HSG	PROC
						MOV		DI,[BP+INCOMING_DI]

						CMP		CH,0FFH
						JE		CDROM_BIOS_READ_SECTOR_EX

						CMP		CH,0
						JE		SHORT @f

						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_PARAMETER
						RET
@@:
						PUSH	ES
						MOV		ES,[BP+INCOMING_DS]

						; At this line
						; ES:DI  Destination
						; BX     Read sector count
						; CL|DX  HSG address

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SECTOR_HSG
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f

						; Read all sectors.
						MOV		WORD PTR [BP+INCOMING_BX],0

@@:
						POP		ES
						RET
CDROM_BIOS_05H_READ_SECTOR_HSG	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; I don't know if 0EH is really Test Unit Ready, but it is called before all other commands.
; It explains if 0EH is Test Unit Ready.

; This function is called every time before file access.
; If something else has already consumed Media_Change of the drive state, directory cache
; has no way of knowing the CD has changed.  Therefore, if there is no error, check
;   BIOSFLAG_MEDIA_CHANGE_CACHE
; and if it is non-zero, return media change error.

CDROM_BIOS_0EH_TEST_UNIT_READY	PROC
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_TEST_UNIT_READY
						CALL	IS_SCSI_ERROR

						CMP		AH,BIOSERR_HARDERROR
						JE		SHORT CDROM_BIOS_0EH_HARDERR_FROM_DRIVE

						; Drive not reporting hard error.
						CMP		AH,0
						JNE		SHORT CDROM_BIOS_0EH_RET

						; Drive is not reporting an error.
						CMP		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
						JE		SHORT CDROM_BIOS_0EH_RET

						; Media_Change Cache is 1
						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_MEDIACHANGED
						RET

CDROM_BIOS_0EH_HARDERR_FROM_DRIVE:
						CMP		CX,BIOSERR_DETAIL_MEDIACHANGED
						JE		SHORT CDROM_BIOS_0EH_CLEAR_MEDIA_CHANGE_CACHE
						CMP		CX,BIOSERR_DETAIL_NOT_READY
						JNE		SHORT CDROM_BIOS_0EH_RET
CDROM_BIOS_0EH_CLEAR_MEDIA_CHANGE_CACHE:
						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
CDROM_BIOS_0EH_RET:
						RET

CDROM_BIOS_0EH_TEST_UNIT_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG		PROC
						XOR		AH,AH

						; Based on Disassembly of Towns OS V2.1 L31
						;If CL==5         <Poll [0x567]>
						;  DL=[0x567], [0x567] is reset to zero.
						CMP		CL,5
						JNE		SHORT @f
						XOR		DL,DL
						XCHG	DL,[BIOSFLAG_0X567]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:

						;If CL==0
						;  DL=[0x564]
						CMP		CL,0
						JNE		SHORT @f
						MOV		DL,[BIOSFLAG_MEDIA_CHANGE_CACHE]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;If CL==1
						;  [0x564]=DL
						;  [0x566]|=DL
						CMP		CL,1
						JNE		SHORT @f
						MOV		[BIOSFLAG_MEDIA_CHANGE_CACHE],DL
						OR		[BIOSFLAG_0X566],DL
						RET
@@:


						;If CL==2          <Poll [0x565]>
						;  DL=[0x565], [0x565] is reset to zero.
						CMP		CL,2
						JNE		SHORT @f
						XOR		DL,DL
						XCHG	[BIOSFLAG_0X565],DL
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;If CL==4
						;  [0x566]|=DL
						CMP		CL,4
						JNE		SHORT @f
						OR		[BIOSFLAG_0X566],DL
						RET
@@:


						;If CL==8          <Retrieve [0x568] Pause flag>
						;  DL=[0x568]
						CMP		CL,8
						JNE		SHORT @f
						MOV		DL,[BIOSFLAG_PAUSE_STATE]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;IF CL==16
						;  [0x568]=DL      <Set [0x568] Pause flag>
						;  DL=[0x568]
						CMP		CL,16
						JNE		SHORT @f
						MOV		[BIOSFLAG_PAUSE_STATE],DL
						RET
@@:

						MOV		AH,080H
						MOV		CX,2
						RET
CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_15H_READ_SECTOR_MSF	PROC
						CMP		CH,0FFH
						JE		CDROM_BIOS_READ_SECTOR_EX

						PUSH	AX

						MOV		AX,DX
						MOVZX	DX,CL  ; <-> Equiv MOV DL,CL / XOR DH,DH

						; DX|AX  MSF
						CALL	MSF2HSG
						; DX|AX  HSG

						; SetParm in READ.ASM@CDSD.SYS subtracting 150 from HSG after MSF2HSG.
						; Also https://www.staff.uni-mainz.de/tacke/scsi/SCSI2-14.html
						; logical block address zero shall be assigned to the block at MSF address 00/02/00

						; Looks like I need to subtract 150 (2 seconds)
						SUB		AX,150
						SBB		DX,0

						MOV		CL,DL
						MOV		DX,AX

						POP		AX

						JMP		CDROM_BIOS_05H_READ_SECTOR_HSG
CDROM_BIOS_15H_READ_SECTOR_MSF	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_050H_START_PLAY		PROC
						CMP		CH,0
						JE		SHORT @f
						CMP		CH,0FEH
						JAE		SHORT @f	; 0FEh or 0FFh

						; Parameter Error
						MOV		AH,080H
						MOV		CX,2
						MOV		CS:[DEBUG_REDIR_SUBSTEP],'a'
						RET
@@:
						; Cache first, and use cache for SCSI command >>
						; DOS Extender Call Back may overwrite the Protected-Mode shared buffer.
						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						MOV		CX,ES:[DI]
						MOV		WORD PTR CS:[CDPLAY_INFO_CACHE],CX   ; CS is supposed to be same as DS though.
						MOV		CX,ES:[DI+2]
						MOV		WORD PTR CS:[CDPLAY_INFO_CACHE+2],CX
						MOV		CX,ES:[DI+4]
						MOV		WORD PTR CS:[CDPLAY_INFO_CACHE+4],CX
						; Cache first <<

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f			; Jump if no SCSI error
						MOV		CS:[DEBUG_REDIR_SUBSTEP],'b'
						RET
@@:

						MOV		AL,[SCSI_DATA_BUF+1]
						CMP		AL,11H ; 11H=PLAYING
						JNE		SHORT @f			; Jump if not playing
						MOV		AH,10H
						MOV		CS:[DEBUG_REDIR_SUBSTEP],'c'
						RET
@@:

						CALL	ENABLE_LINE_IN

						PUSH	CS	; MOV		CX,CS
						POP		ES	; MOV		ES,CX
						MOV		DI,OFFSET CDPLAY_INFO_CACHE
						MOV		AL,[YSSCSICD_SCSI_ID]

						CALL	SCSI_START_PLAY
						CALL	CDROM_BIOS_IS_SCSI_ERROR

						MOV		CS:[DEBUG_REDIR_SUBSTEP],'d'

						RET

CDROM_BIOS_050H_START_PLAY		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_051H_GET_PLAY_INFO	PROC
						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						PUSH	CS
						POP		DS
						MOV		SI,OFFSET CDPLAY_INFO_CACHE
						MOVSD
						MOVSW

						XOR		AH,AH
						RET
CDROM_BIOS_051H_GET_PLAY_INFO	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_052H_STOP_PLAY		PROC
						CMP		CH,0FFH
						JE		CDROM_BIOS_PRETEND_NO_ERROR
						; SCSI2 does not support idle-time to auto stop.  Just ignore.


						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JC		SHORT CDROM_BIOS_052H_RET


						CMP		BYTE PTR [SCSI_DATA_BUF+1],11H ; 11H=PLAYING
						JNE		CDROM_BIOS_PRETEND_NO_ERROR ; Jump if not playing
						; If not playing, just return no error.


						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_STOP_PLAY
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JC		SHORT CDROM_BIOS_052H_RET

						; At least I can stop CD by sending RESTORE command.
						; But, I don't want my CD head to go back and forth when playing in random tracks.
						; I want it to directly move to the next track.
						; MOV		AL,[YSSCSICD_SCSI_ID]
						; CALL	SCSI_RESTORE
						; CALL	CDROM_BIOS_IS_SCSI_ERROR
CDROM_BIOS_052H_RET:
						RET
CDROM_BIOS_052H_STOP_PLAY		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_053H_GET_PLAY_STATE	PROC
						CMP		CH,0
						JE		SHORT @f
						MOV		AH,BIOSERR_HARDERROR		; AH=080H
						MOV		CX,BIOSERR_DETAIL_PARAMETER  ; CL=2
						RET
@@:

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JC		SHORT CDROM_BIOS_053H_EXIT


						; [SCSI_DATA_BUF+1]  Audio Status
						;   11H  Playing
						;   12H  Paused
						;   13H  Completed
						;   14H  Stopped due to error
						;   15H  No current audio status
						; [SCSI_DATA_BUF+6]  Track
						; [SCSI_DATA_BUF+7]  Index
						; [SCSI_DATA_BUF+8]  Absolute CD Addr MSB
						; [SCSI_DATA_BUF+9]  Absolute CD Addr
						; [SCSI_DATA_BUF+10]  Absolute CD Addr LSB
						; [SCSI_DATA_BUF+11]  Track relative CD Addr MSB
						; [SCSI_DATA_BUF+12]  Track relative CD Addr
						; [SCSI_DATA_BUF+13]  Track relative CD Addr LSB

						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						XOR		AH,AH
						CMP		BYTE PTR [SCSI_DATA_BUF+1],11H ; 11H=PLAYING
						JE		SHORT @f			; Jump if playing

						XOR		AX,AX
						XOR		CX,CX
						MOV		[BP+INCOMING_AX],AL ; Why did I do this?  Is it needed?
						RET

@@:
						MOV		AL,1	; AL=Playing or not playing

						MOV		[BIOSFLAG_PAUSE_STATE],AL

						MOV		BYTE PTR ES:[DI],0

						MOV		CH,[SCSI_DATA_BUF+6]
						MOV		ES:[DI+1],CH

						MOV		BYTE PTR ES:[DI+2],0

						; Offset 4+8,4+9,4+10,4+11.
						; Offset 12(=0), 13(=Min), 14(=Sec), 15(=Frm).
						MOV		CX,WORD PTR [SCSI_DATA_BUF+13]
						MOV		ES:[DI+3],CX		; Min, Sec
						MOVZX	CX,BYTE PTR [SCSI_DATA_BUF+15]
						MOV		ES:[DI+5],CX		; Frame

						; Offset 4+4,4+5,4+6,4+7
						; Offset 8(=0), 9(=Min), 10(=Sec), 11(=Frm)
						MOV		CX,WORD PTR [SCSI_DATA_BUF+9]
						MOV		ES:[DI+7],CX
						MOV		CL,[SCSI_DATA_BUF+11]
						MOV		ES:[DI+9],CL

						XOR		AH,AH
						XOR		CX,CX
						MOV		[BP+INCOMING_AX],AL ; Why did I do this?  Is it needed?
CDROM_BIOS_053H_EXIT:
						RET
CDROM_BIOS_053H_GET_PLAY_STATE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;   DS:DI  TOC buffer
CDROM_BIOS_054H_GET_DISC_INFO_TOC	PROC
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f			; Jump if no SCSI error
						RET
@@:

						MOV		AL,[SCSI_DATA_BUF+1]
						CMP		AL,11H ; 11H=PLAYING
						JNE		SHORT @f			; Jump if not playing
						MOV		AH,BIOSERR_ALREADY_PLAYING
						RET
@@:

						MOV		CL,0AAH		; Get min-max track
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READTOC
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f
						RET
@@:


						MOV		CL,[SCSI_DATA_BUF+2]	; First track
						MOV		CH,[SCSI_DATA_BUF+3]	; Last track

						MOV		ES,[BP+INCOMING_DS]
						MOV		SI,[BP+INCOMING_DI]

						MOV		BYTE PTR ES:[SI],0		; Tentatively no data/no audio
						MOV		ES:[SI+1],CX			; First/Last track


						; Volume size is also obtained from RedTOC in CDSD.SYS
						; VolSize calls DskInfo, which shoots RedTOC with CX=0,
						; RedTOC issues SCSI call READ TOC with Track=0AAH.
						; BL(Min), DH(Sec), DL(Frm) are taken from data buffer+9, 10, 11
						; Min, Sec, Frm are then converted to HSG and returned.

						MOV		DL,BYTE PTR [SCSI_DATA_BUF+9]
						MOV		AX,BYTE PTR [SCSI_DATA_BUF+10]
						; !CAUTION!  SCSI uses big-endian.  AL is HIBYTE(sec) and AH is LOBYTE(frm).

						; For unknown reason, CDSD.SYS seems to subtract 150 frames (2 seconds) from volume size.
						; Uncomment the following if it is correct.
						; But, to make it compatible with FM TOWNS CD-ROM BIOS, it shouldn't subtract 2 seconds apparently.
;						SUB		AL,2	; 2 seconds
;						JNC		SHORT @f
;						ADD		AL,60
;						DEC		DL
;@@:
						MOV		ES:[SI+3],DL
						MOV		ES:[SI+4],AX

						LEA		DI,[SI+6]
						MOV		DL,ES:[SI+1]

CDROM_BIOS_054H_TRACK_LOOP:
						PUSH	DI
						PUSH	DX

						MOV		CL,DL
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READTOC
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f

						POP		DX
						POP		DI
						RET
@@:
						;[Summary]
						;  [SCSI_DATA_BUF+5]==14H indicates it is a data track, audio track otherwise.
						;[Details]
						; From assembly code of CDSD.SYS
						; Indication of Data Track 41H is coming from 5th byte of data buffer in RedTOC:
						;	mov	cx,[si+5]		; Set ADR/Control
						;	xchg	ch,cl			; ch = ADR/CTL, cl = Track Address
						; And then rolled 4 times in AudTrk:
						;	rol	ch,1
						;	rol	ch,1
						;	rol	ch,1
						;	rol	ch,1
						; Which is copied to IOCTL communicatoin buffer +6:
						;	mov	es:[di+6],ch		; Control Information
						; Then CDISC2.SYS receives it in GetCDInfo:
						;		mov	ax, word ptr es:[si.I_CtrlInfo]
						;
						; Actual read from a CD data track (track 1):
						;+0+1+2+3+4+5
						;00520109001401000000020000000000
						;          ^^
						; Actual read from a CD audio track (track 2):
						;+0+1+2+3+4+5
						;004A0109001002000028060200000000
						;
						;Fifth byte of Read TOC (43H) return is described as:
						; ADR | Control
						; What's ADR and Control?  ADR is the type of information encoded in the Q sub-channel.  Control is the atribute of the track.
						;
						; According to https://www.staff.uni-mainz.de/tacke/scsi/SCSI2-14.html, Control bits are:
						;   Bit 0: Audio has pre-emphasis
						;   Bit 1: Digital copy permitted
						;   Bit 2: Is data track
						;   Bit 3: Four-channel audio
						;
						; Probably MSCDEX's ADR/Control byte has ADR and Control swapped from SCSI2 spec.

						POP		DX
						POP		DI

						MOV		AH,1  ; Tentatively audio
						MOV		AL,BYTE PTR [SCSI_DATA_BUF+5]
						CMP		AL,14H
						JNE		SHORT @f
						MOV		AH,2	; Data track
						OR		BYTE PTR [SCSI_DATA_BUF+9],80H
@@:
						OR		ES:[SI],AH

						MOV		AL,BYTE PTR [SCSI_DATA_BUF+9]
						MOV		ES:[DI],AL
						MOV		AX,WORD PTR [SCSI_DATA_BUF+10]
						MOV		ES:[DI+1],AX

						LEA		DI,[DI+3]

						INC		DL
						CMP		DL,ES:[SI+2]
						JBE		SHORT CDROM_BIOS_054H_TRACK_LOOP


						XOR		AH,AH
						RET
CDROM_BIOS_054H_GET_DISC_INFO_TOC	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Possible errors
;   02H Device Number Error
;   22H Already Paused
;   80H Hard Error

CDROM_BIOS_055H_PAUSE	PROC
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f
						RET
@@:
						; [SCSI_DATA_BUF+1]  Audio Status
						;   11H  Playing
						;   12H  Paused

						MOV		AL,BYTE PTR [SCSI_DATA_BUF+1]
						CMP		AL,12H
						JNE		SHORT @f
						MOV		AH,BIOSERR_ALREADY_PAUSED
						RET
@@:

						CMP		AL,11H
						JE		SHORT @f

						; Towns OS installer expects AH=0 if this command is called when CDDA has not started.
						XOR		AH,AH
						RET
@@:

						MOV		BYTE PTR [BIOSFLAG_PAUSE_STATE],1

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_PAUSE
						CALL	CDROM_BIOS_IS_SCSI_ERROR

						RET
CDROM_BIOS_055H_PAUSE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Possible errors
;   02H Device Number Error
;   10H Is Playing
;   23H Not paused
;   80H Hard Error

CDROM_BIOS_056H_UNPAUSE	PROC
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		SHORT @f
						RET
@@:
						; [SCSI_DATA_BUF+1]  Audio Status
						;   11H  Playing
						;   12H  Paused
						MOV		AH,BYTE PTR [SCSI_DATA_BUF+1]
						CMP		AH,11H
						JNE		SHORT @f
						MOV		AH,BIOSERR_ALREADY_PLAYING
						RET
@@:

						CMP		AH,12H
						JE		SHORT @f
						MOV		AH,BIOSERR_NOT_PAUSED
						RET
@@:

						MOV		BYTE PTR [BIOSFLAG_PAUSE_STATE],0

						CALL	ENABLE_LINE_IN

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_UNPAUSE
						CALL	CDROM_BIOS_IS_SCSI_ERROR

						RET
CDROM_BIOS_056H_UNPAUSE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unpublished function 57H Set Electric Volume
;   AH=057H
;   AL=0C0H
;   DL=0
;   DS:[DI]    Don't care
;   DS:[DI+1]  Left Volume (Unsigned char)
;   DS:[DI+2]  Don't care
;   DS:[DI+3]  Right Volume (Unsigned char)
;   DS:[DI+4]  Don't care
;   DS:[DI+5]  Don't care
;   DS:[DI+6]  Don't care
;   DS:[DI+7]  Don't care
; Just cache it so that when volume is requested, it can answer what's set.
CDROM_BIOS_057H_SET_ELEVOL	PROC
						PUSH	ES
						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						MOV		AL,ES:[DI+1]
						MOV		CS:[YSSCSICD_ELEVOL_LEFT],AL
						MOV		AL,ES:[DI+3]
						MOV		CS:[YSSCSICD_ELEVOL_RIGHT],AL

						POP		ES
						MOV		AH,0

						RET
CDROM_BIOS_057H_SET_ELEVOL	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unpublished function 57H Get Electric Volume
;   AH=057H
;   AL=0C0H
;   DL=0
; Return
;   DS:[DI]    0
;   DS:[DI+1]  Left Volume (Unsigned char)
;   DS:[DI+2]  1
;   DS:[DI+3]  Right Volume (Unsigned char)
;   DS:[DI+4]  2
;   DS:[DI+5]  Microphone Volume
;   DS:[DI+6]  3
;   DS:[DI+7]  Modem Volume
;
; Here's a problem.  I can return left and right volumes cached in the buffer.
; What about microphone and modem?  Those are set outside of the CD-ROM BIOS.
; If I return 0, subsequently this function may end up muting microphone and modem.
;
; On the other hand, if I end up maximizing the microphone volume, it could explode 
; the speaker by microphone feedback.
;
; .... I just make them zeros.

CDROM_BIOS_058H_GET_ELEVOL	PROC
						PUSH	ES

						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						MOV		BYTE PTR ES:[DI],0
						MOV		CS:[YSSCSICD_ELEVOL_LEFT],AL
						MOV		AL,ES:[DI+1]

						MOV		BYTE PTR ES:[DI+2],1
						MOV		CS:[YSSCSICD_ELEVOL_RIGHT],AL
						MOV		AL,ES:[DI+3]

						; MOV		BYTE PTR ES:[DI+4],02H
						; MOV		BYTE PTR ES:[DI+5],00H
						; MOV		BYTE PTR ES:[DI+6],03H
						; MOV		BYTE PTR ES:[DI+7],00H
						MOV		DWORD PTR [DI+4],00030002H

						POP		ES
						MOV		AH,0

						RET
CDROM_BIOS_058H_GET_ELEVOL	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_READ_SECTOR_EX	PROC
						PUSH	ECX
						PUSH	EDI

						; SI=PHYS_ADDR_HIGH
						; DI=PHYS_ADDR_LOW
						XCHG	SI,DI
						SHL		EDI,16
						MOV		DI,SI
						; Now EDI is the physical address



						CMP		AH,15H
						JNE		SHORT @f		; Jump if it is not Read Sector MSF

						; Convert MSF to HSG
						; BX is carrying number of sectors.  Don't break BX

						; Done with AL and AH
						; Input:
						;  CL=Min
						;  DH=Sec
						;  DL=Frm
						MOV		AX,DX
						MOV		DL,CL
						;	DL		MIN
						;	AH		SEC
						;	AL		FRM
						CALL	MSF2HSG
						; Looks like I need to subtract 150 (2 seconds)
						SUB		AX,150
						SBB		DX,0
						;	DH		0
						;	DL		High-byte of HSG
						;	AH		Mid-byte of HSG
						;	AL		Low-byte of HSG

						MOV		CX,DX	; Make it CX=High word, and DX=Low word
						MOV		DX,AX

						; Now all HSG,
@@:

						; CL		SCSI ID
						; DS:[SI]   SCSI Command
						; EDI       Data Return Buffer Physical Address

						; EDI is already set.

						PUSH	DS
						PUSH	CS
						POP		DS
						MOV		SI,OFFSET READ_SECTOR_EX_SCSI_CMD

						; LBA is 24 bit in TOWNS.
						MOV		[SI+3],CL
						MOV		[SI+4],DH
						MOV		[SI+5],DL

						MOV		[SI+7],BH	; Number of Sectors in Big Endian
						MOV		[SI+8],BL

						MOV		CL,CS:[YSSCSICD_SCSI_ID]
						CALL	SCSI_COMMAND
						POP		DS

						JB		SHORT @f

						MOV		WORD PTR [BP+INCOMING_BX],0
						MOV		AH,00H
						POP		EDI
						POP		ECX
						RET
@@:
						MOV		AH,80H
						MOV		WORD PTR [BP+INCOMING_CX],BIOSERR_DETAIL_HARDWARE
						POP		EDI
						POP		ECX
						MOV		CX,[BP+INCOMING_CX]
						RET

READ_SECTOR_EX_SCSI_CMD	DB		28H,0,0,0,0,0,0,0,0,0

CDROM_BIOS_READ_SECTOR_EX	ENDP



LINE_IN_VOLUME			EQU		3FH		; 3FH is maximum.

ENABLE_LINE_IN			PROC
						PUSH	DX
						PUSH	AX

						MOV		DX,04E1H	; LINE-IN Volume Control
						;IOWrite Port:000004E1 Value:04
						;IOWrite Port:000004E0 Value:3E
						;IOWrite Port:000004E1 Value:05
						;IOWrite Port:000004E0 Value:3E
						MOV		AL,4
						OUT		DX,AL

						DEC		DL
						MOV		AL,LINE_IN_VOLUME
						OUT		DX,AL

						INC		DL
						MOV		AL,5
						OUT		DX,AL

						DEC		DL
						MOV		AL,LINE_IN_VOLUME
						OUT		DX,AL

						POP		AX
						POP		DX
						RET
ENABLE_LINE_IN			ENDP
