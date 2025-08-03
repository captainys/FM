CDIPLTFR
CD IPL sector transfer program for TOWNS.  Usage CDIPLTFR src.iso dst.iso

Both src.iso and dst.iso must have IO.SYS.

Both src.iso and dst.iso needs to be strictly ISO9660, otherwise, the program won't find IO.SYS.

Usage sample:
(1) Take out all files from Towns System Software to a local hard drive.  Make sure to copy hidden IO.SYS, AUTOEXEC.BAT, and CONFIG.SYS.
(2) Make any addition to the files.
(3) Make ISO image of the modified Towns OS.  But, this image does not IPL, and IO.SYS location will be different from the original, therefore, simply coying the IPL sector won't make it bootable.
(4) Use this program to transplant the IPL sector from another TOWNS App.  It will update IO.SYS location in the ISO image, so that it is bootable again.
