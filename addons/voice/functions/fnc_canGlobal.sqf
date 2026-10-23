#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a man may talk on the Global channel (the tablet's GLOBAL button,
 * FUNC(global)): a logged-in admin or the host, as before, and the men the
 * game-voice comm plan puts on a C2 net - the TLs, the ATLs and all of HHC
 * (user, 2026-10-21: "not is leader but atl tl's and all of hhc"). One list
 * decides both: the plan's c2 row in <unit>.radio vonNets, by squad, role or
 * skill (FUNC(c2Net), jmfsb_pac_fnc_netPlanUnit). With no game-voice plan
 * (the old tfarNets slots put everyone on a C2 net) it is admins only.
 *
 * Arguments:
 * 0: Unit <OBJECT> (default: player)
 *
 * Return Value:
 * May use Global <BOOL>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_canGlobal
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

if (isNull _unit) exitWith {false};
if (isServer || {(call BIS_fnc_admin) > 0}) exitWith {true};

// A game-voice plan's nets carry no slot; the tfarNets plan's always do.
private _von = (GVAR(plan) findIf {(_x param [3, 0]) isEqualTo PLAN_NO_SLOT}) >= 0;
_von && {([_unit] call FUNC(c2Net)) isNotEqualTo ""}
