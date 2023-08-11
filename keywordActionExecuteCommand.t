#charset "us-ascii"
//
// keywordActionExecuteCommand.t
//

modify modularExecuteCommand
	firstPhrase = firstKeywordActionPhrase
	otherPhrase = keywordActionPhrase

	getCommandList() {
		local lst;

		lst = callParseTokens();
		if(lst.length() == 0) {
			_debug('no keyword action match');
			throw new KeywordActionException(&commandNotUnderstood);
		}

		return(lst);
	}

	runCommand(action) {
		if(action.keywordActionFailed == true) {
			_debug('keyword action failed');
			throw new KeywordActionException(&commandNotUnderstood);
		}
		inherited(action);
	}
;
