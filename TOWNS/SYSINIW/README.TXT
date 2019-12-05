SYSINIW.EXE - Get Verbose Infornation from SYSINIT
by CaptainYS
http://www.ysflight.com/FM/e.html  (English version)
http://www.ysflight.com/FM/j.html  (Japanese version)



FM TOWNS OS V2.1 uses an executable called SYSINIT.EXE to copy some system data to high memory.

By default, SYSINIT.EXE does not print any debug messages.  If it stops in the middle, there is no way of knowing why it failed.

By the way, it shows a message like insufficient memory, but actually when it fails to open a file it shows the same message.

This program enables debugging information from SYSINIT.EXE.

Just run it at the beginning of AUTOEXEC.BAT




FM TOWNS OS V2.1は起動時にSYSINIT.EXEというプログラムで、システムデータをハイメモリ空間に転送します。

通常、SYSINIT.EXEは何もデバッグメッセージを表示しないため、途中で止まった場合何が起きたかわかりません。

なお、「TownsOSのためのメモリが不足しています」というメッセージが出るときがありますが、ファイルの読み込みに失敗しただけでも同じメッセージが出るので役に立ちません。

このプログラムをSYSINIT.EXEの前に実行すると、SYSINIT.EXEがデバッグメッセージを表示するようになります。

AUTOEXEC.BATの先頭で実行すると良いと思います。



