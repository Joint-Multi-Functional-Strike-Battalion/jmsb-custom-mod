#include "script_component.hpp"
/*
 * Author: YonV
 * One placed jammer site: builds the emitter where the module stands and, if
 * asked, arms the artillery that answers anybody who loiters in its field.
 *
 * PLACED, NOT SPREAD. Sites used to be scattered over an ALiVE commander's
 * objective list by FUNC(spawnObjectiveJammers) - the mission maker chose how
 * many and never chose where, and Zeus could not put one down at all. This is
 * the same site builder, FUNC(spawnJammerSite), given a position by hand.
 *
 * IT WAITS FOR THE JAMMING MODULE. The radius bounds, the burn-through
 * reference and the GPS domain are that module's, and a site built before it
 * has read them would roll its reach from preInit defaults. Module functions
 * have no ordering guarantee between them, so a site placed in Eden alongside
 * the enable arms on the first frame that has one.
 *
 * NO JAMMING MODULE, NO SITE. Placing this alone is a mission that has asked
 * for an emitter without turning the system on; it says so rather than building
 * a mast that denies nothing.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// EDEN CHECKBOXES ARRIVE AS 0 AND 1, NOT false AND true - the same trap
// FUNC(moduleController) documents, and the same coercion.
private _bool = {
    params ["_v"];
    if (_v isEqualType 0) then { _v > 0 } else { _v isEqualTo true }
};

private _domain = toLower (_logic getVariable ["domain", DOM_RADIO]);
if !(_domain in [DOM_RADIO, DOM_DATA, DOM_GPS]) then {
    WARNING_1("Jammer Site: '%1' is not a spectrum - using radio",_domain);
    _domain = DOM_RADIO;
};

// THE ENEMY'S, WORKED OUT (D59): no Side box on the module any more - the
// site belongs to whoever is hostile to the players (EFUNC(common,enemySide)).
private _side = call EFUNC(common,enemySide);

private _pos = getPosATL _logic;

private _cfg = createHashMapFromArray [
    ["domain", _domain],
    ["side", _side],
    ["pos", _pos],
    ["radius", _logic getVariable ["radius", 0]],
    ["arty", [_logic getVariable ["artyReply", false]] call _bool],
    ["delay", (_logic getVariable ["artyDelay", 90]) max 5],
    ["rounds", (_logic getVariable ["artyRounds", 8]) max 1],
    ["scatter", (_logic getVariable ["artyScatter", 120]) max 10],
    ["cooldown", (_logic getVariable ["artyCooldown", 300]) max 30]
];

// ARMED ON THE FIRST FRAME THAT HAS AN ENABLE. A per-frame handler rather than
// a waitUntil, because a module function is not scheduled and cannot sleep.
[{
    params ["_args", "_handle"];
    _args params ["_cfg"];

    if (!GVAR(moduleUp)) exitWith {
        // Ten seconds is longer than any module ordering takes and shorter than
        // a player reaching the site. After it, this was placed without the
        // enable and never will arm.
        if (CBA_missionTime > 10) then {
            [_handle] call CBA_fnc_removePerFrameHandler;
            WARNING_1("Jammer Site at %1: no JMSB - Jamming module on the map, nothing built",mapGridPosition (_cfg get "pos"));
        };
    };

    [_handle] call CBA_fnc_removePerFrameHandler;

    // 0 means roll it, which is what the bounds on the Jamming module are for.
    private _radius = _cfg get "radius";
    if (_radius < 1) then {
        _radius = GVAR(smallRadius) + random ((GVAR(largeRadius) - GVAR(smallRadius)) max 0);
    };

    // GPS IS NOT A BIGGER MAST. It is an uplink on the ground AND a wandering
    // sphere overhead that the uplink steers - FUNC(spawnGpsUplink) builds both
    // and kills the sphere with the uplink. Its own radius here is the uplink's
    // local field, the last four hundred metres of the assault on it, and it is
    // the Jamming module's Uplink Radius rather than the rolled one: a sphere
    // tuned to 300 m would just be a fourth mast.
    private _zoneId = "";
    private _terminal = objNull;

    if ((_cfg get "domain") isEqualTo DOM_GPS) then {
        if (!GVAR(gpsEnable)) exitWith {
            WARNING_1("Jammer Site at %1: GPS Denial is off on the Jamming module - nothing built",mapGridPosition (_cfg get "pos"));
        };
        ([_cfg get "side", _cfg get "pos"] call FUNC(spawnGpsUplink))
            params ["_upId", "", "_upObj"];
        _zoneId = _upId;
        _terminal = _upObj;
        _radius = GVAR(gpsUplinkRadius);
    } else {
        ([_cfg get "side", _cfg get "pos", _cfg get "domain", _radius] call FUNC(spawnJammerSite))
            params ["_siteId", "_siteObj"];
        _zoneId = _siteId;
        _terminal = _siteObj;
    };

    if (_zoneId isEqualTo "") exitWith {
        WARNING_1("Jammer Site at %1: the site failed to build",mapGridPosition (_cfg get "pos"));
    };

    INFO_3("placed %1 jammer site up: %2m at %3",_cfg get "domain",round _radius,mapGridPosition (_cfg get "pos"));

    if (_cfg get "arty") then {
        _cfg set ["radius", _radius];
        [_terminal, _cfg] call FUNC(artyReply);
    };
}, 0, [_cfg]] call CBA_fnc_addPerFrameHandler;

nil
