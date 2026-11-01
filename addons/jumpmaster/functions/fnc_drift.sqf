#include "script_component.hpp"
/*
 * Author: JMSB
 * How far the wind carries a jumper from where he leaves the aircraft to
 * where he lands (user, 2026-10-30: "read the wind and the altitude, draw
 * where the stick lands"). The engine moves a canopy with the wind and a
 * free-falling man not at all, so the drift is the wind's vector for the
 * seconds spent under canopy: from the pull altitude on a HALO, from the
 * aircraft on a HAHO, and from the static line's altitude. CANOPY_SINK_MS
 * is the engine's canopy, near enough; the wind-drift setting scales the
 * answer, and 0 turns it off.
 *
 * Arguments:
 * 0: Jump type, "HALO" / "HAHO" / "STATIC" <STRING>
 *
 * Return Value:
 * 0: Drift east, m <NUMBER>
 * 1: Drift north, m <NUMBER>
 * 2: Seconds under canopy <NUMBER>
 *
 * Example:
 * (["HALO"] call jmfsb_jumpmaster_fnc_drift) params ["_dx", "_dy", "_canopyS"]
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]]];

private _canopyAlt = switch (_type) do {
    case TYPE_HALO: {GVAR(haloOpenAltitude) min GVAR(haloAltitude)};
    case TYPE_HAHO: {GVAR(haloAltitude)};
    default {GVAR(staticAltitude)};
};
private _seconds = _canopyAlt / CANOPY_SINK_MS;
private _wind = wind;

[(_wind select 0) * _seconds * GVAR(windFactor), (_wind select 1) * _seconds * GVAR(windFactor), _seconds]
