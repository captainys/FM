all : CDCCMD3F.EXP



CDCCMD3F.OBJ : CMD3F.C
	HCD386 CMD3F.C -OBJ CDCCMD3F.OBJ

CDCCMD3F.EXP : CDCCMD3F.OBJ
	386LINK CDCCMD3F.OBJ @LIBS.LN -EXE CDCCMD3F.EXP
