#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include <vector>
#include <string>
#include <unordered_set>
#include <fstream>

#include "d77.h"
#include "../lib/cpplib.h"
#include "../lib/fm7lib.h"



////////////////////////////////////////////////////////////

class D77Analyzer
{
public:
	int diskId;
	bool quit;
	D77File *d77Ptr;
	std::string fName;

	int lastDumpTrk,lastDumpSide,lastDumpSec;

	D77Analyzer();

	void Terminal(D77File &d77);
	std::string GetFileExtension(std::string fName) const;
	void ProcessCommand(const std::vector <std::string> &argv);
	void Help(void) const;
	void DumpSector(int diskId,int cyl,int side,int sec) const;
	void DumpSectorByIndex(int diskId,int cyl,int side,int sec) const;
	void DumpSector(const D77File::D77Disk::D77Sector &sec) const;
	void DumpSectorToFile(const D77File::D77Disk::D77Sector &sec,std::string fName) const;
	bool MoveToNextSector(int diskId,int &cyl,int &side,int &sec) const;
	void DiagnoseDuplicateSector(int diskId) const;
	void FindTrackWithSector(int diskId,int sectorId) const;
	void DeleteDuplicateSector(int diskId);
	void DeleteSectorWithId(int diskId,int sectorId);
	void DeleteSectorByIndex(int diskId,int trk,int sid,int sectorIdx);
	void DeleteSectorByNumber(int diskId,int trk,int sid,int sectorNum);
	void FindData(int diskId,const char str[]) const;
	void ReplaceData(int diskId,const char fromStr[],const char toStr[]);
	void StoreData(int diskId,int trk,int sid,int sec,int addr,const char toStr[]);
	void RenumberSector(int diskId,int track,int side,int secFrom,int secTo) const;
	void ResizeSector(int diskId,int track,int side,int sec,int newSize);
	void SetSectorCRCError(int diskId,int track,int side,int sec,int newError);
	void SetSectorDDM(int diskId,int track,int side,int secId,bool ddm);
	bool FormatTrack(int diskId,int track,int side,int nSec,int secSize);
	bool UnformatTrack(int diskId,int track,int side);
	void Compare(const std::vector <std::string> &argv) const;
	void Franken(const std::vector <std::string> &argv);
};

D77Analyzer::D77Analyzer()
{
	lastDumpTrk=0;
	lastDumpSide=0;
	lastDumpSec=1;
	diskId=0;
	quit=false;
}

void D77Analyzer::Terminal(D77File &d77)
{
	diskId=0;
	d77Ptr=&d77;
	quit=false;
	while(true!=quit)
	{
		printf("Command H:Help>");
		char cmd[256];
		fgets(cmd,255,stdin);

		auto argv=D77File::QuickParser(cmd);
		ProcessCommand(argv);
	}
}

std::string D77Analyzer::GetFileExtension(std::string fName) const
{
	size_t lastDot=0;
	for(size_t i=0; i<fName.size(); ++i)
	{
		if('.'==fName[i])
		{
			lastDot=i;
		}
	}
	std::string ext;
	for(size_t i=lastDot; i<fName.size(); ++i)
	{
		ext.push_back(toupper(fName[i]));
	}
	return ext;
}

