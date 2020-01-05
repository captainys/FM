						.386p
						ASSUME	CS:CODE

CODE					SEGMENT
;Patch 1
;000C:00007A67 66BAC204                 MOV	DX,04C2             CD-ROM Command Register    -> C3   RET
;000C:00007A6B EC                       IN	AL,DX
;000C:00007A6C A8FF                     TEST	AL,FF
;000C:00007A6E 74FB                     JE	00007A6B

PATCH1					PROC
						RET
PATCH1					ENDP



;Patch 2
;000C:000079CF B906000000               MOV	ECX,00000006
;000C:000079D4 66BAC404                 MOV	DX,04C4
;000C:000079D8 AC                       LODSB 

PATCH2					PROC
						MOV	AX,52C0H
						XOR	CX,CX
						INT	93H
						MOV	AX,72C0H
						MOV	BX,[ESI]
						MOV	CX,[ESI+2]
						MOV	DX,[ESI+4]
						INT	93H
						RET
PATCH2					ENDP


;Patch 3
;000C:00007988 B906000000               MOV	ECX,00000006
;000C:0000798D 66BAC404                 MOV	DX,04C4
;000C:00007991 AC                       LODSB 

PATCH3					PROC
						MOV	AX,72C0H
						MOV	BX,[ESI]
						MOV	CX,[ESI+2]
						MOV	DX,[ESI+4]
						INT	93H
						RET
PATCH3					ENDP


;Patch 4
;000C:00007A0B B908000000               MOV	ECX,00000008
;000C:00007A10 66BAC404                 MOV	DX,04C4
;000C:00007A14 B000                     MOV	AL,00
;000C:00007A16 EE                       OUT	DX,AL
;000C:00007A17 E2F7                     LOOP32	00007A10
;000C:00007A19 B0C5                     MOV	AL,C5               CDDAPAUSE
;000C:00007A1B 66BAC204                 MOV	DX,04C2             CD-ROM Command Register

PATCH4					PROC
						MOV		AX,55C0H
						XOR		CX,CX
						INT		93H
						RET
PATCH4					ENDP


;Patch 5
;000C:00007A39 B908000000               MOV	ECX,00000008
;000C:00007A3E 66BAC404                 MOV	DX,04C4
;000C:00007A42 B000                     MOV	AL,00
;000C:00007A44 EE                       OUT	DX,AL
;000C:00007A45 E2F7                     LOOP32	00007A3E
;000C:00007A47 B0C7                     MOV	AL,C7               CDDARESUME
;000C:00007A49 66BAC204                 MOV	DX,04C2             CD-ROM Command Register

PATCH5					PROC
						MOV		AX,56C0H
						XOR		CX,CX
						INT		93H
						RET
PATCH5					ENDP




PATCH_APPLIER			PROC

						PUSH	ESI

;Patch1
						MOV		BYTE PTR DS:[00007A67H],0C3H	; RET


;Patch2/Patch3
;66 B8 71C0                   						MOV	AX,71C0H 
;66 8B 1E                     						MOV	BX,[ESI] 
;66 8B 4E 02                  						MOV	CX,[ESI+2] 
;66 8B 56 04                  						MOV	DX,[ESI+4] 
;CD 93                         						INT	93H 
;C3                            						RET 
						MOV		ESI,000079CFH
						CALL	WRITE_PATCH2_PATCH3
						MOV		ESI,00007988H
						CALL	WRITE_PATCH2_PATCH3


; Patch 4
						MOV		ESI,00007A0BH
						MOV		DWORD PTR DS:[ESI  ],055c0b866H
						MOV		DWORD PTR DS:[ESI+4],0cdc93366H
						MOV		 WORD PTR DS:[ESI+8],0c393H


; Patch 5
						MOV		ESI,00007A39H
						MOV		DWORD PTR DS:[ESI  ],056c0b866H
						MOV		DWORD PTR DS:[ESI+4],0cdc93366H
						MOV		 WORD PTR DS:[ESI+8],0c393H


						POP		ESI


						RET

WRITE_PATCH2_PATCH3:
						MOV		DWORD PTR DS:[ESI   ],052C0B866H
						MOV		DWORD PTR DS:[ESI+ 4],0CDC93366H
						MOV		DWORD PTR DS:[ESI+ 8],0C0B86693H
						MOV		DWORD PTR DS:[ESI+12],01E8B6672H
						MOV		DWORD PTR DS:[ESI+16],0024E8B66H
						MOV		DWORD PTR DS:[ESI+20],004568B66H
						MOV		DWORD PTR DS:[ESI+24],090C393CDH
						RET


PATCH_APPLIER			ENDP


CODE					ENDS
						END

