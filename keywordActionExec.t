#charset "us-ascii"
//
// keywordActionExec.t
//
#include <adv3.h>
#include <en_us.h>

keywordActionList: PreinitObject
	_list = nil

	execute() {
		_list = new Vector();
		forEachInstance(KeywordAction, function(o) {
			_list.append(o);
		});
	}

	match(toks, first) {
		return(nil);
	}
;

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

	execute(dst, src, t, first) {
		local r;

		clearState();

		srcActor = src;
		dstActor = dst;
		toks = t;

		libGlobal.enableSenseCache();
		
		setSenseContext(first);

		r = true;
		while(r) {
			try {
				r = parseLoop(first);
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
			if(handleKeywordActions(first))
				return;
			dstActor.notifyParseFailure(srcActor,
				&commandNotUnderstood, []);
		}
	}

	handleKeywordActions(first) {
		return(keywordActionList.match(toks, first));
	}
;
