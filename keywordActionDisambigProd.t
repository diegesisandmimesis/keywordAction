#charset "us-ascii"
//
// keywordActionDisambigProd.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

class KeywordActionDisambigProd: DisambigProd;

grammar keywordActionDisambigPhrase(all)
	: 'all' | 'everything' | 'all' 'of' 'them'
	: DisambigProd
	resolveNouns(resolver, results) {
		return(removeAmbigFlags(resolver.getAll(self)));
	}
	getResponseList() { return([ self ]); }
;

grammar keywordActionDisambigPhrase(both)
	: 'both' | 'both' 'of' 'them'
	: DisambigProd
	resolveNouns(resolver, results) {
		return(removeAmbigFlags(resolver.getAll(self)));
	}
	getResponseList() { return([ self ]); }
;

grammar keywordActionDisambigPhrase(any)
	: 'any' | 'any' 'of' 'them'
	: DisambigProd
	resolveNouns(resolver, results) {
		local lst;

		lst = resolver.matchList.sublist(1, 1);
		if(lst.length() > 0)
			lst[1].flags_ |= UnclearDisambig;

		return(lst);
	}
	getResponseList() { return([ self ]); }
;

grammar keywordActionDisambigPhrase(list)
	: keywordActionDisambigList->lst_
	: DisambigProd
	resolveNouns(resolver, results) {
		return(removeAmbigFlags(resolver.getAll(self)));
	}
	getResponseList() { return([ self ]); }
;

grammar keywordActionDisambigPhrase(ordinalList)
	: disambigOrdinalList->lst_ 'ones'
		| 'the' disambigOrdinalList->lst_ 'ones'
	: DisambigProd
	resolveNouns(resolver, results) {
		return(removeAmbigFlags(lst_.resolveNouns(resolver, results)));
	}
	getResponseList() { return([ lst_ ]); }
;

grammar keywordActionDisambigList(single)
	: keywordActionDisambigListItem->item_
	: DisambigProd
	resolveNouns(resolver, results) {
		return(item_.resolveNouns(resolver, results));
	}
	getResponseList() { return([ item_ ]); }
;

grammar keywordActionDisambigList(list)
	: keywordActionDisambigListItem->item_ commandOrNounConjunction
		keywordActionDisambigList->lst_
	: DisambigProd
	resolveNouns(resolver, results) {
		return(item_.resolveNouns(resolver, results)
			+ lst_.resolveNouns(resolver, results));
	}
	getResponseList() { return([ item_] + lst_.getResponseList()); }
;

grammar keywordActionDisambigList(ordinal)
	: ordinalWord->ord_
		| ordinalWord->ord_ 'one'
		| 'the' ordinalWord->ord_
		| 'the' ordinalWord->ord_ 'one'
	: DisambigOrdProd
;

grammar keywordActionDisambigList(noun)
	: completeNounPhraseWithoutAll->np_
		| terminalNounPhrase->np_
	: DisambigOrdProd
	resolveNouns(resolver, results) {
		local lst;

		lst = np_.resolveNouns(resolver, results);
		results.noteMatches(lst);
		return(lst);
	}
;

grammar keywordActionDisambigListItem(noun)
	: completeNounPhraseWithoutAll->np_
		| ordinalWord->ord_ 'one'
		| 'the' ordinalWord->ord_
		| 'the' ordinalWord->ord_ 'one'
	: DisambigVocabProd
;

grammar mainKeywordActionDisambigPhrase(main)
	: keywordActionDisambigPhrase->dp_
		| keywordActionDisambigPhrase->dp_ '.'
	: BasicProd
	resolveNouns(resolver, results) {
		return(dp_.resolveNouns(resolver, results));
	}
	getResponseList() { return dp_.getResponseList(); }
;

grammar keywordActionCompleteNounPhraseWithoutAll(qualified)
	: keywordActionQualifiedNounPhrase->np_
	: LayeredNounPhraseProd
;

grammar keywordActionQualifiedNounPhrase(main)
	: keywordActionQualifiedSingularNounPhrase->np_
		| keywordActionQualifiedPluralNounPhrase->np_
	: LayeredNounPhraseProd
;

grammar keywordActionQualifiedSingularNounPhrase(definite)
	: ( 'the' | 'the' 'one' | 'the' '1' | )
		keywordActionIndetSingularNounPhrase->np_
	: DefiniteNounProd
;

grammar keywordActionQualifiedSingularNounPhrase(indefinite)
	: ( 'a' | 'an' ) keywordActionIndetSingularNounPhrase->np_
	: IndefiniteNounProd
;

grammar keywordActionQualifiedSingularNounPhrase(arbitrary)
	: ( 'any' | 'one' | '1' | 'any' ( 'one' | '1' ) )
		keywordActionIndetSingularNounPhrase->np_
	: ArbitraryNounProd
;

grammar qualifiedSingularNounPhrase(possessive):
    possessiveAdjPhrase->poss_ indetSingularNounPhrase->np_
    : PossessiveNounProd
;

grammar qualifiedSingularNounPhrase(anyPlural):
    'any' 'of' explicitDetPluralNounPhrase->np_
    : ArbitraryNounProd
;

grammar qualifiedSingularNounPhrase(theOneIn):
    'the' 'one' ('that' ('is' | 'was') | 'that' tokApostropheS | )
    ('in' | 'inside' | 'inside' 'of' | 'on' | 'from')
    completeNounPhraseWithoutAll->cont_
    : VagueContainerDefiniteNounPhraseProd

    mainPhraseText = 'one'
;

grammar keywordActionCompleteNounPhraseWithoutAll(it)
	: 'it'
	: ItProd
;
grammar keywordActionCompleteNounPhraseWithoutAll(them)
	: 'them'
	: ThemProd
;
grammar keywordActionCompleteNounPhraseWithoutAll(him)
	: 'him'
	: HimProd
;
grammar keywordActionCompleteNounPhraseWithoutAll(her)
	: 'her'
	: HerProd
;

grammar keywordActionCompleteNounPhraseWithoutAll(yourself)
	: 'yourself' | 'yourselves' | 'you'
	: YouProd
;

grammar keywordActionCompleteNounPhraseWithoutAll(itself)
	: 'itself'
	: ItselfProd
	checkAgreement(lst) {
		return(((lst.length() == 1) && lst[1].obj_.canMatchIt));
	}
;

grammar keywordActionCompleteNounPhraseWithoutAll(themselves)
	: 'themself' | 'themselves'
	: ThemselvesProd
	checkAgreement(lst) {
		return(true);
	}
;

grammar keywordActionCompleteNounPhraseWithoutAll(himself)
	: 'himself'
	: HimselfProd
	checkAgreement(lst) {
		return(((lst.length() == 1) && lst[1].obj_.canMatchHim));
	}
;

grammar keywordActionCompleteNounPhraseWithoutAll(herself)
	: 'herself'
	: HerselfProd
	checkAgreement(lst) {
		return(((lst.length() == 1) && lst[1].obj_.canMatchHer));
	}
;

grammar keywordActionCompleteNounPhraseWithoutAll(me)
	: 'me' | 'myself'
	: MeProd
;

grammar keywordActionCompleteNounPhraseWithAll(main)
	: 'all' | 'everything'
	: EverythingProd
;