void D77Analyzer::ProcessCommand(const std::vector <std::string> &argv)
{
	if(0==argv.size())
	{
		return;
	}
	auto cmd=argv[0];
	FM7Lib::Capitalize(cmd);
	if(cmd[0]=='H')
	{
		Help();
	}
	else if('0'==cmd[0])
	{
		diskId=0;
		printf("Current Disk=%d\n",diskId);
	}
	else if('1'==cmd[0])
	{
		if(nullptr!=d77Ptr->GetDisk(1))
		{
			diskId=1;
		}
		printf("Current Disk=%d\n",diskId);
	}
	else if('2'==cmd[0])
	{
		if(nullptr!=d77Ptr->GetDisk(2))
		{
			diskId=2;
		}
		printf("Current Disk=%d\n",diskId);
	}
	else if('3'==cmd[0])
	{
		if(nullptr!=d77Ptr->GetDisk(3))
		{
			diskId=3;
		}
		printf("Current Disk=%d\n",diskId);
	}
	else if('L'==cmd[0])
	{
		auto diskPtr=d77Ptr->GetDisk(diskId);
		if(nullptr!=diskPtr)
		{
			if(3<=argv.size())
			{
				auto track=FM7Lib::Atoi(argv[1].data());
				auto side=FM7Lib::Atoi(argv[2].data());
				auto trackPtr=diskPtr->GetTrack(track,side);
				if(nullptr!=trackPtr)
				{
					trackPtr->PrintDetailedInfo();
				}
				else
				{
					printf("Track not found.\n");
				}
			}
			else
			{
				diskPtr->PrintInfo();
			}
		}
	}
	else if("C"==cmd)
	{
		if(2<=argv.size())
		{
			Compare(argv);
		}
	}
	else if("FRANKEN"==cmd)
	{
		Franken(argv);
	}
	else if('D'==cmd[0])
	{
		if('F'==cmd[1])  // DF
		{
			if(5<=argv.size())
			{
				auto cyl=FM7Lib::Atoi(argv[1].data());
				auto side=FM7Lib::Atoi(argv[2].data());
				auto sec=FM7Lib::Atoi(argv[3].data());
				auto diskPtr=d77Ptr->GetDisk(diskId);
				if('#'==argv[3][0])
				{
					sec=FM7Lib::Atoi(argv[3].data()+1);
					auto secPtr=diskPtr->GetSectorByIndex(cyl,side,sec-1);
					if(nullptr!=secPtr)
					{
						DumpSectorToFile(*secPtr,argv[4]);
					}
					else
					{
						printf("No Such Sector.\n");
					}
				}
				else
				{
					auto secPtr=diskPtr->GetSector(cyl,side,sec);
					if(nullptr!=secPtr)
					{
						DumpSectorToFile(*secPtr,argv[4]);
					}
					else
					{
						printf("No Such Sector.\n");
					}
				}
			}
			else
			{
				printf("Too few arguments.\n");
			}
		}
		else if('U'==cmd[1])
		{
			if(4<=argv.size())
			{
				auto cyl=FM7Lib::Atoi(argv[1].data());
				auto side=FM7Lib::Atoi(argv[2].data());
				auto sec=FM7Lib::Atoi(argv[3].data());
				auto diskPtr=d77Ptr->GetDisk(diskId);
				decltype(diskPtr->GetSectorByIndex(cyl,side,sec-1)) secPtr;
				if('#'==argv[3][0])
				{
					sec=FM7Lib::Atoi(argv[3].data()+1);
					secPtr=diskPtr->GetSectorByIndex(cyl,side,sec-1);
				}
				else
				{
					secPtr=diskPtr->GetSector(cyl,side,sec);
				}
				if(nullptr!=secPtr && 0<secPtr->unstableByte.size())
				{
					for(int i=0; i<secPtr->unstableByte.size(); ++i)
					{
						printf("%c",(secPtr->unstableByte[i] ? 'U' : '.'));
						if(15==i%16 || i+1==secPtr->unstableByte.size())
						{
							printf("\n");
						}
					}
				}
				else
				{
					printf("No unstable-byte information on that sector.\n");
				}
			}
			else
			{
				printf("Too few arguments.\n");
			}
		}
//		else if("D77EXT"==cmd)
//		{
//			if(2<=argv.size())
//			{
//				std::ofstream ofp(argv[1]);
//				if(true!=ofp.is_open())
//				{
//					printf("Cannot open file.\n");
//					return;
//				}
//
//				auto diskPtr=d77Ptr->GetDisk(diskId);
//				for(auto loc : diskPtr->AllTrack())
//				{
//					std::unordered_set <unsigned int> doneSectors;
//					auto trk=diskPtr->GetTrack(loc.track,loc.side);
//					if(nullptr!=trk)
//					{
//						for(int i=0; i<trk->sector.size(); ++i)
//						{
//							if(doneSectors.end()!=doneSectors.find(trk->sector[i].sector))
//							{
//								continue;
//							}
//							doneSectors.insert(trk->sector[i].sector);
//
//							std::vector <bool> korokoro;
//							korokoro.resize(trk->sector[i].sectorData.size());
//							for(auto &b : korokoro)
//							{
//								b=false;
//							}
//							int count=0;
//							for(int j=i+1; j<trk->sector.size(); ++j)
//							{
//								if(trk->sector[i].sector==trk->sector[j].sector && // Same Number, same size
//								   trk->sector[i].sectorData.size()==trk->sector[j].sectorData.size())
//								{
//									for(int k=0; k<trk->sector[i].sectorData.size(); ++k)
//									{
//										if(trk->sector[i].sectorData[k]!=trk->sector[j].sectorData[k])
//										{
//											korokoro[k]=true;
//											++count;
//										}
//									}
//								}
//							}
//
//							if(0<count)
//							{
//								korokoro.push_back(false);
//
//								bool prev=false;
//								bool first=true;
//								for(int k=0; k<korokoro.size(); ++k)
//								{
//									if(true!=prev && true==korokoro[k])
//									{
//										if(true==first)
//										{
//											ofp << "S " << loc.track << " " << loc.side << " " << (int)trk->sector[i].sector;
//											first=false;
//										}
//										ofp << " KOROKORO " << k << ":";
//									}
//									else if(true==prev && true!=korokoro[k])
//									{
//										ofp << k-1;
//									}
//									prev=korokoro[k];
//								}
//								if(true!=first)
//								{
//									ofp << std::endl;
//								}
//							}
//						}
//					}
//				}
//			}
//			else
//			{
//				printf("Too few arguments.\n");
//			}
//		}
		else
		{
			if(4<=argv.size())
			{
				auto cyl=FM7Lib::Atoi(argv[1].data());
				auto side=FM7Lib::Atoi(argv[2].data());
				auto sec=FM7Lib::Atoi(argv[3].data());
				if('#'==argv[3][0])
				{
					auto diskPtr=d77Ptr->GetDisk(diskId);
					sec=FM7Lib::Atoi(argv[3].c_str()+1);
					auto secPtr=diskPtr->GetSectorByIndex(cyl,side,sec-1);
					if(nullptr!=secPtr)
					{
						DumpSectorByIndex(diskId,cyl,side,sec);
						sec=secPtr->sector; // For next sector.
					}
					else
					{
						printf("No such sector.\n");
					}
				}
				else
				{
					DumpSector(diskId,cyl,side,sec);
				}
				lastDumpTrk=cyl;
				lastDumpSide=side;
				lastDumpSec=sec;
			}
			else if(1==argv.size())
			{
				if(true==MoveToNextSector(diskId,lastDumpTrk,lastDumpSide,lastDumpSec))
				{
					DumpSector(diskId,lastDumpTrk,lastDumpSide,lastDumpSec);
				}
				else
				{
					printf("No more sector.\n");
				}
			}
			else
			{
				printf("Too few arguments.\n");
			}
		}
	}
	else if('F'==cmd[0] && 2<=argv.size())
	{
		FindData(diskId,argv[1].c_str());
	}
	else if('R'==cmd[0] && 3<=argv.size())
	{
		ReplaceData(diskId,argv[1].c_str(),argv[2].c_str());
	}
	else if("SP"==cmd)
	{
		for(auto diskId=0; diskId<d77Ptr->GetNumDisk(); ++diskId)
		{
			char fName[256];
			sprintf(fName,"%d.d77",diskId+1);
			FILE *fp=fopen(fName,"wb");
			if(nullptr!=fp)
			{
				auto diskPtr=d77Ptr->GetDisk(diskId);
				if(nullptr!=diskPtr)
				{
					auto img=diskPtr->MakeD77Image();
					if(0<img.size())
					{
						auto wrote=fwrite(img.data(),1,img.size(),fp);
						if(wrote==img.size())
						{
							printf("Wrote Disk %d\n",diskId);
						}
						else
						{
							printf("Could not write all bytes.\n");
							printf("Disk full maybe?\n");
							break;
						}
					}
				}
				fclose(fp);
				printf("Saved %s.\n",fName);
			}
			else
			{
				printf("Failed to Save %s.\n",fName);
			}
		}
	}
	else if('S'==cmd[0] && 6<=argv.size())
	{
		// S trk side sec addr "pattern"
		// S trk side sec addr 8614BDE000
		auto trk=FM7Lib::Atoi(argv[1].c_str());
		auto sid=FM7Lib::Atoi(argv[2].c_str());
		auto sec=FM7Lib::Atoi(argv[3].c_str());
		auto addr=FM7Lib::Atoi(argv[4].c_str());
		StoreData(diskId,trk,sid,sec,addr,argv[5].c_str());
	}
	else if('X'==cmd[0])
	{
		if(3<=argv.size() && 'D'==argv[1][0] && 0==strcmp(argv[2].c_str(),"DS"))
		{
			DiagnoseDuplicateSector(diskId);
		}
		else if(4<=argv.size() && 'F'==argv[1][0] && 0==strcmp(argv[2].c_str(),"SC"))
		{
			FindTrackWithSector(diskId,FM7Lib::Atoi(argv[3].c_str()));
		}
	}
	else if('W'==cmd[0])
	{
		std::string fName;
		if(2<=argv.size())
		{
			fName=argv[1];
		}
		else
		{
			fName=this->fName;
		}

		auto ext=GetFileExtension(fName);
		if("WRAW"!=cmd && ".RDD"!=ext && ".D77"!=ext && ".BIN"!=ext && ".XDF"!=ext)
		{
			printf("Unsupported file type.\n");
			return;
		}

		FILE *fp=fopen(fName.c_str(),"wb");
		if(nullptr!=fp)
		{
			for(auto diskId=0; diskId<d77Ptr->GetNumDisk(); ++diskId)
			{
				auto diskPtr=d77Ptr->GetDisk(diskId);
				if(nullptr!=diskPtr)
				{
					decltype(diskPtr->MakeD77Image()) img;
					if("WRAW"==cmd || ".BIN"==ext || ".XDF"==ext)
					{
						img=diskPtr->MakeRawImage();
					}
					else if(".D77"==ext)
					{
						img=diskPtr->MakeD77Image();
					}
					else if(".RDD"==ext)
					{
						img=diskPtr->MakeRDDImage();
					}

					if(0<img.size())
					{
						auto wrote=fwrite(img.data(),1,img.size(),fp);
						if(wrote==img.size())
						{
							printf("Wrote Disk %d\n",diskId);
						}
						else
						{
							printf("Could not write all bytes.\n");
							printf("Disk full maybe?\n");
							break;
						}
					}
					else
					{
						printf("Cannot open %s in the writing mode.\n",fName.c_str());
					}
				}
			}
			printf("Saved %s.\n",fName.c_str());
			fclose(fp);
		}
		else
		{
			printf("Failed to create a D77 image.\n");
		}
	}
	else if('M'==cmd[0])
	{
		auto subCmd=argv[1];
		FM7Lib::Capitalize(subCmd);
		if(2<=argv.size() && 0==strcmp("DS",subCmd.c_str()))
		{
			DeleteDuplicateSector(diskId);
		}
		else if(3<=argv.size() && 0==strcmp("MT",subCmd.c_str()))
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr==diskPtr)
			{
				printf("No disk is open.\n");
			}
			else
			{
				if("2HD"==argv[2] || "2hd"==argv[2])
				{
					diskPtr->header.mediaType=0x20;
					printf("Change media type to %s\n",argv[2].c_str());
				}
				else if("2D"==argv[2] || "2d"==argv[2])
				{
					diskPtr->header.mediaType=0;
					printf("Change media type to %s\n",argv[2].c_str());
				}
				else if("2DD"==argv[2] || "2dd"==argv[2])
				{
					diskPtr->header.mediaType=0x10;
					printf("Change media type to %s\n",argv[2].c_str());
				}
				else
				{
					printf("Media type needs to be 2HD, 2DD, or 2D\n");
				}
			}
		}
		else if(3<=argv.size() && 0==strcmp("DL",subCmd.c_str()))
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr==diskPtr)
			{
				printf("No disk is open.\n");
			}
			else if(diskPtr->IsWriteProtected())
			{
				printf("Disk write protected.\n");
			}
			// M DL x  argc==3
			else if(3==argv.size())
			{
				auto sectorId=FM7Lib::Atoi(argv[2].c_str());
				DeleteSectorWithId(diskId,sectorId);
			}
			// M DL trk sid sec  argc=5
			else if(5==argv.size())
			{
				auto trk=FM7Lib::Atoi(argv[2].c_str());
				auto sid=FM7Lib::Atoi(argv[3].c_str());
				int sec;
				if('#'==argv[4][0])
				{
					sec=FM7Lib::Atoi(argv[4].c_str()+1);
					DeleteSectorByIndex(diskId,trk,sid,sec-1);
				}
				else
				{
					sec=FM7Lib::Atoi(argv[4].c_str());
					DeleteSectorByNumber(diskId,trk,sid,sec);
				}
			}
			else
			{
				printf("Incorrect number of arguments.\n");
			}
		}
		else if(6<=argv.size() && 0==strcmp("RN",subCmd.c_str()))
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto sectorFrom=FM7Lib::Atoi(argv[4].c_str());
			auto sectorTo=FM7Lib::Atoi(argv[5].c_str());
			RenumberSector(diskId,track,side,sectorFrom,sectorTo);
		}
		else if(6<=argv.size() && 0==strcmp("SZ",subCmd.c_str()))
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto sector=FM7Lib::Atoi(argv[4].c_str());
			auto newSize=FM7Lib::Atoi(argv[5].c_str());
			ResizeSector(diskId,track,side,sector,newSize);
		}
		else if(6<=argv.size() && 0==strcmp("CRC",subCmd.c_str()))
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto sector=FM7Lib::Atoi(argv[4].c_str());
			auto newError=FM7Lib::Atoi(argv[5].c_str());
			SetSectorCRCError(diskId,track,side,sector,newError);
		}
		else if(6<=argv.size() && "DDM"==subCmd)
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto sector=FM7Lib::Atoi(argv[4].c_str());
			auto newDDM=FM7Lib::Atoi(argv[5].c_str());
			SetSectorDDM(diskId,track,side,sector,newDDM);
		}
		else if(5<=argv.size() && "CS"==subCmd)
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto sec=FM7Lib::Atoi(argv[4].c_str());
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				auto secDat=diskPtr->ReadSector(track,side,sec);
				if(0<secDat.size())
				{
					for(auto &d : secDat)
					{
						d=0;
					}
					diskPtr->WriteSector(track,side,sec,secDat.size(),secDat.data());
				}
				else
				{
					fprintf(stderr,"Cannot access the sector.\n");
				}
			}
		}
		else if(4<=argv.size() && "CT"==subCmd)
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				auto trkPtr=diskPtr->FindTrack(track,side);
				if(nullptr!=trkPtr)
				{
					for(auto &s : trkPtr->AllSector())
					{
						auto secData=diskPtr->ReadSector(s.track,s.side,s.sector);
						if(0<secData.size())
						{
							for(auto &b : secData)
							{
								b=0;
							}
							diskPtr->WriteSector(s.track,s.side,s.sector,secData.size(),secData.data());
						}
					}
				}
			}
		}
		else if(2<=argv.size() && "WPON"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				diskPtr->SetWriteProtected();
				printf("Set Write Protect.\n");
			}
		}
		else if(2<=argv.size() && "WPOFF"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				diskPtr->ClearWriteProtected();
				printf("Cleared Write Protect.\n");
			}
		}
		else if(6<=argv.size() && "FMT"==subCmd)
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto nSec=FM7Lib::Atoi(argv[4].c_str());
			auto size=FM7Lib::Atoi(argv[5].c_str());
			FormatTrack(diskId,track,side,nSec,size);
		}
		else if(4<=argv.size() && "UFMT"==subCmd)
		{
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			UnformatTrack(diskId,track,side);
		}
		else if(6<=argv.size() && "ADSC"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			auto track=FM7Lib::Atoi(argv[2].c_str());
			auto side=FM7Lib::Atoi(argv[3].c_str());
			auto secId=FM7Lib::Atoi(argv[4].c_str());
			auto size=FM7Lib::Atoi(argv[5].c_str());
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					diskPtr->AddSector(track,side,secId,size);
				}
			}
		}
		else if(6<=argv.size() && "CPSC"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			auto track1=FM7Lib::Atoi(argv[2].c_str());
			auto side1=FM7Lib::Atoi(argv[3].c_str());
			auto secId1=FM7Lib::Atoi(argv[4].c_str());
			auto track2=FM7Lib::Atoi(argv[5].c_str());
			auto side2=FM7Lib::Atoi(argv[6].c_str());
			auto secId2=FM7Lib::Atoi(argv[7].c_str());
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					auto dat=diskPtr->ReadSector(track1,side1,secId1);
					auto nByte=diskPtr->WriteSector(track2,side2,secId2,dat.size(),dat.data());
					printf("Wrote %d bytes.\n",nByte);
				}
			}
		}
		else if(6<=argv.size() && "CPTR"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			auto track1=FM7Lib::Atoi(argv[2].c_str());
			auto side1=FM7Lib::Atoi(argv[3].c_str());
			auto track2=FM7Lib::Atoi(argv[4].c_str());
			auto side2=FM7Lib::Atoi(argv[5].c_str());
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					auto fromTrk=diskPtr->GetTrack(track1,side1);
					auto toTrk=diskPtr->GetTrack(track2,side2);
					if(fromTrk==toTrk)
					{
					}
					else if(nullptr!=fromTrk && nullptr!=toTrk)
					{
						diskPtr->CopyTrack(track2,side2,track1,side1);
						printf("Copied track %d side %d to track %d side %d\n",track1,side1,track2,side2);
					}
					else if(nullptr==fromTrk)
					{
						printf("Source track doesn't exist.\n");
					}
					else if(nullptr==toTrk)
					{
						printf("Destination track doesn't exist.\n");
					}
				}
			}
		}
		else if(9<=argv.size() && "CHRN"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				auto track=FM7Lib::Atoi(argv[2].c_str());
				auto side=FM7Lib::Atoi(argv[3].c_str());
				auto secId=FM7Lib::Atoi(argv[4].c_str());
				auto c=FM7Lib::Atoi(argv[5].c_str());
				auto h=FM7Lib::Atoi(argv[6].c_str());
				auto r=FM7Lib::Atoi(argv[7].c_str());
				auto n=FM7Lib::Atoi(argv[8].c_str());
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					diskPtr->SetSectorCHRN(track,side,secId,c,h,r,n);
				}
			}
		}
		else if(9<=argv.size() && "CHRN"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				auto track=FM7Lib::Atoi(argv[2].c_str());
				auto side=FM7Lib::Atoi(argv[3].c_str());
				auto secId=FM7Lib::Atoi(argv[4].c_str());
				auto c=FM7Lib::Atoi(argv[5].c_str());
				auto h=FM7Lib::Atoi(argv[6].c_str());
				auto r=FM7Lib::Atoi(argv[7].c_str());
				auto n=FM7Lib::Atoi(argv[8].c_str());
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					
					diskPtr->SetSectorCHRN(track,side,secId,c,h,r,n);
				}
			}
		}
		else if(10<=argv.size() && "REPLCHRN"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				auto c0=FM7Lib::Atoi(argv[2].c_str());
				auto h0=FM7Lib::Atoi(argv[3].c_str());
				auto r0=FM7Lib::Atoi(argv[4].c_str());
				auto n0=FM7Lib::Atoi(argv[5].c_str());
				auto c=FM7Lib::Atoi(argv[6].c_str());
				auto h=FM7Lib::Atoi(argv[7].c_str());
				auto r=FM7Lib::Atoi(argv[8].c_str());
				auto n=FM7Lib::Atoi(argv[9].c_str());
				if(diskPtr->IsWriteProtected())
				{
					printf("Write protected\n");
				}
				else
				{
					
					diskPtr->ReplaceSectorCHRN(c0,h0,r0,n0,c,h,r,n);
				}
			}
		}
		else if(6<=argv.size() && "W"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					fprintf(stderr,"Write protected\n");
				}
				else
				{
					auto track=FM7Lib::Atoi(argv[2].c_str());
					auto side=FM7Lib::Atoi(argv[3].c_str());
					auto secId=FM7Lib::Atoi(argv[4].c_str());

					auto newSecDat=FM7Lib::ReadBinaryFile(argv[5].c_str());
					if(0==newSecDat.size())
					{
						fprintf(stderr,"Cannot read %s\n",argv[5].c_str());
					}

					std::string allText;
					for(auto c : newSecDat)
					{
						if(('a'<=c && c<='f') || ('A'<=c && c<='F') || ('0'<=c && c<='9'))
						{
							allText.push_back(c);
						}
					}
					printf("%s\n",allText.c_str());
					auto dat=diskPtr->ReadSector(track,side,secId);
					if(0<dat.size())
					{
						for(int i=0,ptr=0; i<dat.size() && ptr+2<=allText.size(); ++i,ptr+=2)
						{
							char wd[3]={allText[ptr],allText[ptr+1],0};
							dat[i]=FM7Lib::Xtoi(wd);
						}
						diskPtr->WriteSector(track,side,secId,dat.size(),dat.data());

						printf("Updated Track=%d Side=%d Sector=%d\n",track,side,secId);
					}
					else
					{
						fprintf(stderr,"Cannot find the sector.\n");
					}
				}
			}
		}
		else if(6<=argv.size() && "WS"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					fprintf(stderr,"Write protected\n");
				}
				else
				{
					auto track=FM7Lib::Atoi(argv[2].c_str());
					auto side=FM7Lib::Atoi(argv[3].c_str());
					auto secId=FM7Lib::Atoi(argv[4].c_str());

					auto srec=FM7Lib::ReadTextFile(argv[5].c_str());
					FM7BinaryFile binDat;
					if(0>srec.size() || true!=binDat.DecodeSREC(srec))
					{
						fprintf(stderr,"Cannot read %s\n",argv[5].c_str());
						return;
					}

					auto dat=diskPtr->ReadSector(track,side,secId);
					if(0<dat.size())
					{
						for(int i=0; i<dat.size() && binDat.dat.size(); ++i)
						{
							dat[i]=binDat.dat[i];
						}
						diskPtr->WriteSector(track,side,secId,dat.size(),dat.data());

						printf("Updated Track=%d Side=%d Sector=%d\n",track,side,secId);
					}
					else
					{
						fprintf(stderr,"Cannot find the sector.\n");
					}
				}
			}
		}
		else if(6<=argv.size() && "WB"==subCmd)
		{
			auto diskPtr=d77Ptr->GetDisk(diskId);
			if(nullptr!=diskPtr)
			{
				if(diskPtr->IsWriteProtected())
				{
					fprintf(stderr,"Write protected\n");
				}
				else
				{
					auto track=FM7Lib::Atoi(argv[2].c_str());
					auto side=FM7Lib::Atoi(argv[3].c_str());
					auto secId=FM7Lib::Atoi(argv[4].c_str());

					auto newSecDat=FM7Lib::ReadBinaryFile(argv[5].c_str());
					if(0==newSecDat.size())
					{
						fprintf(stderr,"Cannot read %s\n",argv[5].c_str());
					}

					auto dat=diskPtr->ReadSector(track,side,secId);
					if(0<dat.size())
					{
						for(int i=0; i<dat.size() && i<=newSecDat.size(); ++i)
						{
							dat[i]=newSecDat[i];
						}
						diskPtr->WriteSector(track,side,secId,dat.size(),dat.data());

						printf("Updated Track=%d Side=%d Sector=%d\n",track,side,secId);
					}
					else
					{
						fprintf(stderr,"Cannot find the sector.\n");
					}
				}
			}
		}
	}
	else if('Q'==cmd[0])
	{
		quit=true;
	}
}

