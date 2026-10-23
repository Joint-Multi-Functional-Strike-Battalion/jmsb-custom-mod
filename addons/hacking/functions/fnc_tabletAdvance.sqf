#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_tabletAdvance

Description:
    Moves a running hack on, and rescans for devices on a slower cadence. The
    whole of what the tablet DOES between frames, with nothing about how it is
    drawn.

    It lived inside FUNC(tabletTick), which removes itself the moment the
    suite's own dialog closes - so a second front end for the same suite could
    not advance a hack without re-implementing it, and two implementations of a
    progress bar is two answers to how far along you are. FUNC(tabletTick) and
    the tacpad's intrusion app both call this and then draw whatever they draw.

Parameters:
    None

Returns:
    Nothing

Author:
    JMSB
---------------------------------------------------------------------------- */

private _session = GVAR(session);
if (isNil "_session") exitWith {};

private _now = CBA_missionTime;

// --- advance a running hack ------------------------------------------------
if (_session getOrDefault ["running", false]) then {
    private _device = _session getOrDefault ["device", objNull];

    // getOrDefault, not get, ON EVERY FIELD. A session missing "last" or "time"
    // - one built by an older build, one restored, one this addon did not create
    // - made this arithmetic answer nil, and a nil progress is a bar that sits at
    // zero for ever while everything else on the screen looks correct.
    private _dt = _now - (_session getOrDefault ["last", _now]);
    private _duration = _session getOrDefault ["time", 60];
    if (!(_duration isEqualType 0)) then {_duration = 0};
    if (_duration <= 0) then {_duration = 60};

    _session set ["last", _now];

    if ([_device, _session] call FUNC(tabletInRange)) then {
        private _p = ((_session getOrDefault ["progress", 0]) + (_dt / _duration)) min 1;
        _session set ["progress", _p];
        if (!isNull _device) then { _device setVariable [QGVAR(progress), _p, true] };

        if (_p >= 1) then {
            _session set ["running", false];
            _session set ["progress", 0];
            if (!isNull _device) then { _device setVariable [QGVAR(progress), 0, true] };
            [_device, _session get "kind", _session get "intel", _session getOrDefault ["action", HACK_ACTION_DEFAULT]] call FUNC(hackComplete);
        };
    };
};

// --- refresh the device list on a slower cadence ---------------------------
if ((_now - GVAR(lastScan)) >= TAB_REFRESH) then {
    GVAR(lastScan) = _now;
    GVAR(devices) = [player] call FUNC(scanDevices);

    // Selection survives a refresh as long as the device is still listed.
    private _sel = _session get "device";
    if (!isNull _sel && {(GVAR(devices) findIf { (_x select 0) isEqualTo _sel }) < 0}) then {
        if !(_session get "running") then {
            _session set ["device", objNull];
            _session set ["kind", ""];
        };
    };
};
