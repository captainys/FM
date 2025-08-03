SUB_SHARED_AREA			EQU		$C000

; Transformed coordinates.  Used by PROJECT_ORTHOGONAL, PROJECT_PERSPECTIVE
COORD_AREA				EQU		$E000

; Projected coordinates.  Can be used from each demo sequence.
PROJECTION_AREA			EQU		$E600

; BGM Data (MMR Segument #1)
BGMDATA_TOP				EQU		$C000
BGM_MMR_TOP				EQU		0
