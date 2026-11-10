#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminSet

Description:
    The one door through which player data is written. Runs on the server, and
    the first thing it does is check who is knocking.

    CLIENTS NEVER WRITE. An admin's panel sends [caller, uid, field, value] here
    by remoteExec, and this re-checks the caller against the framework's admin
    list before doing anything - a client that could set its own rank by sending
    the right message is a client that owns the roster, and remoteExec is not a
    trust boundary. The panel's own admin check is a courtesy to the person
    using it; this one is the real one.

    ONE FIELD AT A TIME, BY NAME. The fields are the record's own keys and
    nothing else: a caller naming a field the record does not have is refused
    rather than allowed to grow the schema from the outside. Each write stamps
    updatedAt, which is the merge key across servers, and notes a serverId so a
    merged store still says where an edit came from.

    IT PUBLISHES AND SAVES. Publishing is what puts the edit on every client and
    onto the unit of a man already in the field - see FUNC(applyOnClient).
    Saving is debounced, so an admin working down a roster is one write, not
    thirty.

    IDS ARE CHECKED AGAINST THE STRUCTURE. A rankId that is not a rank is
    refused now, at the panel, rather than becoming an orphan flagged at the next
    mission start.

Parameters:
    0: Caller <OBJECT>
    1: Target UID <STRING>
    2: Field <STRING> - "rankId" | "roleId" | "groupId" | "statusId" |
                        "skillIds" | "awardAdd" | "awardRemove" | "noteAdd" |
                        "trainingAdd" | "trainingRemove" |
                        "milsimName" | "discordId" | "enlistedAt" | "clearance" |
                        "company" | "reportsTo" | "excuseAdd" | "excuseRemove"
    3: Value <ANY> - awardAdd takes an award id or [id, citation]; the
       excuse fields take an op window id; trainingAdd takes [courseId, text]
       (a course off the "trainings" section, and a note optionally led by
       YYYY-MM-DD to back-date it) or plain text, trainingRemove the index
       into the record's training list

    EVERY WRITE IS LOGGED (FUNC(logAction)) - dated, signed, on the record
    and in the store's log. A rank change stamps promotedAt; a skill granted
    for the first time is written to qualifications with the day.

Returns:
    Whether the write happened <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_uid", "", [""]], ["_field", "", [""]], "_value"];

if (!isServer) exitWith {false};

if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {
    WARNING_2("adminSet refused: %1 is not an admin (%2)",name _caller,_field);
    false
};

if (GVAR(readOnly)) exitWith {
    WARNING("adminSet refused: store is read-only");
    false
};

private _rec = [_uid] call FUNC(record);
if (count _rec isEqualTo 0) exitWith {false};

private _by = name _caller;
private _now = [] call FUNC(stamp);
private _ok = true;

private _fnc_known = {
    params ["_section", "_id"];
    _id isEqualTo "" || {_id in (GVAR(structure) getOrDefault [_section, createHashMap])}
};

