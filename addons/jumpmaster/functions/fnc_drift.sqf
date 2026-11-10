#include "script_component.hpp"
/*
 * Author: YonV
 * How far the wind carries a jumper from where he leaves the aircraft to
 * where he lands (user, 2026-10-30: "read the wind and the altitude, draw
 * where the stick lands"). The engine moves a canopy with the wind and a
 * free-falling man not at all, so the drift is the wind's vector for the
 * seconds spent under canopy: from the pull altitude on a HALO, from the
 * aircraft on a HAHO, and from the static line's altitude. CANOPY_SINK_MS
 * is the engine's canopy, near enough; the wind-drift setting scales the
 * answer, and 0 turns it off. The altitude is the run's, handed in: each jump
 * aircraft flies its own (2026-11-02, FUNC(typeAlt)).
 *
 * Arguments:
 * 0: Jump type, "HALO" / "HAHO" / "STATIC" <STRING>
 * 1: The run's altitude, m <NUMBER>
 *
 * Return Value:
 * 0: Drift east, m <NUMBER>
 * 1: Drift north, m <NUMBER>
 * 2: Seconds under canopy <NUMBER>
 *
 * Example:
 * (["HALO", 6000] call jmfsb_jumpmaster_fnc_drift) params ["_dx", "_dy", "_canopyS"]
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]], ["_alt", ALT_FREEFALL_DEFAULT, [0]]];

// A HALO stick pulls at the pull altitude; a HAHO and a static line open at
// the aircraft.
private _canopyAlt = [_alt, GVAR(haloOpenAltitude) min _alt] select (_type isEqualTo TYPE_HALO);
private _seconds = _canopyAlt / CANOPY_SINK_MS;
private _wind = wind;

[(_wind select 0) * _seconds * GVAR(windFactor), (_wind select 1) * _seconds * GVAR(windFactor), _seconds]
