#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the compose pane's answers and submits them.
 *
 * Everything typed has already been harvested off its edit - see
 * FUNC(composeHarvest) - so this is the same job for a pressed answer and a
 * typed one. Only the conversion to what the engine stores happens here.
 *
 * WITH NO TEMPLATE IT IS A MESSAGE. The plain box sends as the freetext report,
 * which is a real template with a real field, so the thread it opens is the same
 * kind of thing as every other thread and nothing downstream has to special-case
 * it.
 *
 * The engine validates exactly as it would from any other caller. The pane gets
 * no special treatment, because a form that can submit something the API would
 * refuse is a form that lies to the player.
 *
 * TWO SENDS OF THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09): a FRAGO goes as the FRAGO card with only the changed lines
 * (FUNC(composeFragoPayload)); a support request filed in a TIC, SALUTE or
 * MIST carries the asset on its TO line as the reply's addressee
 * (FUNC(starterInReport)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_composeSend
 *
 * Public: No
 */

private _templateId = [GVAR(composeTemplate), "freetext"] select (GVAR(composeTemplate) isEqualTo "");
private _template = [_templateId] call EFUNC(messaging,template);
private _fields = _template getOrDefault ["fields", createHashMap];

private _payload = [];
{
    private _value = GVAR(composeValues) getOrDefault [_x, ""];
    if (_value isEqualTo "" || _value isEqualTo false) then {continue};

    // A number typed into a box is still a string until somebody says otherwise.
    // Grids are left as they are: a position from CURRENT LOC or a marker, a
    // string from the keyboard, and the engine renders both.
    if ((_fields getOrDefault [_x, createHashMap]) getOrDefault ["type", "text"] isEqualTo "number"
        && _value isEqualType "") then {
        _value = parseNumber _value;
    };

    _payload pushBack [_x, _value];
    // A grid picked from a map marker takes the marker's name with it (user,
    // 2026-11-05), under its own key + the suffix - the template's order
    // does not know that key.
    private _marker = GVAR(composeValues) getOrDefault [_x + MARKER_NAME_SUFFIX, ""];
    if (_value isEqualType [] && _marker isEqualType "" && _marker isNotEqualTo "") then {
        _payload pushBack [_x + MARKER_NAME_SUFFIX, _marker];
    };
} forEach (_template getOrDefault ["order", []]);

// WHICH REQUIRED FIELDS ARE EMPTY, every one of them - the engine's refusal
// names only the first. FUNC(composeCard) frames each of these in the accent
// until it is filled (the handoff's SEND validation). A REQUIRED EXCLUSIVE
// TICK GROUP is "tick one" (2026-11-02, EFUNC(messaging,validate)): it is
// missing once - its first tick's key - and only with none of it ticked. A
// field only a map marker answers (markerOnly) is missing while it holds
// typing.
private _order = _template getOrDefault ["order", []];
private _groupsSeen = [];
GVAR(composeMissing) = [];
{
    private _key = _x;
    private _field = _fields getOrDefault [_key, createHashMap];
    if !(_field getOrDefault ["required", false]) then {continue};
    private _v = GVAR(composeValues) getOrDefault [_key, ""];
    private _group = _field getOrDefault ["exclusive", ""];
    if ((_field getOrDefault ["type", ""]) isEqualTo "bool" && _group isNotEqualTo "") then {
        if (_group in _groupsSeen) then {continue};
        _groupsSeen pushBack _group;
        private _ticked = (_order findIf {
            ((_fields getOrDefault [_x, createHashMap]) getOrDefault ["exclusive", ""]) isEqualTo _group
            && (GVAR(composeValues) getOrDefault [_x, false]) isEqualTo true
        }) >= 0;
        if (!_ticked) then {GVAR(composeMissing) pushBack _key};
        continue;
    };
    private _typed = (_field getOrDefault ["markerOnly", false]) isEqualTo true && _v isEqualType "";
    if (_typed || _v isEqualTo "" || _v isEqualTo false || _v isEqualTo []) then {GVAR(composeMissing) pushBack _key};
} forEach _order;

private _threadId = GVAR(composeThread);
private _addressees = [];

// A FRAGO (2026-11-09): the FRAGO card, carrying only what changed
// (FUNC(composeFragoPayload)); the order's own required lines still hold it
// up (above) - the server checks the merged order again.
private _frago = GVAR(composeFrago) isNotEqualTo [] && _threadId isNotEqualTo "";
private _fragoWhy = "";
if (_frago) then {
    ([] call FUNC(composeFragoPayload)) params ["_fragoPayload", "_changed"];
    if (_changed isEqualTo 0) exitWith {_fragoWhy = FRAGO_NOTHING};
    _templateId = FRAGO_ID;
    _payload = _fragoPayload;
};
if (_fragoWhy isNotEqualTo "") exitWith {
    GVAR(composeError) = format [NOT_SENT_LINE, _fragoWhy];
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    false
};

// A SUPPORT REQUEST FILED IN A REPORT (rule 3, 2026-11-09): the asset on its
// TO line is the reply's addressee - that is what pulls it into the thread
// (FUNC(starterInReport)). One with no asset on the TO line is not sent.
private _hosted = false;
if (_threadId isNotEqualTo "" && !_frago && (_template getOrDefault ["kind", ""]) isEqualTo QUICK_KIND_ROOT) then {
    private _thread = ((missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []]) param [0, createHashMap];
    private _hasAsset = ((_thread getOrDefault ["boxes", []]) findIf {
        _x isEqualType "" && {(toUpper (_x select [0, count SUPPORT_BOX_PREFIX])) isEqualTo SUPPORT_BOX_PREFIX}
    }) >= 0;
    _hosted = !_hasAsset && (_thread getOrDefault ["rootTemplateId", ""]) in REPORT_HOSTS;
};
if (_hosted) then {
    _addressees = ((GVAR(composeTo) splitString ",") apply {trim _x}) select {
        (toUpper (_x select [0, count SUPPORT_BOX_PREFIX])) isEqualTo SUPPORT_BOX_PREFIX
    };
};
if (_hosted && _addressees isEqualTo []) exitWith {
    GVAR(composeError) = format [NOT_SENT_LINE, REPORT_NO_ASSET];
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    false
};

if (_threadId isEqualTo "") then {
    _addressees = (GVAR(composeTo) splitString ",") apply {trim _x} select {_x isNotEqualTo ""};

    // THE CC LINE IS ADDRESSEES TOO, which is the difference between a CC and a
    // tag: a tag wakes somebody up about a thread they can already read, a CC
    // files the thread in their box as well. It is names on screen and ids here -
    // see FUNC(composeCcIds) - and it only exists on a root, because the lines
    // above have already thrown the addressees away on a reply.
    {
        _addressees pushBackUnique _x;
    } forEach ([GVAR(composeCc)] call FUNC(composeCcIds));
};

// Tags travel on a reply as well as on a root - see the TAG row in
// FUNC(composePane) for why.
private _tags = (GVAR(composeTags) splitString ",") apply {trim _x} select {_x isNotEqualTo ""};

// A SUPPORT ASSET ANSWERS UNDER THE NAME IT WAS PICKED BY (2026-11-01). The
// server answers a root filed to an asset's box as the asset, but it cannot
// read the asset's call sign itself; this machine's rows can, and tell it
// first (EFUNC(support,mailboxFiled)) - else the ROGER comes from "CAS:0".
if (_addressees isNotEqualTo [] && !isNil QEFUNC(support,mailboxFiled)) then {
    [_addressees] call EFUNC(support,mailboxFiled);
};

([_templateId, _payload, _addressees, _threadId, "", _tags, +GVAR(composePin)] call EFUNC(messaging,submit)) params ["_ok", "_why"];

// STAYS OPEN ON A REFUSAL. Everything typed is still in the answer map, so a
// missing required field is one box to fill rather than a form to start again.
//
// AND IT SAYS SO ON THE PANE. The notification stack is an RscTitles layer and
// this screen is a dialog, so the one message explaining why nothing happened
// was drawn behind the screen it was about. It is put beside SEND, where the
// press that failed was, as NOT SENT - <reason>; the submit itself says NOT SENT
// upper right and logs it (user, 2026-11-02: "arty never replied").
if (!_ok) exitWith {
    GVAR(composeError) = format [NOT_SENT_LINE, _why];
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    false
};

// A SUPPORT CARD TO NO ASSET (user, 2026-11-02: "arty never replied"). A call
// for fire filed on a net goes in, and no battery answers it: only an asset's
// own box (an @ mention, or the TO picker's SUPPORT group) or a player crew's
// reaches somebody who fires. Sent all the same - men on the net may answer -
// and said upper right and in the RPT.
if (_threadId isEqualTo "" && !isNil QEFUNC(support,boxName)) then {
    ([false, _templateId] call FUNC(composeToSupport)) params ["_supShow", "_supCard", "_supRows"];
    private _supBoxes = _supRows apply {_x select 0};
    private _toAsset = (_addressees findIf {_x in _supBoxes || ([_x] call EFUNC(support,boxName)) isNotEqualTo ""}) >= 0;
    if (_supShow && _supCard && !_toAsset) then {
        INFO_2("'%1' sent to %2 - no support asset addressed, no AI answers it",_templateId,_addressees);
        [NO_ASSET_TITLE, format [NO_ASSET_TEXT, toUpper (_template getOrDefault ["short", _templateId])], "high"] call EFUNC(messaging,notify);
    };
};

GVAR(composeError) = "";
GVAR(composeMissing) = [];
GVAR(composeNote) = "";
GVAR(composeMentionAsk) = [];

// KEPT UNTIL THE SERVER HAS AGREED. The server validates again - a thread that
// closed while the card was open, a template that changed under it - and its
// refusal arrives after this has already tidied up. Held here, that refusal can
// put the card back with everything still in it rather than costing the player a
// nine-line they will now have to type twice. See the reject handler in
// XEH_postInit.
// THE CC IS IN THE TUPLE. It is an addressee like any other and a refusal that
// put the card back without it would send the second attempt to fewer people
// than the first - silently.
GVAR(composePending) = [_threadId, GVAR(composeTemplate), +GVAR(composeValues), +GVAR(composeGridText), GVAR(composeTo), GVAR(composeCc), +GVAR(composePin), +GVAR(composeFrago)];

GVAR(composeOn) = false;
GVAR(composePick) = false;
GVAR(composeToPick) = false;
GVAR(composeMarker) = "";

GVAR(composePin) = [];

GVAR(composePinPick) = false;
GVAR(composeValues) = createHashMap;
GVAR(composeGridText) = createHashMap;
GVAR(composeTemplate) = "";
GVAR(composeFrago) = [];
GVAR(composeTags) = "";
GVAR(composeCc) = "";

// A reply drops back onto the thread it answered; a new message has no thread to
// drop back onto until the server has filed it, so it drops back to the list.
if (_threadId isEqualTo "") then {
    GVAR(readerThread) = "";
} else {
    // Ask for the thread again so the pane redraws with the reply in it when the
    // server has taken it. Submitting is a request, not a write - the copy in
    // the cache is still the one from before this was sent.
    [_threadId, {{[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame}] call EFUNC(messaging,open);
};

{[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;

["COMPOSE", format ["%1 sent.", _template getOrDefault ["short", _templateId]]] call EFUNC(messaging,notify);

true
