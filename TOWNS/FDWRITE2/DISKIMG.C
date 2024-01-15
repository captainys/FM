#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "DISKIMG.H"
#include "UTIL.H"

void AddrMark_Init(ADDRMARK *addr)
{
	addr->CHRN[0]=0;
	addr->CHRN[1]=0;
	addr->CHRN[2]=0;
	addr->CHRN[3]=0;
	addr->flags=0;
}

void Sector_Init(SECTOR *sector)
{
	sector->CHRN[0]=0;
	sector->CHRN[1]=0;
	sector->CHRN[2]=0;
	sector->CHRN[3]=0;
	sector->flags=0;
	sector->numBytes=0;
	sector->data=NULL;
}

void Sector_Alloc(SECTOR *sector,unsigned int len)
{
	sector->numBytes=len;
	sector->data=(unsigned char *)malloc(len);
}

void Sector_Destroy(SECTOR *sector)
{
	if(NULL!=sector->data)
	{
		free(sector->data);
		sector->data=NULL;
	}
	Sector_Init(sector);
}

void Track_Init(TRACK *track)
{
	track->C=0;
	track->H=0;
	track->numAddrMarks=0;
	track->addrMarks=NULL;
	track->numSectors=0;
	track->sectors=NULL;
}

int Track_Prepare(TRACK *track,int C,int H,int numAddrMarks,int numSectors)
{
	int i;
	Track_Destroy(track);

	track->addrMarks=(ADDRMARK *)malloc(sizeof(ADDRMARK)*numAddrMarks);
	track->sectors=(SECTOR *)malloc(sizeof(SECTOR)*numSectors);
	if(NULL==track->addrMarks || NULL==track->sectors)
	{
		Track_Destroy(track);
		return ERROR_OUT_OF_MEMORY;
	}

	track->C=C;
	track->H=H;
	track->numAddrMarks=numAddrMarks;
	for(i=0; i<numAddrMarks; ++i)
	{
		AddrMark_Init(track->addrMarks+i);
	}
	track->numSectors=numSectors;
	for(i=0; i<numSectors; ++i)
	{
		Sector_Init(track->sectors+i);
	}

	return ERROR_NONE;
}

void Track_Destroy(TRACK *track)
{
	if(NULL!=track->addrMarks)
	{
		free(track->addrMarks);
		track->addrMarks=NULL;
	}
	if(NULL!=track->sectors)
	{
		int i;
		for(i=0; i<track->numSectors; ++i)
		{
			Sector_Destroy(&track->sectors[i]);
		}
		free(track->sectors);
	}
	Track_Init(track);
}

