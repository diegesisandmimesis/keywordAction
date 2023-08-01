#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the keywordAction library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

//#include <gramprod.h>

#include "keywordAction.h"

versionInfo:    GameID;

modify Thing
	dobjFor(Foo) { verify() { illogical('You can\'t foo that. '); } }
	dobjFor(Bar) { verify() { illogical('You can\'t bar that. '); } }
;

class Pebble: Thing
	dobjFor(Foo) {
		verify() { nonObvious; }
		action() { "You foo <<theName>>.\n "; }
	}
;

class Rock: Thing
	dobjFor(Bar) {
		verify() { nonObvious; }
		action() { "You bar <<theName>>.\n "; }
	}
;

startRoom: Room 'Void'
        "This is a featureless void.  The other room is to the north. "
	north = otherRoom
;
+alice: Person 'Alice' 'Alice'
	"She looks like the first person you'd turn to in a problem. "
	isHer = true
	isProperName = true
;
++pebbleTopic: Topic 'pebble';
++AskTellTopic @pebbleTopic
	"<q>This space intentionally left blank,</q> Alice says. "
;
+pebble: Pebble 'small round pebble' 'pebble' "A small, round pebble. ";
+rock: Rock 'ordinary rock' 'rock' "An ordinary rock. ";
+stone: Thing 'nondescript stone' 'stone' "A nondescript stone. ";

otherRoom: Room 'Other Room'
	"This is the other room.  The void is to the south. "
	south = startRoom
;
+me: Person;
+redPebble: Pebble 'red pebble' 'red pebble' "A red pebble. ";
+bluePebble: Pebble 'blue pebble' 'blue pebble' "A blue pebble. ";

DefineKeywordAction(Foo, Pebble);
DefineKeywordAction(Bar, Rock);

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		//libGlobal.parserDebugMode = true;
		runGame(true);
	}
;
