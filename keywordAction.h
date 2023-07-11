//
// keywordAction.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_KEYWORD_ACTION

#define DefineKeywordAction(name, cls) \
	DefineTActionSub(name, KeywordAction); \
	VerbRule(name) singleDobj: name##Action \
	verbPhrase = 'act/acting (what)' \
	keywordActionClass = cls

// Don't comment out, used for dependency checking.
#ifndef KEYWORD_ACTION_H
#define KEYWORD_ACTION_H
#endif // KEYWORD_ACTION_H
