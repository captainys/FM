import sys
import os
import mmap



# Can I write:
#   #define PARTITION_TABLE_FILE_OFFSET 512
# or
#   const unsigned int PARTITION_TABLE_FILE_OFFSET=512;
# ?

def PARTITION_TABLE_FILE_OFFSET():
	return int(512)


def SECTOR_LENGTH():
	return int(512)


def MAX_NUM_PARTITIONS():
	return int(10)


def Help():
	print("transpart.py - FM TOWNS HD Image Partition Transplanter.")
	print("by CaptainYS")
	print("Usage:")
	print("  transpart.py SOURCE.BIN SRC_PARTITION_NAME DESTINATION.BIN DST_PARTITION_NAME")
	print("  transpart.py SOURCE.BIN SRC_PARTITION_NAME DESTINATION.BIN DST_PARTITION_NAME BOOT")
	print("")
	print("  CAUTION! Make sure to take a backup copy of your hard-disk image before using")
	print("           this utility!")
	print("")
	print("  This program transplants a partition in the source hard-disk image to the")
	print("  destination hard-disk image.")
	print("")
	print("  If the destination hard-disk image already has the partition name same as the")
	print("  DST_PARTITION_NAME, it will overwrites an existing partition with the same name.")
	print("")
	print("  By adding BOOT as the last parameter, transplanted partition will be marked as")
	print("  BOOT partition.")
	print("")
	print("  Otherwise, it will appends the source partition to the destination hard-disk")
	print("  image.")
	print("")
	print("  I don't know if it can be used for hard-disk image for other computers.")



def ErrorExit(msg):
	print("ERROR!")
	print(msg)
	quit()



def DropLastSpace(s):
	while 0<len(s) and s[-1]==' ':
		s=s[:-1]
	return s



def ReadPartitionTableSector(fName):
	ifp=open(fName,"rb")
	ifp.seek(PARTITION_TABLE_FILE_OFFSET(),0);
	sector=ifp.read(SECTOR_LENGTH())
	ifp.close()
	return sector



def WritePartitionTableSector(fName,sectorData):
	ofp=open(fName,"r+b")
	ofp.seek(PARTITION_TABLE_FILE_OFFSET(),0);
	ofp.write(sectorData)
	ofp.close()



def GetPartitionList(partSect):
	lst=[]
	for i in range(0,MAX_NUM_PARTITIONS()):
		fileOffset=0x20+i*0x30
		bootPart=False
		startSector=0
		sectorCount=0
		partitionName=""
		partitionType=""
		if 0xFF==partSect[fileOffset]:
			bootPart=True
		partitionCode=partSect[fileOffset+1]
		startSector=partSect[fileOffset+2]+partSect[fileOffset+3]*0x100+partSect[fileOffset+4]*0x10000+partSect[fileOffset+5]*0x1000000
		sectorCount=partSect[fileOffset+6]+partSect[fileOffset+7]*0x100+partSect[fileOffset+8]*0x10000+partSect[fileOffset+9]*0x1000000
		for j in range(0,16):
			if partSect[fileOffset+16+j]==0:
				break
			partitionType=partitionType+chr(partSect[fileOffset+16+j])
		for j in range(0,16):
			if partSect[fileOffset+32+j]==0:
				break
			partitionName=partitionName+chr(partSect[fileOffset+32+j])
		partitionType=DropLastSpace(partitionType)
		partitionName=DropLastSpace(partitionName)
		lst.append([bootPart,partitionCode,int(startSector),int(sectorCount),partitionType,partitionName])
	return lst

def PartitionCode(partition):
	return partition[1]

def StartSector(partition):
	return partition[2]

def SectorCount(partition):
	return partition[3]

def PartitionType(partition):
	return partition[4]

def PartitionName(partition):
	return partition[5]



def FindPartition(partName,partList):
	for part in partList:
		if PartitionName(part)==partName:
			return part
	return None



def ErrorIfMultipleMatch(partName,partList):
	count=int(0)
	for part in partList:
		if PartitionName(part)==partName:
			count=count+1
	if 1<count:
		ErrorExit("More than one partition has the name="+partName)


