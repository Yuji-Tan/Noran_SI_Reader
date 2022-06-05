//import .si file
//EDS spectrum imaging data aquired using Noran system

number binning=4 //energy binning
// huge memory and disc size is required for no binning (binning=1).

number magconst=122880 //mag x FOV (field of view for x direction) in um
//this may be system dependent value.

number byte_order=2 //little endian

//check file magic
void SIFileCheck(object fstream)
{
	image fmagic:=IntegerImage("",1,0,4)
	ImageReadImageDataFromStream(fmagic,fstream, byte_order)
	image simagic:=IntegerImage("",1,0,4)
	simagic[0,0]=114 //0x72
	simagic[1,0]=235 //0xEB
	simagic[2,0]=15 //0x0F
	simagic[3,0]=53 //0x35
	if((fmagic-simagic).abs().sum()!=0)
	{
		result("This File is NOT si file.\n")
		Exit(0)
	}
}

//check byte length of count data
number byte_len(object fstream)
{
	number spos=26 //stream position
	fstream.StreamSetPos(0,spos)
	number byte_l=fstream.StreamReadAsText(0,1).val()
	return byte_l
}

//read metadata
TagGroup ReadSImeta(object fstream)
{
	TagGroup metaTg=NewTagGroup()
	number spos //stream position
	//read metadata
	string text
	TagGroup meta1=NewTagGroup()
	spos=184
	fstream.StreamSetPos(0,spos)
	//system name
	text=fstream.StreamReadAsText(0,24)
	metaTg.TagGroupSetTagAsTagGroup(text,meta1)
	//time stamp
	text=fstream.StreamReadAsText(0,16)
	meta1.TagGroupSetTagAsString("Date",text)
	//metadata1
	image metad1:=RealImage("",4,4*16)
	ImageReadImageDataFromStream(metad1,fstream,byte_order)
	number ilen
	for(number i=0;i<4*16;i++)
	{
		if(i<10)
		{
			ilen=1
		}
		else
		{
			ilen=2
		}
		text="data"+left("0",2-ilen)+i+"(unknown)"
		if(i==4)
		{
			text="Dwell Time (s)"
		}
		if(i==5)
		{
			text="Effective Dwell Time without DT? (s)"
		}
		if(i==7)
		{
			text="XPERCHAN (keV/ch)"
		}
		if(i==8)
		{
			text="ZEROWIDTH"
		}
		if(i==21)
		{
			text="XPOSITION"
		}
		if(i==22)
		{
			text="YPOSITION"
		}
		if(i==23)
		{
			text="ZPOSITION"
		}
		if(i==31)
		{
			text="Acceleration Voltage (kV)"
		}
		if(i==35)
		{
			text="Working Distance (mm)"
		}
		if(i==36)
		{
			text="AZIMANGLE (dg)"
		}
		if(i==37)
		{
			text="THCWIND (um)"
		}
		if(i==38)
		{
			text="TDEADLYR (um)"
		}
		if(i==39)
		{
			text="TAUWIND (um)"
		}
		if(i==41)
		{
			text="MAGCAM"
		}
		if(i==42)
		{
			text="ELEVANGLE (deg)"
		}
		if(i==44)
		{
			text="SLIDEPOS"
		}
		if(i==46)
		{
			text="SOLIDANGLE (sR)"
		}
		if(i==47)
		{
			text="CRYSTTHICK"
		}
		if(i==48)
		{
			text="WINDTHICK"
		}
		meta1.TagGroupSetTagAsNumber(text,metad1[i,0].sum())
	}

	//metaTg.TagGroupOpenBrowserWindow("metadata",0)
	return metaTg
}

//read data size
TagGroup ReadSIdSize(object fstream)
{
	TagGroup sizeTg=NewTagGroup()
	number spos=50012
	fstream.StreamSetPos(0,spos)
	image sizeimg:=IntegerImage("",4,0,22)
	ImageReadImageDataFromStream(sizeimg,fstream,byte_order)
	string text
	number ilen
	for(number i=0;i<22;i++)
	{
		if(i<10)
		{
			ilen=1
		}
		else
		{
			ilen=2
		}
		text="data"+left("0",2-ilen)+i
		sizeTg.TagGroupSetTagAsUInt32(text,sizeimg[i,0].sum())
	}
	//sizeTg.TagGroupOpenBrowserWindow("sizedata",0)
	return sizeTg
}

//read micrograph like something (unknown)
image ReadSIRefImg(object fstream,number spos,number x,number y)
{
	fstream.StreamSetPos(0,spos)
	image refimg1:=IntegerImage("",4,0,2*x,y)
	ImageReadImageDataFromStream(refimg1,fstream,byte_order)
	image refimg2:=refimg1.slice2(0,0,0,0,x,2,1,y,1).ImageClone()
	return refimg2
}

//read SI data position
TagGroup ReadSIdPos(object fstream,number spos,number x,number y)
{
	TagGroup posTg=NewTagGroup()
	fstream.StreamSetPos(0,spos+x*y*16)
	Image posimg:=IntegerImage("",4,0,2)
	ImageReadImageDataFromStream(posimg,fstream,byte_order)
	string text
	for(number i=0;i<2;i++)
	{
		text="data"+i
		posTg.TagGroupSetTagAsUInt32(text,posimg[i,0].sum())
	}
	//posTg.TagGroupOpenBrowserWindow("dpos",0)
	return posTg
}

//read SI eds data
Image ReadSIEDS(object fstream,number dpos,number dlen,number jump)
{
	fstream.StreamSetPos(0,dpos+jump)
	image edsimg:=IntegerImage("",2,0,dlen/2)
	ImageReadImageDataFromStream(edsimg,fstream,byte_order)
	return edsimg
}