void D77Analyzer::Help(void) const
{
	printf("Q\n");
	printf("\tQuit\n");
	printf("0\n");
	printf("\tCurrent Disk=0\n");
	printf("1\n");
	printf("\tCurrent Disk=1\n");
	printf("2\n");
	printf("\tCurrent Disk=2\n");
	printf("3\n");
	printf("\tCurrent Disk=3\n");
	printf("L\n");
	printf("\tList Track Info.\n");
	printf("L track side\n");
	printf("\tList Track Info.\n");
	printf("F hexadecimal\n");
	printf("\tFind Data.\n");
	printf("\tExample: F 860AB7FD18\n");
	printf("R hexadecimal hexadecimal\n");
	printf("\tReplace Data.\n");
	printf("\tExample: R 8e7f0086ff 8e7f008600\n");
	printf("C diskimage.d77\n");
	printf("\tCompare disk image.\n");
	printf("D track side sec\n");
	printf("\tDump sector.\n");
	printf("DU track side sec\n");
	printf("\tDump unstable-byte info.\n");
	printf("FRANKEN file.d77 file.d77 ....\n");
	printf("\Make a franken disk by taking good sectors from specified d77 and replace bad sectors in the\n");
	printf("\tcurrent d77.\n");
	printf("DF track side sec filename.bin\n");
	printf("\tDump sector to a binary file.\n");
	printf("W\n");
	printf("\tWrite disk to the original .D77 file.\n");
	printf("W filename\n");
	printf("\tWrite disk to a .D77 file.\n");
	printf("\tCurrnent disk only.  It doesn't write multi-disk D77.\n");
	printf("SP\n");
	printf("\tWrite multi-disk image to single-disk images 1.d77 2.d77 ....\n");
	printf("WRAW filename.bin\n");
	printf("\tWrite Raw Binary.\n");
//	printf("D77EXT filename.D77EXT\n");
//	printf("\tWrite D77EXT file of unstable bytes information.  D77 image\n");
//	printf("\trequires duplicates (multiple-reads) of the sectors of unstable bytes.\n");
	printf("X D DS\n");
	printf("\tDiagnose duplicate sectors.\n");
	printf("X F SC secId\n");
	printf("\tFind Tracks that has a specific sector.\n");
	printf("\tExample: X F SC 0xf7\n");
	printf("M DS\n");
	printf("\tRemove duplicate sectors.\n");
	printf("M MT 2D/2DD/2HD\n");
	printf("\tChange media type.\n");
	printf("M DL sector\n");
	printf("\tDelete sectors with specific sector ID.\n");
	printf("M DL track side sector\n");
	printf("\tDelete selected sector.  Use #N for the sector\n");
	printf("\tto delete Nth sector, not sector N.\n");
	printf("\tUse L command to get the sector index.\n");
	printf("\tExample: M DL 0xf7\n");
	printf("M RN track side sectorFrom sectorTo\n");
	printf("\tRenumber sector.\n");
	printf("M CS trk sid sec\n");
	printf("\tClear the sector with all zero.\n");
	printf("M SZ trk sid sec size\n");
	printf("\tChange the sector size.  Size must be 128,256,512, or 1024\n");
	printf("M FMT trk side nSec size\n");
	printf("\tFormat a track with nSec sectors each of which is size bytes.\n");
	printf("\tSize must be 128,256,512, or 1024\n");
	printf("M UFMT trk side\n");
	printf("\tUnformat a track.\n");
	printf("M ADSC trk side secId size\n");
	printf("\tAdd a sector in the specified track.\n");
	printf("M CPSC trk1 side1 secId1 trk2 side2 secId2\n");
	printf("\tCopy sector 1 to 2.\n");
	printf("M CPTR trk1 side1 trk2 side2\n");
	printf("\tCopy track 1 to 2.\n");
	printf("M CHRN trk side secId C H R N\n");
	printf("\tSet CHRN to a sector in the specified track.\n");
	printf("M REPLCHRN C0 H0 R0 N0 C H R N\n");
	printf("\tSet CHRN to a sector that has CHRN=C0H0R0N0.\n");
	printf("M CRC trk sid sec 1/0\n");
	printf("\tChange the sector CRC error status.\n");
	printf("\tGive -1 as sec to set CRC error to all the sectors in the track.\n");
	printf("M WB trk sid sec input_file\n");
	printf("\tWrite binary file to the sector.\n");
	printf("\tSize longer than the sector length will be ignored.\n");
	printf("\tIf the file size is shorter than the sector length, only up to the binary-size bytes will be updated.\n");
	printf("M W trk sid sec input_file\n");
	printf("\tWrite binary dump to the sector.\n");
	printf("\tInput file must be a text file of hexadecimal numbers\n");
	printf("\tSpaces and line breaks will be ignored.\n");
	printf("\tMore bytes than the sector size will be ignored.\n");
	printf("M WS trk sid sec srec_input_file\n");
	printf("\tWrite SREC binary to the sector.\n");
	printf("M CT trk sid\n");
	printf("M DDM trk sid sec 1/0\n");
	printf("\tChange the sector DDM.\n");
	printf("\tGive -1 as sec to set DDM to all the sectors in the track.\n");
	printf("M CT trk sid\n");
	printf("\tClear the track with all zero.\n");
	printf("M WPON\n");
	printf("\tWrite protect the disk.\n");
	printf("M WPOFF\n");
	printf("\tRemove write protect.\n");
}

