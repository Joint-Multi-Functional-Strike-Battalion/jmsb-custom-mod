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

    ONE REQUEST AT A TIME, ENFORCED. The extension answers every get
    with "get.begin" / "get.chunk" / "get.end" and every list with "list" -
    none of them names the key it answers - so two requests in flight would
    land in one GVAR(svcChunks) and one player could be handed another's
    document. So callers queue on a ticket (GVAR(svcTicket) /
    GVAR(svcServing)) and a request that timed out stays owed
    (GVAR(svcOwed), paid by the callback in XEH_postInit) until its late
    answer arrives or PAC_SVC_STALE passes, so it cannot fill the next one.

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

// THE QUEUE. Each caller takes a ticket and waits its turn, so a second ask
// never resets the first one's chunks or wakes on its answer. The ticket is
// taken in isNil so two scripts cannot draw the same number.
private _turn = 0;
isNil {
    _turn = GVAR(svcTicket);
    GVAR(svcTicket) = _turn + 1;
};
waitUntil {GVAR(svcServing) isEqualTo _turn};

private _result = call {
    // An answer still owed to an earlier ask that timed out would land in this
    // one's chunks, so wait for it first (bounded: the extension may never send it).
    private _t0 = diag_tickTime;
    waitUntil {GVAR(svcOwed) isEqualTo 0 || {diag_tickTime - _t0 > PAC_SVC_STALE}};
    if (GVAR(svcOwed) > 0) then {
        WARNING_1("an earlier service request was never answered - asking anyway after %1 s",PAC_SVC_STALE);
        GVAR(svcOwed) = 0;
    };
    if (GVAR(svcMissing)) exitWith {[createHashMap, "error", [0, 0, 0]]};

    // The ask and the debt it creates in one step, so no answer can land between them.
    private _sent = [];
    isNil {
        GVAR(svcState) = "waiting";
        GVAR(svcChunks) = [];
        _sent = "ghostd_pacdb" callExtension [_fn, [_key]];
        if ((_sent param [2, 1]) isEqualTo 0 && {(_sent param [0, ""]) isEqualTo "queued"}) then {
            GVAR(svcOwed) = GVAR(svcOwed) + 1;
        };
    };
    _sent params [["_text", "", [""]], ["_code", 0, [0]], ["_err", 0, [0]]];
    if (_err isNotEqualTo 0 || _text isNotEqualTo "queued") exitWith {
        WARNING_3("pacdb extension did not take the request (error %1, code %2, said '%3') - is ghostd_pacdb_x64.dll (Windows) / ghostd_pacdb_x64.so (Linux) in the mod folder or the server's Arma root, and is the database address set (CBA setting 'Database', or GHOSTD_PACDB_URL / pacdb.json)?",_err,_code,_text);
        if (_err isNotEqualTo 0) then {GVAR(svcMissing) = true};
        GVAR(svcState) = "error";
        [createHashMap, "error", [0, 0, 0]]
    };

    _t0 = diag_tickTime;
    waitUntil {
        GVAR(svcState) isNotEqualTo "waiting" || {diag_tickTime - _t0 > PAC_SVC_TIMEOUT}
    };
    private _waited = diag_tickTime - _t0;

    switch (GVAR(svcState)) do {
        case "ok": {
            private _json = GVAR(svcChunks) joinString "";
            private _parsed = [nil, false, -1];
            private _t1 = diag_tickTime;
            isNil {_parsed = [_json] call FUNC(fromJson)};
            private _timing = [_waited, diag_tickTime - _t1, count _json];
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
};

// the next caller's turn, whichever way this one ended
GVAR(svcServing) = _turn + 1;

_result
