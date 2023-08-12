#charset "us-ascii"
//
// noActions.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Simple test case for a game containing compiled with the keywordAction
// module, but not defining any keyword actions.
//
// The grammar rules in keywordActionProd.t add a sample keywordActionPredicate
// specifically to prevent the compiler from complaining about there being
// no alternatives defined, so this is a test case to verify that that works.
//
// It can be compiled via the included makefile with
//
//	# t3make -f noActions.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

// Nothing interesting about the game world, all we care about is whether
// or not we throw an error during compilation.
startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;
+pebble: Thing 'small round pebble' 'pebble' "A small, round pebble. ";

versionInfo:    GameID;
gameMain: GameMainDef initialPlayerChar = me;
