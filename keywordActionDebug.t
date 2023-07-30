#charset "us-ascii"
//
// keywordActionDebug.t
//
#include <adv3.h>
#include <en_us.h>

#ifdef __DEBUG_KEYWORD_ACTION

#include <reflect.t>

modify KeywordActionObject
	_debug(msg?) {
		aioSay('\n<<(keywordActionID ? '<<keywordActionID>>: '
			: '')>><<msg>>\n ');
	}
	_debugList(lst) {
		local l;

		if(lst == nil) {
			_debug('_debugList():  nil list');
			return;
		}
		_debug('=====_debugList() start=====');
		_debug('lst.length = <<toString(lst.length)>>');

		lst.forEach(function(obj) {
			if(obj == nil) {
				_debug('object is nil');
				return;
			}
			_debug(reflectionServices.valToSymbol(obj));
			if((l = obj.getPropList()) == nil) {
				_debug('no properties');
				return;
			}
			l.forEach(function(o) {
				if(!obj.propDefined(o, PropDefAny))
					return;
				_debug('\t'
					+ reflectionServices.valToSymbol(o)
					+ ' = '
					+ reflectionServices.valToSymbol(
						obj.(o)));
			});
		});
		_debug('=====_debugList() end=====');
	}

	_debugObject(obj, lbl?) {
		_debug((lbl ? lbl : '')
			+ '<<reflectionServices.valToSymbol(obj)>>');
	}

	_debugObjectFull(obj) {
		local l;

		if(obj == nil) {
			_debug('nil object');
			return;
		}

		if((l = obj.getPropList()) == nil) {
			_debug('\t[no properties]\n ');
			return;
		}
		l.forEach(function(o) {
			if(!obj.propDefined(o, PropDefAny))
				return;
			_debug('\t' + reflectionServices.valToSymbol(o) + ' = '
				+ reflectionServices.valToSymbol(obj.(o)));
		});
	}
;

#endif // __DEBUG_KEYWORD_ACTION
