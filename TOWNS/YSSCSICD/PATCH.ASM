; Input
;   BX    Sector count
;   DS:SI Pointer where sectors are read.
PATCH_RUN386			PROC

						OUT		0EBh,AL		; Tsugaru Status Message.  Use brkon iow EB to break.
						RET

PATCH_RUN386			ENDP


PATCH_DRIVE_R			PROC

						RET

PATCH_DRIVE_R			ENDP
