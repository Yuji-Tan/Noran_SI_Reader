# Noran_SI_Reader
Import EDS-hypermap from ".si" file aquired using Noran system

 There are still some problems to open .si file perfectly. Comments from HyperSpy users are welcome.

 File structure is estimated with reverse engineering (RE). Please be care for scientific use.

# Estimated .si file structure
## metadata
 Metadata of EDS system seems to be begin with 0xB8 (184). The next 24 byte represents system name as ascii (The last data may be 0x 00). The next 16 byte represents date time as ascii. The following data are stored as 4 byte float. No interpretable ascii data is found. To estimate metadata contents, exporting an emsa file and comparison of each data is needed. Acceleration voltage (location at 0x 01 6C (364)) and many other microscope/EDS metadata are stored in this section.

 The 2nd metadata is found after the above data section, but not easy to understand.

## image size data
 The next important data starts from 0x C3 5C (50012) as 4 byte integer. 0xC36C (50028) is energy channel size. 0x C3 78 (50040) is ysize, and the next is xsize. 0x C3 84 (50052) may be important file size information to reconstruct SI data. 0x C3 88 (50056) is start position of the first EDS data section. 0x C3 90 (50064) is data length of the 2nd EDS data section.
 
## image data
 Just after the above image-size data section, image-data section begins from 0x C3 B4 (50100) as 4 byte integer + 0x 00 00 00 00. Data length is 8 byte (4 byte int + 0x 00 00 00 00) x xsize x ysize x 2. The first xsize x ysize image (skip 0x 00 00 00 00) looks like micrograph. The next xsize x ysize image represents reference byte position of each pixel. The 2nd image is sometimes almost 0x FF FF FF FF (no reference point). This may depend on data.

## data length
 Just after the above image section, data length are stored as 4 byte integer. 2 data are found. the 1st data represents start position of EDS data of 2nd part.

## the first EDS data section
 The data section start from value at 0x C3 88 (50056). The top data is again start position of 2nd EDS data section. 16 byte after, EDS data begins. This section is dificult to interpret. Value at 0x C3 84 (50052) (z) mey be energy channel. And data section has a length of z x xsize x ysize (1 byte). If you get image of this size, spectrum-like image is obtained. But its intensity seem to be not correct as 1 byte integer. Data is not random. Specific values (0x 07, 0x 1C, 0x 20 etc) often appear. And specific pare (0x 07 20, 0x 0E 40 etc) often appear. At the moment, reconstruction of this section is not done.

## the second EDS data section
 Data starts from the value at 0x C3 88 (50056) with length at 0x C3 90 (50064). Data is 2 byte integer. This represents EDS enegy channel. The rest of the si file has image type information. 8 byte x xsize x ysize. The top 4 byte as integer in the 8 byte block represents byte position where EDS energy channel data starts. The next 4 byte is set of the identical 2 byte integer data. this value represents total count of the EDS signal.
