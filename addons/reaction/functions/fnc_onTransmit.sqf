#include "script_component.hpp"
/*
 * Author: JMSB
 * A key-up on this client. Filtered here, locally, so only a DETECTABLE
 * transmission costs the server an event.
 *
 * Power: game voice has no per-set transmit power, so its nets beyond the
 * squad - the only ones that reach here - are treated as REACT_VOICE_WATTS,
 * above any sane threshold, which is what they are. The ACRE path (the set's
 * own power, the SATCOM antenna exemption) went with ACRE (DEC1, 2026-10-31).
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

private _watts = REACT_VOICE_WATTS;

// The threshold is a module attribute read on the SERVER and this filter
// runs on a CLIENT - unbroadcast it was nil here, and every key-up died on
// this line as a script error before its event left the machine. Hosted SP
// hid it, because there the client IS the server. The module
// publicVariables it now; the default covers a client that keys up first.
if (_watts < (missionNamespace getVariable [QGVAR(watts), 1])) exitWith {};

// BURN-THROUGH IS NOT AN ORDINARY KEY-UP (user, 2026-08-31). A set powerful
// enough to punch a hole in a jamming field is, by definition, radiating harder
// than everything around it from inside ground somebody is deliberately
// smothering - so it is not rolled for, it is answered. See FUNC(roll).
//
// TWO READS, NOT ONE. The bare field strength says "you are inside a jammer";
// the strength WITH this set's power says what your set did to it. Burn-through
// is the difference between them, so a low-powered set inside the same field
// raises an ordinary "radio" and only the man who reached for the big antenna
// pays for it. With the zone's burnthrough model off the two reads are equal
// and this never fires, which is the right answer for a mission that has not
// asked for the mechanic.
private _source = "radio";
if (!isNil "jmfsb_jamming_fnc_jamFactor") then {
    private _pos = getPosASL player;
    private _raw = ([_pos, 0, "radio"] call jmfsb_jamming_fnc_jamFactor) select 0;
    private _eff = ([_pos, _watts * REACT_MW_PER_WATT, "radio"] call jmfsb_jamming_fnc_jamFactor) select 0;
    if (_raw >= REACT_BURN_BAND && _eff < _raw) then { _source = "burnthrough" };
};

// By remoteExec, so the server knows who sent it (review R1).
[player, _source] remoteExecCall [QFUNC(report), SERVER_OWNER];
