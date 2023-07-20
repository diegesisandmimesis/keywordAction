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

// We replace adv3's tryAskingForObject() with a function that just calls
// our object disambiguation singleton.  We do it this way to preserve
// the usage for all the existing callers in adv3.
replace
tryAskingForObject(srcActor, dstActor, resolver, results, responseProd) {
	return(keywordActionDisambig.disambigObj(srcActor, dstActor,
		resolver, results, responseProd));
}

// A singleton that holds the methods to do object disambiguation.
// This is slightly less performant than having things in one big function
// but it makes it much easier to tweak individual bits of the process
// without having to just replace the whole thing (which is why we're
// doing this in the first place).
keywordActionDisambig: object
	// Our properties are mostly equivalent to the variables used
	// in the default tryAskingForObject().  Making them properties
	// is just a kludge so we don't have to fiddle around with a lot
	// of arguments on the individual methods.
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

	// Clear out all the properties.  We never want to preserve
	// them between calls to tryAskingForObject().
	// We clear at both the start and end of processing.  At the start
	// to make sure we're starting from scratch, and at the end so
	// we're not responsible for any lingering references that might
	// prevent garbage collection.
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

		// Clear all our properties.
		clearState();

		// Remember our arguments.
		srcActor = src;
		dstActor = dst;
		resolver = res1;
		results = res2;
		response = res3;

		// Sort out our tokens.
		getTokens();

		// Main loop.  We keep going until we get a match or
		// hit an exception.
		r = nil;
		while(r == nil) {
			r = parseLoop();
		}

		return(match);
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

	parseLoop() {
		// Try to pick a matching command from the input.
		if(getMatch() == nil)
			return(nil);

		// See if we like the match that got picked.
		checkMatch();

		// Debugging output.
		dbgShowGrammarWithCaption('Missing Object Winner', match);

		// Noun resolution for the chosen match.
		objList = match.resolveNouns(ires, results);
		match.resolvedObjects = objList;

		return(true);
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

		cmdMatchList = firstCommandPhrase.parseTokens(toks, cmdDict);

		return(true);
	}

	checkMatch() {
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

	}
;
