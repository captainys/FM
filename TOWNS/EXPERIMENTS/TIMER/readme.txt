Linux for TOWNS CD-ROM(?) driver does this:

0010:0016EF50 8B542404                  MOV     EDX,[ESP+04H]
0010:0016EF54 E460                      IN      AL,60H (TIMER_INT_CTRL_INT_REASON)
0010:0016EF56 C1E802                    SHR     EAX,02H
0010:0016EF59 83E007                    AND     EAX,07H
0010:0016EF5C 0C80                      OR      AL,80H
0010:0016EF5E E660                      OUT     60H,AL (TIMER_INT_CTRL_INT_REASON)
0010:0016EF60 E460                      IN      AL,60H (TIMER_INT_CTRL_INT_REASON)
0010:0016EF62 A801                      TEST    AL,01H
0010:0016EF64 74FA                      JE      0016EF60
0010:0016EF66 E460                      IN      AL,60H (TIMER_INT_CTRL_INT_REASON)
0010:0016EF68 C1E802                    SHR     EAX,02H
0010:0016EF6B 83E007                    AND     EAX,07H
0010:0016EF6E 0C80                      OR      AL,80H
0010:0016EF70 E660                      OUT     60H,AL (TIMER_INT_CTRL_INT_REASON)
0010:0016EF72 4A                        DEC     EDX
0010:0016EF73 7DEB                      JGE     0016EF60
0010:0016EF75 C3                        RET

while interval-timer interrupt is enabled.

TM0OUT flag is cleared inside of the handler.

Therefore, unless the interrupt occurs exactly during IN AL,60H, this polling loop does not seem to pick up TM0OUT.

Due to this, Tsugaru takes extremely long to get through this polling loop.

However, the test on the real FM TOWNS II MX showed that this polling loop successfully count 10 times given count milliseconds.
