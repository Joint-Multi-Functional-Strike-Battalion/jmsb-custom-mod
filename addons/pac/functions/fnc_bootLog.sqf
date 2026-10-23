#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_bootLog

Description:
    One line of the boot sequence, where it can be seen: the .rpt (which a
    dedicated server's console shows live), and on screen when the server
    is a hosted game or the editor. Every step of FUNC(boot) goes through
    here so the whole sequence reads top to bottom in one grep:

        [TAC//PAC BOOT 3/7] store: profile 12 player(s) -> file gfa_pac.ini read

    The lines are also kept in GVAR(bootLog) and published, so the admin
    page can show the last boot without the .rpt.

    THE .RPT LINE CARRIES THE CLOCK (2026-10-19): "(+12.34 s)", seconds since
    FUNC(boot) began, so the gap between two lines is what that step cost. A
    boot took four minutes and the log could not say where. The kept and
    published line has no clock - the boot screen shows the text alone.
    A line marked RPT ONLY (the per-document timings of the service read)
    goes to the .rpt and nowhere else: seventy of them on the boot screen, and
    the whole log republished seventy more times, is what it would cost.

Parameters:
    0: Step, e.g. "3/7" <STRING>
    1: Text <STRING>
    2: RPT only - not kept, not published <BOOL> (optional, default false)

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_step", "", [""]], ["_text", "", [""]], ["_rptOnly", false, [false]]];

private _line = format ["[TAC//PAC BOOT %1] %2", _step, _text];
private _t0 = missionNamespace getVariable [QGVAR(bootT0), -1];
if (_t0 < 0) then {
    diag_log _line;
} else {
    diag_log format ["[TAC//PAC BOOT %1] (+%2 s) %3", _step, (diag_tickTime - _t0) toFixed 2, _text];
};
if (_rptOnly) exitWith {};

GVAR(bootLog) pushBack _line;

// PUBLISHED PER LINE, small and cheap, so a client's boot screen
// (FUNC(bootScreen)) shows the steps as they happen and not only the whole
// log at READY. GVAR(bootStep) is the fraction done, off the "n/6" step.
if (isServer) then {
    private _parts = _step splitString "/";
    if (count _parts >= 2) then {
        // HALFWAY THROUGH THE STEP THE LINE NAMES, and never backwards: a line
        // is logged as a step starts or as it ends, and step three's own
        // progress (FUNC(bootDoc)) fills its share one document at a time.
        private _n = parseNumber (_parts # 0);
        private _of = (parseNumber (_parts # 1)) max 1;
        GVAR(bootStep) = (missionNamespace getVariable [QGVAR(bootStep), 0]) max ((_n - 0.5) / _of);
        publicVariable QGVAR(bootStep);
    };
    publicVariable QGVAR(bootLog);
};
