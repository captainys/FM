# 2048nize.py:  Convert BIN/CUE data track 2048bytes/sector
import os
import sys



def Error(msg):
	print("ERROR:"+msg)
	quit()



def Help():
	print("2048nize.py - Convert BIN/CUE to 2048 bytes/sector data track and install IPL.")
	print("by CaptainYS")
	print("Usage:")
	print("  2048nize.py input.cue output.cue IPL.BIN")
	print("")
	print("This program converts a data track of 2352 bytes/sector to 2048 bytes/sector")
	print("and installs IPL.BIN in the first sectors of the image.")



def ReadTextFile(fName):
	fp=open(fName,"r")
	txt=[]
	for line in fp:
		line=line.replace('\r','')
		line=line.replace('\n','')
		txt.append(line)
	fp.close()
	return txt



def WriteTextFile(fName,txt):
	fp=open(fName,"w")
	for line in txt:
		fp.write(line+'\n')
	fp.close()



def MSFStrToHSG(MSFStr):
	args=MSFStr.split(":")
	m=int(args[0])
	s=int(args[1])
	f=int(args[2])
	return m*75*60+s*75+f



def MakeUpFullPathBINFileFromCUE(CUEFName,BINFName):
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
	binFName=MakeUpFullPathBINFileFromCUE(CUEFName,binFName)
	print("[Input CUE]")
	print("Number of Data Tracks="+str(nBIN))
	print("Data Track Sector Length="+sectorLength)
	print("BIN File Name="+binFName)
	if True==track2Exists:
		print("Track2BeginTime="+track2BeginTime+"(HSG "+str(MSFStrToHSG(track2BeginTime))+")")
		numDataSectors=MSFStrToHSG(track2BeginTime)
	else:
		fsize=os.path.getsize(binFName)
		numDataSectors=fsize/2352
		print("Track1 Number of Sectors="+str(numDataSectors))
	return [binFName,numDataSectors]



def ProcessCUE(txt,binFName):
	txtOut=[]
	for line in txt:
		LINE=line.upper()
		if 0<=LINE.find("FILE"):
			txtOut.append('FILE "'+os.path.split(binFName)[1]+'" BINARY')
		elif 0<=LINE.find("TRACK") and 0<=LINE.find("MODE1/"):
			mode1pos=LINE.find("MODE1/")
			txtOut.append(line[0:mode1pos+6]+"2048")
		else:
			txtOut.append(line)
	return txtOut



def main(argv):
	if(len(argv)!=4):
		Help()
		quit()

	with open(argv[3],"rb") as f: IPL=[d for d in f.read()]

	print("IPL "+str(len(IPL))+" bytes")

	cueIn=ReadTextFile(argv[1])
	[binInFName,numSectors]=CheckCUE(cueIn,argv[1])

	cueOutFName=argv[2]
	if os.path.exists(cueOutFName):
		print("Output CUE file already exists.")

	binOutFName=os.path.splitext(cueOutFName)[0]
	binOutFName+=".BIN"
	if os.path.exists(binOutFName):
		print("Output BIN file already exists.")

	print("Output CUE file:"+cueOutFName)
	print("Output BIN file:"+binOutFName)

	cueOut=ProcessCUE(cueIn,binOutFName)

	WriteTextFile(cueOutFName,cueOut)

	print("Please wait for extremely long time.")

	with open(binInFName,"rb") as f: data=[d for d in f.read()]

	sect=int(0)
	writePtr=int(0)
	readPtr=int(16)
	while sect<numSectors:
		data[writePtr:writePtr+2048]=data[readPtr:readPtr+2048]
		writePtr=writePtr+2048
		readPtr=readPtr+2352
		sect=sect+1
		if 0==sect%1000:
			print(str(sect)+"/"+str(numSectors))

	data[writePtr:numSectors*2352]=[0]*(numSectors*2352-writePtr)
	data[0:len(IPL)]=IPL

	print("Processing done.  Wait extremely long time for writing output.")

	with open(binOutFName,"wb") as f: f.write(bytearray(data))

	print("The processing done after extremely long wait.  You might be a philosopher by now.")

	return;



if __name__=="__main__":
	main(sys.argv)
