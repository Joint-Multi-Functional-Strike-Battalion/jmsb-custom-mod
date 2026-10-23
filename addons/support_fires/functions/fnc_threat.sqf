#include "script_component.hpp"
/*
 * Author: JMSB
 * Reports a scripted round to the air defence intercept (addons/adsite), so
 * its AD units can shoot it down - the same way they meet a fired one.
 *
 * WHY THIS IS NEEDED. adsite finds threats through the "fired" event of the
 * weapon that shot them. A cruise missile launched here is created, not
 * fired, so it would fly past every air defence site unseen. This hands adsite
 * exactly what its own FUNC(shot) would: the round under an id it can kill it
 * by, and a threat event with the shooter's side. The round is its own owner -
 * it is local to the server, which is where adsite then kills it.
 *
 * A no-op when adsite is not loaded, is switched off, has no AD unit on the
 * map, or has this round's family switched off.
 *
 * Arguments:
 * 0: The round <OBJECT>
 * 1: The side that fired it <SIDE>
 * 2: Where it is going, ASL, [] for a ballistic prediction <ARRAY>
 *
 * Return Value:
 * Reported <BOOL>
 *
 * Example:
 * [_missile, west, _targetASL] call jmfsb_support_fires_fnc_threat
 *
 * Public: No
 */

params [["_proj", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown]], ["_target", [], [[]]]];

if (!isServer || {isNull _proj}) exitWith {false};
if (isNil QEFUNC(adsite,family) || {isNil QEGVAR(adsite,owned)}) exitWith {false};
if !(missionNamespace getVariable [QEGVAR(adsite,enabled), false]) exitWith {false};
if !(missionNamespace getVariable [QEGVAR(adsite,armed), false]) exitWith {false};

private _info = [typeOf _proj] call EFUNC(adsite,family);
private _setting = ADS_FAMILY_SETTINGS param [_info param [0, 0], ""];
if (_setting isEqualTo "" || {!(missionNamespace getVariable [_setting, false])}) exitWith {false};

GVAR(nextThreat) = GVAR(nextThreat) + 1;
private _id = format ["%1:%2", QUOTE(ADDON), GVAR(nextThreat)];

EGVAR(adsite,owned) set [_id, _proj];
[QEGVAR(adsite,threat), [_id, _proj, getPosASL _proj, velocity _proj, _info, _target, _side]] call CBA_fnc_serverEvent;

true
