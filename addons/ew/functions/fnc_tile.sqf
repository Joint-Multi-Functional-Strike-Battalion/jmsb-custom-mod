#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW tile, a provider for jmfsb_tacpad_apps' band (registered in
 * XEH_preInit, like the MEDIC tile): the side's tracks, how many are fixed,
 * and the newest threat. Alert for a DF ON YOU in the last minute, warn for
 * any threat in the last few, rest otherwise; stale until the first slice.
 * A man with no set, no receiver and no jammer gets no tile: he has no ES and
 * no EA.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_ew_fnc_tile
 *
 * Public: No
 */

#define ALERT_S 60

if (GVAR(mine) isEqualTo []) exitWith {
    [[APP_ID, "EW", "NO DATA", "-", "WAITING FOR THE SERVER", "stale"]]
};

GVAR(mine) params ["", "_tracks", "_nodes", "", "_kit", "_jam", "", "_threats"];
_kit params ["_receiver", "_hasJammer"];
if (_nodes isEqualTo [] && {!_receiver} && {!_hasJammer}) exitWith {[]};

private _fixes = {(_x select 5) isNotEqualTo []} count _tracks;
private _now = CBA_missionTime;
private _recent = _threats select {(_now - (_x select 0)) <= THREAT_SHOW_S};
private _newest = _recent param [count _recent - 1, []];
private _state = switch (true) do {
    case ((_recent findIf {(_x select 1) isEqualTo THREAT_DF && {(_now - (_x select 0)) <= ALERT_S}}) >= 0): {"alert"};
    case (_recent isNotEqualTo []): {"warn"};
    default {"rest"};
};
private _detail = if (_newest isEqualTo []) then {
    format ["JAMMER %1", ["OFF", "ON AIR"] select (_jam param [10, false])]
} else {
    format ["%1 - %2", _newest select 1, _newest select 2]
};

[[APP_ID, "EW", format ["%1 FIX", _fixes], str count _tracks, _detail, _state]]
