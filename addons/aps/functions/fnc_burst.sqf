#include "script_component.hpp"
/*
 * Author: YonV
 * THE RF BURST (server, the one arbiter): one omnidirectional pulse off the
 * emitter. Guided munitions in the engagement sphere lose their guidance,
 * drones in it drop - own drones too, there is no IFF - and every radio in
 * the smaller jam sphere goes down for a moment, friend and foe, the
 * emitter's own crew for less. Then the emitter is cold for the cooldown,
 * which is the whole balance of the system.
 *
 * Effects on a thing happen where that thing is local (remoteExec to its
 * owner); the decision of what was hit is made here, once.
 *
 * Arguments:
 * 0: The emitting vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith {};

// public: the HUD's APS tile counts the cooldown down on the crew's screen
_veh setVariable [QGVAR(rfReady), CBA_missionTime + GVAR(rfCooldown), true];
private _pos = getPosASL _veh;
private _r = GVAR(rfRadius);
private _jr = GVAR(rfJamRadius) min _r;
private _hits = 0;

// ---- guided munitions: guidance stripped, the round flies on ballistically ----
{
    {
        private _kind = [_x] call FUNC(isGuided);
        if (_kind isNotEqualTo "" && {!(_x getVariable [QGVAR(deguided), false])}) then {
            private _p = [GVAR(rfProbATGM), GVAR(rfProbIR)] select (_kind isEqualTo "ir");
            if (random 1 < _p) then {
                _x setVariable [QGVAR(deguided), true];
                [_x] remoteExec [QFUNC(deguide), _x];
                _hits = _hits + 1;
            };
        };
    } forEach (_veh nearObjects [_x, _r]);
} forEach ["MissileCore", "RocketCore"];

// ---- drones: engine, fuel and AI gone, whoever they belong to -----------------
{
    if (_x != _veh && {getNumber (configOf _x >> "isUav") > 0} && {alive _x}
            && {!(_x getVariable [QGVAR(disabled), false])}) then {
        private _cls = toLower typeOf _x;
        private _loiter = ["switchblade", "crocus", "ied", "kamikaze", "fpv"] findIf { _x in _cls } > -1;
        private _p = [GVAR(rfProbDrone), GVAR(rfProbLoiter)] select _loiter;
        if (random 1 < _p) then {
            _x setVariable [QGVAR(disabled), true, true];
            [_x] remoteExec [QFUNC(disableDrone), _x];
            _hits = _hits + 1;
        };
    };
} forEach (_veh nearEntities [["Air"], _r]);

// ---- the jam: every player in the near field, the crew for less ---------------
private _crew = crew _veh;
private _id = format ["%1@%2", netId _veh, round (CBA_missionTime * 10)];
{
    if ((getPosASL _x) distance _pos <= _jr) then {
        private _dur = [GVAR(rfJamDismount), GVAR(rfJamCrew)] select (_x in _crew || {vehicle _x == _veh});
        if (_dur > 0) then { [_id, _dur] remoteExec [QFUNC(jamRegister), _x] };
    };
} forEach allPlayers;

// ---- sensors and datalink off for the same moment, on every vehicle in the field ----
{
    if (_x != _veh && {alive _x}) then {
        [_x, GVAR(rfJamDismount)] remoteExec [QFUNC(blackout), _x];
    };
} forEach (_veh nearEntities [["LandVehicle", "Air", "Ship"], _jr]);

// ---- the cues ---------------------------------------------------------------
createVehicle [QGVAR(pulse), (getPosATL _veh) vectorAdd [0, 0, 2.5], [], 0, "CAN_COLLIDE"];
[_veh, -1, "RF BURST"] remoteExec [QFUNC(report), [0, -2] select isDedicatedServer];
["APS", "RF burst - radios and sensors jammed nearby", ASLToAGL _pos, _jr, 1, 30] call EFUNC(common,alert);

if (GVAR(debug)) then {
    INFO_3("%1 RF burst: %2 hit(s), jam radius %3",typeOf _veh,_hits,_jr);
    private _m = createMarker [format ["%1_rf_%2", QUOTE(ADDON), _id], ASLToAGL _pos];
    _m setMarkerShapeLocal "ELLIPSE";
    _m setMarkerSizeLocal [_r, _r];
    _m setMarkerColorLocal "ColorOrange";
    _m setMarkerBrush "Border";
    [{ deleteMarker (_this select 0) }, [_m], 6] call CBA_fnc_waitAndExecute;
};
