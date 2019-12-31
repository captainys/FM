						.386p

						ASSUME	CS:CODE

CODE					SEGMENT



; int cdr_read( int deviceno, int lsector, char *buffer, unsigned int count );





						ORG		0000E8F0H
NEW_MALLOC				PROC

;000C:0000E8F0 C8100000                 ENTER 0010,0
;000C:0000E8F4 53                       PUSH
;000C:0000E8F5 51                       PUSH
;000C:0000E8F6 52                       PUSH	EDX
;000C:0000E8F7 56                       PUSH	ESI
;000C:0000E8F8 57                       PUSH	EDI
;000C:0000E8F9 1E                       PUSH	DS
;000C:0000E8FA 06                       PUSH	ES
;
;000C:0000E8FB BBFFFF0F00               MOV	EBX,000FFFFF    EBX Number of Paragraphs (1 paragraph=16 bytes)  Maybe 4K blocks.
;000C:0000E900 B448                     MOV	AH,48           Malloc?
;000C:0000E902 CD21                     INT	21 
;000C:0000E904 4B                       DEC	EBX             EBX maximum size of the block?
;000C:0000E905 4B                       DEC	EBX
;000C:0000E906 4B                       DEC	EBX
;000C:0000E907 B448                     MOV	AH,48


						ENTER 	0010H,0
						PUSH	EBX
						PUSH	ECX
						PUSH	EDX
						PUSH	ESI
						PUSH	EDI
						PUSH	DS
						PUSH	ES

						MOV		DWORD PTR [EBP-10H],0	; Tentative Return Value=NULL

						MOV		EBX,[EBP+8]
						ADD		EBX,2		; Just in case
						MOV		AH,48H
						INT		21H			; Output AX=Segment Allocated  EBX=# of 4KB blocks

						CMP		EBX,[EBP+8]
						JC		NEW_MALLOC_EXIT

						MOVZX	EAX,AX      ; Segment
						MOV		[EBP-4],EAX	; [EBP-4] is segment allocated
						MOV		[EBP-8],EBX	; [EBP-8] is Number of blocks

						MOV		EBX,EAX
						MOV		AX,2508H	; Input EBX=Segment, Output ECX=Linear Base Address
						INT		21H

						MOV		EBX,ECX		; Base Address
						MOV		ECX,[EBP-8]	; Block count
PAGING_LOOP:			PUSH	ECX
						PUSH	EBX
						MOV		AX,2509H
						INT		21H			; Input EBX=Linear Address, Output ECX=Physical Address

						MOV		AX,DS
						MOV		ES,AX
						MOV		EBX,ECX		; EBX=Physical Address
						MOV		ECX,1		; 1 page
						MOV		AX,250AH
						INT		21H

						CMP		DWORD PTR [EBP-10H],0
						JNE		ADDR_ALREADY_SET
						MOV		[EBP-10H],EAX
ADDR_ALREADY_SET:
						POP		EBX
						POP		ECX
						ADD		EBX,1000H	; 4KB per page
						LOOP	PAGING_LOOP

NEW_MALLOC_EXIT:
						MOV		EAX,[EBP-10H]
						POP		ES
						POP		DS
						POP		EDI
						POP		ESI
						POP		EDX
						POP		ECX
						POP		EBX
						LEAVE
						RET


NEW_MALLOC				ENDP





						ORG		0000EFE2H
CDR_READ				PROC
CDR_READ				ENDP


						ORG		0000E990H

PATCH					PROC
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


PATCH					ENDP



DEBUG_STOP_1D749		PROC
						ORG		1D749H
						MOV		EAX,[ESP]
						MOV		EBX,[ESP+4]
						MOV		ECX,[ESP+8]
						MOV		EDX,[ESP+12]
						MOV		ESI,[ESP+16]
						MOV		EDI,[ESP+20]
INF_1:					JMP		INF_1

DEBUG_STOP_1D749		ENDP


DEBUG_STOP_1D9DC		PROC
						ORG		1D9DCH
						MOV		EAX,[EBP-0CH]
						MOV		EBX,[EBP-08H]
						MOV		ECX,[EBP-04H]
						MOV		ESI,[EBP-14H]
						MOV		EDI,[EBP-10H]
INF_2:					JMP		INF_2

