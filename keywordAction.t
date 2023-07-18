#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

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
;

class KeywordAction: TAction
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

		if(r != true) {
			results.noVocabMatch(self, '');
		}
	}

	// We need to call resolveNounsAsVerbs() after inherited()
	// because the parent method is what will populate dobjList_.
	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		resolveKeywordAsAction(srcActor, dstActor, results);
	}
;

// As written our custom exceptions are handled exactly as if they're
// standard ParseFailureExceptions, but we use a new exception class
// anyway, just to make it easier to modify.
class KeywordActionException: ParseFailureException;

DefineTAction(KeywordActionCatchAll);
VerbRule(KeywordActionCatchAll)
	[badness 999] singleDobj: KeywordActionCatchAllAction
	verbPhrase = 'catch/catching (what)'

	keywordActionID = 'catch-all'

	keywordActionFailed = nil

	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		results.noMatch(self, '');
		keywordActionFailed = true;
	}
;
