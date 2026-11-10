#include "script_component.hpp"
/*
 * Author: YonV
 * SQUAD VIEW (design team_lead.squad_view): F4 while the watch is on shows the
 * whole squad on the device for the squad view time (player setting); F4
 * again hides it. One row per man: role, name, status colour, magazines -
 * NO SIGNAL for a man whose device is jammed or who carries none. Team leads
 * and ATLs only.
 *
 * Arguments:
 * 0: Mode - "toggle", or "text" for the panel's rows <STRING>
 *
 * Return Value:
 * For "text": the rows as structured text, "" while hidden; else whether it is shown <STRING or BOOL>
 *
 * Example:
 * ["toggle"] call jmfsb_watch_fnc_squadView
 *
 * Public: No
 */

params [["_mode", "toggle", [""]]];

if (_mode isEqualTo "toggle") exitWith {
    GVAR(squadUntil) = [CBA_missionTime + GVAR(squadViewSeconds), -1] select (CBA_missionTime < GVAR(squadUntil));
    CBA_missionTime < GVAR(squadUntil)
};

if (CBA_missionTime >= GVAR(squadUntil)) exitWith {""};
private _hex = {_this call BIS_fnc_colorRGBAtoHTML};
private _text = format ["<t color='%1'>SQUAD - %2</t>", COLOUR_INK call _hex, toUpper groupId group player];
{
    private _man = _x;
    ([_man] call FUNC(health)) params ["_word", "_colour"];
    private _role = if (isNil QEFUNC(tacpad,roleShort)) then {""} else {[_man] call EFUNC(tacpad,roleShort)};
    private _signal = [_man] call FUNC(hasSignal);
    private _mags = {_x in compatibleMagazines primaryWeapon _man} count magazines _man;
    _text = _text + format ["<br/><t color='%1'>%2  %3  %4</t>", _colour call _hex, _role, toUpper name _man,
        [format ["%1  MAGS %2", _word, _mags], "NO SIGNAL"] select !_signal];
} forEach (units group player);
_text
