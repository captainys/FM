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
						MOV		BP,SP

						MOV		DX,CS
						MOV		DS,DX
						MOV		ES,DX
						MOV		DX,[BP+INCOMING_DX]


						CMP		AH,00H
						JNE		@f
						CALL	CDROM_BIOS_00H_SET_DRIVE_MODE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,01H
						JNE		@f
						CALL	CDROM_BIOS_01H_GET_DRIVE_MODE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,02H
						JNE		@f
						CALL	CDROM_BIOS_02H_GET_DRIVE_STATUS
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,03H
						JNE		@f
						CALL	CDROM_BIOS_03H_RESTORE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,04H
						JNE		@f
						CALL	CDROM_BIOS_PRETEND_NO_ERROR  ; CDISC2.SYS suggests do nothing for this function
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,05H
						JNE		@f
						CALL	CDROM_BIOS_05H_READ_SECTOR_HSG
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,0EH
						JNE		@f
						CALL	CDROM_BIOS_0EH_TEST_UNIT_READY
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,0FH
						JNE		@f
						CALL	CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,14H
						JNE		@f
						CALL	CDROM_BIOS_PRETEND_NO_ERROR  ; CDISC2.SYS suggests do nothing for this function
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,15H
						JNE		@f
						CALL	CDROM_BIOS_15H_READ_SECTOR_MSF
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,050H
						JNE		@f
						CALL	CDROM_BIOS_050H_START_PLAY
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,051H
						JNE		@f
						CALL	CDROM_BIOS_051H_GET_PLAY_INFO
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,052H
						JNE		@f
						CALL	CDROM_BIOS_052H_STOP_PLAY
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,053H
						JNE		@f
						CALL	CDROM_BIOS_053H_GET_PLAY_STATE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,054H
						JNE		@f
						CALL	CDROM_BIOS_054H_GET_DISC_INFO_TOC
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,055H
						JNE		@f
						CALL	CDROM_BIOS_055H_PAUSE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,056H
						JNE		@f
						CALL	CDROM_BIOS_056H_UNPAUSE
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,057H
						JNE		@f
						CALL	CDROM_BIOS_057H_SET_ELEVOL
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,058H
						JNE		@f
						CALL	CDROM_BIOS_058H_GET_ELEVOL
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,060H
						JNE		@f
						CALL	CDROM_BIOS_PRETEND_NO_ERROR
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,061H
						JNE		@f
						CALL	CDROM_BIOS_PRETEND_NO_ERROR
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						CMP		AH,0FCH
						JNE		@f
						CALL	CDROM_BIOS_PRETEND_NO_ERROR
						JMP		REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT
@@:

						; Undefined Request
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_PARAMETER

REDIRECT_CDROM_BIOSCALL_PROCESSED_EXIT:
						MOV		BYTE PTR [BP+INCOMING_AX+1],AH
						CMP		AH,80H
						JNE		REDIRECT_CDROM_BIOSCALL_EXIT
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

REDIRECT_CDROM_BIOSCALL	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_PRETEND_NO_ERROR	PROC
						MOV		AH,0
						RET
CDROM_BIOS_PRETEND_NO_ERROR	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_IS_SCSI_ERROR	PROC
						CALL	IS_SCSI_ERROR
						PUSHF
						CMP		AH,BIOSERR_HARDERROR
						JNE		@f
						CMP		CX,BIOSERR_DETAIL_MEDIACHANGED
						JNE		@f

						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],1
@@:

						POPF
						RET
CDROM_BIOS_IS_SCSI_ERROR	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_00H_SET_DRIVE_MODE	PROC
						CMP		DL,4
						JE		@f

						MOV		AH,BIOSERR_HARDERROR
						MOV		DX,BIOSERR_DETAIL_PARAMETER
						RET
@@:
						MOV		BYTE PTR [BIOSCACHE_DRIVEMODE],DL
						XOR		AH,AH
						RET
CDROM_BIOS_00H_SET_DRIVE_MODE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_01H_GET_DRIVE_MODE	PROC
						MOV		DL,BYTE PTR [BIOSCACHE_DRIVEMODE]
						XOR		AH,AH
						RET
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
						JNC		@f
						RET
@@:

						XOR		DH,DH
						MOV		DL,BYTE PTR [SCSI_DATA_BUF+9]	; MIN
						MOV		AH,BYTE PTR [SCSI_DATA_BUF+10]	; SEC
						MOV		AL,BYTE PTR [SCSI_DATA_BUF+11]	; FRM

						CALL	MSF2HSG

						MOV		BX,DX
						MOV		DX,AX

						MOV		[BP+INCOMING_BX],BX
						MOV		[BP+INCOMING_DX],DX

						MOV		AL,BYTE PTR [BIOSCACHE_DRIVEMODE]
						MOV		[BP+INCOMING_AX],AL
						XOR		AH,AH
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
						PUSH	ES

						MOV		ES,[BP+INCOMING_DS]
						MOV		DI,[BP+INCOMING_DI]

						CMP		CH,0FFH
						JNE		@f

						XCHG	CH,CL
						MOV		AX,SI
						AND		AX,0FH
						MOV		CL,12
						SHL		AX,CL
						MOV		ES,AX
						XCHG	CH,CL

						XOR		CH,CH
						CMP		SI,10H
						JC		@f

						; Physical Address>0FFFFFH  Inaccessible from real mode.
						POP		ES
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_PARAMETER
						RET
