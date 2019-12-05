
Making V1.1 L30 Boot Disk is a little bit tricky.  First you need to create a system with "CD-PLAYER".

If you are lucky enough to be able to boot into V1.1 L30, just go to Disk Format and format with Install CD-PLAYER option turned on.  Then jump to step (7) of the instruction.



If not, like you are relying on the boot floppy disk to boot into Towns OS V2.1 L20 in the SCSI CD-ROM drive, you need to go through a few more steps.  The thing is you need to somehow install IO.SYS of TownsOS V1.1 L30 into the floppy disk.fs

(1) Start Towns OS V2.1 in the CD-ROM drive using the boot floppy.
(2) Click on Disk Format.
(3) Once Disk Format window starts, remove V2.1 CD-ROM and insert V1.1 L30 CD-ROM.
(4) Make sure to check Copy System and 1.2MB options turned on, and click "OK"
(5) It stopps in the middle with an error because the format program is expecting to be copying V2.1 files.  However, it is ok as long as IO.SYS has been installed in the disk.
(6) It is better rebooting into V2.1 once.
(7) Insert V1.1 L30 CD-ROM and copy TBIOS.SYS and TBIOS.BIN to the floppy disk.
(8) Copy YSSCSICD.SYS to the floppy disk.
(9) Copy SYSDRV.EXE to the floppy disk.
(10) Copy CONFIG.SYS and AUTOEXEC.BAT in this directory to the floppy disk.

By the way, you need to select "Slow Mode", or your mouse cursor will jump around.





Towns OS V1.1 L30のブートフロッピーディスクを作るのはV2.1に比べてやや面倒です。まず、"CD演奏"をインストールしたフロッピーディスクを作らなくてはなりません。

もしも、現在FM TOWNS本体でV1.1 L30が起動可能な状態にあるならば、ディスクの初期化を選んで「CD演奏をインストール」オプションを選んだ状態でディスクをフォーマットして、手順の(7)に飛んでください。

そうでない場合、たとえばV2.1のブートフロッピーから起動する場合は、いくつか余計なステップが必要です。

(1) Towns OS V2.1を起動する。
(2) Towns MENUでディスクの初期化を選ぶ。
(3) 初期化のウィンドウが開いたら、V2.1のCD-ROMを取り出してV1.1 L30のCD-ROMを入れる。
(4) 「システムの複写」と「1.2MB」をチェックした状態で、「実行」をクリック。
(5) 途中でエラーで止まるが、IO.SYSさえコピーされていればあとは関係ない。
(6) 一応、念のためTOWNSを再起動。
(7) V1.1 L30のCD-ROMから、TBIOS.SYS, TBIOS.BINをブートフロッピーディスクにコピー。
(8) YSSCSICD.SYSをブートフロッピーディスクにコピー。
(9) SYSDRV.EXEをブートフロッピーディスクにコピー。
(10) このディレクトリにあるAUTOEXEC.BATとCONFIG.SYSをブートフロッピーディスクにコピー。
