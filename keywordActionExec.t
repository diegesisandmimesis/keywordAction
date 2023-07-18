#charset "us-ascii"
//
// keywordActionExec.t
//
#include <adv3.h>
#include <en_us.h>

modify PendingCommandToks
	executePending(targetActor) {
		keywordActionExec.execute(targetActor, issuer_, tokens_,
			startOfSentence_);
	}
;

keywordActionExec: object
	action = nil
	match = nil
	extraIdx = nil
	extraTokens = nil
	nextCommandTokens = nil
	nextIdx = nil
	rankings = nil

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

		actorPhrase = nil;
		actorSpecified = nil;

		srcActor = nil;
		dstActor = nil;

		toks = nil;
	}

	// Drop-in replacement for adv3's executeCommand().
	// Should only be called from PendingCommandToks.executePending().
	execute(dst, src, t, first) {
		local r;

		// Start from scratch every time we're called.
		clearState();

		// Remember most of our arguments.
		srcActor = src;
		dstActor = dst;
		toks = t;

		libGlobal.enableSenseCache();
		setSenseContext(first);

		// More or less equivalent to the parseTokenLoop: loop
		// from executeCommand().  We loop through the tokens
		// until we're done or something throws an exception.
		r = true;
		while(r) {
			try {
				r = parseLoop(first);
			}
			// This is our addition to the try/catch block.
			// As written it's exactly the same as a generic
			// ParseFailureException, but we break it out
			// to make it easier to modify later.
			catch(KeywordActionException kaExc) {
				kaExc.notifyActor(dstActor, srcActor);
				return;
			}
			catch(ParseFailureException rfExc) {
				rfExc.notifyActor(dstActor, srcActor);
				return;
			}
			catch(CancelCommandLineException ccExc) {
				if(nextCommandTokens != nil)
					dstActor.getParserMessageObj()
						.explainCancelCommandLine();
				return;
			}
			catch(TerminateCommandException tcExc) {
				return;
			}
			catch(RetryCommandTokensException rctExc) {
				toks = rctExc.newTokens_ + extraTokens;
				r = true;
			}
			catch(ReplacementCommandStringException rcsExc) {
				local str;
	
				str = rcsExc.newCommand_;
				if(str == nil)
					return;
				toks = cmdTokenizer.tokenize(str);
				first = true;
				srcActor = rcsExc.issuingActor_;
				dstActor = rcsExc.targetActor_;
				dstActor.addPendingCommand(true, srcActor,
					toks);
				return;
			}
			catch(KeywordActionException kaExc) {
				aioSay('Whaaaat?\n ');
				return;
			}
		}
	}

	setSenseContext(first) {
		if(first && (srcActor != dstActor)
			&& srcActor.revertTargetActorAtEndOfSentence) {
			dstActor = srcActor;
			senseContext.setSenseContext(srcActor, sight);
		}
	}

	parseLoop(first) {
		local lst;

		extraTokens = [];

		lst = (first ? firstCommandPhrase : commandPhrase)
			.parseTokens(toks, cmdDict);

		lst = lst.subset({ x: x.resolveFirstAction(srcActor,
			dstActor) != nil
		});
		if(lst.length() == 0) {
			handleEmptyActionList(first);
			return(nil);
		}

		dbgShowGrammarList(lst);
		rankings = CommandRanking.sortByRanking(lst,
			srcActor, dstActor);
		match = rankings[1].match;
		dbgShowGrammarWithCaption('Winner', match);
		nextIdx = match.getNextCommandIndex();
		nextCommandTokens = toks.sublist(nextIdx);

		if(nextCommandTokens.length() == 0)
			nextCommandTokens = nil;

		extraIdx = match.tokenList.length() + 1;
		extraTokens = toks.sublist(extraIdx);

		if(match.hasTargetActor())
			return(handleActorMatch(match, toks, first));

		action = match.resolveFirstAction(srcActor, dstActor);
		if(rankings[1].unknownWordCount != 0) {
			match.resolveNouns(srcActor, dstActor,
				new OopsResults(srcActor, dstActor));
		}

		if((action != nil) && action.isConversational(srcActor)) {
			senseContext.setSenseContext(srcActor, sight);
		} else if(actorSpecified && (srcActor != dstActor)) {
			senseContext.setSenseContext(dstActor, sight);
		}

		if(action.keywordActionFailed == true) {
			throw new KeywordActionException(&commandNotUnderstood);
		}

		withCommandTranscript(CommandTranscript, function() {
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

	handleActorMatch(match, toks, first) {
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

	handleEmptyActionList(first) {
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
