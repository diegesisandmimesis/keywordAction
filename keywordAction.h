//
// keywordAction.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_KEYWORD_ACTION

#define DefineKeywordAction(name, cls) \
	DefineTActionSub(name, KeywordAction); \
	VerbRule(name) [badness 999] singleDobj: name##Action \
	verbPhrase = (toString(#@name).toLower() + '/' \
			+ toString(#@name).toLower() + 'ing (what)') \
	keywordActionID = toString(#@name).toLower() \
	keywordActionClass = cls

#define DefineKeywordActionSub(name, cls, sub) \
	class name##KeywordActionSub: ##sub, KeywordAction; \
	DefineTActionSub(name, name##KeywordActionSub); \
	VerbRule(name) [badness 999] singleDobj: name##Action \
	verbPhrase = (toString(#@name).toLower() + '/' \
			+ toString(#@name).toLower() + 'ing (what)') \
	keywordActionID = toString(#@name).toLower() \
	keywordActionClass = cls

// Don't comment out, used for dependency checking.
#ifndef KEYWORD_ACTION_H
#define KEYWORD_ACTION_H
#endif // KEYWORD_ACTION_H