int Track_MakeFormatData(unsigned int *len,unsigned char data[],unsigned long maxLen,const TRACK *track,unsigned char crunchGapLevel)
{
	int err=ERROR_NONE;
	unsigned int ptr=0;

	int i,sec;
	unsigned int len_preGap=32;
	unsigned int len_sync=12;
	unsigned int len_gap2=0x16;
	unsigned int len_gap3=0x36;

	if(0==crunchGapLevel)
	{
		// No change.
	}
	if(1==crunchGapLevel)
	{
		len_preGap=24;
		len_sync=10;
		len_gap2=0x10;
		len_gap3=0x30;
	}
	else
	{
		len_preGap=20;
		len_sync=9;
		len_gap2=0x0C;
		len_gap3=0x26;
	}

	const unsigned char FORMATBYTE_SYNC=0;
	const unsigned char FORMATBYTE_MISSING_CLOCK=0xF5;
	const unsigned char FORMATBYTE_ADDR_MARK=0xFE;
	const unsigned char FORMATBYTE_DATA_MARK=0xFB;
	const unsigned char FORMATBYTE_DELETED_DATA_MARK=0xF8;
	const unsigned char FORMATBYTE_CRC=0xF7;
	const unsigned char FORMATBYTE_GAP=0x4E;
	const unsigned char FORMATBYTE_FILLER=0xE5;

	for(i=0; i<len_preGap && ptr<maxLen; ++i)
	{
		data[ptr++]=FORMATBYTE_GAP;
	}
	for(sec=0; sec<track->numAddrMarks && ptr<maxLen; ++sec)
	{
		for(i=0; i<len_sync && ptr<maxLen; ++i)
		{
			data[ptr++]=FORMATBYTE_SYNC;
		}

		// Make ID Mark
		if(maxLen<ptr+8)
		{
			err=ERROR_FORMAT_DATA_OVERFLOW;
			break;
		}
		data[ptr++]=FORMATBYTE_MISSING_CLOCK;
		data[ptr++]=FORMATBYTE_MISSING_CLOCK;
		data[ptr++]=FORMATBYTE_MISSING_CLOCK;
		data[ptr++]=FORMATBYTE_ADDR_MARK;
		data[ptr++]=track->addrMarks[sec].CHRN[0];
		data[ptr++]=track->addrMarks[sec].CHRN[1];
		data[ptr++]=track->addrMarks[sec].CHRN[2];
		data[ptr++]=track->addrMarks[sec].CHRN[3];
		data[ptr++]=FORMATBYTE_CRC;

		for(i=0; i<len_gap2 && ptr<maxLen; ++i)
		{
			data[ptr++]=FORMATBYTE_GAP;
		}

		if(0==(track->addrMarks[sec].flags&FLAG_RECORD_NOT_FOUND))
		{
			// Make Data Mark
			if(maxLen<ptr+4)
			{
				err=ERROR_FORMAT_DATA_OVERFLOW;
				break;
			}
			data[ptr++]=FORMATBYTE_MISSING_CLOCK;
			data[ptr++]=FORMATBYTE_MISSING_CLOCK;
			data[ptr++]=FORMATBYTE_MISSING_CLOCK;
			data[ptr++]=FORMATBYTE_DATA_MARK;

			unsigned int size=(128<<(track->addrMarks[sec].CHRN[3]&3));
			for(i=0; i<size && ptr<maxLen; ++i)
			{
				data[ptr++]=FORMATBYTE_FILLER;
			}

			if(ptr<maxLen)
			{
				data[ptr++]=FORMATBYTE_CRC;
			}

			for(i=0; i<len_gap3 && ptr<maxLen; ++i)
			{
				data[ptr++]=FORMATBYTE_GAP;
			}
		}
	}

	*len=ptr;

	while(ptr<maxLen)
	{
		data[ptr++]=FORMATBYTE_GAP;
	}

	return err;
}

void Track_Print(TRACK *track)
{
	int i;
	printf("C%02dH%02d ",track->C,track->H);
	for(i=0; i<track->numAddrMarks; ++i)
	{
		printf("%02x%02x%02x%02x ",track->addrMarks[i].CHRN[0],track->addrMarks[i].CHRN[1],track->addrMarks[i].CHRN[2],track->addrMarks[i].CHRN[3]);
		if(i+1==track->numAddrMarks)
		{
			printf("\n");
		}
		else if(7==i%8)
		{
			printf("\n       ");
		}
	}
	if(0==track->numAddrMarks)
	{
		printf("No Sectors\n");
	}
}

int VerifyDiskWritable(const DISKPROP *prop)
{
	switch(prop->mediaType)
	{
	case D77_MEDIATYPE_2D :
		return ERROR_2D_NOT_SUPPORTED;
	case D77_MEDIATYPE_1D :
	case D77_MEDIATYPE_1DD:
		return ERROR_1D_1DD_NOT_SUPPORTED;
	}
	return ERROR_NONE;
}

int IdentifyDiskSizeInKB(const DISKPROP *prop,const TRACK *track)
{
	switch(prop->mediaType)
	{
	case D77_MEDIATYPE_2HD:
		{
			int num512byteSectors=0;
			int i;
			for(i=0; i<track->numSectors; ++i)
			{
				if(512==track->sectors[i].numBytes)
				{
					++num512byteSectors;
				}
			}
			if(16<num512byteSectors)
			{
				return 1440;
			}
		}
		return 1232;
	case D77_MEDIATYPE_2D:
		return 320;
	case D77_MEDIATYPE_2DD:
		return 640;
	}
	return 0;
}

