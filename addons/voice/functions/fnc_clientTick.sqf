#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every CLIENT_TICK_S: the PAC plan re-read, the player's sets into
 * RF, his nets, the active net kept valid, the mesh onto the voice (fnc_updateQuality) and
 * radio silence under EMCON 3 (one of the cut-offs of fnc_applyBlock).
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_voice_fnc_clientTick
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player) exitWith {};

[] call FUNC(planRefresh);
[] call FUNC(fill);

private _before = GVAR(myNets);
GVAR(myNets) = [player] call FUNC(nets);
if (_before isNotEqualTo GVAR(myNets)) then {[QGVAR(netsChanged), []] call CBA_fnc_localEvent};
[] call FUNC(checkActive);

[] call FUNC(updateQuality);

private _emcon = (GVAR(rosterIndex) getOrDefault [getPlayerUID player, [objNull, "", [], 0]]) select 3;
// radio silence: one of the cut-offs, applied with the others (fnc_applyBlock)
GVAR(blocked) = _emcon >= EMCON_SILENT;
[] call FUNC(applyBlock);
