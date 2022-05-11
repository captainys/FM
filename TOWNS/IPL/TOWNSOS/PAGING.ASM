; Disk BIOS refuses to recognize memory card if all zero.
; Needs to write different way.

						.386p
						ASSUME	CS:CODE

						PUBLIC	SETUP_PAGE_TABLE
						PUBLIC	TRANSFER_TO_ICM
						PUBLIC	MALLOC_PHYS_ADDR

CODE					SEGMENT


; This proc worked on Tsugaru, but didn't work on actual.

; [EBP]		ESP
; [EBP+4]	Return EIP
; [EBP+8]	Big-enough Page Table Buffer.  Must fit 8 times 4KB pages.
SETUP_PAGE_TABLE		PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	EDX
						PUSH	ESI
						PUSH	EDI
						PUSH	ES



						MOV		BX,DS
						MOV		AX,2508H	; Get Segment Base Linear Address
						INT		21H
						; ECX=Linear Address

						MOV		EDI,[EBP+8]
						LEA		EDI,[ECX+EDI+4095]
						AND		EDI,0FFFFF000H
						SUB		EDI,ECX
						MOV		[EBP+8],EDI


						PUSH	DS
						POP		ES

						MOV		EAX,0C0000007H	; User, Read+Write, Present
SETUP_PAGE_MAKE_LOOP:
						STOSD
						ADD		EAX,4096
						CMP		EAX,0C2000000H
						JB		SETUP_PAGE_MAKE_LOOP


						MOV		BX,DS
						MOV		AX,2508H	; Get Segment Base Linear Address
						INT		21H
						; ECX=Linear Address
						MOV		EDX,ECX
						; Save DS base in EDX


						MOV		AX,0040H	; 00000000H to FFFFFFFFH Linear Access for updating page table.
						MOV		ES,AX
						MOV		EDI,CR3
						ADD		EDI,0C00H
						; Shift by 22 bits then times DWORD.  Shift by 20 bits overall.
						; 80000000H -> 0800H
						; C0000000H -> 0C00H

						MOV		ESI,CR3
						ADD		ESI,0C20H

						MOV		ECX,[EBP+8]
PAGE_TABLE_INDEX_LOOP:
						PUSH	ESI
						PUSH	EDI
						PUSH	ECX
						PUSH	EDX

						LEA		EBX,[EDX+ECX]	; EDX=DS Base, ECX=Offset
						MOV		AX,2509H		; Linear to Physical
						INT		21H
						; ECX is phys addr
						MOV		EAX,ECX

						POP		EDX
						POP		ECX
						POP		EDI
						POP		ESI

						AND		EAX,0FFFFF000H
						OR		EAX,7

						STOSD
						ADD		ECX,4096
						CMP		EDI,ESI
						JB		PAGE_TABLE_INDEX_LOOP

						MOV		EAX,CR3
						MOV		CR3,EAX

						POP		ES
						POP		EDI
						POP		ESI
						POP		EDX
						POP		EBX
						MOV		ESP,EBP
						POP		EBP
						RET

SETUP_PAGE_TABLE		ENDP




; TRANSFER_TO_ICM(unsigned int size,const unsigned char from[],unsigned char to[]);
;	[EBP]		EBP
;	[EBP+4]		Return EIP
;	[EBP+8]		Size (Must be 4*N)
;	[EBP+12]	FROM
;	[EBP+16]	TO
TRANSFER_TO_ICM			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	ESI
						PUSH	EDI
						PUSH	EBX
						PUSH	EDX
						PUSH	ES

						MOV		ECX,[EBP+8]
						ADD		ECX,3
						SHR		ECX,2
						MOV		ESI,[EBP+12]
						MOV		EDI,[EBP+16]
						CLD
						REP		MOVSD

						POP		ES
						POP		EDX
						POP		EBX
						POP		EDI
						POP		ESI
						MOV		ESP,EBP
						POP		EBP
						RET

TRANSFER_TO_ICM			ENDP



MALLOC_PHYS_ADDR		PROC


						PUSH	EBX
						PUSH	EDX
						PUSH	ESI
						PUSH	EDI
						PUSH	ES

						MOV		AX,DS
						MOV		EBX,0C0000000H
						MOV		ECX,32	; 32 pages * 4KB = 128KB	; At this time I only need 64K, but for the future.
						MOV		AX,250AH
						INT		21H
						; EAX is the pointer to C0000000H

						POP		ES
						POP		EDI
						POP		ESI
						POP		EDX
						POP		EBX
						RET


MALLOC_PHYS_ADDR		ENDP



CODE					ENDS

						END
