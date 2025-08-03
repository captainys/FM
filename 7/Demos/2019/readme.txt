DUCKY IS BACK for Fujitsu FM77AV series

Disk Image: FM77AVDEMO_2019_YS_V2.D77 (Tested on FM-7 Emulator "XM7" and actual FM77AV40 hardware.)

Fujitsu FM77AV was a massively improved version of FM-7 released in 1985.  It gave a shock to the Japanese personal computing scene by boasting 4096 simultaneous colors.  4096 colors can also be fully paletted.  This demo sets up palette so that it uses two 8-color screens for double-buffering in front of a 64-color screen for background.

But Fujitsu was fully aware that it was too much for a 6809 to deal with all 12 bit planes for graphics, even though one of the two 6809s can be dedicated to the graphics drawing.  For this problem Fujitsu added some hardware supports for drawing.  The line-drawing chip was one of those additions.  Since two 6809 CPUs are free while the line-drawing hardware is working, the main CPU can do coordinate transformation, and the sub-CPU can do scaling and viewport-clipping, while the line-drawing chip is drawing a line.  Although it made FM77AV an ideal wireframe 3D graphics platform, 3D games were not that popular then, and we saw only handful of 3D-graphics titles taking advantage of the line-drawing hardware.  Now multi-threading and GPU-accelerated rendering is so common.  Again, Fujitsu was years too early.

Also FM77AV came with on-board YM2203C, which was an option for earlier FM-7 and FM-77 models.  Therefore a demo for FM77AV must use 3 FM and 3 PSG channels of YM2203C.  But I am no expert of YM2203C.  All I could do was pretty much to write a music code using F-BASIC and MML.  I wrote a program for playing a music in F-BASIC and its extension called HGPLAY, and tweaked FM-7/77 emulator code to capture register dump, and played it back.  The register dump initially was 110KB and did not fit in FM77AVÅfs 64K expanded RAM.  After some compression I was able to shrink it to 50K and fit in the expanded RAM.

Earlier version of this demo was launched from a loader written in F-BASIC.  I have written all sorts of command-line tools for manipulating F-BASIC file system in a disk image.  It was very easy to assemble the code and write binary into a disk image in F-BASIC format.  However, F-BASIC disk expansion was taking up 4KB in the middle of the main RAM $7000 to $7FFF ($8000 to $FBFF are taken by F-BASIC ROM or can be switched to the RAM mode.).  To free up this precious 4KB, I wrote my own loader for F-BASIC file system.  You see ÅgYS-DOS V1.0 by CaptainYS 2019Åh while booting.  That message is from my loader, which I call ÅgYS-DOSÅh.



Build Instruction:
- Put asm6809.exe where PATH is set.
- Run buildDemo2019.py
- Create a F-BASIC format 2D disk image
- Write DM2019I.srec in Track 0 Side 0 Sector 1
- Write DM2019L.srec from Track 0 Side 0 Sector 9
- Save DM2019-0.srec as "DM2019-0" in the disk image.
- Save DM2019-1.srec as "DM2019-1" in the disk image.
- Save DM2019M.srec as "DM2019M" in the disk image.

I avoided assembler-specific macros as much as possible.  It probably can be compiled with other 6809 assemblers.
