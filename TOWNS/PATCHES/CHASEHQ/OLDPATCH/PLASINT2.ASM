; This is the code that is injected to the ChaseHQ binary LASINT2.EXP.
; Actual modificatoins are made after the ChaseHQ code is decrypted during runtime by the code written in 
; patch.asm (for LASINT.EXP) and patch2.asm (for LASINT2.EXP).


						.386p
						ASSUME	CS:CODE

CODE					SEGMENT


JUMPTABLE				EQU		001A8DA4H
; LASINT.EXP    001A5FB4H
; LASINT2.EXP   001A8DA4H


CDDAPLAY				PROC
						MOV		BX,0C43AH
						CALL	DWORD PTR CS:[JUMPTABLE+4*6]  ; Address for CMD #6 Save PIC and disable
						MOV		AX,52C0H
						XOR		ECX,ECX
						INT		93H
						MOV		AX,72C0H
						MOV		BX,[ESI]
						MOV		CX,[ESI+2]
						MOV		DX,[ESI+4]
						INT		93H
						CALL	DWORD PTR CS:[JUMPTABLE+4*7]  ; Address for CMD #7 Restore PIC
						RET
CDDAPLAY				ENDP



CDDAPAUSE				PROC
						MOV		BX,0C43AH
						CALL	DWORD PTR CS:[JUMPTABLE+4*6]  ; Address for CMD #6 Save PIC and disable
						MOV		AX,55C0H
						XOR		ECX,ECX
						INT		93H
						CALL	DWORD PTR CS:[JUMPTABLE+4*7]  ; Address for CMD #7 Restore PIC
						RET
CDDAPAUSE				ENDP



CDDARESUME				PROC
						MOV		BX,0C43AH
						CALL	DWORD PTR CS:[JUMPTABLE+4*6]  ; Address for CMD #6 Save PIC and disable
						MOV		AX,56C0H
						XOR		ECX,ECX
						INT		93H
						CALL	DWORD PTR CS:[JUMPTABLE+4*7]  ; Address for CMD #7 Restore PIC
						RET
CDDARESUME				ENDP


CODE					ENDS
						END