@@:

						CMP		CH,0
						JE		@f
						POP		ES
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_PARAMETER
						RET
@@:

						; At this line
						; ES:DI  Destination
						; BX     Read sector count
						; CL|DX  HSG address

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SECTOR_HSG
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		@f

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
						JE		CDROM_BIOS_0EH_HARDERR_FROM_DRIVE

						; Drive not reporting hard error.
						CMP		AH,0
						JNE		@f

						; Drive is not reporting an error.
						CMP		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
						JE		@f

						; Media_Change Cache is 1
						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
						MOV		AH,BIOSERR_HARDERROR
						MOV		CX,BIOSERR_DETAIL_MEDIACHANGED

@@:
						RET

CDROM_BIOS_0EH_HARDERR_FROM_DRIVE:
						CMP		CX,BIOSERR_DETAIL_MEDIACHANGED
						JE		@f
						CMP		CX,BIOSERR_DETAIL_NOT_READY
						JE		@f
						RET
@@:
						MOV		BYTE PTR [BIOSFLAG_MEDIA_CHANGE_CACHE],0
						RET

CDROM_BIOS_0EH_TEST_UNIT_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG		PROC
						XOR		AH,AH

						; Based on Disassembly of Towns OS V2.1 L31
						;If CL==5         <Poll [0x567]>
						;  DL=[0x567], [0x567] is reset to zero.
						CMP		CL,5
						JNE		@f
						XOR		DL,DL
						XCHG	DL,[BIOSFLAG_0X567]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:

						;If CL==0
						;  DL=[0x564]
						CMP		CL,0
						JNE		@f
						MOV		DL,[BIOSFLAG_MEDIA_CHANGE_CACHE]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;If CL==1
						;  [0x564]=DL
						;  [0x566]|=DL
						CMP		CL,1
						JNE		@f
						MOV		[BIOSFLAG_MEDIA_CHANGE_CACHE],DL
						OR		[BIOSFLAG_0X566],DL
						RET
@@:


						;If CL==2          <Poll [0x565]>
						;  DL=[0x565], [0x565] is reset to zero.
						CMP		CL,2
						JNE		@f
						XOR		DL,DL
						XCHG	[BIOSFLAG_0X565],DL
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;If CL==4
						;  [0x566]|=DL
						CMP		CL,4
						JNE		@f
						OR		[BIOSFLAG_0X566],DL
						RET
@@:


						;If CL==8          <Retrieve [0x568] Pause flag>
						;  DL=[0x568]
						CMP		CL,8
						JNE		@f
						MOV		DL,[BIOSFLAG_PAUSE_STATE]
						MOV		[BP+INCOMING_DX],DL
						RET
@@:


						;IF CL==16
						;  [0x568]=DL      <Set [0x568] Pause flag>
						;  DL=[0x568]
						CMP		CL,16
						JNE		@f
						MOV		[BIOSFLAG_PAUSE_STATE],DL
						RET
@@:

						MOV		AH,080H
						MOV		CX,2
						RET
CDROM_BIOS_0FH_DIRECT_ACCESS_INTERNAL_FLAG		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_15H_READ_SECTOR_MSF	PROC
						PUSH	AX

						MOV		AX,DX
						MOV		DL,CL
						XOR		DH,DH
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
						JE		@f
						CMP		CH,0FFH
						JE		@f
						CMP		CH,0FEH
						JE		@f

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
						JNC		@f			; Jump if no SCSI error
						MOV		CS:[DEBUG_REDIR_SUBSTEP],'b'
						RET
@@:

						MOV		AL,[SCSI_DATA_BUF+1]
						CMP		BYTE PTR [SCSI_DATA_BUF+1],11H ; 11H=PLAYING
						JNE		@f			; Jump if not playing
						MOV		AH,10H
						MOV		CS:[DEBUG_REDIR_SUBSTEP],'c'
						RET
@@:

						MOV		CX,CS
						MOV		ES,CX
						LEA		DI,[CDPLAY_INFO_CACHE]
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

						MOV		AX,WORD PTR [CDPLAY_INFO_CACHE]
						MOV		ES:[DI],AX
						MOV		AX,WORD PTR [CDPLAY_INFO_CACHE+2]
						MOV		ES:[DI+2],AX
						MOV		AX,WORD PTR [CDPLAY_INFO_CACHE+4]
						MOV		ES:[DI+4],AX

						XOR		AH,AH
						RET
CDROM_BIOS_051H_GET_PLAY_INFO	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_052H_STOP_PLAY		PROC
						CMP		CH,0FFH
						JNE		@f

						; SCSI2 does not support idle-time to auto stop.  Just ignore.
						MOV		AH,0
						RET

