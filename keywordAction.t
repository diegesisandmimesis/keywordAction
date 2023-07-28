#charset "us-ascii"
//
// keywordAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

// Module ID for the library
keywordActionModuleID: ModuleID {
        name = 'Keyword Action Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

modify Action
	keywordActionFailed = nil
	keywordActionID = nil

	_actionInfo() {}
;


class KeywordActionBase: KeywordActionObject
	// The class of objects, if any, this action applies to.
	keywordActionClass = nil

	// See if our dobjList_ contains any objects of the class
	// defined above.  If it doesn't, then we mark the results
	// as being a weak phrasing.  If there are other options
	// for the parser to pick from, it will prefer them over us.
	//
	resolveKeywordAsAction(srcActor, dstActor, results) {
		local r;

		if((dobjList_ == nil) || (keywordActionClass == nil))
			return;

		r = nil;
		dobjList_.forEach(function(o) {
			if(o.obj_ && o.obj_.ofKind(keywordActionClass))
				r = true;
		});

		if(keywordActionDisambigState.get() != nil)
			r = nil;

		if(r != true) {
			results.noVocabMatch(self, '');
			keywordActionFailed = true;
			_debug('resolveKeywordAsAction() failed');
		}
	}

	// We need to call resolveNounsAsVerbs() after inherited()
	// because the parent method is what will populate dobjList_.
	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
//aioSay('resolveNouns() on <<toString(keywordActionID)>>\n ');
		resolveKeywordAsAction(srcActor, dstActor, results);
	}

	//resolveAction(srcActor, dstActor) { aioSay('resolveAction()\n '); return(self); }
	//resolveFirstAction(srcActor, dstActor) { aioSay('resolveFirstAction()\n '); return(self); }
/*
	getNextCommandIndex() {
		_debugObject(cmd_, 'getNextCommandIndex(): cmd_ = ');
		return(inherited());
	}
*/
;

class KeywordTAction: KeywordActionBase, TAction;

/*
DefineTAction(KeywordActionCatchAll);
KeywordActionRule(KeywordActionCatchAll)
	singleDobj: KeywordActionCatchAllAction
	verbPhrase = 'catch/catching (what)'

	keywordActionID = 'catch-all'

	keywordActionFailed = nil

	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		results.noMatch(self, '');
		keywordActionFailed = true;
	}
;
*/

class KeywordActionObject: object
	keywordActionID = nil
	_debug(msg?) {}
	_debugList(lst) {}
	_debugObject(obj, lbl?) {}
;
