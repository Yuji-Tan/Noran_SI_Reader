# -*- coding: utf-8 -*-
"""
Created on Fri May 20 23:01:24 2022

@author: Yuji_Tan
"""


import numpy as np

filename="test.si"
binn=4 #energy binning
# if input: 2048 ch and binn==2, output energy ch = 2048//binn = 1024

with open(filename,"rb") as f:
    #check file top
    #should be 0x72, 0xEB, 0x0F, 0x35
    ftop=np.fromfile(f,dtype=np.uint8,count=4)
    if np.all(1+ftop-[0x72,0xEB,0x0F,0x35]):
        print("Opening {} ...".format(filename))
    else:
        print("This file is not Noran .si format.")
        exit()
    
    #check meta data
    print("\nCheck analytical condition...")
    f.seek(240) #0x F0 (240)
    meta=np.fromfile(f,dtype=np.float32,count=4*15)
    stagex,stagey,stagez=meta[17:20]
    print("x = {}, y = {}, z = {}".format(stagex,stagey,stagez))
    vacc=meta[27]
    print("Acceleration voltage = {} (kV)".format(vacc))
    mag=meta[37]
    print("Magnification = x {}".format(mag))
    
    #check byte position, pixel size
    print("\nCheck file information...")
    f.seek(50012) #0x C3 5C, may be fixed value?
    pos=np.fromfile(f,dtype=np.uint32, count=22)
    #1st and 2nd values are pixel size as uint16?
    ch=pos[4] #may be number of ch
    print("Energy channel size = {}".format(ch))
    nextpos=pos[6] #may be 0x 00 00 C3 B4
    y,x=pos[7:9] #may be pixel size
    print("Pixel size ({}, {})".format(x,y))
    jump=pos[11] #may be offset
    datalen=pos[13] #may be length of SI data
    imglen=pos[15] #may be length of reference image data
    f.seek(nextpos)
    unknownimg=np.fromfile(f,dtype=np.uint32,count=x*y*2)[::2].reshape([y,x])
    f.seek(nextpos + x*y*16)
    datapos,imgpos=np.fromfile(f,dtype=np.uint32,count=2)
    #may be start position of SI and reference image data
    
    #read  SI and image data
    print("\nreading SI and reference image data...")
    f.seek(datapos+jump)
    sid=np.fromfile(f,dtype=np.uint16,count=datalen//2)
    imgd=np.fromfile(f,dtype=np.uint16,count=x*y*2*4)
    #print(datapos+jump+datalen,datapos+jump+datalen+x*y*2*4)

    #conver to SI data
    countimg=imgd[3::4] #total count of each pixel
    #print(countimg.size)
    #print(np.sum(countimg),sid.size,imgd)
    si=np.zeros((x*y,ch//binn),dtype=np.uint16)
    spc=np.zeros((ch//binn,),dtype=np.uint16)
    cumsumimg=np.cumsum(countimg)
    #print(cumsumimg.size,cumsumimg)
    sid=sid//binn
    for i in range(len(countimg)):
        if i==0:
            spc=np.bincount(sid[:cumsumimg[i]],minlength=ch//binn)
        else:
            spc=np.bincount(sid[cumsumimg[i-1]:cumsumimg[i]],minlength=ch//binn)
        si[i,:]=spc
si=np.reshape(si,[y,x,ch//binn])
savename=filename[:-3]+".npy"
print("save as "+savename)
np.save(filename[:-3]+"_image",unknownimg)
np.save(savename,si)