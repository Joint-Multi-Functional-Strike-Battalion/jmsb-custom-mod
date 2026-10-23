#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_jamming_fnc_jamFactor

Description:
    Jamming strength at a position, 0 (clear) to 1 (fully smothered). One shared
    calculator for every consumer - the RF noise source, the ACRE applier, the jamming HUD,
    the RDF scanner, UAV jamming. They can disagree about what to DO with the
    number, never about what the number is.

    STILL ZONE-BASED (2026-10-19). RF prices the same zones as noise through
    FUNC(rfNoise), which calls this, so a zone's reach is one shape in both.
    It knows the zones only: a noise source registered with RF directly (the
    Drone40 Jammer) is not in this number.

    Concept adapted from WaldosMissionPack (Adam Waldie, MIT) - one shared
    propagation function rather than each system rolling its own. Implementation
    is jmfsb-original and works off the jmfsb zone registry.

    Every model feature is off by default, so with no new attributes set this
    returns exactly what the old inline distance maths returned: 1 inside the
    core, a linear ramp to 0 at the falloff edge.

Parameters:
    _pos     : ARRAY  - position to evaluate, ASL.
    _powerMw : NUMBER - transmitter power in mW, for burn-through. 0 = ignore.
                        Optional, default 0.
    _domain  : STRING - which denial is being asked about (user, 2026-08-31):
                        DOM_RADIO (default) the voice net, DOM_DATA messaging
                        and BFT, DOM_GPS the GPS item and the map self-icon,
                        DOM_UAV drones, DOM_ANY "is anything jamming here".

                        A zone answers for a domain only if it carries it, so
                        the terminal that kills the net leaves TAC//MSG alone
                        and the hub that kills TAC//MSG leaves the net alone.
                        DOM_UAV is the odd one out and still reads the jamUavs
                        flag rather than the domain list: it is a property of
                        the emitter's power, not of what it was pointed at.

Returns:
    ARRAY - [_factor, _zone] where _zone is the strongest contributing registry
            entry, or [] when nothing reaches. Callers that only want the number
            use `select 0`.

Example:
    ([getPosASL player, 500] call jmfsb_jamming_fnc_jamFactor) select 0

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_pos", [0,0,0], [[]]], ["_powerMw", 0, [0]], ["_domain", DOM_RADIO, [""]]];

private _reg = missionNamespace getVariable [QGVAR(jammers), []];
if (_reg isEqualTo []) exitWith { [0, []] };

private _best = 0;
private _bestZone = [];

{
    private _obj = _x param [ZONE_OBJ, objNull];
    private _isTemp = _x param [ZONE_TEMP, false];

    // A real emitter must be alive; an abstract zone has nothing to kill.
    if (!_isTemp && {isNull _obj || {!alive _obj}}) then { continue };

    private _zpos = if (isNull _obj) then { _x param [ZONE_POS, [0,0,0]] } else { getPosASL _obj };
    private _rEff = _x param [ZONE_REFF, 0];
    private _rFall = _x param [ZONE_RFALL, 0];
    private _model = _x param [ZONE_MODEL, createHashMap];

    // --- does this zone answer for the domain being asked about? ------------
    // DOM_ANY skips the gate: the HUD tile and the EW scanner report that the
    // spectrum is dirty, not which service is down.
    if (_domain isEqualTo DOM_UAV) then {
        if (!(_model getOrDefault ["jamUavs", false])) then { continue };
    } else {
        if (_domain isNotEqualTo DOM_ANY
            && {!(_domain in (_model getOrDefault ["domains", DOM_DEFAULT]))}) then { continue };
    };

    private _d = _pos distance _zpos;
    if (_d > _rFall) then { continue };

    // --- base falloff: 1 in the core, ramping to 0 at the outer edge --------
    private _f = if (_d <= _rEff) then {
        1
    } else {
        private _p = (_d - _rEff) / ((_rFall - _rEff) max 1);
        if ((_model getOrDefault ["curve", "LINEAR"]) isEqualTo "INVSQ") then {
            (1 - _p) ^ 2
        } else {
            1 - _p
        };
    };

    // --- duty cycle: a pulsing jammer is only up part of the time ----------
    private _duty = _model getOrDefault ["duty", 100];
    if (_duty < 100) then {
        // Deterministic from the zone id and the clock, so every client that
        // asks at the same moment gets the same answer.
        private _phase = ((round CBA_missionTime) + (count (_x param [ZONE_ID, ""]))) % 10;
        if (_phase >= (_duty / 10)) then { _f = 0 };
    };

    // --- directional cone ---------------------------------------------------
    private _from = _model getOrDefault ["coneFrom", -1];
    if (_f > 0 && _from >= 0) then {
        private _arc = _model getOrDefault ["coneArc", 360];
        private _bearing = [_zpos, _pos] call BIS_fnc_dirTo;
        private _delta = abs (((_bearing - _from + 180) % 360) - 180);
        if (_delta > (_arc / 2)) then { _f = 0 };
    };

    // --- terrain occlusion --------------------------------------------------
    if (_f > 0 && {_model getOrDefault ["los", false]}) then {
        if (!(terrainIntersectASL [_zpos, _pos])) then {} else { _f = 0 };
    };

    // --- burn-through: a stronger set punches deeper into the field ---------
    if (_f > 0 && _powerMw > 0 && {_model getOrDefault ["burnthrough", false]}) then {
        private _ref = (_model getOrDefault ["burnRef", 500]) max 1;
        _f = _f * ((_ref / (_powerMw max 1)) min 1);
    };

    if (_f > _best) then {
        _best = _f;
        _bestZone = _x;
    };
} forEach _reg;

[_best min 1, _bestZone]
