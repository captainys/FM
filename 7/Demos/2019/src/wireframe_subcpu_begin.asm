							EXPORT		WIREFRAME_SUBCPU_BEGIN
;			Sub-CPU code
;			Must assemble as:
;			wireframe_subcpu_begin.asm
;			wireframe_subcpu.asm
;			(divisions.asm)
;			wireframe_subcpu_end.asm

;			The code will be transferred to $C000 in sub-CPU space.


LINE_CMD_2D_END_OF_CMDSET	EQU		0	; End of commands (Stay in the loop)
LINE_CMD_2D_NOCLIPPING		EQU		1	; Draw 2D lines without clipping. (#lines, CXYXYCXYXY.... C:8bit X:16bit  Y:16bit )
LINE_CMD_2D_CLIPPING		EQU		2	; Draw 2D lines with clipping. (#lines, CXYXYCXYXY....  C:8bit X:16bit  Y:16bit)
LINE_CMD_2D_TRANS_CLIP		EQU		3	; Draw 2D lines with rotation, scaling, translation, and clipping (#lines, CXYXYCXYXY....  C:8bit X:8bit Y:8bit)
										;   Positive-Y of the line coordinates is up.
										;   Cx,Cy of the transformation is in the screen coordinate (LU as origin)
										;   Y is inverted after rotation to match the coordinate system

LINE_CMD_3D_NOCLIPPING		EQU		4	; Draw 3D lines without viewport clipping.  Calculate projection and draw. (#lines, CXYZXYZCXYZXYZ....  C:8bit X,Y,Z:16bit )
LINE_CMD_3D_CLIPPING		EQU		5	; Draw 3D lines with viewport clipping.  Calculate projection and draw. (#lines, CXYZXYZCXYZXYZ....  C:8bit X,Y,Z:16bit )

LINE_CMD_SELECT_BANK0		EQU		6	;	Select Bank 0
LINE_CMD_SELECT_BANK1		EQU		7	;	Select Bank 1
LINE_CMD_CLS				EQU		8	;	CLS (All active page)

LINE_CMD_HALF_CLS			EQU		9	; Followed by 2-byte VRAM offset ($0000 or $2000)
LINE_CMD_SET_OFFSET			EQU		10	; Followed by 2-byte VRAM offset ($0000 or $2000)
LINE_CMD_SET_TRANS			EQU		11	; Followed by 1-byte Rotation, 1-byte unsigned Scaling (x128), 2-byte X, and 2-byte Y

LINE_CMD_PRINT				EQU		12	; Followed by color (0-63), #chrs, VRAMADDR, string

LINE_CMD_2D_TRANS_CLIP_16	EQU		13	; Draw 2D lines with rotation, scaling, translation, and clipping.  Takes 16-bit XY coordinates. (#lin32 CXYXYXY...  C:8bit X:16bit Y:16bit)
										;   Positive-Y of the line coordinates is up.
										;   Cx,Cy of the transformation is in the screen coordinate (LU as origin)
										;   Y is inverted after rotation to match the coordinate system

LINE_CMD_NOP				EQU		$7F
LINE_CMD_END_CMDLOOP		EQU		$FF


LINE_CMD_END				EQU		$FF		; Any negative number.



LINEDATA_BUF				EQU		$CA00
SUBSYS_YS_WORKAREA			EQU		$D100	; Shuwa book tells $D000 to $D09F may be altered in NMI handler.



WIREFRAME_SUBCPU_BEGIN
