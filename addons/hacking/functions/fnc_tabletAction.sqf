#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_tabletAction

Description:
    START / ABORT. Starting validates the target the way the old ACE actions did
    - cooldowns for towers, range for everything - and refuses with a reason
    rather than silently doing nothing.

    Aborting throws the progress away deliberately. Closing the tablet is the way
    to pause; the button is the way to give up.

Author:
    JMSB
---------------------------------------------------------------------------- */
private _session = GVAR(session);

if (_session get "running") exitWith {
    private _device = _session get "device";
    _session set ["running", false];
    _session set ["progress", 0];
    if (!isNull _device) then { _device setVariable [QGVAR(progress), 0, true] };
    ["Hack", "Intrusion aborted.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

private _device = _session get "device";
if (isNull _device) exitWith {
    ["Hack", "No device selected.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

if !([_device, _session] call FUNC(tabletInRange)) exitWith {
    ["Hack", "Out of range of that device.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

private _kind = _session get "kind";

// NO GATE HERE. There was one - it refused to start when the product menu was
// empty, on the reasoning that a minute spent to be told "Nothing to report" is
// a minute wasted. It was the wrong trade: a button that refuses looks exactly
// like a button that is broken, and the bar sitting at 0% is indistinguishable
// from a hack that never ran. The hack runs; FUNC(serverPick) says honestly that
// there was nothing on the network.

// Towers hold a cooldown; -1 makes them one-shot. Guards at function scope:
// an exitWith inside a then-block leaves only the block, and the hack started
// anyway - the server now refuses that hack (review S7), so the refusal has to
// happen here, before the clock runs.
private _cd = [QGVAR(cfg_hack_cooldown)] call FUNC(hackSetting);
private _last = _device getVariable [QGVAR(lastHack), -1e9];
if (_kind isEqualTo "tower" && _cd < 0 && _last > -1e8) exitWith {
    ["Hack", "That tower is spent.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};
if (_kind isEqualTo "tower" && _cd >= 0 && {(CBA_missionTime - _last) < _cd}) exitWith {
    ["Hack", format ["Tower cooling down - %1s.", round (_cd - (CBA_missionTime - _last))], [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

// Each kind runs on its own clock.
_session set ["time", [_kind] call FUNC(hackDuration)];

// A pop's witnesses are the server's call, in FUNC(srvHackStart) (review S7).
_session set ["last", CBA_missionTime];
_session set ["running", true];

// THE SERVER STARTS ITS OWN CLOCK (review S7): a completion it never saw start,
// or one that comes sooner than the kind's clock allows, is refused there.
[_device, _kind] remoteExecCall [QFUNC(srvHackStart), SERVER_OWNER];