void D77Analyzer::DumpSectorByIndex(int diskId,int cyl,int side,int idx) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		auto secPtr=diskPtr->GetSectorByIndex(cyl,side,idx);
		if(nullptr!=secPtr)
		{
			DumpSector(*secPtr);
		}
		else
		{
			printf("No such sector.\n");
		}
	}
	else
	{
		printf("Disk is not open.\n");
	}
}

void D77Analyzer::DumpSector(int diskId,int cyl,int side,int sec) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		bool appeared=false;
		auto trackPtr=diskPtr->FindTrack(cyl,side);
		for(auto &s : trackPtr->sector)
		{
			if(s.sector==sec)
			{
				appeared=true;
				DumpSector(s);
			}
		}
		if(true!=appeared)
		{
			printf("No such sector.\n");
		}
		else
		{
			printf("\n");
		}
	}
	else
	{
		printf("Disk is not open.\n");
	}
}

void D77Analyzer::DumpSector(const D77File::D77Disk::D77Sector &s) const
{
	printf("Disk:%d Track:%d Side:%d Sector:%d\n",diskId,s.cylinder,s.head,s.sector);
	for(int i=0; i<s.sectorData.size(); ++i)
	{
		if(0==i%16)
		{
			printf("%04x ",i);
		}
		printf(" %02x",s.sectorData[i]);
		if(15==i%16 || i==s.sectorData.size()-1)
		{
			printf("|");
			int i0=(i&0xfffffff0);
			for(int j=i0; j<=i; ++j)
			{
				if(' '<=s.sectorData[j] && s.sectorData[j]<128)
				{
					printf("%c",s.sectorData[j]);
				}
				else
				{
					printf(".");
				}
			}

			printf("\n");
		}
	}
}