static void D77Reader_Init(D77READER *reader)
{
	int i;
	reader->fp=NULL;
	reader->prop.writeProtected=0;
	reader->prop.mediaType=0;
	reader->prop.numTracks=0;
	reader->diskSize=0;
	for(i=0; i<D77_HEADER_LENGTH; ++i)
	{
		reader->header_basic[i]=0;
	}
	for(i=0; i<MAX_NUM_TRACKS; ++i)
	{
		reader->trackPtr[i]=0;
	}
};


D77READER *D77Reader_Create(void)
{
	D77READER *reader=(D77READER *)malloc(sizeof(D77READER));
	if(NULL!=reader)
	{
		D77Reader_Init(reader);
	}
	return reader;
}

int D77Reader_Begin(D77READER *reader,const char fn[])
{
	reader->fp=fopen(fn,"rb");
	if(NULL==reader->fp)
	{
		return ERROR_OPEN_FILE;
	}

	if(D77_HEADER_LENGTH!=fread(reader->header_basic,1,D77_HEADER_LENGTH,reader->fp))
	{
		fclose(reader->fp);
		reader->fp=NULL;
		return ERROR_TOO_SHORT;
	}

	//int i;
	//for(i=0; i<D77_HEADER_LENGTH; ++i)
	//{
	//	printf("%02x ",reader->header_basic[i]);
	//	if(i%16==15)
	//	{
	//		printf("\n");
	//	}
	//}


	reader->prop.writeProtected=reader->header_basic[D77_HEADER_OFFSET_WRITEPROT];
	reader->prop.mediaType=reader->header_basic[D77_HEADER_OFFSET_MEDIATYPE];
	reader->diskSize=DWordToUnsignedInt(reader->header_basic+D77_HEADER_OFFSET_DISKSIZE);

	{
		// According to the D77 format, I need to find the first non-zero offset
		// to know how many tracks in this 
		unsigned int track=0;
		long int headerEndPtr=DAMN_BIG_NUMBER;
		for(long int i=D77_HEADER_LENGTH; i<reader->diskSize && i<headerEndPtr && track<MAX_NUM_TRACKS; i+=4)
		{
			unsigned long offset;
			unsigned char dw[4];
			if(4!=fread(dw,1,4,reader->fp))
			{
				fclose(reader->fp);
				reader->fp=NULL;
				return ERROR_TOO_SHORT;
			}

			offset=DWordToUnsignedInt(dw);
			if(0!=offset && DAMN_BIG_NUMBER==headerEndPtr)
			{
				headerEndPtr=offset;
			}
			reader->trackPtr[track]=offset;
			++track;
		}

		if(MAX_NUM_TRACKS<track)
		{
			fclose(reader->fp);
			reader->fp=NULL;
			return ERROR_TOO_MANY_TRACKS;
		}

		reader->prop.numTracks=track;
	}

	return ERROR_NONE;
}

