#charset "us-ascii"
//
// keywordActionExec.t
//
//	This is a replacement for adv3's default executeCommand() function.
//	It is MOSTLY logically equivalent to executeCommand(), with a couple
//	additions for the keywordAction module.  The code has also been
//	re-organized to make further updates/modification simpler (hopefully).
//
//	The code from executeCommand() is found in lib/adv3/exec.t in the
//	TADS3 source.  The original code carries the following copyright
//	message:
//
//	/* 
//	 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
//	 *   
//	 *   TADS 3 Library: command execution
//	 *   
//	 *   This module defines functions that perform command execution.  
//	 */
//
//	The keywordAction module is distributed under the MIT license, a copy
//	of which can be found in LICENSE.txt in the top level of the module
//	source.
//
#include <adv3.h>
#include <en_us.h>

modify PendingCommandToks
	executePending(targetActor) {
		keywordActionExec.execute(targetActor, issuer_, tokens_,
			startOfSentence_);
	}
;

keywordActionExec: KeywordActionObject
	keywordActionID = 'keywordActionExec'

	action = nil
	match = nil
	extraIdx = nil
	extraTokens = nil
	nextCommandTokens = nil
	nextIdx = nil
	rankings = nil

	first = nil

	srcActor = nil
	dstActor = nil
	actorPhrase = nil
	actorSpecified = nil

	toks = nil

	// Clear out all of our properties.
	clearState() {
		action = nil;
		match = nil;
		extraIdx = nil;
		extraTokens = nil;
		nextCommandTokens = nil;
		nextIdx = nil;
		rankings = nil;

		first = nil;

		actorPhrase = nil;
		actorSpecified = nil;

		srcActor = nil;
		dstActor = nil;

		toks = nil;

		// Clear the disambiguator's state as well.
		//keywordActionDisambig.clearState();
	}

	// Drop-in replacement for adv3's executeCommand().
	// Should only be called from PendingCommandToks.executePending().
	execute(dst, src, t, fst) {
		local r;

		// Start from scratch every time we're called.
		clearState();

		// Remember our arguments.
		srcActor = src;
		dstActor = dst;
		toks = t;
		first = fst;

		libGlobal.enableSenseCache();
		setSenseContext();

		// More or less equivalent to the parseTokenLoop: loop
		// from executeCommand().  We loop through the tokens
		// until we're done or something throws an exception.
		r = true;
		while(r) {
			try {
				r = parseLoop();
			}
			// This is our addition to the try/catch block.
			// As written it's exactly the same as a generic
			// ParseFailureException, but we break it out
			// to make it easier to modify later.
			catch(KeywordActionException kaExc) {
				local dst, f, src, t;

				_debug('===KeywordActionException===');
				dst = dstActor;
				src = srcActor;
				f = first;
				t = toks;
				clearState();
				executeCommand(dst, src, t, f);
				//kaExc.notifyActor(dstActor, srcActor);
				return;
			}
			catch(ParseFailureException rfExc) {
				_debug('===ParseFailureException===');
				rfExc.notifyActor(dstActor, srcActor);
				clearState();
				return;
			}
			catch(CancelCommandLineException ccExc) {
				_debug('===CancelCommandLineException===');
				if(nextCommandTokens != nil)
					dstActor.getParserMessageObj()
						.explainCancelCommandLine();
				clearState();
				return;
			}
			catch(TerminateCommandException tcExc) {
				_debug('===TerminateCommandException===');
				clearState();
				return;
			}
			catch(RetryCommandTokensException rctExc) {
				_debug('===RetryCommandTokensException===');
				toks = rctExc.newTokens_ + extraTokens;
				r = true;
			}
			catch(ReplacementCommandStringException rcsExc) {
				local str;
	
				_debug('===ReplacementCommandStringException===');
				str = rcsExc.newCommand_;
				if(str == nil)
					return;
				toks = cmdTokenizer.tokenize(str);
				first = true;
				srcActor = rcsExc.issuingActor_;
				dstActor = rcsExc.targetActor_;
				dstActor.addPendingCommand(true, srcActor,
					toks);
				clearState();
				return;
			}
		}
	}

	setSenseContext() {
		if(first && (srcActor != dstActor)
			&& srcActor.revertTargetActorAtEndOfSentence) {
			dstActor = srcActor;
			senseContext.setSenseContext(srcActor, sight);
		}
	}

	_getCommandList(flg, dict?) {
		local lst, prod;

		prod = (first ? firstKeywordActionPhrase
			: keywordActionPhrase);

		if(keywordActionDisambigState.get() != nil) {
			_debug('in disabiguation, not using keyword actions');
			throw new KeywordActionException(&commandNotUnderstood);
		}

		_debug('evaluating keyword actions');

		lst = _tryParseTokens(prod, dict);
		if(lst.length() == 0) {
			_debug('no keyword action match');
			throw new KeywordActionException(&commandNotUnderstood);
		}

		return(lst);
	}

	_tryParseTokens(prod, dict?) {
		local lst;

		lst = prod.parseTokens(toks, (dict ? dict : cmdDict));

		_debug('\tparseTokens() returned <<toString(lst.length)>>
			actions');

		lst = lst.subset({ x: x.resolveFirstAction(srcActor,
			dstActor) != nil
		});

		_debug('\tresolveFirstAction() returned <<toString(lst.length)>>
			actions');

		return(lst);
	}

	getCommandList(dict?) {
		local lst;

		lst = _getCommandList(dict);

		_debugList(lst);
		dbgShowGrammarList(lst);

		if(lst.length() == 0) {
			_debug('_getCommandList() produced zero-length
				list');
			throw new KeywordActionException(&commandNotUnderstood);
		}

		dbgShowGrammarList(lst);

		return(lst);
	}

	parseLoop() {
		local lst;

		extraTokens = [];

		if((lst = getCommandList()) == nil)
			return(nil);

		_debug('getCommandList() returned
			<<toString(lst.length())>> candidates');

		rankings = CommandRanking.sortByRanking(lst,
			srcActor, dstActor);

		match = rankings[1].match;

		_debugObject(match, 'match = ');
		dbgShowGrammarWithCaption('Winner', match);

		nextIdx = match.getNextCommandIndex();
		nextCommandTokens = toks.sublist(nextIdx);

		if(nextCommandTokens.length() == 0)
			nextCommandTokens = nil;

		extraIdx = match.tokenList.length() + 1;
		extraTokens = toks.sublist(extraIdx);

		if(match.hasTargetActor())
			return(handleActorMatch(match));

		action = match.resolveFirstAction(srcActor, dstActor);
		if(rankings[1].unknownWordCount != 0) {
			_debug('===unknownWordCound===');
			match.resolveNouns(srcActor, dstActor,
				new OopsResults(srcActor, dstActor));
		}

		if((action != nil) && action.isConversational(srcActor)) {
			senseContext.setSenseContext(srcActor, sight);
		} else if(actorSpecified && (srcActor != dstActor)) {
			senseContext.setSenseContext(dstActor, sight);
		}

		if((action.keywordActionFailed == true) 
			&& (keywordActionDisambigState.get() == nil)) {
			throw new KeywordActionException(&commandNotUnderstood);
		}

		withCommandTranscript(CommandTranscript, function() {
			_debug('===executeAction===');
			executeAction(dstActor, actorPhrase, srcActor,
				(actorSpecified && (srcActor != dstActor)),
				action);
		});

		if(nextCommandTokens != nil) {
			dstActor.addFirstPendingCommand(match.isEndOfSentence(),
				srcActor, nextCommandTokens);
		}

		if(actorSpecified && (srcActor != dstActor))
			srcActor.waitForIssuedCommand(dstActor);

		return(nil);
	}

	handleActorMatch(match) {
		local actorResults;

		if(!actorSpecified && (srcActor != dstActor)) {
			if(!srcActor.issueCommandsSynchronously) {
				senseContext.setSenseContext(nil, sight);
				srcActor.getParserMessageObj()
					.cannotChangeActor();
				return(nil);
			}
			srcActor.addFirstPendingCommand(first, srcActor, toks);
			return(nil);
		}

		actorResults = new ActorResolveResults();
		actorResults.setActors(dstActor, srcActor);


		match.resolveNouns(srcActor, dstActor, actorResults);
		dstActor = match.getTargetActor();
		actorPhrase = match.getActorPhrase();

		dstActor.copyPronounAntecedentsFrom(srcActor);
		match.execActorPhrase(srcActor);
		if(!dstActor.acceptCommand(srcActor))
			return(nil);
		actorSpecified = true;
		toks = match.getCommandTokens();
		first = nil;

		return(true);
	}

	handleEmptyActionList() {
		local i, lst;

		if(first) {
			lst = actorBadCommandPhrase.parseTokens(toks, cmdDict);
			lst = lst.mapAll({
				x: x.resolveNouns(srcActor, srcActor,
					new TryAsActorResolveResults())
			});
			if((lst.length() == 0)
				&& (i = lst.indexWhich({
					x: x[1].obj_.ofKind(Actor)
				}) != nil)) {
				targetActor = lst[i][1].obj_;
			}
		}
		tryOops(toks, srcActor, dstActor, 1, toks, rmcCommand);
		if(specialTopicHistory.checkHistory(toks)) {
			dstActor.notifyParseFailure(srcActor,
				&specialTopicInactive, []);
		} else {
			dstActor.notifyParseFailure(srcActor,
				&commandNotUnderstood, []);
		}
	}
;

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