void D77Analyzer::DumpSectorToFile(const D77File::D77Disk::D77Sector &sec,std::string fName) const
{
	FILE *fp=fopen(fName.c_str(),"wb");
	if(nullptr!=fp)
	{
		fwrite(sec.sectorData.data(),1,sec.sectorData.size(),fp);
		fclose(fp);
		printf("Wrote %s\n",fName);
	}
	else
	{
		printf("Could not write to file.\n");
	}
}

bool D77Analyzer::MoveToNextSector(int diskId,int &trk,int &side,int &sec) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		auto trkPtr=diskPtr->FindTrack(trk,side);
		if(nullptr!=trkPtr)
		{
			while(sec<256)
			{
				++sec;
				if(nullptr!=trkPtr->FindSector(sec))
				{
					return true;
				}
			}
		}

		while(trk<90)
		{
			++side;
			if(2<=side)
			{
				side=0;
				++trk;
			}

			auto trkPtr=diskPtr->FindTrack(trk,side);
			if(nullptr!=trkPtr)
			{
				for(sec=1; sec<256; ++sec)
				{
					if(nullptr!=trkPtr->FindSector(sec))
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}

void D77Analyzer::DiagnoseDuplicateSector(int diskId) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		for(auto &loc : diskPtr->AllTrack())
		{
			auto trkPtr=diskPtr->FindTrack(loc.track,loc.side);
			if(nullptr==trkPtr)
			{
				continue;
			}
			auto &t=*trkPtr;
			for(int i=0; i<t.sector.size(); ++i)
			{
				auto &s0=t.sector[i];
				for(int j=i+1; j<t.sector.size(); ++j)
				{
					auto &s1=t.sector[j];
					if(s0.sector==s1.sector)
					{
						bool diff=false;
						if(s0.sectorData.size()!=s1.sectorData.size())
						{
							diff=true;
						}
						else
						{
							for(int i=0; i<s0.sectorData.size(); ++i)
							{
								if(s0.sectorData[i]!=s1.sectorData[i])
								{
									diff=true;
									break;
								}
							}
						}

						printf("Duplicate Sector Track:%d Side:%d Sector:%d ",s0.cylinder,s0.head,s0.sector);
						if(true==diff)
						{
							printf("!!!Different Content!!!\n");
						}
						else
						{
							printf("Identical Content.\n");
						}
					}
				}
			}
		}
	}
}