int D77Reader_ReadTrack(TRACK *track,D77READER *reader,unsigned int trackPos)
{
	int i;
	unsigned int C=trackPos/2;
	unsigned int H=trackPos&1;

	unsigned long trackBegin=0,trackEnd=0,trackSize=0;
	unsigned char *trackData=NULL;
	unsigned long sectorOffset=0,numAddrMarks=0,numSectors=0,numSectorTrack=0;

	unsigned int sectorIdx=0,addrMarkIdx=0;

	Track_Init(track);
	track->C=C;
	track->H=H;
	if(NULL==reader->fp)
	{
		return ERROR_NOT_OPEN;
	}

	if(reader->prop.numTracks<=trackPos)
	{
		return ERROR_TRACK_OUT_OF_RANGE;
	}

	trackBegin=reader->trackPtr[trackPos];
	if(0==trackBegin)
	{
		/* Unformatted track */
		return ERROR_NONE;
	}

	for(i=trackPos+1; i<reader->prop.numTracks; ++i)
	{
		trackEnd=reader->trackPtr[i];
		if(0!=trackEnd) // Next track is unformatted
		{
			break;
		}
	}
	if(0==trackEnd)
	{
		trackEnd=reader->diskSize;
	}
	trackSize=(trackBegin<trackEnd ? trackEnd-trackBegin : 0);

	fseek(reader->fp,trackBegin,SEEK_SET);
	trackData=(unsigned char *)malloc(trackSize);
	if(NULL==trackData)
	{
		return ERROR_OUT_OF_MEMORY;
	}

	fread(trackData,1,trackSize,reader->fp);



	numSectorTrack=DAMN_BIG_NUMBER;
	for(sectorOffset=0; sectorOffset<trackSize && numSectors<numSectorTrack; )
	{
		unsigned char CHRN[4];
		unsigned char *sectorPtr=trackData+sectorOffset;
		long int sectorNBytes=WordToUnsignedShort(sectorPtr+0x0e);
		if(trackSize<=sectorOffset+0x10)
		{
			return ERROR_BROKEN_DATA;
		}

		CHRN[0]=sectorPtr[0];
		CHRN[1]=sectorPtr[1];
		CHRN[2]=sectorPtr[2];
		CHRN[3]=sectorPtr[3];

		++numAddrMarks;

		if(DAMN_BIG_NUMBER==numSectorTrack)
		{
			numSectorTrack=WordToUnsignedShort(sectorPtr+4);
		}
		else if(numSectorTrack!=WordToUnsignedShort(sectorPtr+4))
		{
			printf("Broken Data.  Number of sectors inconsistent within a track.\n");
			printf("  Cyl:%d Head:%d Sec:%d\n",CHRN[0],CHRN[1],CHRN[2]);
			printf("  Previous number of sectors for the track:%d\n",(int)numSectorTrack);
			printf("  Number of sectors for the track:%d\n",WordToUnsignedShort(sectorPtr+4));
			return ERROR_BROKEN_DATA;
		}

		if(0==numSectorTrack)
		{
			// printf("Unformatted Track.\n");
			break;
		}

		if(D77_SECTOR_STATUS_RECORD_NOT_FOUND!=sectorPtr[8])
		{
			++numSectors;
		}

		sectorOffset+=0x10+sectorNBytes;
	}


	Track_Prepare(track,C,H,numAddrMarks,numSectors);


	sectorIdx=0,
	addrMarkIdx=0;
	for(sectorOffset=0; sectorOffset<trackSize && sectorIdx<numSectors && addrMarkIdx<numAddrMarks; )
	{
		unsigned int numBytes=0;
		unsigned char CHRN[4];
		unsigned char *sectorPtr=trackData+sectorOffset;
		if(trackSize<=sectorOffset+0x10)
		{
			return ERROR_BROKEN_DATA;
		}

		CHRN[0]=sectorPtr[0];
		CHRN[1]=sectorPtr[1];
		CHRN[2]=sectorPtr[2];
		CHRN[3]=sectorPtr[3];

		track->addrMarks[addrMarkIdx].CHRN[0]=sectorPtr[0];
		track->addrMarks[addrMarkIdx].CHRN[1]=sectorPtr[1];
		track->addrMarks[addrMarkIdx].CHRN[2]=sectorPtr[2];
		track->addrMarks[addrMarkIdx].CHRN[3]=sectorPtr[3];

		track->density=sectorPtr[6];

		numBytes=WordToUnsignedShort(sectorPtr+0x0e);

		if(D77_SECTOR_STATUS_RECORD_NOT_FOUND==sectorPtr[8])
		{
			// Flag address-mark so that formatter won't make a data mark for this address mark.
			track->addrMarks[addrMarkIdx].flags|=FLAG_RECORD_NOT_FOUND;
		}
		else
		{
			if(D77_DATAMARK_DELETED==sectorPtr[7])
			{
				track->sectors[sectorIdx].flags|=FLAG_DELETED_DATA;
			}
			if(0!=sectorPtr[8])
			{
				track->sectors[sectorIdx].flags|=FLAG_CRC_ERROR;
			}

			Sector_Alloc(&track->sectors[sectorIdx],numBytes);

			track->sectors[sectorIdx].CHRN[0]=CHRN[0];
			track->sectors[sectorIdx].CHRN[1]=CHRN[1];
			track->sectors[sectorIdx].CHRN[2]=CHRN[2];
			track->sectors[sectorIdx].CHRN[3]=CHRN[3];
			memcpy(track->sectors[sectorIdx].data,sectorPtr+0x10,numBytes);

			++sectorIdx;
		}

		++addrMarkIdx;

		sectorOffset+=0x10+numBytes;
	}

	free(trackData);

	return ERROR_NONE;
}

