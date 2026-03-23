void Palette(unsigned char code,unsigned char r,unsigned char g,unsigned char b)
{
	outp(0xFD90,code);
	outp(0xFD92,b&0xF0);
	outp(0xFD94,r&0xF0);
	outp(0xFD96,g&0xF0);
}
