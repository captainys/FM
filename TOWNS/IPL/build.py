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
		"-conscmd","CD IPL",
		"-conscmd","TASK.BAT"
	])
proc.communicate()
if 0!=proc.returncode:
	print("**** ERROR ***")