void D77Reader_DestroyTrack(TRACK *track)
{
	Track_Destroy(track);
}

int D77Reader_End(D77READER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	return ERROR_NONE;
}

void D77Reader_Destroy(D77READER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	free(reader);
}





RDDREADER *RDDReader_Create(void)
{
	RDDREADER *reader=(RDDREADER *)malloc(sizeof(RDDREADER));
	if(NULL!=reader)
	{
		reader->fp=NULL;
		reader->prop.writeProtected=0;
		reader->prop.mediaType=0;
		reader->prop.numTracks=0;
	}
	return reader;
}
int RDDReader_Begin(RDDREADER *reader,const char fn[])
{
	int err=ERROR_NONE;
	reader->fp=fopen(fn,"rb");
	if(NULL!=reader->fp)
	{
		unsigned char buf[48];
		if(16!=fread(buf,1,16,reader->fp))
		{
			err=ERROR_TOO_SHORT;
			goto CLOSE_AND_RETURN;
		}
		if(0!=strcmp((char *)buf,RDD_SIGNATURE))
		{
			err=ERROR_BROKEN_DATA;
			goto CLOSE_AND_RETURN;
		}

		if(48!=fread(buf,1,48,reader->fp))
		{
			err=ERROR_TOO_SHORT;
			goto CLOSE_AND_RETURN;
		}
		if(RDDCMD_BEGIN_DISK!=buf[0])
		{
			err=ERROR_BROKEN_DATA;
			goto CLOSE_AND_RETURN;
		}

		reader->RDDVer=buf[1];
		reader->prop.mediaType=buf[2];
		reader->prop.writeProtected=buf[3]&1;
		reader->prop.numTracks=0; // Unknown at the beginning.
		reader->captureDevice=buf[4];
		strncpy(reader->diskName,(char *)buf+16,32);
		reader->diskName[32]=0;
		reader->diskName[33]=0;
	}
	return err;

CLOSE_AND_RETURN:
	fclose(reader->fp);
	reader->fp=NULL;
	return err;
}
int RDDReader_ReadTrack(TRACK *track,RDDREADER *reader)
{
	int err=0;
	size_t fpos=ftell(reader->fp);
	unsigned char buf[16],C,H;
	unsigned int numAddrMarks=0,numSectors=0,addrMark,sector;

	if(16!=fread(buf,1,16,reader->fp))
	{
		return ERROR_TOO_SHORT;
	}
	if(RDDCMD_END_DISK==buf[0])
	{
		return END_OF_FILE;
	}
	if(RDDCMD_BEGIN_TRACK!=buf[0])
	{
		return ERROR_BROKEN_DATA;
	}
	C=buf[1];
	H=buf[2];

	while(1)
	{
		size_t s;
		if(16!=fread(buf,1,16,reader->fp))
		{
			return ERROR_TOO_SHORT;
		}
		switch(buf[0])
		{
		case RDDCMD_END_DISK:
			fprintf(stderr,"End of Disk before End of Track.\n",buf[0]);
			return ERROR_BROKEN_DATA;
		case RDDCMD_IDMARK:
			++numAddrMarks;
			break;
		case RDDCMD_DATA:
			++numSectors;
			s=WordToUnsignedShort(buf+0x0E);
			s=RDD_PADDED_SIZE(s);
			fseek(reader->fp,ftell(reader->fp)+s,SEEK_SET);
			break;
		case RDDCMD_END_TRACK:
			break;
		case RDDCMD_TRACK_READ:
		case RDDCMD_UNSTABLE_BYTES:
		case RDDCMD_RESERVED07H:
		case RDDCMD_RESERVED08H:
		case RDDCMD_RESERVED09H:
		case RDDCMD_RESERVED0AH:
		case RDDCMD_RESERVED0BH:
		case RDDCMD_RESERVED0CH:
		case RDDCMD_RESERVED0DH:
		case RDDCMD_RESERVED0EH:
		case RDDCMD_RESERVED0FH:
			s=WordToUnsignedShort(buf+0x0E);
			s=RDD_PADDED_SIZE(s);
			fseek(reader->fp,ftell(reader->fp)+s,SEEK_SET);
			break;
		default:
			fprintf(stderr,"Unknown RDD tag 0x%02x.\n",buf[0]);
			return ERROR_BROKEN_DATA;
		}
		if(RDDCMD_END_TRACK==buf[0])
		{
			break;
		}
	}

	fseek(reader->fp,fpos,SEEK_SET);

	Track_Init(track);
	err=Track_Prepare(track,C,H,numAddrMarks,numSectors);

	addrMark=0;
	sector=0;
	while(1)
	{
		size_t s;
		if(16!=fread(buf,1,16,reader->fp))
		{
			return ERROR_TOO_SHORT;
		}
		switch(buf[0])
		{
		case RDDCMD_END_DISK:
			// End of Disk without End of Track
			return ERROR_BROKEN_DATA;
		case RDDCMD_IDMARK:
			track->addrMarks[addrMark].CHRN[0]=buf[1];
			track->addrMarks[addrMark].CHRN[1]=buf[2];
			track->addrMarks[addrMark].CHRN[2]=buf[3];
			track->addrMarks[addrMark].CHRN[3]=buf[4];
			track->addrMarks[addrMark].flags=0;
			if(MB8877_IOERR_CRC&buf[7])
			{
				track->addrMarks[addrMark].flags|=FLAG_CRC_ERROR;
			}

			++addrMark;
			break;
		case RDDCMD_DATA:
			track->density=buf[6]&1;

			s=WordToUnsignedShort(buf+0x0E);
			s=RDD_PADDED_SIZE(s);

			track->sectors[sector].CHRN[0]=buf[1];
			track->sectors[sector].CHRN[1]=buf[2];
			track->sectors[sector].CHRN[2]=buf[3];
			track->sectors[sector].CHRN[3]=buf[4];

			Sector_Alloc(&track->sectors[sector],s);
			fread(track->sectors[sector].data,1,s,reader->fp);

			if(MB8877_IOERR_CRC&buf[7])
			{
				track->sectors[sector].flags|=FLAG_CRC_ERROR;
			}
			if(MB8877_IOERR_RECORD_NOT_FOUND&buf[7])
			{
				track->sectors[sector].flags|=FLAG_RECORD_NOT_FOUND;
			}

			++sector;
			break;
		case RDDCMD_BEGIN_TRACK:
		case RDDCMD_END_TRACK:
			break;
		case RDDCMD_TRACK_READ:
		case RDDCMD_UNSTABLE_BYTES:
		case RDDCMD_RESERVED07H:
		case RDDCMD_RESERVED08H:
		case RDDCMD_RESERVED09H:
		case RDDCMD_RESERVED0AH:
		case RDDCMD_RESERVED0BH:
		case RDDCMD_RESERVED0CH:
		case RDDCMD_RESERVED0DH:
		case RDDCMD_RESERVED0EH:
		case RDDCMD_RESERVED0FH:
			s=WordToUnsignedShort(buf+0x0E);
			s=RDD_PADDED_SIZE(s);
			fseek(reader->fp,ftell(reader->fp)+s,SEEK_SET);
			break;
		default:
			fprintf(stderr,"Unknown RDD tag 0x%02x.\n",buf[0]);
			return ERROR_BROKEN_DATA;
		}
		if(RDDCMD_END_TRACK==buf[0])
		{
			break;
		}
	}
	for(addrMark=0; addrMark<track->numAddrMarks; ++addrMark)
	{
		unsigned char recordNotFound=FLAG_RECORD_NOT_FOUND; // Tentative
		for(sector=0; sector<track->numSectors; ++sector)
		{
			if(track->sectors[sector].CHRN[0]==track->addrMarks[addrMark].CHRN[0] &&
			   track->sectors[sector].CHRN[2]==track->addrMarks[addrMark].CHRN[2])
			{
				recordNotFound=(track->sectors[sector].flags&FLAG_RECORD_NOT_FOUND);
				break;
			}
		}
		track->addrMarks[addrMark].flags|=recordNotFound;
	}

	return err;
}
void RDDReader_DestroyTrack(TRACK *track)
{
	Track_Destroy(track);
}
int RDDReader_End(RDDREADER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	return ERROR_NONE;
}
void RDDReader_Destroy(RDDREADER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	free(reader);
}