def MakeDestinationPartition(dstFile,dstPartList,dstPartitionName,srcPartition):
	dstSize=os.path.getsize(dstFile)
	dstNumSectors=int(int(dstSize)/SECTOR_LENGTH())

	lastPartIdx=int(0)
	for i in range(0,MAX_NUM_PARTITIONS()):
		if ""!=PartitionName(dstPartList[i]) and 0<SectorCount(dstPartList[i]):
			lastPartIdx=i;
	if 9<=lastPartIdx:
		ErrorExit("Last Partition Entry is Already Used.")

	lastPart=dstPartList[lastPartIdx]
	nextSector=StartSector(lastPart)+SectorCount(lastPart)

	availableSectors=dstNumSectors-nextSector

	if availableSectors<SectorCount(srcPartition):
		extendSectorCount=SectorCount(srcPartition)-availableSectors
		zero=[0]*SECTOR_LENGTH()
		ofp=open(dstFile,"ab")
		for i in range(0,extendSectorCount):
			ofp.write(bytearray(zero))
		ofp.close()


	nextPart=lastPartIdx+1
	nextPartLength=SectorCount(srcPartition)
	partSect=[d for d in ReadPartitionTableSector(dstFile)]
	fileOffset=0x20+nextPart*0x30

	partSect[fileOffset  ]=0	# Not a boot sector
	partSect[fileOffset+1]=PartitionCode(srcPartition)	# 0:Partition Not Present  1:DOS Partition?   90H:OASYS

	partSect[fileOffset+2]= nextSector     &255
	partSect[fileOffset+3]=(nextSector>> 8)&255
	partSect[fileOffset+4]=(nextSector>>16)&255
	partSect[fileOffset+5]=(nextSector>>24)&255

	partSect[fileOffset+6]= nextPartLength     &255
	partSect[fileOffset+7]=(nextPartLength>> 8)&255
	partSect[fileOffset+8]=(nextPartLength>>16)&255
	partSect[fileOffset+9]=(nextPartLength>>24)&255

	for i in range(0,MAX_NUM_PARTITIONS()):
		if i<len(PartitionType(srcPartition)):
			partSect[fileOffset+0x10+i]=ord(PartitionType(srcPartition)[i])
		else:
			partSect[fileOffset+0x10+i]=ord(' ')

	for i in range(0,16):
		if i<len(dstPartitionName):
			partSect[fileOffset+0x20+i]=ord(dstPartitionName[i])
		else:
			partSect[fileOffset+0x20+i]=ord(' ')

	# Debugging >>
	#for part in GetPartitionList(partSect):
	#	print(part)
	# Debugging <<

	WritePartitionTableSector(dstFile,bytearray(partSect))



def MatchDestinationPartitionSize(dstFile,dstPartList,dstPartition,sectorCount):
	partIdx=int(-1)
	for i in range(0,MAX_NUM_PARTITIONS()):
		if PartitionName(dstPartList[i])==PartitionName(dstPartition):
			partIdx=i
			break

	if partIdx<0:
		ErrorExit("Destination Partition Not Found.")

	partSect=[d for d in ReadPartitionTableSector(dstFile)]
	sectorCount=int(sectorCount)

	partSect[0x20+0x30*partIdx+6]=( sectorCount     )&255
	partSect[0x20+0x30*partIdx+7]=((sectorCount)>> 8)&255
	partSect[0x20+0x30*partIdx+8]=((sectorCount)>>16)&255
	partSect[0x20+0x30*partIdx+9]=((sectorCount)>>24)&255

	WritePartitionTableSector(dstFile,bytearray(partSect))



def MakeBootPartition(dstFile,dstPartList,dstPart):
	partIdx=int(-1)
	for i in range(0,MAX_NUM_PARTITIONS()):
		if PartitionName(dstPartList[i])==PartitionName(dstPart):
			partIdx=i
			break

	if partIdx<0:
		ErrorExit("Destination Partition Not Found.")

	partSect=[d for d in ReadPartitionTableSector(dstFile)]

	for i in range(0,MAX_NUM_PARTITIONS()):
		partSect[0x20+0x30*i]=0

	partSect[0x20+0x30*partIdx]=0xFF

	WritePartitionTableSector(dstFile,bytearray(partSect))



