# To be shipped with demo2019src

import subprocess

def Assemble(fnInD77,asmFn):
	srecFn=fnInD77+".srec"
	allcmd=["asm6809.exe","-v"]+asmFn+["-S","-o",srecFn]
	print(allcmd)
	proc=subprocess.Popen(allcmd)
	proc.communicate()

	if 0!=proc.returncode:
		raise



demo2019_0_src=["prep0main.asm",
	 "maincpu_io_77av.asm",
	 "mmr_77av.asm",
	 "bgm0.asm"]

demo2019_1_src=["prep1main.asm",
	 "maincpu_io_77av.asm",
	 "mmr_77av.asm",
	 "bgm1.asm"]

demo2019_ipl_src=["ipl.asm"]

demo2019_l_src=[
	 "org1000.asm",
	 "loader.asm",
	 "diskbios.asm",
	 "dir.asm",
	 "fat.asm",
	 "fbasic_errcode.asm",
	 "fbasic_fileutil.asm",
	 "fbasic_loadm.asm",
	"shorttext.asm",
	]

demo2019_m_src=["main.asm",
	 "bgm.asm",
	 "opn.asm",
	 "bgmjumptable.asm",
	 "maincpu_io_77av.asm",
	 "subcpu_io_77av.asm",
	 "subsysmem.asm",
	 "mmr_77av.asm",
	 "subcpu.asm",
	 "analog_palette.asm",
	 "subcpu_cmdutil.asm",
	 "prolog.asm",
	 "planets.asm",
	 "showcase.asm",
	 "asteroid.asm",
	 "afterburner.asm",
	 "landing.asm",
	 "endtitle.asm",
	 "intro_fm77av.asm",
	 "intro.asm",
	 "sin16test.asm",
	 "spinsquare.asm",
	 "solarsystem.asm",
	 "approach_earth.asm",
	 "satellite.asm",
	 "spin_ortho.asm",
	 "spin_pers.asm",
	 "project_orthogonal.asm",
	 "project_perspective.asm",
	 "2dtrans.asm",
	 "trans3d.asm",
	 "printtest.asm",
	 "drawhorizon.asm",
	 "high_level_graphics.asm",
	 "bitmap.asm",
	 "dot8.asm",
	 "divtable.asm",

	 # Sub-CPU code >>
	 "wireframe_subcpu_begin.asm",
	 "wireframe_subcpu.asm",
	 "div8.asm",							# div8, div16 needs to be immediately before wireframe_subcpu_end.asm
	 "div16.asm",
	 "sin8.asm",
	 "sin16.asm",
	 "mul16.asm",
	 "imul8.asm",
	 "viewportclip.asm",
	 "wireframe_subcpu_end.asm",
	 # Sub-CPU code <<

	 # Bitmaps <<
	 # Need to be placed before $B000
	 "bmp_galaxy_96.asm",
	 "bmp_galaxy45_96.asm",
	 "bmp_star_blue_16.asm",
	 "bmp_star_blue_8.asm",
	 # Out of memory.  I used up to $B000.
	 # "bmp_star_red_8.asm",
	 # "bmp_star_white_8.asm",
	 # Bitmaps <<

	 # Data Sources >>
	 "3ddata.asm",
	 "ducky.asm",
	 "asteroid_data.asm",
	 "ostrich.asm",
	 "earth_2d.asm",
	 "mars_2D.asm",
	 "jupiter_2D.asm",
	 "jupiter_2D_LOD.asm",
	 "saturn_2D_LOD.asm",
	 "saturn_2D.asm",
	 "saturn_broken_2D.asm",
	 "neptune_2D.asm",
	 "pluto_2D.asm",
	 "ducky_2d.asm",
	 "F14_2D.asm",
	 "AV8B_2D.asm",
	 "AV8B_2D_LOD.asm",
	 "hubble_3D.asm",
	 "Hubble_Fuselage_2D.asm",
	 "Hubble_Panel_1.asm",
	 "Hubble_Panel_2.asm",
	 "rover_3D.asm",
	 "rover_2D.asm",
	 "voyeger_3D.asm",
	 "voyeger_2D.asm",
	 "voyeger_1_2D.asm",
	 "voyeger_2_2D.asm",
	 "newhorizons_3D.asm",
	 "newhorizons_2D_1.asm",
	 "newhorizons_2D_2.asm",
	 "64color.asm",
	 "CMU_2D.asm",
	 # Data Sources <<

	 "mainram.asm",
	 ]



Assemble("DM2019-0",demo2019_0_src)
Assemble("DM2019-1",demo2019_1_src)
Assemble("DM2019I",demo2019_ipl_src)
Assemble("DM2019L",demo2019_l_src)
Assemble("DM2019M",demo2019_m_src)


print("DM2019-0.srec needs to be saved as DM2019-0 in 2D F-BASIC format disk")
print("DM2019-1.srec needs to be saved as DM2019-1 in 2D F-BASIC format disk")
print("DM2019I.srec needs to be written to Track 0 Side 0 Sector 1")
print("DM2019L.srec needs to be written from Track 0 Side 0 Sector 9")
print("DM2019M.srec needs to be written as DM2019M in 2D F-BASIC format disk")