//read count data (not aligned)
Image ReadRawCountImage(object fstream, number cpos,number x,number y)
{
	fstream.StreamSetPos(0,cpos)
	image countref:=IntegerImage("",4,0,2*x,y)
	ImageReadImageDataFromStream(countref,fstream,byte_order)
	return countref
}

//read count image
Image GetCountImage(image raw,number x,number y,number byte_l)
{
	image countimg:=IntegerImage("",4,0,x,y)
	image tempimg:=IntegerImage("",4,0,x,y)
	countimg=raw.slice2(1,0,0,0,x,2,1,y,1)
	number dtype
	if(byte_l==2)
	{
		tempimg=countimg/(2**16)
		countimg=countimg-2**16*tempimg
		dtype=ImageConstructDataType("scalar","uint",0,16)
		countimg.ImageChangeDataType(dtype)
	}
	return countimg
}

//read count-ref image (unknown data)
Image GetCountRefImage(image raw,number x,number y)
{
	image countrefimg:=IntegerImage("",4,0,x,y)
	countrefimg=raw.slice2(0,0,0,0,x,2,1,y,1)
	return countrefimg
}

//get SI data
Image GetSIImage(image raw,image countimg,number ch,number byte_l)
{
	number x,y
	countimg.GetSize(x,y)
	image SIimg:=IntegerImage("",byte_l,0,x,y,ch)
	image histo:=IntegerImage("",byte_l,0,ch)
	number start,end
	start=0
	for(number iy=0;iy<y;iy++)
	{
		for(number ix=0;ix<x;ix++)
		{
			end=start+countimg.GetPixel(ix,iy)
			ImageCalculateHistogram(raw[0,start,1,end],histo,0,0,ch)
			SIimg.slice1(ix,iy,0,2,ch,1)=histo
			start=end
		}
	}
	return SIimg
}


//main
//get file path of si file
string filename
if(!OpenDialog(Null, "Select si file", "*.si", filename)) exit(0)
result("opening the next file\n")
result(filename+"\n")
string basename=filename.PathExtractBaseName(0)
result(basename+"\n")

//file open
number fileID=OpenFileForReading(filename)
object fstream=NewStreamFromFileReference(fileID,1)

//reading byte-length
fstream.SIFileCheck()
number byte_l=fstream.byte_len()

//reading metadata
TagGroup metaTg=fstream.ReadSImeta()
number mag,evpch,zeropos
//metaTg.TagGroupOpenBrowserWindow("metadata",0)
TagGroup childTg
metaTg.TagGroupGetIndexedTagAsTagGroup(0,childTg)
childTg.TagGroupGetTagAsNumber("MAGCAM",mag)
childTg.TagGroupGetTagAsNumber("XPERCHAN (keV/ch)",evpch)

//reading size infomation
TagGroup dSizeTg=fstream.ReadSIdSize()
number ch,x,y,nextpos,jump,datalen,imglen
dSizeTg.TagGroupGetTagAsUInt32("data04",ch) //number of eds channel (z-depth of SI image)
dSizeTg.TagGroupGetTagAsUInt32("data06",nextpos) //reference image data starts here
dSizeTg.TagGroupGetTagAsUInt32("data07",y)
dSizeTg.TagGroupGetTagAsUInt32("data08",x) //SI image size
dSizeTg.TagGroupGetTagAsUInt32("data11",jump) //seek size of file stream
dSizeTg.TagGroupGetTagAsUInt32("data13",datalen) //SI data size
dSizeTg.TagGroupGetTagAsUInt32("data15",imglen) //count-image data size
result("x = "+x+", y = "+y+", ch = "+ch+"\n")
number scale=magconst/(mag*x)

//reading micrograph like something (unknown)
image refimg:=fstream.ReadSIRefImg(nextpos,x,y)
refimg.SetName(basename+"_ref")
refimg.ImageSetDimensionCalibration(0,0,scale,"ƒÊm",0)
refimg.ImageSetDimensionCalibration(1,0,scale,"ƒÊm",0)
refimg.showimage()
ImageDisplay refimgDisp=refimg.ImageGetImageDisplay(0)
refimgDisp.ApplyDataBar()

//reading start position of SI data
TagGroup dposTg=fstream.ReadSIdPos(nextpos,x,y)
number dposStart
dposTg.TagGroupGetTagAsUInt32("data0",dposStart)

//readind eds-data
image edsimg:=fstream.ReadSIEDS(dposStart,datalen,jump)
//edsimg.showimage()

//get count data
number spos=fstream.StreamGetPos()
image rawcount:=fstream.ReadRawCountImage(spos,x,y)
image count:=rawcount.GetCountImage(x,y,byte_l)
count.SetName(basename+"_count")
count.ImageCopyCalibrationFrom(refimg)
count.showimage()
ImageDisplay countDisp=count.ImageGetImageDisplay(0)
countDisp.ApplyDataBar()
image countref:=rawcount.GetCountRefImage(x,y)
countref.SetName(basename+"_countref")
countref.ImageCopyCalibrationFrom(refimg)
countref.showimage()
ImageDisplay countrefDisp=countref.ImageGetImageDisplay(0)
countrefDisp.ApplyDataBar()

//get SI data
edsimg=edsimg/binning
image SIimage:=GetSIImage(edsimg,count,ch/binning,byte_l)
SIimage.SetName(basename+"_SI")

//set tag
TagGroup SITg=SIimage.ImageGetTagGroup()
SITg.TagGroupSetTagAsTagGroup(basename,metaTg)
SIimage.ImageCopyCalibrationFrom(refimg)
SIimage.ImageSetDimensionCalibration(2,0,evpch*binning,"keV",1)
SIimage.showimage()
ImageDisplay SIimageDisp=SIimage.ImageGetImageDisplay(0)
SIimageDisp.ApplyDataBar()