void D77Analyzer::FindTrackWithSector(int diskId,int sectorId) const
{
	bool found=false;
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		for(auto trkLoc : diskPtr->AllTrack())
		{
			auto trkPtr=diskPtr->FindTrack(trkLoc.track,trkLoc.side);
			if(nullptr==trkPtr)
			{
				continue;
			}
			auto &t=*trkPtr;
			for(auto secLoc : t.AllSector())
			{
				if(secLoc.sector==sectorId)
				{
					found=true;
					t.PrintInfo();
					break;
				}
			}
		}
	}
	if(true!=found)
	{
		printf("No track has sector %d(0x%02x)\n",sectorId,sectorId);
	}
}

void D77Analyzer::DeleteDuplicateSector(int diskId)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		for(auto trkLoc : diskPtr->AllTrack())
		{
			// diskPtr->DeleteDuplicateSector(trkLoc.track,trkLoc.side);

			// Make it corocoro aware.
			auto trkPtr=diskPtr->FindTrack(trkLoc.track,trkLoc.side);
			auto &t=*trkPtr;
			for(int i=0; i<trkPtr->sector.size(); ++i)
			{
				std::vector <int> duplicateIdx;
				duplicateIdx.push_back(i);
				for(int j=i+1; j<trkPtr->sector.size(); ++j)
				{
					auto &si=trkPtr->sector[i];
					auto &sj=trkPtr->sector[j];
					if(sj.cylinder==si.cylinder &&
					   sj.head==si.head &&
					   sj.sector==si.sector &&
					   sj.sizeShift==si.sizeShift)
					{
						duplicateIdx.push_back(j);
					}
				}
				if(1<duplicateIdx.size())
				{
					int toLeave=duplicateIdx[0];
					// Which sector to leave?
					if(0xF7==trkPtr->sector[i].sector)
					{
						for(auto idx : duplicateIdx)
						{
							bool corocoro=true;
							auto &sec=trkPtr->sector[idx];
							for(int i=0; i<20; ++i)
							{
								if(sec.sectorData[i]!=0xF7)
								{
									corocoro=false;
									break;
								}
							}
							for(int i=0; i<19; ++i)
							{
								if(sec.sectorData[i+24]!=0xF6)
								{
									corocoro=false;
									break;
								}
							}
							if(true==corocoro)
							{
								printf("Found Corocoro Protect V2.\n");
								toLeave=idx;
								break;
							}
						}
					}

					for(size_t i=duplicateIdx.size()-1; 0<=i && i<duplicateIdx.size(); --i)
					{
						if(duplicateIdx[i]!=toLeave)
						{
							trkPtr->sector.erase(trkPtr->sector.begin()+duplicateIdx[i]);
						}
					}

					--i;
				}
			}
			for(auto &sec : trkPtr->sector)
			{
				sec.nSectorTrack=trkPtr->sector.size();
			}
		}
	}
}

void D77Analyzer::DeleteSectorWithId(int diskId,int sectorId)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		for(auto trkLoc : diskPtr->AllTrack())
		{
			diskPtr->DeleteSectorWithId(trkLoc.track,trkLoc.side,sectorId);
		}
	}
}

void D77Analyzer::DeleteSectorByIndex(int diskId,int trk,int sid,int sectorIdx)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		diskPtr->DeleteSectorByIndex(trk,sid,sectorIdx);
	}
}

