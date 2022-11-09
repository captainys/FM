FDDUMP.EXE for FM TOWNS by CaptainYS (http://www.ysflight.com)



Introduction

This is a disk-imaging tool that runs on Fujitsu FM TOWNS computers.  The model needs to be UG or newer since the program uses Free-Run Timer for measuring the time.  If the model is older, you can try MAKED77.EXP instead, although it captures less information.

This program was developed for preserving programs for Fujitsu FM-7/77/77AV series computers and FM TOWNS series computers.  FDDUMP.EXE captures ID marks, sector contents, and track-read output.  It also measures time for reading a sector.  Some copy protection checkers rely on sector-read timing, and FDDUMP.EXE can capture that information.

Also it captures a sector that changes the contents up to 12 times by default.  Multiple-samples are necessary for replicating one type of copy protection that relies on unstable bytes.

Some games for FM-7 used Leaf-In-The-Forest protect, that hides real sectors among dummy sectors.  Initially I thought it would be difficult to capture this information.  However, to my surprise, track-read command in FM TOWNS (2MX at least) returns accurate sector data.  I have confirmed that hidden-sector content can be recovered from track-read output of The Fire Crystal.  Well, Thexder's one of the two hidden sectors was crossing the index hole, and Track-Read stopped in the middle, so it did not work for Thexder unfortunately.

Therefore, to my knowledge, FDDUMP.EXE can capture information needed for replicating majority of known copy protect used for FM-7/77/77AV series and FM TOWNS series computers.  (Post processors are in the works now)

My best suggestion is, if you own an original copy of classic games, use a pulse-width capture devices such as KryoFlux, Pauline, FD Shield, and FDX, as well as capture from real hardware.  We have not yet explored how the error-correction of the real hardware was working.  I have experience many cases that I could not recover sectors from pulse-width capture image, but real FM77AV or FM TOWNS was able to read missed sectors with no error.

.D77 disk image cannot store timing information and track-read output.  Therefore, FDDUMP.EXE creates .RDD file (Real Disk Dump), which can be converted to .D77 image by RDD2D77.EXE for the time being, but FM TOWNS Emulator Tsugaru and FM77AV Emulator Mutsu will support .RDD format directly.



このプログラムは、富士通FM TOWNS実機上で動作するディスクイメージキャプチャツールです。ただし、フリーランタイマーを使用する都合で、FM TOWNSモデルUG以降であ必要があります。UGよりも前の機種では、MAKED77.EXPが利用できますが、FDDUMP.EXEほどの情報はキャプチャできません。

このプログラムは、富士通FM-7/77/77AVシリーズ、FM TOWNSシリーズ用アプリケーションを保存するために開発しました。FDDUMP.EXEは、ディスクのIDマーク、セクタ内容、トラックリードの出力結果を記録します。また、セクタ読み込み中に、所要時間を記録します。ある種のコピープロテクトはセクタ読み込み時間を計測するので、再現するためにはこの情報が必要です。

また、読み込むたびに内容が変化するセクタは、最大12回マルチサンプルします。マルチサンプルは、セクタ内容の変化をチェックする通称コロコロプロテクトを再現するために必要です。

さらに、いくつかのゲーム（確認できているのは今のところ Thexder と Fire Crystal)が使う木の葉隠れプロテクトの再現に必要な情報もTrack Readから回収できる、らしいということがわかって、実際Fire Crystalの隠れセクタは取り出すことができたのですが、Thexderの場合は、ダミーセクタの間に隠れているセクタのうちのひとつがインデックスホールをまたいでしまうのですが、トラックリードコマンドが途中で止まってしまうらしく、手持ちのMXではキャプチャに失敗しました。

というわけで、FDDUMP.EXEは、Thexderはだめだったものの、FM-7/FM TOWNSで使われた主要なプロテクトの再現に必要な情報を抜き出すことができます。

もしも、レトロゲームの原本を持っているならば、KryoFlux, Pauline, FD Shieldなどのツールによるパルスイメージと合わせて実機でのサンプルも保存しておくことをお勧めします。パルスイメージは、生データを保存できる反面、まだ実機のフロッピーディスクコントローラがどういうエラー修正をしていたのか完全に解明できていません。PaulineでキャプチャしたイメージではいくつかのセクタにCRCエラーが出たままだったのに、実機に読ませたらなにごともなく読んだというケースがかなり多くあります。いつかは実機のエラー補正機能も解明できて、パルスから完全な情報の抜き出しができるようになるかもしれませんが、現状では両方残しておくと完璧と思います。

.D77ファイルフォーマットではセクタ読み込み時間の情報を保存できないので、FDDUMP.EXEは、.RDD (Real Disk Dump)フォーマットなるファイルを出力します。現在のところ、これをRDD2D77.EXEを使って.D77形式に変換することでエミュレータに食わせることができますが、いずれ、FM TOWNSエミュレータ津軽・FM77AVエミュレータ陸奥は.RDDフォーマットに直接対応する予定です。





