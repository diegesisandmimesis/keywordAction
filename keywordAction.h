//
// keywordAction.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_KEYWORD_ACTION

#define DefineKeywordAction(name, cls, vrb, args...) \
	DefineTActionSub(name, KeywordAction); \
	VerbRule(name) [badness 999] singleDobj: name##Action \
	verbPhrase = toString(vrb) + '/' + toString(vrb) + 'ing' + ' (what)' \
	keywordActionID = toString(vrb) \
	keywordActionClass = cls

// Don't comment out, used for dependency checking.
#ifndef KEYWORD_ACTION_H
#define KEYWORD_ACTION_H
#endif // KEYWORD_ACTION_H