void D77Analyzer::DeleteSectorByNumber(int diskId,int trk,int sid,int sectorNum)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		diskPtr->DeleteSectorWithId(trk,sid,sectorNum);
	}
}

void D77Analyzer::FindData(int diskId,const char str[]) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		auto ptn=FM7Lib::StrToByteArray(str);
		for(auto trkLoc : diskPtr->AllTrack())
		{
			auto trkPtr=diskPtr->FindTrack(trkLoc.track,trkLoc.side);
			if(nullptr==trkPtr)
			{
				continue;
			}
			auto &t=*trkPtr;
			for(auto found : t.Find(ptn))
			{
				printf("Found Track:%d Side:%d Sector:%d(0x%x) Addr:%04x\n",
				    found.track,
				    found.side,
				    found.sector,found.sector,
				    found.addr);
			}
		}
	}
}

void D77Analyzer::ReplaceData(int diskId,const char fromStr[],const char toStr[])
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true==diskPtr->IsWriteProtected())
		{
			printf("Write protected.\n");
			return;
		}

		auto from=FM7Lib::StrToByteArray(fromStr);
		auto to=FM7Lib::StrToByteArray(toStr);
		if(from.size()!=to.size())
		{
			printf("FROM and TO must be the same size.\n");
			return;
		}
		diskPtr->ReplaceData(from,to);
	}
}

void D77Analyzer::StoreData(int diskId,int trk,int sid,int sec,int addr,const char toStr[])
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true==diskPtr->IsWriteProtected())
		{
			printf("Write protected.\n");
			return;
		}

		auto to=FM7Lib::StrToByteArray(toStr);

		auto secData=diskPtr->ReadSector(trk,sid,sec);
		if(secData.size()<addr+to.size())
		{
			fprintf(stderr,"Overflow.\n");
			return;
		}

		for(auto d : to)
		{
			secData[addr]=d;
			++addr;
		}
		diskPtr->WriteSector(trk,sid,sec,secData.size(),secData.data());
	}
}

void D77Analyzer::RenumberSector(int diskId,int track,int side,int secFrom,int secTo) const
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		diskPtr->RenumberSector(track,side,secFrom,secTo);
	}
}

void D77Analyzer::ResizeSector(int diskId,int track,int side,int sec,int newSize)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true!=diskPtr->ResizeSector(track,side,sec,newSize))
		{
			fprintf(stderr,"Failed to resize sector.\n");
		}
	}
}
void D77Analyzer::SetSectorCRCError(int diskId,int track,int side,int sec,int newError)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true!=diskPtr->SetCRCError(track,side,sec,(0!=newError)))
		{
			fprintf(stderr,"Failed to change CRC error status.\n");
		}
	}
}

void D77Analyzer::SetSectorDDM(int diskId,int track,int side,int secId,bool ddm)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true!=diskPtr->SetDDM(track,side,secId,ddm))
		{
			fprintf(stderr,"Failed to change DDM (Deleted Data) status.\n");
		}
	}
}

bool D77Analyzer::FormatTrack(int diskId,int track,int side,int nSec,int secSize)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true==diskPtr->IsWriteProtected())
		{
			printf("Write protected.\n");
			return false;
		}

		std::vector <D77File::D77Disk::D77Sector> sec;
		sec.resize(nSec);
		for(int i=0; i<nSec; ++i)
		{
			if(true!=sec[i].Make(track,side,i+1,secSize))
			{
				return false;
			}
			sec[i].nSectorTrack=nSec;
		}
		diskPtr->WriteTrack(track,side,sec.size(),sec.data());
		return true;
	}
	return false;
}

bool D77Analyzer::UnformatTrack(int diskId,int track,int side)
{
	auto diskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr!=diskPtr)
	{
		if(true==diskPtr->IsWriteProtected())
		{
			printf("Write protected.\n");
			return false;
		}
		diskPtr->WriteTrack(track,side,0,nullptr);
		return true;
	}
	return false;
}

void D77Analyzer::Compare(const std::vector <std::string> &argv) const
{
	printf("Compare Disks\n");

	if(2>argv.size())
	{
		fprintf(stderr,"Too few arguments.\n");
		return;
	}


	D77File bDiskD77;
	auto raw=FM7Lib::ReadBinaryFile(argv[1].c_str());
	if(0<raw.size())
	{
		auto ext=GetFileExtension(argv[1]);
		if(".D77"==ext)
		{
			bDiskD77.SetData(raw);
		}
		else if(".RDD"==ext)
		{
			bDiskD77.SetRDDData(raw);
		}
		else if(".BIN"==ext || ".XDF"==ext)
		{
			bDiskD77.SetRawBinary(raw);
		}
		else
		{
			fprintf(stderr,"Unsupported file extension %s\n",argv[1].c_str());
			return;
		}
	}
	else
	{
		fprintf(stderr,"Cannot open %s\n",argv[1].c_str());
		return;
	}

	if(1>bDiskD77.GetNumDisk())
	{
		fprintf(stderr,"No disk in %s\n",argv[1].c_str());
		return;
	}

	auto aDiskPtr=d77Ptr->GetDisk(diskId);
	if(nullptr==aDiskPtr)
	{
		fprintf(stderr,"No disk is open.\n");
		return;
	}

	auto &aDisk=*aDiskPtr;
	auto &bDisk=*bDiskD77.GetDisk(0);

	auto aTrkLoc=aDisk.AllTrack();
	auto bTrkLoc=bDisk.AllTrack();
	if(aTrkLoc.size()!=bTrkLoc.size())
	{
		printf("ADisk and BDisk have different number of tracks.\n");
		printf("ADisk %d tracks.\n",(int)aTrkLoc.size());
		printf("BDisk %d tracks.\n",(int)bTrkLoc.size());
	}

	for(auto trkLoc : aTrkLoc)
	{
		auto aTrackPtr=aDisk.FindTrack(trkLoc.track,trkLoc.side);
		auto bTrackPtr=bDisk.FindTrack(trkLoc.track,trkLoc.side);

		if(nullptr==bTrackPtr)
		{
			printf("BDisk does not have track %d side %d formatted.\n",trkLoc.track,trkLoc.side);
			continue;
		}

		auto aSecLoc=aTrackPtr->AllSector();
		auto bSecLoc=aTrackPtr->AllSector();
		for(auto secLoc : aSecLoc)
		{
			if(nullptr==bTrackPtr->FindSector(secLoc.sector))
			{
				printf("Track %d Side %d Sector %d does not exist in BDisk\n",secLoc.track,secLoc.side,secLoc.sector);
			}
		}
		for(auto secLoc : bSecLoc)
		{
			if(nullptr==aTrackPtr->FindSector(secLoc.sector))
			{
				printf("Track %d Side %d Sector %d does not exist in ADisk\n",secLoc.track,secLoc.side,secLoc.sector);
			}
		}

		for(auto secLoc : aSecLoc)
		{
			auto aSecPtr=aTrackPtr->FindSector(secLoc.sector);
			auto bSecPtr=bTrackPtr->FindSector(secLoc.sector);
			if(nullptr!=aSecPtr && nullptr!=bSecPtr)
			{
				if(aSecPtr->sectorData.size()!=bSecPtr->sectorData.size())
				{
					printf("Track %d Side %d Sector %d have different size.\n",secLoc.track,secLoc.side,secLoc.sector);
					printf("ADisk %d bytes\n",(int)aSecPtr->sectorData.size());
					printf("BDisk %d bytes\n",(int)bSecPtr->sectorData.size());
				}
				else
				{
					for(int i=0; i<aSecPtr->sectorData.size(); ++i)
					{
						if(aSecPtr->sectorData[i]!=bSecPtr->sectorData[i])
						{
							printf("Different!  Track %d Side %d Sector %d (Offset %04x)\n",secLoc.track,secLoc.side,secLoc.sector,i);
							goto NEXTSECTOR;
						}
					}
				}
			}
		NEXTSECTOR:
			;
		}
	}
}

