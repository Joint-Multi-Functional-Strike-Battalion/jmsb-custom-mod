#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a virtual barrage is coming down (jmfsb_common_fnc_fireBarrage's
 * event - the enemy's shells with no gun on the map: a major reaction, a QRF's
 * fires, a jammer's reply, a drone's spot, the counter-battery answer). The
 * radar reports ALL enemy shells (user, 2026-10-25: "no, all enemy shells"),
 * so this one is reported too, from a virtual battery.
 *
 * THE BATTERY IS KEPT. The first barrage in an area places one CB_SITE_MIN-
 * CB_SITE_MAX metres from where it lands, inside the map; every later barrage
 * of that side within CB_SITE_REACH of it comes from the same place, so a fix
 * is still true next time. One report per battery per cbRadarCooldown.
 *
 * Arguments:
 * 0: Where the barrage lands <ARRAY>
 *
 * Return Value:
 * Teams told <NUMBER>
 *
 * Example:
 * [_impact] call jmfsb_reaction_fnc_cbVirtual
 *
 * Public: No
 */

params [["_impact", [], [[]]]];

if (!isServer || {count _impact < 2} || {!GVAR(moduleUp)} || GVAR(cbRadar) <= 0) exitWith {0};

private _gside = call EFUNC(common,enemySide);
if (_gside isEqualTo sideUnknown) exitWith {0};

private _at = GVAR(cbSites) findIf {(_x # 0) isEqualTo _gside && {((_x # 1) distance2D _impact) <= CB_SITE_REACH}};
private _site = [];
if (_at >= 0) then {
    _site = (GVAR(cbSites) # _at) # 1;
} else {
    private _try = 0;
    while {_site isEqualTo [] && _try < CB_SITE_TRIES} do {
        private _p = _impact getPos [CB_SITE_MIN + random (CB_SITE_MAX - CB_SITE_MIN), random 360];
        if ((_p # 0) > CB_SITE_EDGE && {(_p # 1) > CB_SITE_EDGE} && {(_p # 0) < worldSize - CB_SITE_EDGE}
            && {(_p # 1) < worldSize - CB_SITE_EDGE} && {!surfaceIsWater _p}) then {_site = _p};
        _try = _try + 1;
    };
    if (_site isEqualTo []) exitWith {};
    GVAR(cbSites) pushBack [_gside, _site];
};
if (_site isEqualTo []) exitWith {0};

private _key = str _site;
if (CBA_missionTime < (GVAR(cbRadarLast) getOrDefault [_key, -1e9]) + GVAR(cbRadarCooldown)) exitWith {0};
GVAR(cbRadarLast) set [_key, CBA_missionTime];

[_site, _gside, CB_WHAT_DEFAULT] call FUNC(cbReport)
