# 2048nize.py:  Convert BIN/CUE data track 2048bytes/sector
import os
import sys



def Error(msg):
	print("ERROR:"+msg)
	quit()



def Help():
	print("2048nize.py - Convert BIN/CUE to 2048 bytes/sector data track.")
	print("by CaptainYS")
	print("Usage:")
	print("  2048nize.py input.cue output.cue")



def ReadTextFile(fName):
	fp=open(fName,"r")
	txt=[]
	for line in fp:
		txt.append(line)
	return txt



def MSFStrToHSG(MSFStr):
	args=MSFStr.split(":")
	m=int(args[0])
	s=int(args[1])
	f=int(args[2])
	return m*75*60+s*75+f



def MakeUpBINFileFromCUE(CUEFName,BINFName):
	path=os.path.split(CUEFName)[0]
	return os.path.join(path,BINFName)



def CheckCUE(txt,CUEFName):
	nBIN=0
	readingTrack=-1
	lastTrack=-1
	track2Exists=False
	for line in txt:
		LINE=line.upper()
		if 0<=LINE.find("FILE"):
			if 0<=LINE.find("BINARY"):
				nBIN=nBIN+1
				if 2<=nBIN:
					Error("CUE file includes more than one reference to a BINARY file.")
				fNameBegin=line.find('"')
				fNameEnd=line.rfind('"')
				binFName=line[fNameBegin+1:fNameEnd]
			else:
				Error("CUE file includes a reference to non-BINARY file.")
		if 0<=LINE.find("TRACK") and 0<=LINE.find("MODE1/"):
			mode1pos=LINE.find("MODE1/")
			sectorLength=LINE[mode1pos+6:mode1pos+10]
			if "2352"!=sectorLength:
				Error("Input Data Track needs to be 2352 bytes per sector (CUE file says "+sectorLength+")")
		if 0<=LINE.find("TRACK"):
			args=LINE.split()
			readingTrack=int(args[1])
			lastTrack=readingTrack
		if 0<=LINE.find("INDEX"):
			args=LINE.split()
			indexType=int(args[1])
			if 1==indexType and 2==readingTrack:
				track2BeginTime=args[2]
				track2Exists=True
	print("[Input CUE]")
	print("Number of Data Tracks="+str(nBIN))
	print("Data Track Sector Length="+sectorLength)
	print("BIN File Name="+binFName)
	if True==track2Exists:
		print("Track2BeginTime="+track2BeginTime+"(HSG "+str(MSFStrToHSG(track2BeginTime))+")")
		numDataSectors=MSFStrToHSG(track2BeginTime)
	else:
		fsize=os.path.getsize(MakeUpBINFileFromCUE(CUEFName,binFName))
		numDataSectors=fsize/2352
		print("Track1 Number of Sectors="+str(numDataSectors))
	return [binFName,numDataSectors]



# For every 2352 bytes skip first 16 bytes take 2048 bytes



def main(argv):
	if(3!=len(argv)):
		Help()
		quit()

	cue=ReadTextFile(argv[1])
	[binFName,numSectors]=CheckCUE(cue,argv[1])

	raise   # Working on it now

	return;



if __name__=="__main__":
	main(sys.argv)
