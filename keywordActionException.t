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

// As written our custom exceptions are handled exactly as if they're
// standard ParseFailureExceptions, but we use a new exception class
// anyway, just to make it easier to modify.
class KeywordActionException: ParseFailureException;
