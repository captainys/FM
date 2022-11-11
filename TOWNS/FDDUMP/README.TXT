FDDUMP.EXE for FM TOWNS by CaptainYS (http://www.ysflight.com)



Introduction

This is a disk-imaging tool that runs on Fujitsu FM TOWNS computers.  The model needs to be UG or newer since the program uses Free-Run Timer for measuring the time.  If the model is older, you can try MAKED77.EXP instead, although it captures less information.

This program was developed for preserving programs for Fujitsu FM-7/77/77AV series computers and FM TOWNS series computers.  FDDUMP.EXE captures ID marks, sector contents, and track-read output.  It also measures time for reading a sector.  Some copy protection checkers rely on sector-read timing, and FDDUMP.EXE can capture that information.

Also it captures a sector that changes the contents up to 12 times by default.  Multiple-samples are necessary for replicating one type of copy protection that relies on unstable bytes.

Some games for FM-7 used Leaf-In-The-Forest protect, which hides real sectors among dummy sectors.  Initially I thought it would be difficult to capture this information.  However, to my surprise, track-read command in FM TOWNS (2MX at least) returns accurate sector data, from which I can extract real sectors.  I have confirmed that hidden-sector content can be recovered from track-read output of The Fire Crystal and Thexder.  I initially thought I failed to capture hidden sector of Thexder, but I was wrong.

So, this program captures all copy protections used for FM-7 series to my knowledge.

My best suggestion is, if you own an original copy of classic games, use a pulse-width capture devices such as KryoFlux, Pauline, FD Shield, and FDX, as well as capture from real hardware.  We have not yet explored how the error-correction of the real hardware was working.  I have experience many cases that I could not recover sectors from pulse-width capture image, but real FM77AV or FM TOWNS was able to read missed sectors with no error.

.D77 disk image cannot store timing information and track-read output.  Therefore, FDDUMP.EXE creates .RDD file (Real Disk Dump), which can be converted to .D77 image by RDD2D77.EXE for the time being, but FM TOWNS Emulator Tsugaru and FM77AV Emulator Mutsu will support .RDD format directly.



このプログラムは、富士通FM TOWNS実機上で動作するディスクイメージキャプチャツールです。ただし、フリーランタイマーを使用する都合で、FM TOWNSモデルUG以降であ必要があります。UGよりも前の機種では、MAKED77.EXPが利用できますが、FDDUMP.EXEほどの情報はキャプチャできません。

このプログラムは、富士通FM-7/77/77AVシリーズ、FM TOWNSシリーズ用アプリケーションを保存するために開発しました。FDDUMP.EXEは、ディスクのIDマーク、セクタ内容、トラックリードの出力結果を記録します。また、セクタ読み込み中に、所要時間を記録します。ある種のコピープロテクトはセクタ読み込み時間を計測するので、再現するためにはこの情報が必要です。

また、読み込むたびに内容が変化するセクタは、最大12回マルチサンプルします。マルチサンプルは、セクタ内容の変化をチェックする通称コロコロプロテクトを再現するために必要です。

さらに、いくつかのゲーム（確認できているのは今のところ Thexder と Fire Crystal)が使う木の葉隠れプロテクトの再現に必要な情報もTrack Readから回収できることが判明して、ThexderとFire Crystalはこの方法で隠れセクタを再現することができました。

というわけで、このツールを使うととりあえず今まで自分が知ってる範囲のFM-7/77/77AV, FM TOWNSシリーズで使われたすべてのコピープロテクトを再現するために必要な情報を抜き出すことができます。

もしも、レトロゲームの原本を持っているならば、KryoFlux, Pauline, FD Shieldなどのツールによるパルスイメージと合わせて実機でのサンプルも保存しておくことをお勧めします。パルスイメージは、生データを保存できる反面、まだ実機のフロッピーディスクコントローラがどういうエラー修正をしていたのか完全に解明できていません。PaulineでキャプチャしたイメージではいくつかのセクタにCRCエラーが出たままだったのに、実機に読ませたらなにごともなく読んだというケースがかなり多くあります。いつかは実機のエラー補正機能も解明できて、パルスから完全な情報の抜き出しができるようになるかもしれませんが、現状では両方残しておくと完璧と思います。

.D77ファイルフォーマットではセクタ読み込み時間の情報を保存できないので、FDDUMP.EXEは、.RDD (Real Disk Dump)フォーマットなるファイルを出力します。現在のところ、これをRDD2D77.EXEを使って.D77形式に変換することでエミュレータに食わせることができますが、いずれ、FM TOWNSエミュレータ津軽・FM77AVエミュレータ陸奥は.RDDフォーマットに直接対応する予定です。





Required System
必要なシステム

FM TOWNS UG or newer plus SCSI hard disk (can be virtual SCSI hard drive like SCSI2SD).  Or, more than 8MB RAM.  Towns OS Command Mode, ORICON, or MS-DOS.

You cannot save disk image to a floppy disk because it won't fit to start with and it cannot access floppy disk while this program is reading a disk.  FM TOWNS (and many other systems) use same floppy-disk controller.  It is NOT possible to read image from drive A and save to drive B, since FDDUMP.EXE take over all floppy-disk access.

Therefore, you need to save disk image to either hard drive, or save disk image to RAM disk and transfer to outside of TOWNS.



FM TOWNS UG以上 ＋ SCSI ハードディスク (SCSI2SDなどの仮想SCSIハードディスクも可）、または8MB程度のRAMで4MB程度のRAMディスク。Towns OS Command Mode, ORICON, or MS-DOS.

フロッピーディスクイメージを取りながらフロッピーディスクに書き込むことは、そもそもディスクに入りきらないのとFDDUMPが両ドライブのアクセスをテイクオーバーしてしまうのでできません。SCSIハードディスクに保存するか、あるいはいったんRAMディスクに保存してTOWNSの外に転送するかどちらかが必要です。





Usage
使い方

FDDUMP drive: mediaType -out filename
  drive:  A or B
  mediaType  2D/2DD/2HD or can be 320KB/640KB/1232KB (for 1440KB 2HD disk, try 2HD)

Optional
  -starttrk t    Start capture from cylinder t
  -endtrk t      End capture at cylinder 5



FDDUMP ドライブ: メディアタイプ -out ファイル名
  ドライブ:  A or B
  メディアタイプ  2D/2DD/2HD または 320KB/640KB/1232KB (1440KBのディスクの場合2HDで多分読めます)

Optional
  -starttrk t    シリンダーtからキャプチャ開始
  -endtrk t      シリンダーtまでキャプチャ
