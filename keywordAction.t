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

class KeywordActionObject: object
	keywordActionID = nil
	_debug(msg?) {}
	_debugList(lst) {}
	_debugObject(obj, lbl?) {}
;

modify Action keywordActionFailed = nil;

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
		_debug('===starting KeywordAction.resolveNouns()===');
		inherited(srcActor, dstActor, results);
		_debug('===finished inherited resolveNouns()===');
		resolveKeywordAsAction(srcActor, dstActor, results);
		_debug('===finished resolveKeywordAsAction()===');
	}
;

class KeywordTAction: KeywordActionBase, TAction;

modify SingleNounProd
	_debug(msg) { aioSay('\nSingleNounProd: <<toString(msg)>>\n '); }
	resolveNouns(resolver, results) {
		local lst;

		results.beginSingleObjSlot();
		_debug('\tnp_.resolveNouns() start');
		lst = np_.resolveNouns(resolver, results);
		_debug('\tnp_.resolveNouns() end');
		results.endSingleObjSlot();
		if(lst.length() > 1) {
			_debug('lst.length = <<toString(lst.length())>>');
			results.uniqueObjectRequired(getOrigText(), lst);
		}

		return(lst);
	}
;

/*
modify NounPhraseWithVocab
	_debug(msg) { aioSay('\nsingleNounProd: <<toString(msg)>>\n '); }
	resolveNouns(resolver, results) {
		local r;
		_debug('===NounPhraseWithVocab.resolveNouns() start===');
		r = inherited(resolver, results);
		_debug('===NounPhraseWithVocab.resolveNouns() end===');
		return(r);
	}
;
*/

/*
modify BasicResolveResults
	_debug(msg) { aioSay('\nBasicResolveResults: <<toString(msg)>>\n '); }
	askMissingObject(asker, resolver, responseProd) {
		local r;

		_debug('===BasicResolveResults start===');
		r = inherited(asker, resolver, responseProd);
		_debug('===BasicResolveResults end===');
		return(r);
	}
;

modify ResolveAsker
	_debug(msg) { aioSay('\nResolveAsker: <<toString(msg)>>\n '); }
	askDisambig(actor, prompt, cur, full, req, again, dist) {
		local r;

		_debug('===askDisambig() start===');
		r = inherited(actor, prompt, cur, full, req, again, dist);
		_debug('===askDisambig() end===');
		return(r);
	}
	askMissingObject(actor, action, which) {
		local r;

		_debug('===askMissingObject() start===');
		r = inherited(actor, action, which);
		_debug('===askMissingObject() end===');
		return(r);
	}
;

modify BasicResolveResults
	_debug(msg) { aioSay('\nBasicResolveResults: <<toString(msg)>>\n '); }
	ambiguousNounPhrase(k, a, t, ml, fml, sl, rn, res) {
		local r;

		_debug('===ambiguousNounPhrase() start===');
		r = _ambiguousNounPhrase(k, a, t, ml, fml, sl, rn, res);
		_debug('===ambiguousNounPhrase() end===');
		return(r);
	}
;