@@:

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		@f
						RET
@@:

						CMP		BYTE PTR [SCSI_DATA_BUF+1],11H ; 11H=PLAYING
						JE		@f			; Jump if playing
						; If not playing, just return no error.
						MOV		AH,0
						RET

@@:
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_STOP_PLAY
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JC		@f

						; At least I can stop CD by sending RESTORE command.
						; But, I don't want my CD head to go back and forth when playing in random tracks.
						; I want it to directly move to the next track.
						; MOV		AL,[YSSCSICD_SCSI_ID]
						; CALL	SCSI_RESTORE
						; CALL	CDROM_BIOS_IS_SCSI_ERROR
@@:
						RET
CDROM_BIOS_052H_STOP_PLAY		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDROM_BIOS_053H_GET_PLAY_STATE	PROC
						CMP		CH,0
						JE		@f
						MOV		AH,BIOSERR_HARDERROR		; AH=080H
						MOV		CX,BIOSERR_DETAIL_PARAMETER  ; CL=2
						RET
@@:

						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READ_SUB_CHANNEL_CDROM_CUR_POS
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		@f
						RET
@@:

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
						JE		@f			; Jump if playing

						XOR		AX,AX
						XOR		CX,CX
						MOV		[BP+INCOMING_AX],AL
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
						MOV		CL,[SCSI_DATA_BUF+15]
						XOR		CH,CH
						MOV		ES:[DI+5],CX		; Frame

						; Offset 4+4,4+5,4+6,4+7
						; Offset 8(=0), 9(=Min), 10(=Sec), 11(=Frm)
						MOV		CX,WORD PTR [SCSI_DATA_BUF+9]
						MOV		ES:[DI+7],CX
						MOV		CL,[SCSI_DATA_BUF+11]
						MOV		ES:[DI+9],CL

						XOR		AH,AH
						XOR		CX,CX
						MOV		[BP+INCOMING_AX],AL
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
						JNC		@f			; Jump if no SCSI error
						RET
@@:

						MOV		AL,[SCSI_DATA_BUF+1]
						CMP		BYTE PTR [SCSI_DATA_BUF+1],11H ; 11H=PLAYING
						JNE		@f			; Jump if not playing
						MOV		AH,BIOSERR_ALREADY_PLAYING
						RET
@@:

						MOV		CL,0AAH		; Get min-max track
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READTOC
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		@f
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
						; For unknown reason, CDSD.SYS subtracts 150 frames (2 seconds) from volume size.
						; I just follow it

						MOV		DL,BYTE PTR [SCSI_DATA_BUF+9]
						MOV		AH,BYTE PTR [SCSI_DATA_BUF+10]
						MOV		AL,BYTE PTR [SCSI_DATA_BUF+11]
						SUB		AH,2	; 2 seconds
						JNC		@f
						ADD		AH,60
						DEC		DL
@@:
						MOV		ES:[SI+3],DL
						MOV		ES:[SI+4],AH
						MOV		ES:[SI+5],AL

						LEA		DI,[SI+6]
						MOV		DL,ES:[SI+1]

CDROM_BIOS_054H_TRACK_LOOP:
						PUSH	DI
						PUSH	DX

						MOV		CL,DL
						MOV		AL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_READTOC
						CALL	CDROM_BIOS_IS_SCSI_ERROR
						JNC		@f

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
						JNE		@f
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
						JBE		CDROM_BIOS_054H_TRACK_LOOP


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
						JNC		@f
						RET
@@:
						; [SCSI_DATA_BUF+1]  Audio Status
						;   11H  Playing
						;   12H  Paused

						MOV		AL,BYTE PTR [SCSI_DATA_BUF+1]
						CMP		AL,12H
						JNE		@f
						MOV		AH,BIOSERR_ALREADY_PAUSED
						RET
@@:

						CMP		AL,11H
						JE		@f
						MOV		AH,BIOSERR_ALREADY_PAUSED	; ? Is there Not Playing Error ?
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
						JNC		@f
						RET
@@:
						; [SCSI_DATA_BUF+1]  Audio Status
						;   11H  Playing
						;   12H  Paused
						MOV		AH,BYTE PTR [SCSI_DATA_BUF+1]
						CMP		AH,11H
						JNE		@f
						MOV		AH,BIOSERR_ALREADY_PLAYING
						RET
@@:

						CMP		AH,12H
						JE		@f
						MOV		AH,BIOSERR_NOT_PAUSED
						RET
@@:

						MOV		BYTE PTR [BIOSFLAG_PAUSE_STATE],0

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

						MOV		BYTE PTR ES:[DI+4],02H
						MOV		BYTE PTR ES:[DI+5],00H
						MOV		BYTE PTR ES:[DI+6],03H
						MOV		BYTE PTR ES:[DI+7],00H

						POP		ES
						MOV		AH,0

						RET
CDROM_BIOS_058H_GET_ELEVOL	ENDP
