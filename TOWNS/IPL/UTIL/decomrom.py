# decomrom.py - Decompose combined ROM file transmitted by XMODEM to individual ROM files.

import os
import sys



def Error(msg):
	print("ERROR:"+msg)
	quit()



def Help():
	print("decomrom.py - Decompose combined ROM file transmitted via XMODEM to individual ROM files.")
	print("by CaptainYS")
	print("Usage:")
	print("  decomrom.py combined.bin")
	print("")
	print("This program decomposes ROM files transmitted from actual FM TOWNS unit by the IPL using")
	print("XMODEM into individual ROM files.")



def main(argv):
	if(len(argv)!=2):
		Help()
		quit()

	ifp=open(argv[1],"rb")
	while True:
		header=ifp.read(16)
		if ''==header or 0==len(header):
			break

		fileName=header[0:12]
		sizeByte=[d for d in header[12:]]

		fileSize=sizeByte[0]+0x100*sizeByte[1]+0x10000*sizeByte[2]+0x1000000*sizeByte[3]

		print("File Name="+str(fileName)+"  Size="+str(fileSize))

		binary=ifp.read(fileSize)
		ofp=open(fileName,"wb")
		ofp.write(binary)
		ofp.close()


if __name__=="__main__":
	main(sys.argv)
