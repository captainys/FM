#ifndef FM77AVKEYMAP_IS_INCLUDED
#define FM77AVKEYMAP_IS_INCLUDED
/* { */

#include <map>
#include "fm77avkey.h"

class FM77AVKeyMap
{
public:
	std::map <int,int> map;

	FM77AVKeyMap();
	void MakeUS101KeyMap(void);
};


/* } */
#endif
