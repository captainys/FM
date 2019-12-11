YSPING.SYS Register Dump to RS232C for Fujitsu FM TOWNS series computers.
by CaptainYS
http://www.ysflight.com



Usage:
In CONFIG.SYS

DEVICE=YSPING.SYS

Then, INT 77H will dump registers to RS232C (19200bps, 8bit, 1 Stop Bit, No Parity).




使い方:
CONFIG.SYSで、

DEVICE=YSPING.SYS

と書くことで、INT 77HがレジスタダンプをRS232C (19200bps, 8bit, 1 Stop Bit, No Parity)ポートに出力する。
