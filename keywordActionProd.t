#charset "us-ascii"
//
// keywordActionProd.t
//
//	New grammatical productions for the keywordAction stuff.
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

// These are probably superfluous;  as written, we could just use
// the base classes instead of rolling our own.  But this way if we
// need to tweak methods on one of the production types, we can just
// modify the class instead of having to fiddle around with the ones
// used elsewhere in adv3.
class FirstKeywordActionProd: FirstCommandProd;
class KeywordActionProd: CommandProd;
class KeywordActionProdWithDefiniteConj: CommandProdWithDefiniteConj;
class KeywordActionProdWithAmbiguousConj: CommandProdWithAmbiguousConj;

class SingleKeywordProd: SingleNounProd;

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
