#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_storeSync

Description:
    Writes the store to the database WITHOUT OVERWRITING THE OTHER SERVERS:
    reads the database's copy, folds it in (FUNC(storeMerge)), then pushes
    (FUNC(svcSave)). The unit runs one ops, one training and one dev server,
    possibly at once, and each push is the whole store document - a blind push
    dropped whatever the others had written since this server loaded.

    ONE AT A TIME. A call while a sync is running asks for one more round after
    it, so the last state always goes down and two rounds never interleave.

    A DATABASE THAT DOES NOT ANSWER IS NOT WRITTEN: pushing without the read
    is the overwrite this exists to stop. The profile already holds everything,
    and the next save tries again.

    AFTER A RESTORE OR A SAMPLE REMOVE (GVAR(syncReplace)) the next round
    pushes without merging, once - merging would bring back what was removed.

Parameters:
    None

Returns:
    Nothing

Example:
    [] call jmfsb_pac_fnc_storeSync

Public: No

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};

private _start = false;
isNil {
    if (GVAR(syncBusy)) then {
        GVAR(syncAgain) = true;
    } else {
        GVAR(syncBusy) = true;
        _start = true;
    };
};
if (!_start) exitWith {};

[] spawn {
    while {true} do {
        GVAR(syncAgain) = false;
        private _replace = GVAR(syncReplace);
        GVAR(syncReplace) = false;
        private _push = true;
        if (!_replace) then {
            ([] call FUNC(svcLoad)) params ["_doc", "_status"];
            switch (_status) do {
                case "ok": {
                    private _took = false;
                    isNil {_took = [_doc] call FUNC(storeMerge)};
                    if (_took) then {[] call FUNC(publish)};
                };
                case "empty": {};
                default {
                    _push = false;
                    WARNING("store not pushed: the database did not answer the read before the write - the next save tries again");
                };
            };
        };
        if (_push) then {[] call FUNC(svcSave)};
        if !(GVAR(syncAgain)) exitWith {};
    };
    GVAR(syncBusy) = false;
};
