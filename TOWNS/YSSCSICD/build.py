import subprocess
import os
import sys
import shutil


THISFILE=os.path.realpath(__file__)
THISDIR=os.path.dirname(THISFILE)

FREETOWNSOS=os.path.join(THISDIR,"..","..","..","FreeTOWNSOS")
HC386ENV=os.path.join(THISDIR,"..","..","..","HC386ENV")

proc=subprocess.Popen([
		"Tsugaru_Headless",
		os.path.join(FREETOWNSOS,"CompROM"),
		"-FD0",
		os.path.join(FREETOWNSOS,"resources","RUNNERFD.bin"),
		"-FD1",
		os.path.join(THISDIR,"TESTFD","TESTFD.BIN"),
		"-BOOTKEY",
		"F0",
		"-TGDRV",
		HC386ENV,
		"-TGDRV",
		os.path.join(THISDIR,".."),
		"-FREQ","100",
		"-DEBUG",
		#"-UNITTEST",
		"-DONTUSEFPU",	# Let High-C use no-fpu mode.
		"-VMFLAG", "CONSOUT", # Automatic in Tsugaru_Headless.  Needed if Tsugaru_CUI is used.
		"-conscmd","D:\AUTOEXEC.BAT",
		"-conscmd","E:",
		"-conscmd","CD YSSCSICD",
		"-conscmd","MAKE",
		"-conscmd","IF ERRORLEVEL 1 FAIL",
		"-conscmd","SUCCESS",
	])
proc.communicate()
if 0!=proc.returncode:
	print("**** ERROR ***")
	exit(1)
exit(0)
