#charset "us-ascii"
//
// regression.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Simple regression test for use with the regressionTest module.
//
// It can be compiled via the included makefile with
//
//	# t3make -f regression.t3m
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

// This isn't actually needed and is only here to demonstrate that the
// regression testing logic will work in parallel with an existing game world.
startRoom: Room 'Void' "This is a featureless void. ";
+me: Person;

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;
