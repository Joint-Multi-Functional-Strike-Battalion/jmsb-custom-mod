#include "script_component.hpp"
/*
 * Author: YonV
 * The default status-row providers: a hashmap of icon -> code, each
 * answering [icon word, short value, state] for its cell. Stored as
 * GVAR(overlayProviders) at preInit, so another addon can `set` its own over
 * one of these, or add one and put its icon in GVAR(overlayOrder).
 *
 * THE OLD TOP BAR, BACK (user, 2026-10-21: "more like your old top bar on the
 * phone and side devices", "just no net number it did not make sense, net %
 * maybe"):
 * - NET: how much of game voice's ten custom channels is still FREE, as a
 *   percent (jmfsb_voice_fnc_channelUse; user: "reverse the % to available so
 *   it should read 70%") - amber at CHANNEL_WARN_PCT or less, red at none;
 *   dim when nothing is counted (voice unavailable).
 * - MESH: hops to the nearest relay on RF's data net ("2H"), "DIR" when only
 *   direct peers are in reach, red "--" with no path at all. From the RF
 *   client slice via FUNC(overlayRf), cached in GVAR(overlayRf).
 * - JAM: the jamming addon's shared calculator, any domain, as a percent.
 * - GPS: the grid you are in (FUNC(overlayGrid): 8 or 10 figures by Device
 *   grid digits) - red NO FIX when denied, amber when SUSPECT.
 * - DRONES: the hostile-drone scanner's state as the DRONES tile words it -
 *   CLR / WARN / ALERT (user, 2026-11-01; it was "mine+level", read as a count).
 * - MSG: unread messages in the messaging index, red above none.
 * FIRES and BATT are gone (2026-10-21): placeholders that only said --.
 *
 * Every reach into another addon is guarded, because none of them is
 * required - a mission without jamming gets a dim JAM cell, not an error.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Providers, icon -> code <HASHMAP>
 *
 * Example:
 * jmfsb_devices_overlayProviders = [] call jmfsb_devices_fnc_overlayProviders
 *
 * Public: No
 */

createHashMapFromArray [
    ["NET", {
        if (isNil QEFUNC(voice,channelUse)) exitWith {["NET", "--", STATE_OFF]};
        ([] call EFUNC(voice,channelUse)) params [["_used", -1, [0]], ["_of", 0, [0]]];
        if (_used < 0 || _of <= 0) exitWith {["NET", "--", STATE_OFF]};
        private _pct = round ((_of - _used) / _of * PERCENT) max 0;
        private _state = switch (true) do {
            case (_used >= _of): {STATE_ALERT};
            case (_pct <= CHANNEL_WARN_PCT): {STATE_WARN};
            default {STATE_OK};
        };
        ["NET", format ["%1%2", _pct, "%"], _state]
    }],

    ["MESH", {
        private _rf = missionNamespace getVariable [QGVAR(overlayRf), createHashMap];
        if (!(_rf getOrDefault ["ready", false]) || {(_rf getOrDefault ["nodes", []]) isEqualTo []}) exitWith {
            ["MESH", "--", STATE_OFF]
        };
        private _hops = _rf getOrDefault ["relayHops", -1];
        if (_hops > 0) exitWith {["MESH", format ["%1H", _hops], STATE_OK]};
        if ((_rf getOrDefault ["meshReach", 0]) > 0) exitWith {["MESH", "DIR", STATE_OK]};
        ["MESH", "--", STATE_ALERT]
    }],

    ["JAM", {
        if (isNil QEFUNC(jamming,jamFactor)) exitWith {["JAM", "--", STATE_OFF]};
        private _jam = ([getPosASL (call CBA_fnc_currentUnit), 0, JAM_DOMAIN_ANY] call EFUNC(jamming,jamFactor)) param [0, 0];
        private _pct = round (_jam * PERCENT);
        if (_pct <= 0) exitWith {["JAM", "0%", STATE_OK]};
        ["JAM", format ["%1%2", _pct, "%"], [STATE_WARN, STATE_ALERT] select (_pct >= JAM_ALERT_PCT)]
    }],

    ["GPS", {
        ([] call FUNC(overlayGrid)) params ["_grid", "_gps"];
        private _state = switch (_gps) do {
            case GPS_STATE_NOFIX: {STATE_ALERT};
            case GPS_STATE_SUSPECT: {STATE_WARN};
            default {STATE_OK};
        };
        ["GPS", _grid, _state]
    }],

    ["DRONES", {
        // THE HOSTILE-DRONE STATE, AS A WORD (user, 2026-11-01): the scanner
        // answers a level - 0 clear, 1 warn, 2 alert - not a count, and
        // "0+2" read as two drones. The cell now reads as the DRONES tile.
        private _sweep = if (isNil QEFUNC(hud,sweep)) then {[]} else {[] call EFUNC(hud,sweep)};
        private _level = _sweep param [0, 0];
        if !(_level isEqualType 0) then {_level = 0};
        _level = (round _level) max 0 min (count DRONE_STATE_WORDS - 1);
        ["DRONES", DRONE_STATE_WORDS select _level, [STATE_OK, STATE_WARN, STATE_ALERT] select _level]
    }],

    ["BATT", {
        // The player's own sets, as RF's server last told him; the lowest.
        private _sets = ((call CBA_fnc_currentUnit) getVariable [QEGVAR(rf,batteries), []]) select {(_x param [1, -1]) >= 0};
        if (_sets isEqualTo []) exitWith {[BATT_ICON, "--", STATE_OFF]};
        private _low = selectMin (_sets apply {_x select 1});
        private _state = switch (true) do {
            case (_low <= BATT_ALERT_K): {STATE_ALERT};
            case (_low <= BATT_WARN_K): {STATE_WARN};
            default {STATE_OK};
        };
        [BATT_ICON, format ["%1%2", round (_low * PERCENT), "%"], _state]
    }],

    ["MSG", {
        private _unread = 0;
        {
            if (_x isEqualType createHashMap) then {
                private _n = _x getOrDefault ["unread", 0];
                if (_n isEqualType 0) then {_unread = _unread + _n};
            };
        } forEach (missionNamespace getVariable [QEGVAR(messaging,index), []]);
        ["MSG", str _unread, [STATE_OK, STATE_ALERT] select (_unread > 0)]
    }]
]
