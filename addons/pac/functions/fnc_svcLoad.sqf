#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_svcLoad

Description:
    Asks the pacdb extension for the unit's store and waits for the answer.
    Server only, scheduled (it waits). See tools/pacdb/README.md for the
    extension, the service behind it, and the protocol.

    THE EXTENSION ANSWERS THROUGH A CALLBACK, in chunks, and the handler in
    XEH_postInit assembles them into GVAR(svcChunks) and sets
    GVAR(svcState). This waits on that state, up to PAC_SVC_TIMEOUT seconds.
    A service that is down costs that wait and nothing else: the caller
    falls back to the file or profile copy.

    ONE REQUEST AT A TIME, and it has to be. The extension answers every get
    with "get.begin" / "get.chunk" / "get.end" and every list with "list" -
    none of them names the key it answers - so two requests in flight would
    land in one GVAR(svcChunks). Overlapping the boot's reads needs the
    extension to tag its answers first (docs/new.md, 2026-10-19).

    THE WAIT CHECKS EVERY FRAME, not every 0.2 s: the boot reads seventy-odd
    documents in a row, and a fixed sleep added up to a tenth of a second to
    each one for nothing.

    THE PARSE RUNS UNSCHEDULED (isNil). Scheduled, the character-by-character
    parse of a 127 KB arsenal got the scheduler's three milliseconds a frame,
    shared with every other scheduled script on a busy server (ALiVE's among
    them); unscheduled it finishes in one go - a short hitch on the server at
    mission start instead of minutes of boot. FUNC(fromJson) has no `while`
    loop, so the unscheduled 10,000-turn cap cannot cut a document short.

Parameters:
    0: Document key, or a key prefix for "list" <STRING> (optional, default
       settings.unitId - the store)
    1: Verb <STRING> - "get" (a document) | "list" (the keys under the
       prefix, as an array) (optional, default "get")

Returns:
    [document or empty hashmap, status, timing] <ARRAY>
        status "ok" | "empty" | "error" | "off"
        timing [seconds waiting for the answer, seconds parsing it, characters]
        - for the boot log; [0, 0, 0] when nothing was asked

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {[createHashMap, "off", [0, 0, 0]]};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {[createHashMap, "off", [0, 0, 0]]};

params [["_key", "", [""]], ["_fn", "get", [""]]];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
if (_key isEqualTo "") then {_key = _unit};
if (_unit isEqualTo "") exitWith {
    WARNING("sync = service but settings.unitId is empty - nothing to ask for");
    [createHashMap, "error", [0, 0, 0]]
};

// A SERVER WITHOUT THE EXTENSION is told once and every later ask answers
// "error" at once, so the boot does not wait a timeout per document for a
// library that is not there (tools/pacdb/README.md says where it goes).
if (GVAR(svcMissing)) exitWith {[createHashMap, "error", [0, 0, 0]]};

GVAR(svcState) = "waiting";
GVAR(svcChunks) = [];

("ghostd_pacdb" callExtension [_fn, [_key]]) params [["_text", "", [""]], ["_code", 0, [0]], ["_err", 0, [0]]];
if (_err isNotEqualTo 0 || _text isNotEqualTo "queued") exitWith {
    WARNING_3("pacdb extension did not take the request (error %1, code %2, said '%3') - is ghostd_pacdb_x64.dll (Windows) / ghostd_pacdb_x64.so (Linux) in the mod folder or the server's Arma root, and is the database address set (CBA setting 'Database', or GHOSTD_PACDB_URL / pacdb.json)?",_err,_code,_text);
    if (_err isNotEqualTo 0) then {GVAR(svcMissing) = true};
    GVAR(svcState) = "error";
    [createHashMap, "error", [0, 0, 0]]
};

private _t0 = diag_tickTime;
waitUntil {
    GVAR(svcState) isNotEqualTo "waiting" || {diag_tickTime - _t0 > PAC_SVC_TIMEOUT}
};
private _waited = diag_tickTime - _t0;

switch (GVAR(svcState)) do {
    case "ok": {
        private _text = GVAR(svcChunks) joinString "";
        private _parsed = [nil, false, -1];
        private _t1 = diag_tickTime;
        isNil {_parsed = [_text] call FUNC(fromJson)};
        private _timing = [_waited, diag_tickTime - _t1, count _text];
        _parsed params ["_doc", "_ok", "_where"];
        if (_ok && _fn isEqualTo "list" && {_doc isEqualType []}) exitWith {[_doc, "ok", _timing]};
        if (_ok && {_doc isEqualType createHashMap}) exitWith {[_doc, "ok", _timing]};
        WARNING_1("service answered with something that is not a store document (JSON error at %1)",_where);
        [createHashMap, "error", _timing]
    };
    case "empty": {[createHashMap, "empty", [_waited, 0, 0]]};
    case "waiting": {
        WARNING_1("service did not answer within %1 s - using the local copy",PAC_SVC_TIMEOUT);
        GVAR(svcState) = "error";
        [createHashMap, "error", [_waited, 0, 0]]
    };
    default {[createHashMap, "error", [_waited, 0, 0]]};
};
