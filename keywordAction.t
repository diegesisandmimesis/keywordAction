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
			return(nil);

		r = nil;
		dobjList_.forEach(function(o) {
			if(o.obj_ && o.obj_.ofKind(keywordActionClass))
				r = true;
		});

		if(r != true) {
			aioSay('Nope.\n ');
			//results.unknownNounPhrase(self, resolver);
			results.noteWeakPhrasing(100);
		}

		return(r);
	}

	// We need to call resolveNounsAsVerbs() after inherited()
	// because the parent method is what will populate dobjList_.
	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		return(resolveKeywordAsAction(srcActor, dstActor, results));
	}
;

class KeywordActionException: ParseFailureException
;

/*
DefineTAction(KeywordActionCatchAll);
VerbRule(KeywordActionCatchAll)
	[badness 500 ] singleDobj: KeywordActionCatchAllAction
	verbPhrase = 'catch/catching (what)'

	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		//throw new KeywordActionException(&commandNotUnderstood);
		aioSay('Catch all.\n ');
		results.noteBadPrep();
		results.noteNounSlots(0);
	}
;
*/