switch (_field) do {
    case "rankId": {
        if !(["ranks", _value] call _fnc_known) exitWith { _ok = false };
        if ((_rec getOrDefault ["rankId", ""]) isNotEqualTo _value) then {_rec set ["promotedAt", _now select [0, 10]]};
        _rec set ["rankId", _value];
    };
    case "roleId": {
        if !(["roles", _value] call _fnc_known) exitWith { _ok = false };
        _rec set ["roleId", _value];
    };
    case "statusId": {
        if !(["statuses", _value] call _fnc_known) exitWith { _ok = false };
        _rec set ["statusId", _value];
    };
    case "groupId": {
        if !(_value isEqualType "") exitWith { _ok = false };
        _rec set ["groupId", _value];
    };
    case "skillIds": {
        if !(_value isEqualType []) exitWith { _ok = false };
        private _bad = _value select {!(["skills", _x] call _fnc_known)};
        if (_bad isNotEqualTo []) exitWith {
            WARNING_1("adminSet refused: unknown skill(s) %1",_bad);
            _ok = false;
        };
        // a skill granted for the first time is a qualification, dated
        private _quals = _rec getOrDefault ["qualifications", []];
        private _had = _rec getOrDefault ["skillIds", []];
        {
            private _sid = _x;
            if (!(_sid in _had) && {(_quals findIf {(_x # 0) isEqualTo _sid}) < 0}) then {
                _quals pushBack [_sid, ["skills", _sid] call FUNC(lookup), _now select [0, 10]];
            };
        } forEach _value;
        _rec set ["qualifications", _quals];
        _rec set ["skillIds", +_value];
    };
    case "awardAdd": {
        private _aid = _value;
        private _citation = "";
        if (_value isEqualType []) then {_aid = _value param [0, ""]; _citation = _value param [1, ""]};
        if !(_aid isEqualType "" && _aid isNotEqualTo "" && {["awards", _aid] call _fnc_known}) exitWith { _ok = false };
        if !(_citation isEqualType "") then {_citation = ""};
        private _awards = _rec getOrDefault ["awards", []];
        _awards pushBack [_aid, _now, _by, _citation];
        _rec set ["awards", _awards];
        _value = _aid;
    };
    case "awardRemove": {
        private _awards = (_rec getOrDefault ["awards", []]) select {(_x # 0) isNotEqualTo _value};
        _rec set ["awards", _awards];
    };
    case "noteAdd": {
        if (!(_value isEqualType "") || _value isEqualTo "") exitWith { _ok = false };
        private _notes = _rec getOrDefault ["notes", []];
        _notes pushBack [_now, _by, _value];
        _rec set ["notes", _notes];
    };
    // TRAINING: a course held, dated. The value is [courseId, text] - the course
    // off the catalogue (structure section "trainings") and the box beside the
    // list - or plain text on a unit that keeps no catalogue. Text that starts
    // with YYYY-MM-DD is back-dated to that day; the rest is the note. The
    // entry keeps the course ID, so a renamed course renames on every record.
    case "trainingAdd": {
        private _course = "";
        private _text = "";
        if (_value isEqualType []) then {
            _course = _value param [0, "", [""]];
            _text = _value param [1, "", [""]];
        } else {
            if (_value isEqualType "") then {_text = _value};
        };
        _text = trim _text;
        if (_course isNotEqualTo "" && {!(["trainings", _course] call _fnc_known)}) exitWith { _ok = false };
        private _when = _now;
        if (count _text >= 10) then {
            private _head = _text select [0, 10];
            private _digits = (toArray _head) select {_x >= 48 && _x <= 57};
            if (count _digits isEqualTo 8 && {(_head select [4, 1]) isEqualTo "-"} && {(_head select [7, 1]) isEqualTo "-"}) then {
                _when = _head;
                _text = trim (_text select [10]);
            };
        };
        if (_course isEqualTo "" && _text isEqualTo "") exitWith { _ok = false };
        private _training = _rec getOrDefault ["training", []];
        _training pushBack [_when, _by, _text, _course];
        _rec set ["training", _training];
        private _courseName = ["", ["trainings", _course] call FUNC(lookup)] select (_course isNotEqualTo "");
        _value = format ["%1 %2%3", _when, _courseName, ["", " - " + _text] select (_text isNotEqualTo "")];
    };
    case "trainingRemove": {
        if !(_value isEqualType 0) exitWith { _ok = false };
        private _training = _rec getOrDefault ["training", []];
        if (_value < 0 || _value >= count _training) exitWith { _ok = false };
        private _gone = _training deleteAt _value;
        _rec set ["training", _training];
        _value = format ["%1 %2", _gone # 0, _gone # 2];
    };
    // THE OPERATOR FIELDS - what only a person can know
    case "milsimName";
    case "discordId";
    case "email";
    case "clearance";
    case "company";
    case "reportsTo": {
        if !(_value isEqualType "") exitWith { _ok = false };
        _rec set [_field, trim _value];
    };
    // THE TWO DATES, typed to back-date: time in service counts from
    // enlistedAt, time in grade from promotedAt.
    case "enlistedAt";
    case "promotedAt": {
        if !(_value isEqualType "") exitWith { _ok = false };
        _value = trim _value;
        private _digits = (toArray _value) select {_x >= 48 && _x <= 57};
        if (count _value isNotEqualTo 10 || {count _digits isNotEqualTo 8} || {(_value select [4, 1]) isNotEqualTo "-"} || {(_value select [7, 1]) isNotEqualTo "-"}) exitWith {
            WARNING_2("adminSet refused: %1 '%2' is not YYYY-MM-DD",_field,_value);
            _ok = false;
        };
        _rec set [_field, _value];
    };
    case "excuseAdd": {
        if (!(_value isEqualType "") || _value isEqualTo "") exitWith { _ok = false };
        private _ex = _rec getOrDefault ["excused", []];
        _ex pushBackUnique _value;
        _rec set ["excused", _ex];
    };
    case "excuseRemove": {
        _rec set ["excused", (_rec getOrDefault ["excused", []]) select {_x isNotEqualTo _value}];
    };
    default {
        WARNING_1("adminSet refused: '%1' is not a field",_field);
        _ok = false;
    };
};

if (!_ok) exitWith {false};

_rec set ["updatedAt", _now];
_rec set ["serverId", GVAR(settings) getOrDefault ["serverId", ""]];
GVAR(players) set [_uid, _rec];

private _who = _rec getOrDefault ["name", _uid];
INFO_4("%1 set %2 on %3 (%4)",_by,_field,_who,_uid);

// THE LOG LINE - the type is the field's kind, the detail what it became.
private _type = switch (_field) do {
    case "rankId": {"rank"};
    case "roleId": {"role"};
    case "groupId": {"group"};
    case "statusId": {"status"};
    case "skillIds": {"skills"};
    case "awardAdd";
    case "awardRemove": {"award"};
    case "noteAdd": {"note"};
    case "trainingAdd";
    case "trainingRemove": {"training"};
    case "excuseAdd";
    case "excuseRemove": {"excuse"};
    case "enlistedAt": {"enlisted"};
    case "promotedAt": {"promoted"};
    default {"operator"};
};
private _shown = if (_value isEqualType "") then {_value} else {str _value};
private _detail = switch (_field) do {
    case "rankId": {"rank " + (["ranks", _value] call FUNC(lookup))};
    case "roleId": {"role " + (["roles", _value] call FUNC(lookup))};
    case "statusId": {"status " + (["statuses", _value] call FUNC(lookup))};
    case "skillIds": {"skills " + ((_value apply {["skills", _x] call FUNC(lookup)}) joinString ", ")};
    case "awardAdd": {"awarded " + (["awards", _value] call FUNC(lookup))};
    case "awardRemove": {"award removed " + (["awards", _value] call FUNC(lookup))};
    case "noteAdd": {"note: " + _shown};
    case "trainingAdd": {"training: " + _shown};
    case "trainingRemove": {"training removed: " + _shown};
    case "enlistedAt": {"enlisted " + _shown};
    case "promotedAt": {"promoted " + _shown};
    default {format ["%1 = %2", _field, _shown]};
};
[getPlayerUID _caller, _by, _type, _uid, _detail] call FUNC(logAction);

[] call FUNC(storeSave);
[] call FUNC(publish);

// The admin who made the edit gets the record back at once, so their page
// shows what the server now holds and not what they think they typed - and
// the recent log, which just grew by one line. The promotion points ride on
// the COPY (a transient "_promotion" key), never on the stored record: they
// are derived from sessions the client cannot see, and an edit just changed them.
private _send = +_rec;
_send set ["_promotion", [_uid] call FUNC(promotionPoints)];
[_uid, _send] remoteExec [QFUNC(adminRecv), owner _caller];
[_caller, "", 40] call FUNC(adminLog);

true
