#charset "us-ascii"
//
// keywordActionResolve.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

modify BasicResolveResults
	_debug(msg) { aioSay('\nBasicResolveResults: <<msg>>\n '); }
	ambiguousNounPhrase(k, a, t, ml, fml, sl, rn, r) {
		local rt;

		_debug('===start ambiguousNounPhrase===');
		rt = _ambiguousNounPhrase(k, a, t, ml, fml, sl, rn, r);
		_debug('===end ambiguousNounPhrase===');
		return(rt);
	}
	_ambiguousNounPhrase(keeper, asker, txt, matchList, fullMatchList, scopeList, requiredNum, resolver) {

		matchList = matchList.sort(SortAsc, {
			a, b: (a.obj_.disambigPromptOrder
				- b.obj_.disambigPromptOrder)
		});

		local np = matchList[1].np_;
		local npToks = np ? np.getOrigTokenList() : [];
		local promptTxt = txt.toLower().htmlify();
		local pastResponses = keeper.getAmbigResponses();
		local disambigResults = new DisambigResults(self);
		local stillToResolve = [];
		local resultList = [];

		if(!canResolveInteractively(resolver.getAction())) {
			throw new ParseFailureException(&ambiguousNounPhrase, txt.htmlify(), matchList, fullMatchList);
		}

		local everAsked = nil;
		local askingAgain = nil;

		queryLoop:
			for (local pastIdx = 1 ;; ) {
				local str;
				local toks;
				local dist;
				local curMatchList = [];

				foreach(dist in matchList[1].obj_.distinguishers) {
					curMatchList = filterWithDistinguisher(matchList, dist);
					if (curMatchList.length() > requiredNum)
						break;
				}
				if(curMatchList.length() <= requiredNum)
					return fullMatchList.sublist(1, requiredNum);
				if(pastIdx <= pastResponses.length()) {
					str = pastResponses[pastIdx++];
					toks = cmdTokenizer.tokenize(str);
				} else {
					local basicDistList = filterWithDistinguisher(matchList, basicDistinguisher);
					if(basicDistList.length() == 1)
						promptTxt = basicDistList[1].obj_.disambigEquivName;
					dist.notePrompt(curMatchList);
					asker.askDisambig(targetActor_, promptTxt, curMatchList, fullMatchList, requiredNum, everAsked && askingAgain, dist);
					str = readMainCommandTokens(rmcDisambig);
					if(gTranscript)
						gTranscript.activate();

					everAsked = true;
					if(str == nil)
						throw new ReplacementCommandStringException(nil, nil, nil);
					toks = str[2];
					str = str[1];
				}
				askingAgain = nil;
				npToks = npToks.append(['(', tokPunct, '(']);
				npToks += toks;
				npToks = npToks.append([')', tokPunct, ')']);

			retryParse:
				local prodList = mainDisambigPhrase.parseTokens(toks, cmdDict);

				if(prodList == []) {
					throw new ReplacementCommandStringException(str, nil, nil);
				}

				dbgShowGrammarList(prodList);
				local disResolver = new DisambigResolver(txt, matchList, fullMatchList, fullMatchList, resolver, dist);

				local scopeDisResolver = new DisambigResolver(txt, matchList, fullMatchList, scopeList, resolver, dist);

				local rankings = DisambigRanking.sortByRanking(prodList, disResolver);

				if(rankings[1].nonMatchCount != 0 && rankings[1].unknownWordCount != 0) {
					try {
						tryOops(toks, issuingActor_, targetActor_, 1, toks, rmcDisambig);
					}
					catch (RetryCommandTokensException exc) {
						toks = exc.newTokens_;
						str = cmdTokenizer.buildOrigText(toks);

						goto retryParse;
					}
				}

				if(rankings[1].nonMatchCount != 0 && rankings[1].miscWordListCount != 0) {
					throw new ReplacementCommandStringException(str, nil, nil);
				}

				dbgShowGrammarWithCaption('Disambig Winner', rankings[1].match);

				local respList = rankings[1].match.getResponseList();

				foreach (local resp in respList) {
					try {
						try {
							local newObjs = resp.resolveNouns(disResolver, disambigResults);

							for(local n in newObjs) {
								if(n.np_ != nil)
									n.np_.setOrigTokenList(npToks);
							}
							resultList += newObjs;
						}
					catch(UnmatchedDisambigException udExc) {
						resultList += resp.resolveNouns(scopeDisResolver, disambigResults);
					}
				}
				catch(StillAmbiguousException saExc) {
					local newList = new Vector(saExc.matchList_.length());
					foreach(local cur in fullMatchList) {
						if(cur.isDistEquivInList(saExc.matchList_, dist))
							newList.append(cur);
					}

					newList = newList.toList();

					if(newList == [])
						newList = matchList;

					local newFullList = new Vector(fullMatchList.length());
					foreach (local cur in fullMatchList) {
						if(cur.isDistEquivInList(newList, dist)) {
							newFullList.append(cur);
						}
					}

					newFullList = newFullList.toList();
					stillToResolve += new StillToResolveItem(newList, newFullList, saExc.origText_);
				}
				catch(DisambigOrdinalOutOfRangeException oorExc) {
					if(everAsked)
						targetActor_.getParserMessageObj().disambigOrdinalOutOfRange(targetActor_, oorExc.ord_, txt.htmlify());
					askingAgain = true;
					continue queryLoop;
				}
				catch (UnmatchedDisambigException udExc) {
					local newList;
					newList = firstCommandPhrase.parseTokens(toks, cmdDict);
					if(newList.length() != 0) {
						throw new ReplacementCommandStringException(str, nil, nil);
					}

					if(everAsked)
						targetActor_.getParserMessageObj().noMatchDisambig(targetActor_, txt.htmlify(), udExc.resp_);
						askingAgain = true;
						continue queryLoop;
				}
			}

			if(everAsked)
				keeper.addAmbigResponse(str);

			if(stillToResolve.length() == 0)
				break;

			matchList = stillToResolve[1].matchList;
			fullMatchList = stillToResolve[1].fullMatchList;
			txt = stillToResolve[1].origText;

			stillToResolve = stillToResolve.sublist(2);
		}
_debugList(resultList);
//__debugTool.breakpoint();


		return(resultList);
	}
	_debugList(lst) {
		local l;

		if(lst == nil) {
			_debug('_debugList():  nil list');
			return;
		}
		_debug('=====_debugList() start=====');
		_debug('lst.length = <<toString(lst.length)>>');

		lst.forEach(function(obj) {
			if(obj == nil) {
				_debug('object is nil');
				return;
			}
			_debug(reflectionServices.valToSymbol(obj));
			if((l = obj.getPropList()) == nil) {
				_debug('no properties');
				return;
			}
			l.forEach(function(o) {
				if(!obj.propDefined(o, PropDefAny))
					return;
				_debug('\t'
					+ reflectionServices.valToSymbol(o)
					+ ' = '
					+ reflectionServices.valToSymbol(
						obj.(o)));
			});
		});
		_debug('=====_debugList() end=====');
	}
;
