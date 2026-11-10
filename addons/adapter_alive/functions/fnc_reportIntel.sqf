#include "script_component.hpp"
/*
 * Author: YonV
 * Hands a piece of jmfsb intel to the friendly commander's G2, so the
 * C2ISTAR tablet, the COP and ALiVE's own confidence decay show what the
 * players earned through a hack or a deposit - one picture, not two.
 *
 * G2 is per OPCOM (mil_intelligence fnc_G2.sqf, created at mil_opcom
 * fnc_OPCOM.sqf:400 and stored on the handler under "G2"); it exists only
 * when the side's C2ISTAR has displayIntel on. No G2, nothing happens - the
 * jmfsb circle is still drawn by its own renderer.
 *
 * WHAT IS REPORTED IS WHAT THE CIRCLE SAYS. The position handed over is the
 * circle's centre, fuzzed by the ladder, never the true position - the G2
 * learns exactly as much as the player did.
 *
 * Arguments:
 * 0: Side that earned the intel <SIDE>
 * 1: Side the target belongs to <SIDE>
 * 2: Target id <STRING> - a profileID where there is one, any stable id otherwise
 * 3: Reported position <ARRAY>
 * 4: Kind <STRING> - jmfsb's label ("artillery", "air defence", "camp", ...)
 *
 * Return Value:
 * Reported <BOOL>
 *
 * Example:
 * [west, east, _profileID, _centre, "artillery"] call jmfsb_adapter_alive_fnc_reportIntel
 *
 * Public: No
 */

params [
    ["_forSide", sideUnknown, [sideUnknown]],
    ["_targetSide", sideUnknown, [sideUnknown]],
    ["_id", "", [""]],
    ["_pos", [], [[]]],
    ["_kind", "", [""]]
];

if (!GVAR(ready) || {_forSide isEqualTo sideUnknown} || {_pos isEqualTo []}) exitWith {false};

private _inst = [];
private _targetFaction = "";
{
    _x params ["_cside", "", "_cf", "", "_ci"];
    if (_cside isEqualTo _forSide) then { _inst = _ci };
    if (_cside isEqualTo _targetSide) then { _targetFaction = _cf };
} forEach (call FUNC(commanders));
if (_inst isEqualTo []) exitWith {false};

// A hint carries no target side: file it against the first commander hostile
// to the side that earned it, which on any ground a commander holds is the
// one the hint was pointing at.
if (_targetSide isEqualTo sideUnknown) then {
    {
        _x params ["_cside", "", "_cf"];
        if (_cside getFriend _forSide < 0.6) exitWith { _targetSide = _cside; _targetFaction = _cf };
    } forEach (call FUNC(commanders));
};
if (_targetSide isEqualTo sideUnknown) exitWith {false};

private _g2 = [_inst, "G2"] call ALiVE_fnc_hashGet;
if (isNil "_g2" || {isNull _g2}) exitWith {false};

// ALiVE's type vocabulary (mil_c2istar cop fnc_COPHelpers.sqf:148-240).
private _groupType = switch (toLower _kind) do {
    case "artillery": {"art"};
    case "air defence": {"aa"};
    case "anti-ship battery";
    case "coastal battery": {"at"};
    case "coastal radar";
    // No electronic-warfare type exists in the COP vocabulary (art, aa, at,
    // air, armor, naval, recon, infantry, unknown), and a jammer mast is not
    // any of the others. "unknown" is the honest one - a structure the
    // commander can see is there and cannot classify.
    case "jamming";
    case "radar": {"unknown"};
    default {"infantry"};
};

[_g2, "createSpotrep", [
    toUpper str _targetSide, _targetFaction, _id, +_pos, _groupType, 1, 0, 0, 0
]] call ALiVE_fnc_G2;
true
