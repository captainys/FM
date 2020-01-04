						.386p

						ASSUME	CS:CODE

CODE					SEGMENT



; int cdr_read( int deviceno, int lsector, char *buffer, unsigned int count );


						ORG		0000670BH
CDR_READ				PROC
CDR_READ				ENDP


						ORG		00004BFCH

READ_SECTOR_PATCH		PROC

; 000C:00004BFC C8080000                 ENTER	0008,00
; 000C:00004C00 53                       PUSH	EBX
; 000C:00004C01 56                       PUSH	ESI
; 000C:00004C02 57                       PUSH	EDI
; 000C:00004C03 B003                     MOV	AL,03
; 000C:00004C05 E6A1                     OUT	A1,AL
; 000C:00004C07 B0FF                     MOV	AL,FF
; 000C:00004C09 E6A2                     OUT	A2,AL
; 000C:00004C0B E6A3                     OUT	A3,AL
; 000C:00004C0D 66BB1400                 MOV	BX,0014
; 000C:00004C11 66B80825                 MOV	AX,2508
; 000C:00004C15 CD21                     INT	21
; 000C:00004C17 8B5D20                   MOV	EBX,[EBP+20]
; 000C:00004C1A 03D9                     ADD	EBX,ECX
; 000C:00004C1C 66B80925                 MOV	AX,2509
; 000C:00004C20 CD21                     INT	21
; 000C:00004C22 894DF8                   MOV	[EBP-8],ECX     [EBP-8]=Physical Address
; 000C:00004C25 8AC1                     MOV	AL,CL
; 000C:00004C27 E6A4                     OUT	A4,AL
; 000C:00004C29 8AC5                     MOV	AL,CH
; 000C:00004C2B E6A5                     OUT	A5,AL
; 000C:00004C2D C1F910                   SAR	ECX,10

						ENTER	0008,00
						PUSH	EBX
						PUSH	ESI
						PUSH	EDI

						LEA		EDI,[EBP+8]
						MOV		ECX,6
BCD2BIN_LOOP:			MOV		EAX,SS:[EDI]
						CALL	BCD2BIN
						MOV		SS:[EDI],EAX
						LEA		EDI,[EDI+4]
						LOOP	BCD2BIN_LOOP

						; [EBP+08H]     Start M
						; [EBP+0CH]     Start S
						; [EBP+10H]     Start F
						; [EBP+14H]     End M
						; [EBP+18H]     End S
						; [EBP+1CH]     End F

						MOV		DL,[EBP+08H]
						MOV		AH,[EBP+0CH]
						MOV		AL,[EBP+10H]
						CALL	MSF2HSG
						SUB		AX,150
						SBB		DX,0
						MOV		[EBP+08H],AX
						MOV		[EBP+0AH],DX

						; [EBP+8] is now HSG address

						MOV		DL,[EBP+14H]
						MOV		AH,[EBP+18H]
						MOV		AL,[EBP+1CH]
						CALL	MSF2HSG
						SUB		AX,150
						SBB		DX,0
						MOV		[EBP+14H],AX
						MOV		[EBP+16H],DX

						; [EBP+14H] is now HSG address

READ_SECTOR_LOOP:
						; [EBP-8]

						MOV		EBX,[EBP+14H]
						INC		EBX
						SUB		EBX,[EBP+08H]
						JBE		READ_SECTOR_EXIT

						; Make sure to have call buffer greater than 16KB
						; RUN386.EXE -nocrt -callbufs 20 GF2PATCH.EXP
						CMP		EBX,8
						JL		READ_SECTOR_LESS_THAN_8
						MOV		EBX,8
READ_SECTOR_LESS_THAN_8:
						PUSH	EBX					; COUNT
						PUSH	DWORD PTR [EBP+20H]	; Buffer
						PUSH	DWORD PTR [EBP+08H]	; HSG
						PUSH	DWORD PTR 0			; Device No.
						CALL	CDR_READ
						ADD		ESP,0CH
						POP		EBX

						ADD		DWORD PTR [EBP+08H],EBX
						SHL		EBX,11
						ADD		DWORD PTR [EBP+20H],EBX

						CMP		WORD PTR [EBP+24H],0
						JE		NO_CALL_BACK
						PUSH	DWORD PTR [EBP+28H]
						CALL	[EBP+24H]
						ADD		ESP,4
NO_CALL_BACK:

						JMP		READ_SECTOR_LOOP

