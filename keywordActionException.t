#charset "us-ascii"
//
// keywordActionException.t
//
//	Custom exception for keywordActionExec.
//
//	Probably doesn't deserve to be in its own source file, but we might
//	want to gussy it up later.
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

// A new exception class for keyword action parse failures.
class KeywordActionException: ParseFailureException;

// Our custom exception is a subclass of ParseFailureException, so
// we either have to worry about precedence of the modular exception
// handling (because KeywordActionException.ofKind(ParseFailureException)
// will return true) or we do what we do below:  just add our checks to
// the existing ParseFailureException handler.
modify mehParseFailure
	// We just check to see if we're a keyword action exception or
	// a "normal" parse failure.
	handle(ex) {
		if(ex.ofKind(KeywordActionException))
			return(_handleKeywordException(ex));
		else
			return(inherited(ex));
	}
	// If we're a keyword action exception, we handle it by just
	// passing the original arguments to the stock executeCommand().
	_handleKeywordException(ex) {
		local dst, f, src, t;

		_debug('==KeywordActionException==');
		dst = execState.dstActor;
		src = execState.srcActor;
		f = execState.first;
		t = execState.toks;
		clearExecState();
		executeCommand(dst, src, t, f);
		//exit;
		return(mehReturn);
	}
;

//keywordActionModularExceptionHandler:  ModularExceptionHandler
	//type = KeywordActionException
	//id = 'foo'
//;
