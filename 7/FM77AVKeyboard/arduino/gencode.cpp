#include <string>
#include <stdio.h>

enum
{
  AVKEY_NULL,

  AVKEY_BREAK,
  AVKEY_PF1,
  AVKEY_PF2,
  AVKEY_PF3,
  AVKEY_PF4,
  AVKEY_PF5,
  AVKEY_PF6,
  AVKEY_PF7,
  AVKEY_PF8,
  AVKEY_PF9,
  AVKEY_PF10,
  AVKEY_EL,
  AVKEY_CLS,
  AVKEY_DUP,
  AVKEY_HOME,
  AVKEY_INS,
  AVKEY_DEL,
  AVKEY_LEFT,
  AVKEY_RIGHT,
  AVKEY_UP,
  AVKEY_DOWN,

  AVKEY_ESC,
  AVKEY_0,
  AVKEY_1,
  AVKEY_2,
  AVKEY_3,
  AVKEY_4,
  AVKEY_5,
  AVKEY_6,
  AVKEY_7,
  AVKEY_8,
  AVKEY_9,
  AVKEY_MINUS,
  AVKEY_HAT,
  AVKEY_YEN,
  AVKEY_BACKSPACE,

  AVKEY_TAB,
  AVKEY_Q,
  AVKEY_W,
  AVKEY_E,
  AVKEY_R,
  AVKEY_T,
  AVKEY_Y,
  AVKEY_U,
  AVKEY_I,
  AVKEY_O,
  AVKEY_P,
  AVKEY_AT,
  AVKEY_LEFT_SQUARE_BRACKET,
  AVKEY_RETURN,

  AVKEY_CTRL,
  AVKEY_A,
  AVKEY_S,
  AVKEY_D,
  AVKEY_F,
  AVKEY_G,
  AVKEY_H,
  AVKEY_J,
  AVKEY_K,
  AVKEY_L,
  AVKEY_SEMICOLON,
  AVKEY_COLON,
  AVKEY_RIGHT_SQUARE_BRACKET,

  AVKEY_LEFT_SHIFT,
  AVKEY_Z,
  AVKEY_X,
  AVKEY_C,
  AVKEY_V,
  AVKEY_B,
  AVKEY_N,
  AVKEY_M,
  AVKEY_COMMA,
  AVKEY_DOT,
  AVKEY_SLASH,
  AVKEY_DOUBLE_QUOTE,
  AVKEY_RIGHT_SHIFT,

  AVKEY_CAPS,
  AVKEY_GRAPH,
  AVKEY_LEFT_SPACE,
  AVKEY_MID_SPACE,
  AVKEY_RIGHT_SPACE,
  AVKEY_KANA,

  AVKEY_NUM_STAR,
  AVKEY_NUM_SLASH,
  AVKEY_NUM_PLUS,
  AVKEY_NUM_MINUS,
  AVKEY_NUM_EQUAL,
  AVKEY_NUM_COMMA,
  AVKEY_NUM_RETURN,
  AVKEY_NUM_DOT,
  AVKEY_NUM_0,
  AVKEY_NUM_1,
  AVKEY_NUM_2,
  AVKEY_NUM_3,
  AVKEY_NUM_4,
  AVKEY_NUM_5,
  AVKEY_NUM_6,
  AVKEY_NUM_7,
  AVKEY_NUM_8,
  AVKEY_NUM_9,

AVKEY_NUM_KEYCODE
};

enum
{
  SHIFT_BIT=0x80000000L,
  CTRL_BIT= 0x40000000L,
  GRAPH_BIT=0x20000000L,
  KANA_BIT= 0x10000000L,
};

struct FM77AVKeyCombination
{
  unsigned short keyCode;
  bool shift;
  bool ctrl;
  bool graph;
  bool kana;
};

uint32_t bitPattern[AVKEY_NUM_KEYCODE]; // Supposed to be 101 elem = 404 bytes.
std::string keyLabel[AVKEY_NUM_KEYCODE];
uint32_t keyTranslationMap[256];  // Supposed to be 1024 bytes.