def main(argv):
	if len(argv)!=5 and len(argv)!=6:
		Help()
		quit()

	makeBootPartition=False
	if 6==len(argv):
		if argv[5]=="BOOT":
			makeBootPartition=True
		else:
			ErrorExit("Unrecognized last parameter:"+argv[5])

	print("From="+argv[1])
	print("To  ="+argv[3])

	srcSize=os.path.getsize(argv[1])
	dstSize=os.path.getsize(argv[3])
	if 0!=srcSize%512:
		ErrorExit("Source hard disk image size is not 512 times integer.")
	if 0!=dstSize%512:
		ErrorExit("Destination hard disk image size is not 512 times integer.")

	srcPartitionTableSector=ReadPartitionTableSector(argv[1])
	dstPartitionTableSector=ReadPartitionTableSector(argv[3])

	srcPartList=GetPartitionList(srcPartitionTableSector)
	dstPartList=GetPartitionList(dstPartitionTableSector)

	print("<<<Source Hard Disk Image Partitions>>>")
	for part in srcPartList:
		print(part)
	print("<<<Destination Hard Disk Image Partitions>>>")
	for part in dstPartList:
		print(part)

	srcPart=FindPartition(argv[2],srcPartList)
	if None==srcPart:
		ErrorExit("Source Partition not found.")


	ErrorIfMultipleMatch(argv[2],srcPartList)
	ErrorIfMultipleMatch(argv[4],dstPartList)


	print("!!!!Warning!!!!")
	print("Failure of the operation may corrupt your hard-disk image.")
	while True:
		print("Did you take a backup copy of the hard-disk images?")
		sys.stdout.write("  Enter Y or N>")
		sys.stdout.flush()
		yesNo=sys.stdin.readline()
		yesNo=yesNo.replace('\n','')
		if "Y"==yesNo:
			break
		elif "N"==yesNo:
			print("Take a backup copy and try again.")
			quit()
		else:
			print("Please enter Y or N exactly (One letter, capital).")


	dstPart=FindPartition(argv[4],dstPartList)
	if None==dstPart:
		MakeDestinationPartition(argv[3],dstPartList,argv[4],srcPart)
		dstSize=os.path.getsize(argv[3])
		dstPartitionTableSector=ReadPartitionTableSector(argv[3])
		dstPartList=GetPartitionList(dstPartitionTableSector)
		dstPart=FindPartition(argv[4],dstPartList)
		if None==dstPart:
			ErrorExit("Destination Partition was supposed to be created, but something went wrong.")
	elif SectorCount(dstPart)<SectorCount(srcPart):
		ErrorExit("Destination Partition is smaller than Source Partition")
	else:
		MatchDestinationPartitionSize(argv[3],dstPartList,dstPart,SectorCount(srcPart))


	if True==makeBootPartition:
		MakeBootPartition(argv[3],dstPartList,dstPart)
		dstPart[0]=True


	print("Source Partition:")
	print(srcPart)
	print("Destination Partition:")
	print(dstPart)

	copyBytes=SectorCount(srcPart)*SECTOR_LENGTH()

	srcStart=StartSector(srcPart)*SECTOR_LENGTH()
	srcEnd=srcStart+copyBytes
	dstStart=StartSector(dstPart)*SECTOR_LENGTH()
	dstEnd=dstStart+copyBytes

	srcFp=open(argv[1],"r+b")
	dstFp=open(argv[3],"r+b")

	srcMM=mmap.mmap(srcFp.fileno(),0)
	dstMM=mmap.mmap(dstFp.fileno(),0)
	dstMM[dstStart:dstEnd]=srcMM[srcStart:srcEnd]
	dstMM.flush()

	srcFp.close()
	dstFp.close()

	print("Partition Transplantation Completed.")

	return;



if __name__=="__main__":
	main(sys.argv)
