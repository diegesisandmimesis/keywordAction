#charset "us-ascii"
//
// keywordActionDisambig.t
//
//	This is a replacement for adv3's default tryAskingForObject() function.
//	It is MOSTLY logically equivalent to tryAskingForObject(), with a couple
//	additions for the keywordAction module.  The code has also been
//	re-organized to make further updates/modification simpler (hopefully).
//
//	The code from tryAskingForObject() is found in lib/adv3/parser.t in the
//	TADS3 source.  The original code carries the following copyright
//	message:
//
//	/* 
//	 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
//	 *   
//	 *   TADS 3 Library: parser
//	 *   
//	 *   This modules defines the language-independent parts of the command
//	 *   parser.
//	 *   
//	 *   Portions based on xiny.t, copyright 2002 by Steve Breslin and
//	 *   incorporated by permission.  
//	 */
//
//	The keywordAction module is distributed under the MIT license, a copy
//	of which can be found in LICENSE.txt in the top level of the module
//	source.
//
#include <adv3.h>
#include <en_us.h>

replace
tryAskingForObject(srcActor, dstActor, resolver, results, responseProd) {
	return(keywordActionDisambig.disambigObj(srcActor, dstActor,
		resolver, results, responseProd));
}
/*
replace
tryAskingForObject(srcActor, dstActor, resolver, results, responseProd) {
	local cmdMatchList, ires, match, matchList, objList, rankings, str;
	local toks;

	str = readMainCommandTokens(rmcAskObject);
	if(gTranscript)
		gTranscript.activate();

	if(str == nil)
		throw new ReplacementCommandStringException(nil, nil, nil);
    
	toks = str[2];
	str = str[1];

	for(;;) {    
		matchList = responseProd.parseTokens(toks, cmdDict);
        
		if(matchList == []) {
			throw new ReplacementCommandStringException(str, nil,
				nil);
		}

		dbgShowGrammarList(matchList);
        
		ires = new InteractiveResolver(resolver);
		rankings = MissingObjectRanking.sortByRanking(matchList, ires);

		if((rankings[1].nonMatchCount != 0)
			&& (rankings[1].unknownWordCount != 0)) {
			try {
				tryOops(toks, srcActor, dstActor, 1, toks,
					rmcAskObject);
			}
			catch(RetryCommandTokensException exc) {
				toks = exc.newTokens_;

				str = cmdTokenizer.buildOrigText(toks);

				continue;
			}
		}

		if((rankings[1].nonMatchCount != 0)
			&& (rankings[1].miscWordListCount != 0)) {
				throw new ReplacementCommandStringException(str,
					nil, nil);
		}

		match = rankings[1].match;

		cmdMatchList = firstCommandPhrase.parseTokens(toks, cmdDict);
		if(cmdMatchList != []) {
			// This is why we're here.  This handles the case
			// where we have an action defined on a noun phrase
			// and the noun phrase has just been given as the
			// response to a disambiguation request.  We want to
			// handle the noun phrase as the object of the original
			// command instead of as the action associated with
			// the bare noun phrase.
			if(!match.isSpecialResponseMatch
				&& (keywordActionDisambigState.get() == nil)) {
				throw new ReplacementCommandStringException(str,
					nil, nil);
			}
		}

		dbgShowGrammarWithCaption('Missing Object Winner', match);

		objList = match.resolveNouns(ires, results);

		match.resolvedObjects = objList;

		return match;
	}
}
*/

keywordActionDisambig: object
	srcActor = nil
	dstActor = nil
	resolver = nil
	results = nil
	response = nil

	cmdMatchList = nil
	ires = nil
	match = nil
	matchList = nil
	objList = nil
	rankings = nil

	str = nil
	toks = nil

	clearState() {
		srcActor = nil;
		dstActor = nil;
		resolver = nil;
		results = nil;
		response = nil;
		str = nil;
		toks = nil;

		cmdMatchList = nil;
		ires = nil;
		match = nil;
		matchList = nil;
		objList = nil;
		rankings = nil;
	}

	// Main entry point.  Usage is the same as the stock adv3
	// tryAskingForObject().
	disambigObj(src, dst, res1, res2, res3) {
		local r;

		clearState();

		srcActor = src;
		dstActor = dst;

		resolver = res1;
		results = res2;
		response = res3;

		getTokens();

		r = nil;
		while(r == nil) {
			r = parseLoop();
		}

		return(match);
	}

	getMatch() {
		matchList = response.parseTokens(toks, cmdDict);
        
		if(matchList == []) {
			throw new ReplacementCommandStringException(str, nil,
				nil);
		}

		dbgShowGrammarList(matchList);
        
		ires = new InteractiveResolver(resolver);
		rankings = MissingObjectRanking.sortByRanking(matchList, ires);

		if((rankings[1].nonMatchCount != 0)
			&& (rankings[1].unknownWordCount != 0)) {
			try {
				tryOops(toks, srcActor, dstActor, 1, toks,
					rmcAskObject);
			}
			catch(RetryCommandTokensException exc) {
				toks = exc.newTokens_;

				str = cmdTokenizer.buildOrigText(toks);

				return(nil);
			}
		}

		if((rankings[1].nonMatchCount != 0)
			&& (rankings[1].miscWordListCount != 0)) {
				throw new ReplacementCommandStringException(str,
					nil, nil);
		}

		match = rankings[1].match;

		return(true);
	}

	pickWinner() {
		cmdMatchList = firstCommandPhrase.parseTokens(toks, cmdDict);
		if(cmdMatchList != []) {
			// This is why we're here.  This handles the case
			// where we have an action defined on a noun phrase
			// and the noun phrase has just been given as the
			// response to a disambiguation request.  We want to
			// handle the noun phrase as the object of the original
			// command instead of as the action associated with
			// the bare noun phrase.
			if(!match.isSpecialResponseMatch
				&& (keywordActionDisambigState.get() == nil)) {
				throw new ReplacementCommandStringException(str,
					nil, nil);
			}
		}

		dbgShowGrammarWithCaption('Missing Object Winner', match);
	}

	parseLoop() {
		if(getMatch() == nil)
			return(nil);

		pickWinner();
		objList = match.resolveNouns(ires, results);

		match.resolvedObjects = objList;

		return(true);
	}

	getTokens() {
		str = readMainCommandTokens(rmcAskObject);
		if(gTranscript)
			gTranscript.activate();
		if(str == nil)
			throw new ReplacementCommandStringException(nil, nil,
				nil);

		toks = str[2];
		str = str[1];
	}
;
