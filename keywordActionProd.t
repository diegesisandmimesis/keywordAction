#charset "us-ascii"
//
// keywordActionProd.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

class FirstKeywordActionProd: FirstCommandProd;
class KeywordActionProd: CommandProd;
class KeywordActionProdWithDefiniteConj: CommandProdWithDefiniteConj;
class KeywordActionProdWithAmbiguousConj: CommandProdWithAmbiguousConj;

class SingleKeywordProd: SingleNounProd;

#ifndef KEYWORD_ACTION_NEW_GRAMMAR

replace grammar commandPhrase(definiteConj)
	: predicate->cmd_
		| predicate->cmd_ commandOnlyConjunction->conj_ *
		| keywordActionPredicate->cmd_
		| keywordActionPredicate->cmd_ commandOnlyConjunction->conj_ *
	: CommandProdWithDefiniteConj
;

#else // KEYWORD_ACTION_NEW_GRAMMAR

grammar keywordActionPhrase(definiteConj)
	: keywordActionPredicate->cmd_
		| keywordActionPredicate->cmd_ commandOnlyConjunction->conj_ *
	: KeywordActionProdWithDefiniteConj
;

grammar keywordActionPhrase(ambiguousConj)
	: keywordActionPredicate->cmd1_
		commandOrNounConjunction->conj_ keywordActionPhrase->cmd2_
	: KeywordActionProdWithAmbiguousConj
;

grammar firstKeywordActionPhrase(commandOnly)
	: keywordActionPhrase->cmd_
	: FirstKeywordActionProd
;

#endif // KEYWORD_ACTION_NEW_GRAMMAR