void FM77AVSetKeyComb(unsigned char c,unsigned short avKey,bool shift,bool ctrl,bool graph)
{
  keyTranslationMap[c]=avKey;
  keyTranslationMap[c]|=(shift ? SHIFT_BIT : 0)|(ctrl ? CTRL_BIT : 0)|(graph ? GRAPH_BIT : 0);
}

struct FM77AVKeyCombination FM77AVGetKeyComb(unsigned char c)
{
  struct FM77AVKeyCombination comb;
  comb.keyCode=(keyTranslationMap[c]&0xFFFF);
  comb.shift=(0!=(keyTranslationMap[c]&SHIFT_BIT));
  comb.ctrl=(0!=(keyTranslationMap[c]&CTRL_BIT));
  comb.graph=(0!=(keyTranslationMap[c]&GRAPH_BIT));
  comb.kana=(0!=(keyTranslationMap[c]&KANA_BIT));
  return comb;
}

void FM77AVMakeMap(void)
{
  int i;
  for(i=0; i<256; ++i)
  {
    keyTranslationMap[i]=0;
  }
  FM77AVSetKeyComb( 3  , AVKEY_BREAK,         false,false,false);    // Ctrl+C
  FM77AVSetKeyComb(127 , AVKEY_DEL,           false,false,false);    // Ctrl+C
  FM77AVSetKeyComb('\t', AVKEY_TAB,           false,false,false);
  FM77AVSetKeyComb(0x0d ,AVKEY_RETURN,        false,false,false);
  FM77AVSetKeyComb(0x0a ,AVKEY_RETURN,        false,false,false);
  FM77AVSetKeyComb(' ',  AVKEY_MID_SPACE,     false,false,false);    // 32
  FM77AVSetKeyComb( 8 ,  AVKEY_BACKSPACE,     false,false,false);    // Backspace=8
  FM77AVSetKeyComb('!',  AVKEY_1,             true,false,false);
  FM77AVSetKeyComb('\"', AVKEY_DOUBLE_QUOTE,  false,false,false);
  FM77AVSetKeyComb('#',  AVKEY_3,             true,false,false);
  FM77AVSetKeyComb('$',  AVKEY_4,             true,false,false);
  FM77AVSetKeyComb('%',  AVKEY_5,             true,false,false);
  FM77AVSetKeyComb('&',  AVKEY_6,             true,false,false);
  FM77AVSetKeyComb('\'', AVKEY_7,             true,false,false);
  FM77AVSetKeyComb('(',  AVKEY_8,             true,false,false);
  FM77AVSetKeyComb(')',  AVKEY_9,             true,false,false);
  FM77AVSetKeyComb('*',  AVKEY_NUM_STAR,      false,false,false);
  FM77AVSetKeyComb('+',  AVKEY_NUM_PLUS,      false,false,false);
  FM77AVSetKeyComb(',',  AVKEY_NUM_COMMA,     false,false,false);
  FM77AVSetKeyComb('-',  AVKEY_NUM_MINUS,     false,false,false);
  FM77AVSetKeyComb('.',  AVKEY_NUM_DOT,       false,false,false);
  FM77AVSetKeyComb('/',  AVKEY_NUM_SLASH,     false,false,false);
  FM77AVSetKeyComb('0',  AVKEY_NUM_0,         false,false,false);    // 48
  FM77AVSetKeyComb('1',  AVKEY_NUM_1,         false,false,false);
  FM77AVSetKeyComb('2',  AVKEY_NUM_2,         false,false,false);
  FM77AVSetKeyComb('3',  AVKEY_NUM_3,         false,false,false);
  FM77AVSetKeyComb('4',  AVKEY_NUM_4,         false,false,false);
  FM77AVSetKeyComb('5',  AVKEY_NUM_5,         false,false,false);
  FM77AVSetKeyComb('6',  AVKEY_NUM_6,         false,false,false);
  FM77AVSetKeyComb('7',  AVKEY_NUM_7,         false,false,false);
  FM77AVSetKeyComb('8',  AVKEY_NUM_8,         false,false,false);
  FM77AVSetKeyComb('9',  AVKEY_NUM_9,         false,false,false);
  FM77AVSetKeyComb(':',  AVKEY_COLON,         false,false,false);
  FM77AVSetKeyComb(';',  AVKEY_SEMICOLON,     false,false,false);
  FM77AVSetKeyComb('<',  AVKEY_COMMA,true,false,false);
  FM77AVSetKeyComb('=',  AVKEY_NUM_EQUAL,     false,false,false);
  FM77AVSetKeyComb('>',  AVKEY_DOT,true,false,false);
  FM77AVSetKeyComb('?',  AVKEY_SLASH,         true,false,false);
  FM77AVSetKeyComb('@',  AVKEY_AT,            false,false,false);    //64
  FM77AVSetKeyComb('A',  AVKEY_A,             true,false,false);
  FM77AVSetKeyComb('B',  AVKEY_B,             true,false,false);
  FM77AVSetKeyComb('C',  AVKEY_C,             true,false,false);
  FM77AVSetKeyComb('D',  AVKEY_D,             true,false,false);
  FM77AVSetKeyComb('E',  AVKEY_E,             true,false,false);
  FM77AVSetKeyComb('F',  AVKEY_F,             true,false,false);
  FM77AVSetKeyComb('G',  AVKEY_G,             true,false,false);
  FM77AVSetKeyComb('H',  AVKEY_H,             true,false,false);
  FM77AVSetKeyComb('I',  AVKEY_I,             true,false,false);
  FM77AVSetKeyComb('J',  AVKEY_J,             true,false,false);
  FM77AVSetKeyComb('K',  AVKEY_K,             true,false,false);
  FM77AVSetKeyComb('L',  AVKEY_L,             true,false,false);
  FM77AVSetKeyComb('M',  AVKEY_M,             true,false,false);
  FM77AVSetKeyComb('N',  AVKEY_N,             true,false,false);
  FM77AVSetKeyComb('O',  AVKEY_O,             true,false,false);
  FM77AVSetKeyComb('P',  AVKEY_P,             true,false,false);     //80
  FM77AVSetKeyComb('Q',  AVKEY_Q,             true,false,false);
  FM77AVSetKeyComb('R',  AVKEY_R,             true,false,false);
  FM77AVSetKeyComb('S',  AVKEY_S,             true,false,false);
  FM77AVSetKeyComb('T',  AVKEY_T,             true,false,false);
  FM77AVSetKeyComb('U',  AVKEY_U,             true,false,false);
  FM77AVSetKeyComb('V',  AVKEY_V,             true,false,false);
  FM77AVSetKeyComb('W',  AVKEY_W,             true,false,false);
  FM77AVSetKeyComb('X',  AVKEY_X,             true,false,false);
  FM77AVSetKeyComb('Y',  AVKEY_Y,             true,false,false);
  FM77AVSetKeyComb('Z',  AVKEY_Z,             true,false,false);
  FM77AVSetKeyComb('[',  AVKEY_LEFT_SQUARE_BRACKET,false,false,false);
  FM77AVSetKeyComb('\\', AVKEY_YEN,           false,false,false);
  FM77AVSetKeyComb(']',  AVKEY_RIGHT_SQUARE_BRACKET,false,false,false);
  FM77AVSetKeyComb('^',  AVKEY_HAT,           false,false,false);
  FM77AVSetKeyComb('_',  AVKEY_DOUBLE_QUOTE,true,false,false);
  FM77AVSetKeyComb('`',  AVKEY_AT,true,false,false);  // 96
  FM77AVSetKeyComb('a',  AVKEY_A,             false,false,false);
  FM77AVSetKeyComb('b',  AVKEY_B,             false,false,false);
  FM77AVSetKeyComb('c',  AVKEY_C,             false,false,false);
  FM77AVSetKeyComb('d',  AVKEY_D,             false,false,false);
  FM77AVSetKeyComb('e',  AVKEY_E,             false,false,false);
  FM77AVSetKeyComb('f',  AVKEY_F,             false,false,false);
  FM77AVSetKeyComb('g',  AVKEY_G,             false,false,false);
  FM77AVSetKeyComb('h',  AVKEY_H,             false,false,false);
  FM77AVSetKeyComb('i',  AVKEY_I,             false,false,false);
  FM77AVSetKeyComb('j',  AVKEY_J,             false,false,false);
  FM77AVSetKeyComb('k',  AVKEY_K,             false,false,false);
  FM77AVSetKeyComb('l',  AVKEY_L,             false,false,false);
  FM77AVSetKeyComb('m',  AVKEY_M,             false,false,false);
  FM77AVSetKeyComb('n',  AVKEY_N,             false,false,false);
  FM77AVSetKeyComb('o',  AVKEY_O,             false,false,false);
  FM77AVSetKeyComb('p',  AVKEY_P,             false,false,false);
  FM77AVSetKeyComb('q',  AVKEY_Q,             false,false,false);
  FM77AVSetKeyComb('r',  AVKEY_R,             false,false,false);
  FM77AVSetKeyComb('s',  AVKEY_S,             false,false,false);
  FM77AVSetKeyComb('t',  AVKEY_T,             false,false,false);
  FM77AVSetKeyComb('u',  AVKEY_U,             false,false,false);
  FM77AVSetKeyComb('v',  AVKEY_V,             false,false,false);
  FM77AVSetKeyComb('w',  AVKEY_W,             false,false,false);
  FM77AVSetKeyComb('x',  AVKEY_X,             false,false,false);
  FM77AVSetKeyComb('y',  AVKEY_Y,             false,false,false);
  FM77AVSetKeyComb('z',  AVKEY_Z,             false,false,false);
  FM77AVSetKeyComb('{',  AVKEY_LEFT_SQUARE_BRACKET,true,false,false);
  FM77AVSetKeyComb('|',  AVKEY_YEN,           true,false,false);
  FM77AVSetKeyComb('}',  AVKEY_RIGHT_SQUARE_BRACKET,true,false,false);
  FM77AVSetKeyComb('~',  AVKEY_HAT,           true,false,false);

  for(auto &p : bitPattern)
  {
    p=0;
  }
  bitPattern[AVKEY_BREAK        ]=0b101010101010101001001010110101;
  bitPattern[AVKEY_PF1          ]=0b101010101010101001001010101001;
  bitPattern[AVKEY_PF2          ]=0b101010101010101001001001010101;
  bitPattern[AVKEY_PF3          ]=0b101010101010101001001001001001;
  bitPattern[AVKEY_PF4          ]=0b101010101001010110110110110101;
  bitPattern[AVKEY_PF5          ]=0b101010101001010110110110101001;
  bitPattern[AVKEY_PF6          ]=0b101010101001010110110101010101;
  bitPattern[AVKEY_PF7          ]=0b101010101001010110110101001001;
  bitPattern[AVKEY_PF8          ]=0b101010101001010110101010110101;
  bitPattern[AVKEY_PF9          ]=0b101010101001010110101010101001;
  bitPattern[AVKEY_PF10         ]=0b101010101001010110101001010101;
  bitPattern[AVKEY_EL           ]=0b101010101010110101010110101001;
  bitPattern[AVKEY_CLS          ]=0b101010101010110101010101010101;
  bitPattern[AVKEY_DUP          ]=0b101010101010110101001010110101;
  bitPattern[AVKEY_HOME         ]=0b101010101010110101001001010101;
  bitPattern[AVKEY_INS          ]=0b101010101010110101010110110101;
  bitPattern[AVKEY_DEL          ]=0b101010101010110101010101001001;
  bitPattern[AVKEY_LEFT         ]=0b101010101010110101001001001001;
  bitPattern[AVKEY_RIGHT        ]=0b101010101010101010110110101001;
  bitPattern[AVKEY_UP           ]=0b101010101010110101001010101001;
  bitPattern[AVKEY_DOWN         ]=0b101010101010101010110110110101;

  bitPattern[AVKEY_ESC          ]=0b101010110110110110110110101001;
  bitPattern[AVKEY_0            ]=0b101010110110110101010101001001;
  bitPattern[AVKEY_1            ]=0b101010110110110110110101010101;
  bitPattern[AVKEY_2            ]=0b101010110110110110110101001001;
  bitPattern[AVKEY_3            ]=0b101010110110110110101010110101;
  bitPattern[AVKEY_4            ]=0b101010110110110110101010101001;
  bitPattern[AVKEY_5            ]=0b101010110110110110101001010101;
  bitPattern[AVKEY_6            ]=0b101010110110110110101001001001;
  bitPattern[AVKEY_7            ]=0b101010110110110101010110110101;
  bitPattern[AVKEY_8            ]=0b101010110110110101010110101001;
  bitPattern[AVKEY_9            ]=0b101010110110110101010101010101;
  bitPattern[AVKEY_MINUS        ]=0b101010110110110101001010110101;
  bitPattern[AVKEY_HAT          ]=0b101010110110110101001010101001;
  bitPattern[AVKEY_YEN          ]=0b101010110110110101001001010101;
  bitPattern[AVKEY_BACKSPACE    ]=0b101010110110110101001001001001;

  bitPattern[AVKEY_TAB          ]=0b101010110110101010110110110101;
  bitPattern[AVKEY_Q            ]=0b101010110110101010110110101001;
  bitPattern[AVKEY_W            ]=0b101010110110101010110101010101;
  bitPattern[AVKEY_E            ]=0b101010110110101010110101001001;
  bitPattern[AVKEY_R            ]=0b101010110110101010101010110101;
  bitPattern[AVKEY_T            ]=0b101010110110101010101010101001;
  bitPattern[AVKEY_Y            ]=0b101010110110101010101001010101;
  bitPattern[AVKEY_U            ]=0b101010110110101010101001001001;
  bitPattern[AVKEY_I            ]=0b101010110110101001010110110101;
  bitPattern[AVKEY_O            ]=0b101010110110101001010110101001;
  bitPattern[AVKEY_P            ]=0b101010110110101001010101010101;
  bitPattern[AVKEY_AT           ]=0b101010110110101001010101001001;
  bitPattern[AVKEY_LEFT_SQUARE_BRACKET]=0b101010110110101001001010110101;
  bitPattern[AVKEY_RETURN       ]=0b101010110110101001001010101001;

  bitPattern[AVKEY_CTRL         ]=0b101010101010101010110101010101;
  bitPattern[AVKEY_A            ]=0b101010110110101001001001010101;
  bitPattern[AVKEY_S            ]=0b101010110110101001001001001001;
  bitPattern[AVKEY_D            ]=0b101010110101010110110110110101;
  bitPattern[AVKEY_F            ]=0b101010110101010110110110101001;
  bitPattern[AVKEY_G            ]=0b101010110101010110110101010101;
  bitPattern[AVKEY_H            ]=0b101010110101010110110101001001;
  bitPattern[AVKEY_J            ]=0b101010110101010110101010110101;
  bitPattern[AVKEY_K            ]=0b101010110101010110101010101001;
  bitPattern[AVKEY_L            ]=0b101010110101010110101001010101;
  bitPattern[AVKEY_SEMICOLON    ]=0b101010110101010110101001001001;
  bitPattern[AVKEY_COLON        ]=0b101010110101010101010110110101;
  bitPattern[AVKEY_RIGHT_SQUARE_BRACKET ]=0b101010110101010101010110101001;

  bitPattern[AVKEY_LEFT_SHIFT   ]=0b101010101010101010110101001001;
  bitPattern[AVKEY_Z            ]=0b101010110101010101010101010101;
  bitPattern[AVKEY_X            ]=0b101010110101010101010101001001;
  bitPattern[AVKEY_C            ]=0b101010110101010101001010110101;
  bitPattern[AVKEY_V            ]=0b101010110101010101001010101001;
  bitPattern[AVKEY_B            ]=0b101010110101010101001001010101;
  bitPattern[AVKEY_N            ]=0b101010110101010101001001001001;
  bitPattern[AVKEY_M            ]=0b101010110101001010110110110101;
  bitPattern[AVKEY_COMMA        ]=0b101010110101001010110110101001;
  bitPattern[AVKEY_DOT          ]=0b101010110101001010110101010101;
  bitPattern[AVKEY_SLASH        ]=0b101010110101001010110101001001;
  bitPattern[AVKEY_DOUBLE_QUOTE ]=0b101010110101001010101010110101;
  bitPattern[AVKEY_RIGHT_SHIFT  ]=0b101010101010101010101010110101;

  bitPattern[AVKEY_CAPS         ]=0b101010101010101010101010101001;
  bitPattern[AVKEY_GRAPH        ]=0b101010101010101010101001010101;
  bitPattern[AVKEY_LEFT_SPACE   ]=0b101010101010101010101001001001;
  bitPattern[AVKEY_MID_SPACE    ]=0b101010101010101001010110110101;
  bitPattern[AVKEY_RIGHT_SPACE  ]=0b101010110101001010101010101001;
  bitPattern[AVKEY_KANA         ]=0b101010101010101001010101010101;

  bitPattern[AVKEY_NUM_STAR     ]=0b101010110101001010101001010101;
  bitPattern[AVKEY_NUM_SLASH    ]=0b101010110101001010101001001001;
  bitPattern[AVKEY_NUM_PLUS     ]=0b101010110101001001010110110101;
  bitPattern[AVKEY_NUM_MINUS    ]=0b101010110101001001010110101001;
  bitPattern[AVKEY_NUM_EQUAL    ]=0b101010110101001001001010101001;
  bitPattern[AVKEY_NUM_COMMA    ]=0b101010101010110110110110101001;
  bitPattern[AVKEY_NUM_RETURN   ]=0b101010101010110110101010101001;
  bitPattern[AVKEY_NUM_DOT      ]=0b101010101010110110101001001001;
  bitPattern[AVKEY_NUM_0        ]=0b101010101010110110101001010101;
  bitPattern[AVKEY_NUM_1        ]=0b101010101010110110110101010101;
  bitPattern[AVKEY_NUM_2        ]=0b101010101010110110110101001001;
  bitPattern[AVKEY_NUM_3        ]=0b101010101010110110101010110101;
  bitPattern[AVKEY_NUM_4        ]=0b101010110101001001001001010101;
  bitPattern[AVKEY_NUM_5        ]=0b101010110101001001001001001001;
  bitPattern[AVKEY_NUM_6        ]=0b101010101010110110110110110101;
  bitPattern[AVKEY_NUM_7        ]=0b101010110101001001010101010101;
  bitPattern[AVKEY_NUM_8        ]=0b101010110101001001010101001001;
  bitPattern[AVKEY_NUM_9        ]=0b101010110101001001001010110101;

  for(auto &l : keyLabel)
  {
    l="";
  }
  keyLabel[AVKEY_BREAK]="AVKEY_BREAK";
  keyLabel[AVKEY_PF1]="AVKEY_PF1";
  keyLabel[AVKEY_PF2]="AVKEY_PF2";
  keyLabel[AVKEY_PF3]="AVKEY_PF3";
  keyLabel[AVKEY_PF4]="AVKEY_PF4";
  keyLabel[AVKEY_PF5]="AVKEY_PF5";
  keyLabel[AVKEY_PF6]="AVKEY_PF6";
  keyLabel[AVKEY_PF7]="AVKEY_PF7";
  keyLabel[AVKEY_PF8]="AVKEY_PF8";
  keyLabel[AVKEY_PF9]="AVKEY_PF9";
  keyLabel[AVKEY_PF10]="AVKEY_PF10";
  keyLabel[AVKEY_EL]="AVKEY_EL";
  keyLabel[AVKEY_CLS]="AVKEY_CLS";
  keyLabel[AVKEY_DUP]="AVKEY_DUP";
  keyLabel[AVKEY_HOME]="AVKEY_HOME";
  keyLabel[AVKEY_INS]="AVKEY_INS";
  keyLabel[AVKEY_DEL]="AVKEY_DEL";
  keyLabel[AVKEY_LEFT]="AVKEY_LEFT";
  keyLabel[AVKEY_RIGHT]="AVKEY_RIGHT";
  keyLabel[AVKEY_UP]="AVKEY_UP";
  keyLabel[AVKEY_DOWN]="AVKEY_DOWN";
  keyLabel[AVKEY_ESC]="AVKEY_ESC";
  keyLabel[AVKEY_0]="AVKEY_0";
  keyLabel[AVKEY_1]="AVKEY_1";
  keyLabel[AVKEY_2]="AVKEY_2";
  keyLabel[AVKEY_3]="AVKEY_3";
  keyLabel[AVKEY_4]="AVKEY_4";
  keyLabel[AVKEY_5]="AVKEY_5";
  keyLabel[AVKEY_6]="AVKEY_6";
  keyLabel[AVKEY_7]="AVKEY_7";
  keyLabel[AVKEY_8]="AVKEY_8";
  keyLabel[AVKEY_9]="AVKEY_9";
  keyLabel[AVKEY_MINUS]="AVKEY_MINUS";
  keyLabel[AVKEY_HAT]="AVKEY_HAT";
  keyLabel[AVKEY_YEN]="AVKEY_YEN";
  keyLabel[AVKEY_BACKSPACE]="AVKEY_BACKSPACE";
  keyLabel[AVKEY_TAB]="AVKEY_TAB";
  keyLabel[AVKEY_Q]="AVKEY_Q";
  keyLabel[AVKEY_W]="AVKEY_W";
  keyLabel[AVKEY_E]="AVKEY_E";
  keyLabel[AVKEY_R]="AVKEY_R";
  keyLabel[AVKEY_T]="AVKEY_T";
  keyLabel[AVKEY_Y]="AVKEY_Y";
  keyLabel[AVKEY_U]="AVKEY_U";
  keyLabel[AVKEY_I]="AVKEY_I";
  keyLabel[AVKEY_O]="AVKEY_O";
  keyLabel[AVKEY_P]="AVKEY_P";
  keyLabel[AVKEY_AT]="AVKEY_AT";
  keyLabel[AVKEY_LEFT_SQUARE_BRACKET]="AVKEY_LEFT_SQUARE_BRACKET";
  keyLabel[AVKEY_RETURN]="AVKEY_RETURN";
  keyLabel[AVKEY_CTRL]="AVKEY_CTRL";
  keyLabel[AVKEY_A]="AVKEY_A";
  keyLabel[AVKEY_S]="AVKEY_S";
  keyLabel[AVKEY_D]="AVKEY_D";
  keyLabel[AVKEY_F]="AVKEY_F";
  keyLabel[AVKEY_G]="AVKEY_G";
  keyLabel[AVKEY_H]="AVKEY_H";
  keyLabel[AVKEY_J]="AVKEY_J";
  keyLabel[AVKEY_K]="AVKEY_K";
  keyLabel[AVKEY_L]="AVKEY_L";
  keyLabel[AVKEY_SEMICOLON]="AVKEY_SEMICOLON";
  keyLabel[AVKEY_COLON]="AVKEY_COLON";
  keyLabel[AVKEY_RIGHT_SQUARE_BRACKET]="AVKEY_RIGHT_SQUARE_BRACKET";
  keyLabel[AVKEY_LEFT_SHIFT]="AVKEY_LEFT_SHIFT";
  keyLabel[AVKEY_Z]="AVKEY_Z";
  keyLabel[AVKEY_X]="AVKEY_X";
  keyLabel[AVKEY_C]="AVKEY_C";
  keyLabel[AVKEY_V]="AVKEY_V";
  keyLabel[AVKEY_B]="AVKEY_B";
  keyLabel[AVKEY_N]="AVKEY_N";
  keyLabel[AVKEY_M]="AVKEY_M";
  keyLabel[AVKEY_COMMA]="AVKEY_COMMA";
  keyLabel[AVKEY_DOT]="AVKEY_DOT";
  keyLabel[AVKEY_SLASH]="AVKEY_SLASH";
  keyLabel[AVKEY_DOUBLE_QUOTE]="AVKEY_DOUBLE_QUOTE";
  keyLabel[AVKEY_RIGHT_SHIFT]="AVKEY_RIGHT_SHIFT";
  keyLabel[AVKEY_CAPS]="AVKEY_CAPS";
  keyLabel[AVKEY_GRAPH]="AVKEY_GRAPH";
  keyLabel[AVKEY_LEFT_SPACE]="AVKEY_LEFT_SPACE";
  keyLabel[AVKEY_MID_SPACE]="AVKEY_MID_SPACE";
  keyLabel[AVKEY_RIGHT_SPACE]="AVKEY_RIGHT_SPACE";
  keyLabel[AVKEY_KANA]="AVKEY_KANA";
  keyLabel[AVKEY_NUM_STAR]="AVKEY_NUM_STAR";
  keyLabel[AVKEY_NUM_SLASH]="AVKEY_NUM_SLASH";
  keyLabel[AVKEY_NUM_PLUS]="AVKEY_NUM_PLUS";
  keyLabel[AVKEY_NUM_MINUS]="AVKEY_NUM_MINUS";
  keyLabel[AVKEY_NUM_EQUAL]="AVKEY_NUM_EQUAL";
  keyLabel[AVKEY_NUM_COMMA]="AVKEY_NUM_COMMA";
  keyLabel[AVKEY_NUM_RETURN]="AVKEY_NUM_RETURN";
  keyLabel[AVKEY_NUM_DOT]="AVKEY_NUM_DOT";
  keyLabel[AVKEY_NUM_0]="AVKEY_NUM_0";
  keyLabel[AVKEY_NUM_1]="AVKEY_NUM_1";
  keyLabel[AVKEY_NUM_2]="AVKEY_NUM_2";
  keyLabel[AVKEY_NUM_3]="AVKEY_NUM_3";
  keyLabel[AVKEY_NUM_4]="AVKEY_NUM_4";
  keyLabel[AVKEY_NUM_5]="AVKEY_NUM_5";
  keyLabel[AVKEY_NUM_6]="AVKEY_NUM_6";
  keyLabel[AVKEY_NUM_7]="AVKEY_NUM_7";
  keyLabel[AVKEY_NUM_8]="AVKEY_NUM_8";
  keyLabel[AVKEY_NUM_9]="AVKEY_NUM_9";
}

int main(void)
{
	FM77AVMakeMap();

	for(int i=0; i<AVKEY_NUM_KEYCODE; ++i)
	{
		printf("0b");
		unsigned int bit=(1<<29);
		while(0!=bit)
		{
			if(bitPattern[i]&bit)
			{
				printf("1");
			}
			else
			{
				printf("0");
			}
			bit>>=1;
		}
		printf(", // %s\n",keyLabel[i].c_str());
	}

	printf("\n");

	for(int i=0; i<256; ++i)
	{
		printf("0x%08x,\n",keyTranslationMap[i]);
	}

	return 0;
}
