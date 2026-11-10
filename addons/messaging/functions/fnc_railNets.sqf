#include "script_component.hpp"
/*
 * Author: YonV
 * The nets one man may see on a rail, in the order they are drawn.
 *
 * THE RAIL WAS SHOWING EVERY SQUAD IN THE TASK FORCE (user, 2026-09-03, having
 * asked repeatedly: "there is a nets section in the config this is not that
 * this is every fucking thing"). Fifteen squad nets he cannot read, on a
 * fifteen-row rail, above the three or four he can.
 *
 * TWO THINGS WERE WRONG, and both were in the drawing rather than in the
 * permission - FUNC(srvBoxesFor) has always been right, which is why the header
 * said 1 NETS while the rail listed thirty:
 *
 *   1. Every declared squad's net was appended, for everybody. That was once
 *      the ask and is not any more: a man sees HIS OWN squad and no other.
 *   2. The named nets came off GVAR(namedBoxes) - the ADDON SETTING - so the
 *      mission's own JMFSBFR_Nets was ignored on the client and the role gate
 *      was never applied. That is how a rail could show MEDICAL.mist to a role
 *      that does not carry it, and miss the four arm nets that role does.
 *
 * ONE FUNCTION, THREE CALLERS. The reader rail, the tacpad panel's tab strip
 * and the compose target list each built this by hand, and the three had
 * already drifted. Same rule, same order, one place - which is the note
 * FUNC(netBox) opens with, for the same reason.
 *
 * NOT A PERMISSION CHECK. It answers what to DRAW. The server decides what a
 * man may read and what reaches him; if the two ever disagree, the server wins
 * and this is the bug.
 *
 * Arguments:
 * 0: The man <OBJECT> (optional, default player)
 *
 * Return Value:
 * Net names, named nets first, his own squad last <ARRAY>
 *
 * Example:
 * private _nets = [] call jmfsb_messaging_fnc_railNets
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

// THE SAME LIST THE SERVER OPENS MAILBOXES FOR - TAC//PAC's nets, the
// mission's JMFSBFR_Nets, or the setting, in that order - see FUNC(netNames).
private _out = [] call FUNC(netNames);

// HIS ROLE DECIDES WHICH OF THEM ARE HIS. Ungated missions - nobody declares
// nets[] on a role - keep the whole list, so a mission that never asked for
// role gating is not silently stripped. See FUNC(roleNets).
([_unit] call FUNC(roleNets)) params ["_gated", "_allowed"];
if (_gated) then {
    _out = _out select {_x in _allowed};
};

// AND HIS OWN SQUAD, WHICH IS NEVER GATED and never listed in a role's nets[]:
// he reads it because he is in it, not because a config granted it. Last,
// because it is the one row he can always find.
private _own = groupId (group _unit);
if (_own isNotEqualTo "") then {
    _out pushBackUnique _own;
};

_out
