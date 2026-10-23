#include "script_component.hpp"
/*
 * Author: JMSB
 * Asks the provider that owns an asset what a request WOULD do, before it is
 * sent - an ETA, a time of flight, "OUT OF RANGE" - the verdict Simplex shows
 * beside its confirm button. The provider's optional "preview" code, called
 * on the requesting machine every time TAC//SUPPORT redraws a request that
 * has its unit, task and point; it must be cheap and must not change
 * anything. A provider without one answers [] and the board shows no line.
 *
 * ok false is a verdict against the request: the board shows the line as
 * missing and holds CONFIRM until it changes.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Task token <STRING>
 * 2: The task point [x, y, 0] ATL, [] for none <ARRAY>
 * 3: The parameter array as CONFIRM would send it <ARRAY>
 *
 * Return Value:
 * [ok <BOOL>, line <STRING>], or [] when the provider has no preview <ARRAY>
 *
 * Example:
 * ["fires:0", "HE", _pos, _prm] call jmfsb_support_fnc_preview
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

if (_assetId isEqualTo "" || _task isEqualTo "") exitWith {[]};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "" || {!("preview" in _decl)}) exitWith {[]};

private _res = [_assetId, _task, _pos, _prm] call (_decl get "preview");
if (isNil "_res" || {!(_res isEqualType [])} || {_res isEqualTo []}) exitWith {[]};
_res params [["_ok", true, [true]], ["_line", "", [""]]];
if (_line isEqualTo "") exitWith {[]};

[_ok, _line]
