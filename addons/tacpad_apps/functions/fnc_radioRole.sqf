#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player's place in the voice permission table (DESIGN_VOICE.md,
 * MANAGE): "ADMIN", "RTO", "SL", "TL", or "" for everyone else. RADIO_ROLES is
 * the order; an action is open to a role at or above the one RADIO_RIGHTS names.
 *
 * WHAT PLACES HIM, highest first: the jmfsb admin flag (jmfsb_common sets it on
 * #login); the RTO job, by the one RTO test (jmfsb_voice_fnc_isRto - the RTO
 * console is a player job, not admins only: user, 2026-10-20); the leader
 * words of his slot's role (RADIO_ROLE_WORDS, read through
 * jmfsb_tacpad_fnc_roleShort); and leading his group, which makes him at least
 * a team leader. Without the voice addon nobody is placed as RTO.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Role, one of RADIO_ROLES <STRING>
 *
 * Example:
 * private _role = [] call jmfsb_tacpad_apps_fnc_radioRole
 *
 * Public: No
 */

private _unit = call CBA_fnc_currentUnit;
if (isNull _unit) exitWith {""};
if (_unit getVariable [QEGVAR(common,isAdmin), false]) exitWith {"ADMIN"};

if (!isNil QEFUNC(voice,isRto) && {[_unit] call EFUNC(voice,isRto)}) exitWith {"RTO"};

private _described = toUpper ([_unit] call EFUNC(tacpad,roleShort));
private _words = _described splitString " -_/.,()";

private _role = "";
{
    _x params ["_rank", "_tokens"];
    private _hit = (_tokens findIf {
        [_x in _words, (_described find _x) >= 0] select (" " in _x)
    }) >= 0;
    if (_hit) exitWith {_role = _rank};
} forEach RADIO_ROLE_WORDS;

if (_role isEqualTo "" && leader group _unit isEqualTo _unit) then {_role = "TL"};

_role