BINREADER *BINReader_Create(void)
{
	BINREADER *reader=(BINREADER *)malloc(sizeof(BINREADER));
	reader->fp=NULL;
	reader->fileSize=0;
	reader->trackPos=0;
	return reader;
}

int BINReader_Begin(BINREADER *reader,const char fn[])
{
	reader->fp=fopen(fn,"rb");
	if(NULL!=reader->fp)
	{
		fseek(reader->fp,0,SEEK_END);
		reader->fileSize=ftell(reader->fp);
		fseek(reader->fp,0,SEEK_SET);
		reader->trackPos=0;
		switch(reader->fileSize)
		{
		case FILESIZE_2DD_640KB:
			reader->prop.mediaType=D77_MEDIATYPE_2DD;
			reader->prop.writeProtected=0;
			reader->prop.numTracks=160;
			reader->numSectorTrack=8;
			reader->N=2;
			break;
		case FILESIZE_2DD_720KB:
			reader->prop.mediaType=D77_MEDIATYPE_2DD;
			reader->prop.writeProtected=0;
			reader->prop.numTracks=160;
			reader->numSectorTrack=9;
			reader->N=2;
			break;
		case FILESIZE_2HD_1440KB:
			reader->prop.mediaType=D77_MEDIATYPE_2HD;
			reader->prop.writeProtected=0;
			reader->prop.numTracks=160;
			reader->numSectorTrack=18;
			reader->N=2;
			break;
		case FILESIZE_2HD_1232KB:
			reader->prop.mediaType=D77_MEDIATYPE_2HD;
			reader->prop.writeProtected=0;
			reader->prop.numTracks=154;
			reader->numSectorTrack=8;
			reader->N=3;
			break;
		default:
			fclose(reader->fp);
			reader->fp=NULL;
			return ERROR_UNSUPPORTED_FILE_TYPE;
		}
	}
	return ERROR_NONE;
}

