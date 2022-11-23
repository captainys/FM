FDDUMP.EXE for FM TOWNS by CaptainYS (http://www.ysflight.com)



Introduction

This is a disk-imaging tool that runs on Fujitsu FM TOWNS computers.  The model needs to be UG or newer since the program uses Free-Run Timer for measuring the time.  If the model is older, you can try MAKED77.EXP instead, although it captures less information.

This program was developed for preserving programs for Fujitsu FM-7/77/77AV series computers and FM TOWNS series computers.  FDDUMP.EXE captures ID marks, sector contents, and track-read output.  It also measures time for reading a sector.  Some copy protection checkers rely on sector-read timing, and FDDUMP.EXE can capture that information.

Also it captures a sector that changes the contents up to 12 times by default.  Multiple-samples are necessary for replicating one type of copy protection that relies on unstable bytes.

Some games for FM-7 used Leaf-In-The-Forest protect, which hides real sectors among dummy sectors.  Initially I thought it would be difficult to capture this information.  However, to my surprise, track-read command in FM TOWNS (2MX at least) returns accurate sector data, from which I can extract real sectors.  I have confirmed that hidden-sector content can be recovered from track-read output of The Fire Crystal and Thexder.  I initially thought I failed to capture hidden sector of Thexder, but I was wrong.

So, this program captures all copy protections used for FM-7 series to my knowledge.

My best suggestion is, if you own an original copy of classic games, use a pulse-width capture devices such as KryoFlux, Pauline, FD Shield, and FDX, as well as capture from real hardware.  We have not yet explored how the error-correction of the real hardware was working.  I have experience many cases that I could not recover sectors from pulse-width capture image, but real FM77AV or FM TOWNS was able to read missed sectors with no error.

.D77 disk image cannot store timing information and track-read output.  Therefore, FDDUMP.EXE creates .RDD file (Real Disk Dump), which can be converted to .D77 image by RDD2D77.EXE for the time being, but FM TOWNS Emulator Tsugaru and FM77AV Emulator Mutsu will support .RDD format directly.



���̃v���O�����́A�x�m��FM TOWNS���@��œ��삷��f�B�X�N�C���[�W�L���v�`���c�[���ł��B�������A�t���[�����^�C�}�[���g�p����s���ŁAFM TOWNS���f��UG�ȍ~�ł��K�v������܂��BUG�����O�̋@��ł́AMAKED77.EXP�����p�ł��܂����AFDDUMP.EXE�قǂ̏��̓L���v�`���ł��܂���B

���̃v���O�����́A�x�m��FM-7/77/77AV�V���[�Y�AFM TOWNS�V���[�Y�p�A�v���P�[�V������ۑ����邽�߂ɊJ�����܂����BFDDUMP.EXE�́A�f�B�X�N��ID�}�[�N�A�Z�N�^���e�A�g���b�N���[�h�̏o�͌��ʂ��L�^���܂��B�܂��A�Z�N�^�ǂݍ��ݒ��ɁA���v���Ԃ��L�^���܂��B�����̃R�s�[�v���e�N�g�̓Z�N�^�ǂݍ��ݎ��Ԃ��v������̂ŁA�Č����邽�߂ɂ͂��̏�񂪕K�v�ł��B

�܂��A�ǂݍ��ނ��тɓ��e���ω�����Z�N�^�́A�ő�12��}���`�T���v�����܂��B�}���`�T���v���́A�Z�N�^���e�̕ω����`�F�b�N����ʏ̃R���R���v���e�N�g���Č����邽�߂ɕK�v�ł��B

����ɁA�������̃Q�[���i�m�F�ł��Ă���͍̂��̂Ƃ��� Thexder �� Fire Crystal)���g���؂̗t�B��v���e�N�g�̍Č��ɕK�v�ȏ���Track Read�������ł��邱�Ƃ��������āAThexder��Fire Crystal�͂��̕��@�ŉB��Z�N�^���Č����邱�Ƃ��ł��܂����B

�Ƃ����킯�ŁA���̃c�[�����g���ƂƂ肠�������܂Ŏ������m���Ă�͈͂�FM-7/77/77AV, FM TOWNS�V���[�Y�Ŏg��ꂽ���ׂẴR�s�[�v���e�N�g���Č����邽�߂ɕK�v�ȏ��𔲂��o�����Ƃ��ł��܂��B

�������A���g���Q�[���̌��{�������Ă���Ȃ�΁AKryoFlux, Pauline, FD Shield�Ȃǂ̃c�[���ɂ��p���X�C���[�W�ƍ��킹�Ď��@�ł̃T���v�����ۑ����Ă������Ƃ������߂��܂��B�p���X�C���[�W�́A���f�[�^��ۑ��ł��锽�ʁA�܂����@�̃t���b�s�[�f�B�X�N�R���g���[�����ǂ������G���[�C�������Ă����̂����S�ɉ𖾂ł��Ă��܂���BPauline�ŃL���v�`�������C���[�W�ł͂������̃Z�N�^��CRC�G���[���o���܂܂������̂ɁA���@�ɓǂ܂�����Ȃɂ��Ƃ��Ȃ��ǂ񂾂Ƃ����P�[�X�����Ȃ葽������܂��B�����͎��@�̃G���[�␳�@�\���𖾂ł��āA�p���X���犮�S�ȏ��̔����o�����ł���悤�ɂȂ邩������܂��񂪁A����ł͗����c���Ă����Ɗ����Ǝv���܂��B

.D77�t�@�C���t�H�[�}�b�g�ł̓Z�N�^�ǂݍ��ݎ��Ԃ̏���ۑ��ł��Ȃ��̂ŁAFDDUMP.EXE�́A.RDD (Real Disk Dump)�t�H�[�}�b�g�Ȃ�t�@�C�����o�͂��܂��B���݂̂Ƃ���A�����RDD2D77.EXE���g����.D77�`���ɕϊ����邱�ƂŃG�~�����[�^�ɐH�킹�邱�Ƃ��ł��܂����A������AFM TOWNS�G�~�����[�^�Ìy�EFM77AV�G�~�����[�^������.RDD�t�H�[�}�b�g�ɒ��ڑΉ�����\��ł��B





Required System
�K�v�ȃV�X�e��

FM TOWNS UG or newer plus SCSI hard disk (can be virtual SCSI hard drive like SCSI2SD).  Or, more than 8MB RAM.  Towns OS Command Mode, ORICON, or MS-DOS.

You cannot save disk image to a floppy disk because it won't fit to start with and it cannot access floppy disk while this program is reading a disk.  FM TOWNS (and many other systems) use same floppy-disk controller.  It is NOT possible to read image from drive A and save to drive B, since FDDUMP.EXE take over all floppy-disk access.

Therefore, you need to save disk image to either hard drive, or save disk image to RAM disk and transfer to outside of TOWNS.



FM TOWNS UG�ȏ� �{ SCSI �n�[�h�f�B�X�N (SCSI2SD�Ȃǂ̉��zSCSI�n�[�h�f�B�X�N���j�A�܂���8MB���x��RAM��4MB���x��RAM�f�B�X�N�BTowns OS Command Mode, ORICON, or MS-DOS.

�t���b�s�[�f�B�X�N�C���[�W�����Ȃ���t���b�s�[�f�B�X�N�ɏ������ނ��Ƃ́A���������f�B�X�N�ɓ��肫��Ȃ��̂�FDDUMP�����h���C�u�̃A�N�Z�X���e�C�N�I�[�o�[���Ă��܂��̂łł��܂���BSCSI�n�[�h�f�B�X�N�ɕۑ����邩�A���邢�͂�������RAM�f�B�X�N�ɕۑ�����TOWNS�̊O�ɓ]�����邩�ǂ��炩���K�v�ł��B





Usage
�g����

FDDUMP drive: mediaType -out filename
  drive:  A or B
  mediaType  2D/2DD/2HD or can be 320KB/640KB/1232KB (for 1440KB 2HD disk, try 2HD)

Optional
  -starttrk t    Start capture from cylinder t
  -endtrk t      End capture at cylinder 5



FDDUMP �h���C�u: ���f�B�A�^�C�v -out �t�@�C����
  �h���C�u:  A or B
  ���f�B�A�^�C�v  2D/2DD/2HD �܂��� 320KB/640KB/1232KB (1440KB�̃f�B�X�N�̏ꍇ2HD�ő����ǂ߂܂�)

Optional
  -starttrk t    �V�����_�[t����L���v�`���J�n
  -endtrk t      �V�����_�[t�܂ŃL���v�`��