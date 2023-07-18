#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#ifdef __DEBUG_KEYWORD_ACTION

modify Action
	keywordActionID = nil

	_debug(msg?) {
		aioSay('\n<<(keywordActionID ? '<<keywordActionID>>: '
			: '')>><<msg>>\n ');
	}
;

#endif // __DEBUG_KEYWORD_ACTION
