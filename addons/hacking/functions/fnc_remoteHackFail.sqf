#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_remoteHackFail

Description:
    Server end of a failed remote hack. Two independent rolls (D11):

    1. Alert - always: every enemy group with a unit inside the alert radius of
       the hacker learns exactly where the hacker is and goes to COMBAT.
    2. Jamming - jam_chance: a temporary zone centred on the HACKER's position,
       spawned through the electronic_war_zones public API so it jams, scans and
       expires exactly like a module zone. Silently skipped without ew-zones.

    Deliberately NO drone dispatch (D12) - that stays the price of hacking EW
    emitters, not people.

Parameters:
    _hacker : OBJECT - who failed.
    _pos    : ARRAY  - the hacker's position at failure time.

Author:
    JMSB
---------------------------------------------------------------------------- */
if (!isServer) exitWith {};

params ["_hacker", "_pos"];

if (isNull _hacker) exitWith {};

private _alertR = missionNamespace getVariable [QGVAR(rh_alert_radius), RH_ALERT_DEF];
private _mySide = side group _hacker;
private _alerted = 0;

{
    if ((side _x) getFriend _mySide >= 0.6) then { continue };
    if (side _x isEqualTo civilian) then { continue };
    if ((units _x findIf { alive _x && {(getPosASL _x) distance2D _pos <= _alertR} }) < 0) then { continue };

    _x reveal [_hacker, 4];
    _x setBehaviour "COMBAT";
    _alerted = _alerted + 1;
} forEach allGroups;

INFO_2("Hacking: remote hack failed by %1 - %2 groups alerted",name _hacker,_alerted);

// Roll 2, exactly as the header always promised and the hack.fail debug
// command tells testers to check for - the roll itself was never written.
// A temporary zone on the HACKER through the jamming public API, so it
// jams, scans and expires like a module zone. Silently skipped without
// the jamming addon.
private _jamChance = missionNamespace getVariable [QGVAR(rh_jam_chance), RH_JAM_CHANCE_DEF];
if (!isNil "jmfsb_jamming_fnc_spawnTempZone" && {random 100 < _jamChance}) then {
    private _r = (RH_JAM_MIN_DEF + random (RH_JAM_MAX_DEF - RH_JAM_MIN_DEF)) min RH_JAM_MAX_CAP;
    private _zone = [_pos, _r, RH_JAM_DURATION_DEF] call jmfsb_jamming_fnc_spawnTempZone;
    INFO_2("Hacking: failure jam zone '%1', %2 m",_zone,round _r);
};

// The one reaction path hears it too (new.md section 2).
// Called on the server, not raised as a CBA event (review R1).
if (!isNil QEFUNC(reaction,roll)) then {
    [_hacker, "hack"] call EFUNC(reaction,roll);
};
