#charset "us-ascii"
//
// keywordActionException.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

// As written our custom exceptions are handled exactly as if they're
// standard ParseFailureExceptions, but we use a new exception class
// anyway, just to make it easier to modify.
class KeywordActionException: ParseFailureException;
