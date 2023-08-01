#charset "us-ascii"
//
// keywordAction.t
//
//	This module provides a mechanism by which you can associate
//	actions with bare noun phrases typed by themselves on the command
//	line.
//
//	Example usage:
//
//	  DefineKeywordAction(NounAsExamine, Thing);
//	  modify Thing dobjFor(NounAsExamine) asDobjFor(Examine);
//	  pebble: Thing 'small round pebble' 'pebble' "A small, round pebble. ";
//
//	Will result in "pebble" by itself being treated as >X PEBBLE:
//
//		>X PEBBLE
//		A small, round pebble.
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

// Mixin class for most of the module's stuff.  Provides stub methods
// for the debugging stuff.
class KeywordActionObject: object
	keywordActionID = nil
	_debug(msg?) {}
	_debugList(lst) {}
	_debugObject(obj, lbl?) {}
;

// Add a property to all actions, nil by default.
modify Action keywordActionFailed = nil;

// Base class for our keyword actions.
class KeywordActionBase: KeywordActionObject
	// The class of objects, if any, this action applies to.
	keywordActionClass = nil

	// See if our dobjList_ contains any objects of the class
	// defined above.  We mark the failed flag.  We also note
	// noVocabMatch() on the results object.
	// If any keyword action DOES match, it will NOT have
	// noVocabMatch() called on its results, so it will
	// "win", and it will be used as the action.
	// If all possible keyword actions fail, an arbitrary one
	// will end up "winning" (just by being first in a list of
	// equally failed options).  At this point keywordActionExec
	// will notice the keywordActionFailed flag set on it,
	// and it'll throw an exception, causing parsing of
	// keyword actions to terminate, and punting things off
	// to the normal adv3 parsing logic.
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
			// We set a placeholder as the noVocabMatch
			// text, but it'll never be displayed;  a non-failed
			// result will be preferred to a failed one, and if
			// all results failed then an exception will be
			// thrown and the entire attempt to resolve keyword
			// actions will end.

			// This part is to help pick a "winner" among different
			// potential keyword action matches.
			results.noVocabMatch(self, 'FIXME');

			// This part is to tell keywordActionExec to throw
			// an exception if none of the potential keyword actions
			// matched anything.
			keywordActionFailed = true;

			_debug('resolveKeywordAsAction() failed');
		}
	}

	// We need to call resolveNounsAsVerbs() after inherited()
	// because the parent method is what will populate dobjList_.
	resolveNouns(srcActor, dstActor, results) {
		inherited(srcActor, dstActor, results);
		resolveKeywordAsAction(srcActor, dstActor, results);
	}
;

// Keyword actions are always transitive (they function exactly like
// [some action] [some object]), but we defined a base keyword action
// class and mix in TAction because who knows.
class KeywordTAction: KeywordActionBase, TAction;
