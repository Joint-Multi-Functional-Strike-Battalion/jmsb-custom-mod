#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "threadAnchor" (report-card review, user 2026-11-02, D33):
 * the point the thread being answered is anchored on - a BDA filed in a CAS
 * thread is about that thread's target; the SITREP sent after a TIC
 * (FUNC(sitrepAfterTic)) takes the TIC's grid from here. SALUTE was kept as
 * it was (2026-11-02) and fills nothing from it. Read off this machine's own
 * index row (EFUNC(messaging,cltIndex)).
 *
 * Arguments:
 * 0: The thread being answered, "" for a new message <STRING>
 *
 * Return Value:
 * Position [x, y, 0], [] for none <ARRAY>
 *
 * Example:
 * ["T0004"] call jmfsb_tacpad_fnc_autoAnchor
 *
 * Public: No
 */

params [["_threadId", "", [""]]];

if (_threadId isEqualTo "") exitWith {[]};

private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _at = _rows findIf {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId};
if (_at < 0) exitWith {[]};

private _anchor = (_rows select _at) getOrDefault ["anchorPos", []];
if !(_anchor isEqualType []) exitWith {[]};

[_anchor] call EFUNC(messaging,fieldPos)
