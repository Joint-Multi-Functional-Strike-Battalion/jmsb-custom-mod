#include "script_component.hpp"
/*
 * Author: JMSB
 * A key-up on this client. Filtered here, locally, so only a DETECTABLE
 * transmission costs the server an event.
 *
 * SATCOM IS EXEMPT (new.md section 2), and the test is ACRE's own antenna
 * connection rather than a flag jmfsb keeps - a set talking to a satellite is
 * not radiating across the valley, and that is the point of carrying one.
 *
 * Power: ACRE knows the live channel's transmit power in milliwatts. Game
 * voice has no equivalent, so its nets beyond the squad - the only ones that
 * reach here - are treated as above any sane threshold, which is what they are.
 *
 * Arguments:
 * 0: Radio id or class <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_radio", "", [""]]];

// SATCOM: ACRE's own answer, asked of this radio. One condition, one
// exitWith at function scope - the old inner exitWith only left its own
// then-block, and the exemption never exempted anybody.
if (
    _radio isNotEqualTo ""
    && {!isNil "acre_sys_gsa_fnc_isAntennaConnected"}
    && {[_radio] call acre_sys_gsa_fnc_isAntennaConnected}
) exitWith {};

private _watts = 5;
if (_radio isNotEqualTo "" && {!isNil "acre_api_fnc_getRadioChannelData"}) then {
    private _data = [_radio] call acre_api_fnc_getRadioChannelData;
    if (_data isEqualType []) then {
        // ACRE's channel data carries power in mW; shapes differ by version,
        // so a number is looked for rather than an index assumed.
        private _mw = 0;
        { if (_x isEqualType 0) then {_mw = _mw max _x} } forEach _data;
        if (_mw > 0) then { _watts = _mw / REACT_MW_PER_WATT };
    };
};

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

[QGVAR(event), [player, _source]] call CBA_fnc_serverEvent;
