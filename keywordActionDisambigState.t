#charset "us-ascii"
//
// keywordActionDisambigState.t
//
#include <adv3.h>
#include <en_us.h>

keywordActionDisambigState: object
	_flag = nil
	set() { _flag = true; }
	unset() { _flag = nil; }
	get() { return(_flag == true); }
;

StringPreParser
	doParsing(str, which) {
		if(which != rmcCommand) {
			keywordActionDisambigState.set();
		} else {
			keywordActionDisambigState.unset();
		}
		return(str);
	}
;
