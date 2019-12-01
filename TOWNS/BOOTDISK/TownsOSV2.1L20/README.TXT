Instruction for Creating a Towns OS V2.1L20 Boot Floppy:

The purpose of the bootable floppy disk is to boot into Towns OS V2.1L20 from external SCSI CD-ROM drive for basic set up, formatting floppy disks, etc, to prepare for the day when your internal CD-ROM drive is broken.  You need to be able to start Towns OS V2.1L20 at least once.  If that already happened, please find someone who can help you create a bootable floppy disk from Towns OS V2.1 L20.  It should be easier than finding a replacement internal CD-ROM drive.



Steps:
1. Create a Towns OS V2.1 L20 command-mode bootable floppy disk from TownsMENU.  Make sure to select 1.2MB and check "Copy System" option.
2. Copy two files in here, AUTOEXEC.BAT and CONFIG.SYS to the floppy disk.  Majority of the USB floppy disk drives should be able to write to 1.2MB-format floppy from Windows.
3. Copy YSSCSICD.SYS to the floppy disk.



Booting:
1. Connect your external SCSI CD-ROM drive to FM TOWNS.
2. Insert Towns OS V2.1 L20 CD-ROM in your SCSI CD-ROM drive.
3. Insert the boot floppy disk in A drive.
4. Power on FM TOWNS with F and 0 keys (0 key should be on the full-key side, NOT num-pad 0).  Keep the key held down until floppy boot starts.

In case you don't have a keyboard, if you leave FM TOWNS long enough, it should eventually find the floppy disk and boot from there.



Take a back up:
FM TOWNS needs Towns OS to do basic set ups.  I suggest to take as many back-up copies of the boot floppy disk as you can and store multiple safe locations in a zip lock with drying agent.  To preserve FM TOWNS for the future.





Towns OS V2.1 L20 Boot FDの作り方

このブートフロッピーの目的は、そのうちFM TOWNSの内蔵CD-ROMドライブが故障したとき、外付けSCSI CD-ROMドライブからTowns OSを起動できるようにするものです。その過程で一度だけTowns OS V2.1 L20を起動する必要があります。すでに内蔵CD-ROMドライブが故障してTowns OS V2.1 L20が起動できない場合は、どこかでTowns OS V2.1 L20起動フロッピーを入手してください。今となっては内蔵ドライブの交換よりもその方が簡単だと思います。


ステップ:
1. Towns OS V2.1 L20のコマンドモード起動フロッピーディスクを作る。Towns MENUのディスクの初期化で、1.2MB、システムの複写にチェックして初期化する。
2. このディレクトリにあるAUTOEXEC.BAT, CONFIG.SYSをフロッピーディスクにコピー。
3. YSSCSICD.SYSをフロッピーディスクにコピー


起動:
1. FM TOWNSに外付けSCSI CDドライブを接続。
2. 外付けCDドライブにTowns OS V2.1 L20を入れる。
3. 起動フロッピーディスクをAドライブに入れる。
4. Fキーと0キー (0キーはテンキー側でなく、フルキー側) を押しながら電源投入。フロッピーから起動が始まるまで押し続ける。

キーボードが無い場合は放っておけばいつかフロッピーから起動すると思います。


バックアップを取る:
FM TOWNSはCDからブートできなくなるととたんに基本的なセットアップなどができなくなって詰みます。外付けSCSI CD-ROMから起動できるフロッピーディスクを作成したら、できるかぎりたくさんバックアップを取っておきましょう。そして、バックアップフロッピーディスクはZipLocなどに乾燥剤と一緒に入れて、複数個所に保管しましょう。末永くFM TOWNSを動態保存するために。

