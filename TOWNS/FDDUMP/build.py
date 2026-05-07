import os
import sys
import subprocess

THISFILE=os.path.realpath(__file__)
THISDIR=os.path.dirname(THISFILE)



def SetENV():
	WATCOM=os.environ["WATCOM"]

	if not os.path.isdir(WATCOM):
		print("Set environment variable WATCOM and try again.")
		quit()

	os.environ["PATH"]=os.path.join(WATCOM,"BINNT")+";"+os.environ["PATH"]
	os.environ["INCLUDE"]=os.path.join(WATCOM,"H")
	os.environ["LIB"]=os.path.join(WATCOM,"LIB386","DOS")+";"+os.path.join(WATCOM,"LIB386")
	os.environ["EDPATH"]=os.path.join(WATCOM,"EDDAT")
	os.environ["WIPFC"]=os.path.join(WATCOM,"WIPFC")




def Make():
	proc=subprocess.Popen(["nmake"])
	proc.communicate()



def main(argv):
	SetENV()
	Make()


if __name__=="__main__":
	os.chdir(THISDIR)
	main(sys.argv)