int BINReader_ReadTrack(TRACK *track,BINREADER *reader)
{
	int err=ERROR_NONE;
	unsigned char C=reader->trackPos/2,H=reader->trackPos&1;
	unsigned int sectorLen=(128<<reader->N);
	int i;

	Track_Init(track);
	err=Track_Prepare(track,C,H,reader->numSectorTrack,reader->numSectorTrack);

	for(i=0; i<reader->numSectorTrack; ++i)
	{
		AddrMark_Init(&track->addrMarks[i]);
		track->addrMarks[i].CHRN[0]=C;
		track->addrMarks[i].CHRN[1]=H;
		track->addrMarks[i].CHRN[2]=i+1;
		track->addrMarks[i].CHRN[3]=reader->N;

		Sector_Init(&track->sectors[i]);
		Sector_Alloc(&track->sectors[i],sectorLen);
		track->sectors[i].CHRN[0]=C;
		track->sectors[i].CHRN[1]=H;
		track->sectors[i].CHRN[2]=i+1;
		track->sectors[i].CHRN[3]=reader->N;

		fread(track->sectors[i].data,1,sectorLen,reader->fp);
	}

	reader->trackPos++;
	return err;
}

void BINReader_DestroyTrack(TRACK *track)
{
	Track_Destroy(track);
}

int BINReader_End(BINREADER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	return ERROR_NONE;
}

void BINReader_Destroy(BINREADER *reader)
{
	if(NULL!=reader->fp)
	{
		fclose(reader->fp);
		reader->fp=NULL;
	}
	free(reader);
}