void D77Analyzer::Franken(const std::vector <std::string> &argv)
{
	printf("Franken Disks\n");

	if(2>argv.size())
	{
		fprintf(stderr,"Too few arguments.\n");
		return;
	}


	for(int i=1; i<argv.size(); ++i)
	{
		D77File bDiskD77;
		auto raw=FM7Lib::ReadBinaryFile(argv[i].c_str());
		if(0<raw.size())
		{
			bDiskD77.SetData(raw);
		}
		else
		{
			fprintf(stderr,"Cannot open %s\n",argv[1].c_str());
			return;
		}

		if(1>bDiskD77.GetNumDisk())
		{
			fprintf(stderr,"No disk in %s\n",argv[1].c_str());
			return;
		}

		auto aDiskPtr=d77Ptr->GetDisk(diskId);
		if(nullptr==aDiskPtr)
		{
			fprintf(stderr,"No disk is open.\n");
			return;
		}

		auto &aDisk=*aDiskPtr;
		auto &bDisk=*bDiskD77.GetDisk(0);

		auto numCylA=aDisk.AllTrack().size()/2;
		auto numCylB=bDisk.AllTrack().size()/2;
		if(numCylA<numCylB)
		{
			aDisk.SetNumTrack(numCylB);
			printf("Increased number of tracks to %d\n",numCylB);
		}

		for(int C=0; C<aDisk.AllTrack().size() ; ++C)
		{
			for(int H=0; H<2; ++H)
			{
				auto trkA=aDisk.GetTrack(C,H);
				auto trkB=bDisk.GetTrack(C,H);
				if(nullptr!=trkA)
				{
				RETRY:
					for(int i=0; i<trkA->sector.size(); ++i)
					{
						auto &secI=trkA->sector[i];
						for(int j=i+1; j<trkA->sector.size(); ++j)
						{
							auto &secJ=trkA->sector[j];
							if(secI.cylinder==secJ.cylinder &&
							   secI.head==secJ.head &&
							   secI.sector==secJ.sector &&
							   secI.sizeShift==secJ.sizeShift)
							{
								if(0==secI.crcStatus && 0!=secJ.crcStatus)
								{
									printf("Erase C%d H%d R%d N%d\n",
									   secJ.cylinder,
									   secJ.head,
									   secJ.sector,
									   secJ.sizeShift);
									trkA->sector.erase(trkA->sector.begin()+j);
									goto RETRY;
								}
								else if(0!=secI.crcStatus && 0==secJ.crcStatus)
								{
									printf("Erase C%d H%d R%d N%d\n",
									   secI.cylinder,
									   secI.head,
									   secI.sector,
									   secI.sizeShift);
									trkA->sector.erase(trkA->sector.begin()+i);
									goto RETRY;
								}
							}
						}
					}

					if(nullptr!=trkB)
					{
						for(auto &secJ : trkB->sector)
						{
							bool foundInTrackA=false;
							for(auto &secI : trkA->sector)
							{
								if(secI.cylinder==secJ.cylinder &&
								   secI.head==secJ.head &&
								   secI.sector==secJ.sector &&
								   secI.sizeShift==secJ.sizeShift)
								{
									foundInTrackA=true;
									if(0!=secI.crcStatus && 0==secJ.crcStatus)
									{
										printf("Replace C%d H%d R%d N%d\n",
										   secI.cylinder,
										   secI.head,
										   secI.sector,
										   secI.sizeShift);
										secI=secJ;
									}
								}
							}
							if(true!=foundInTrackA)
							{
								printf("Added C%d H%d R%d N%d\n",
								   secJ.cylinder,
								   secJ.head,
								   secJ.sector,
								   secJ.sizeShift);
								trkA->sector.push_back(secJ);
							}
						}
					}

					for(auto &sec : trkA->sector)
					{
						sec.nSectorTrack=trkA->sector.size();
					}
				}
			}
		}
	}
}

////////////////////////////////////////////////////////////

int main(int ac,char *av[])
{
	bool readRaw=false;
	const char *fName=av[1];

	if(3<=ac && (0==strcmp("-new",av[1]) || 0==strcmp("-NEW",av[1])))
	{
		D77File d77;
		d77.CreateStandardFormatted();
		D77Analyzer term;
		term.fName=av[2];
		term.Terminal(d77);
		return 0;
	}
	if(3<=ac && (0==strcmp("-raw",av[1]) || 0==strcmp("-RAW",av[1])))
	{
		fName=av[2];
		readRaw=true;
	}

	if(2>ac)
	{
		printf("Usage:\n");
		printf("  d77analyze filename.d77/.rdd\n");
		printf("    or\n");
		printf("  d77analyze -new filename.d77\n");
		printf("    or\n");
		printf("  d77analyze -raw filename.bin\n");
		return 1;
	}

	std::vector <unsigned char> dat;
	FILE *fp=fopen(fName,"rb");
	if(nullptr==fp)
	{
		return 1;
	}

	fseek(fp,0,SEEK_END);
	auto fsize=ftell(fp);
	fseek(fp,0,SEEK_SET);

	dat.resize(fsize);
	fread(dat.data(),1,fsize,fp);

	fclose(fp);


	D77File d77;
	if(true!=readRaw)
	{
		if(16<fsize && 0==strncmp((const char *)dat.data(),"REALDISKDUMP",12))
		{
			d77.SetRDDData(dat);
		}
		else
		{
			d77.SetData(dat);
		}
	}
	else
	{
		if(true!=d77.SetRawBinary(dat,false))
		{
			return 1;
		}

	}
	d77.PrintInfo();

	D77Analyzer term;
	term.fName=av[1];
	term.Terminal(d77);

	return 0;
}
