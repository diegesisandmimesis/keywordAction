//
// keywordAction.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_KEYWORD_ACTION

// Dependency checking.
#include "modularExecuteCommand.h"
#ifndef MODULAR_EXECUTE_COMMAND_H
#error "This module requires the modularExecuteCommand module."
#error "https://github.com/diegesisandmimesis/modularExecuteCommand"
#error "It should be in the same parent directory as this module.  So if"
#error "keywordAction is in /home/user/tads/keywordAction, then"
#error "modularExecuteCommand should be in"
#error "/home/user/tads/modularExecuteCommand ."
#endif // MODULAR_EXECUTE_COMMAND_H

#define KeywordActionRule(tag) grammar keywordActionPredicate(tag):

#define DefineKeywordAction(name, cls) \
	DefineTActionSub(name, KeywordTAction); \
	KeywordActionRule(name) \
		singleDobj: name##Action \
		verbPhrase = (toString(#@name).toLower() + '/' \
			+ toString(#@name).toLower() + 'ing (what)') \
		keywordActionID = toString(#@name).toLower() \
		keywordActionClass = cls

#define DefineKeywordActionSub(name, cls, sub) \
	class name##KeywordActionSub: ##sub, KeywordTAction; \
	DefineTActionSub(name, name##KeywordActionSub); \
	KeywordActionRule(name) singleDobj: name##Action \
	verbPhrase = (toString(#@name).toLower() + '/' \
			+ toString(#@name).toLower() + 'ing (what)') \
	keywordActionID = toString(#@name).toLower() \
	keywordActionClass = cls

// Don't comment out, used for dependency checking.
#ifndef KEYWORD_ACTION_H
#define KEYWORD_ACTION_H
#endif // KEYWORD_ACTION_H