DEBUG_STOP_1D9DC		ENDP


DEBUG_STOP_OPENING4		PROC

;000C:0001D5BB 57                       PUSH	EDI
;000C:0001D5BC E8B75F0000               CALL	00023578             Make capital letters
;000C:0001D5C1 2BF6                     SUB	ESI,ESI
;000C:0001D5C3 83C404                   ADD	ESP,4

						CMP		EDI,DS:[00033B40H]
INF_3:					JE		INF_3
						NOP

DEBUG_STOP_OPENING4		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DEBUG_STOP_FILE_FOUND	PROC
;000C:0001D5F8 83FE13                   CMP	ESI,13                if(13H<=ESI)return 0;     ESI=File Index
;000C:0001D5FB 7D22                     JGE	0001D61F
;000C:0001D5FD 8D04F6                   LEA	EAX,[ESI+ESI*8]
;000C:0001D600 8B048548C00300           MOV	EAX,[EAX*4+0003C048]  EAX=[3C034+ESI*36+0x14]

						MOV		EAX,[EDI]
						MOV		EBX,[EDI+4]
INF_4:					JMP		INF_4

DEBUG_STOP_FILE_FOUND	ENDP



DEBUG_STOP_SEE_MSF_AND_CALLBACK		PROC

;//000C:0001D72D FF7514                   PUSH	Dword Ptr [EBP+14]      ? Call-Back Function Parameter 4th parameter
;//000C:0001D730 FF7510                   PUSH	Dword Ptr [EBP+10]      ? Call-Back Function Pointer 3rd parameter
;//000C:0001D733 FF353C7E0200             PUSH	Dword Ptr [00027E3C]    Must be the data poiter
;//000C:0001D739 FF75E4                   PUSH	Dword Ptr [EBP-1C]      End F in BCD
;//000C:0001D73C FF75E0                   PUSH	Dword Ptr [EBP-20]      End S in BCD
;//000C:0001D73F 52                       PUSH	EDX                     End M in BCD
;//000C:0001D740 FF75F0                   PUSH	Dword Ptr [EBP-10]      Start F in BCD
;//000C:0001D743 FF75EC                   PUSH	Dword Ptr [EBP-14]      Start S in BCD
;//000C:0001D746 FF75E8                   PUSH	Dword Ptr [EBP-18]      Start M in BCD
;//000C:0001D749 E84212FFFF               CALL	0000E990                Direct CD-ROM I/O

						MOV		EAX,[EBP-18H]
						MOV		EBX,[EBP-14H]
						MOV		ECX,[EBP-10H]
						MOV		ESI,[EBP-20H]
						MOV		EDI,[EBP-1CH]
						MOV		EBP,[EBP+10H]
INF_5:					JMP		INF_5

DEBUG_STOP_SEE_MSF_AND_CALLBACK		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;000C:0001D749 E84212FFFF               CALL	0000E990                Direct CD-ROM I/O
;000C:0001D74E E859000000               CALL	0001D7AC                Sound BIOS Call Mute_Unmute_Electric_Volume
;000C:0001D753 A13C7E0200               MOV	EAX,[00027E3C]          Must be the data pointer (Looks like a large buffer)
;000C:0001D758 8B55D8                   MOV	EDX,[EBP-28]            EDX=fileNumber*36

DEBUG_STOP_E990			PROC

						ORG		0001D749H
; 8B 5D 14   MOV  EBX,[EBP+14H]
; 8B 45 08   MOV  EAX,[EBP+08H]

						MOV		AX,9090H; NOP NOP
						MOV		CS:[0000EA42H],AX
						MOV		CS:[0000EA44H],AL

						MOV		EAX,0F85D8BH   ; MOV EBX,[EBP-8]
						MOV		CS:[0000EA4AH],EAX

						MOV		EAX,008458BH   ; MOV EAX,[EBP+8]
						MOV		CS:[0000EA4AH+3],EAX

						MOV		AX,0FEEBH	; JMP $
						MOV		WORD PTR CS:[0000EA4AH+6],AX
						CALL	L0000E990

DEBUG_STOP_E990			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

READ_CDROM				PROC

						ORG		0000E990H
L0000E990:

READ_CDROM				ENDP


CODE					ENDS
						END