READ_SECTOR_EXIT:
						XOR		EAX,EAX
						POP		EDI
						POP		ESI
						POP		EBX
						LEAVE
						RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input AL in BCD
; Output AL in Binary
;        AH destroyed
BCD2BIN:

						PUSH	BX

						MOV		BL,AL
						AND		BL,0FH

						SHR		AL,4
						MOV		AH,10
						MUL		AH

						ADD		AL,BL

						POP		BX
						RET

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

MSF2HSG:
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


READ_SECTOR_PATCH		ENDP



						ORG		00001FA4H
CDDA_PLAY_PATCH			PROC

; 000C:00001FA4 C8000000                 ENTER	0008,00
; 000C:00001FA8 52                       PUSH	EDX
; 000C:00001FA9 53                       PUSH	EBX
; 000C:00001FAA 51                       PUSH	ECX
; 000C:00001FAB B910000000               MOV	ECX,00000010
; 000C:00001FB0 66BAC004                 MOV	DX,04C0
; 000C:00001FB4 EC                       IN	AL,DX
; 000C:00001FB5 A801                     TEST	AL,01
; 000C:00001FB7 74FB                     JE	00001FB4
; 000C:00001FB9 8B5D08                   MOV	EBX,[EBP+8]
; 000C:00001FBC 66BAC404                 MOV	DX,04C4
; 000C:00001FC0 8A03                     MOV	AL,[EBX]
; 000C:00001FC2 EE                       OUT	DX,AL
; 000C:00001FC3 8A4301                   MOV	AL,[EBX+1]
; 000C:00001FC6 EE                       OUT	DX,AL
; 000C:00001FC7 8A4302                   MOV	AL,[EBX+2]
; 000C:00001FCA EE                       OUT	DX,AL


						ENTER	0,0
						PUSH	EBX
						PUSH	ECX
						PUSH	EDX

						; Use YSSCSICD.SYS expanded function.
						MOV		EDX,[EBP+08H]
						MOV		BX,[EDX]
						MOV		CL,[EDX+2]

						MOV		EDX,[EBP+0CH]
						MOV		CH,[EDX]
						MOV		DX,[EDX+1]

						MOV		AX,72C0H
						INT		93H

						POP		EDX
						POP		ECX
						POP		EBX
						LEAVE
						XOR		EAX,EAX
						RET

CDDA_PLAY_PATCH			ENDP





; Force Use EGB somewhat works, but not really.
						ORG		0000191DH
EGB_WRITEPAGE			PROC
EGB_WRITEPAGE			ENDP

						ORG		000018E2H
EGB_DISPLAYSTART		PROC
EGB_DISPLAYSTART		ENDP


						ORG		00015C4BH
USE_EGB_PATCH			PROC

						MOV		EBX,0
USE_EGB_PAGE_LOOP:
						PUSH	EBX
						CALL	EGB_WRITEPAGE

						PUSH	DWORD PTR	2	; 2x
						PUSH	DWORD PTR	2	; 2x
						PUSH	DWORD PTR	2	; Scaling
						CALL	EGB_DISPLAYSTART

						MOV		EAX,320
						CMP		BYTE PTR [ESI],10
						JE		USE_EGB_SCRN10
						MOV		EAX,256
USE_EGB_SCRN10:
						PUSH	DWORD PTR	256	; DY=256
						PUSH	EAX
						PUSH	DWORD PTR	3   ; Display Size
						CALL	EGB_DISPLAYSTART

						ADD		ESP,1CH

USE_EGB_NEXT_PAGE:
						LEA		ESI,[ESI+0AH]
						INC		EBX
						CMP		EBX,2
						JNE		USE_EGB_PAGE_LOOP

						POP		EDI
						POP		ESI
						POP		EBX
						LEAVE
						RET


USE_EGB_PATCH			ENDP





AVOID_15K				PROC

;000C:00015D46 0FB615F40D0200           MOVZX	EDX,Byte Ptr [00020DF4]
;000C:00015D4D 8D1492                   LEA	EDX,[EDX+EDX*4]
;000C:00015D50 8D149500000000           LEA	EDX,[EDX*4]
;000C:00015D57 0FB7D2                   MOVZX	EDX,DX

						MOV		BYTE PTR DS:[00020DF4H],1
						MOV		EDX,20
						NOP
						NOP
						NOP
						NOP
						NOP

AVOID_15K				ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					ENDS
						END
