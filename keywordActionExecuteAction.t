#charset "us-ascii"
//
// keywordActionExecuteAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "keywordAction.h"

replace executeAction(dstActor, dstActorPhrase, srcActor,
	countsAsIssuerTurn, action) {
	keywordActionExecuteAction.execAction(dstActor, dstActorPhrase,
		srcActor, countsAsIssuerTurn, action);
}


keywordActionExecuteAction: KeywordActionObject
	execAction(dst, dstPhrase, src, isTurn, action) {
		local rm, results;

	startOver:

		rm = GlobalRemapping.findGlobalRemapping(src, dst, action);
		dst = rm[1];
		action = rm[2];
		results = new BasicResolveResults();
		results.setActors(dst, src);

		try {
			action.resolveNouns(src, dst, results);
		}
		catch(RemapActionSignal sig) {
			sig.action_.setRemapped(action);
			action = sig.action_;
			goto startOver;
		}

		if(action.includeInUndo && action.parentAction == nil && (dst.isPlayerChar() || (src.isPlayerChar() && isTurn))) {
			libGlobal.lastCommandForUndo = action.getOrigText();
			libGlobal.lastActorForUndo = (dstPhrase == nil ? nil : dstPhrase.getOrigText());
			savepoint();
		}

		if(isTurn && !action.isConversational(src)) {
			src.lastInterlocutor = dst;
			src.addBusyTime(nil, src.orderingTime(dst));
			dst.nonIdleTurn();
		}
		if(src != dst && !action.isConversational(src) && !dst.obeyCommand(src, action)) {
			if(src.orderingTime(dst) == 0)
			src.addBusyTime(nil, 1);
			action.saveActionForAgain(src, isTurn, dst, dstPhrase);
			throw new TerminateCommandException();
		}

		action.doAction(src, dst, dstPhrase, isTurn);
	}
;
