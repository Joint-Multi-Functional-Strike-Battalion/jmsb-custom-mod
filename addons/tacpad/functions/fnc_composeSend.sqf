#include "script_component.hpp"
/*
 * Author: JMSB
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
} forEach (_template getOrDefault ["order", []]);

// WHICH REQUIRED FIELDS ARE EMPTY, every one of them - the engine's refusal
// names only the first. FUNC(composeCard) frames each of these in the accent
// until it is filled (the handoff's SEND validation).
GVAR(composeMissing) = (_template getOrDefault ["order", []]) select {
    private _v = GVAR(composeValues) getOrDefault [_x, ""];
    ((_fields getOrDefault [_x, createHashMap]) getOrDefault ["required", false])
    && {_v isEqualTo "" || _v isEqualTo false || _v isEqualTo []}
};

private _threadId = GVAR(composeThread);
private _addressees = [];
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

([_templateId, _payload, _addressees, _threadId, "", _tags, +GVAR(composePin)] call EFUNC(messaging,submit)) params ["_ok", "_why"];

// STAYS OPEN ON A REFUSAL. Everything typed is still in the answer map, so a
// missing required field is one box to fill rather than a form to start again.
//
// AND IT SAYS SO ON THE PANE. The notification stack is an RscTitles layer and
// this screen is a dialog, so the one message explaining why nothing happened
// was drawn behind the screen it was about. It is put beside SEND, where the
// press that failed was.
if (!_ok) exitWith {
    GVAR(composeError) = _why;
    ["COMPOSE", _why, "high"] call EFUNC(messaging,notify);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    false
};

GVAR(composeError) = "";
GVAR(composeMissing) = [];

// KEPT UNTIL THE SERVER HAS AGREED. The server validates again - a thread that
// closed while the card was open, a template that changed under it - and its
// refusal arrives after this has already tidied up. Held here, that refusal can
// put the card back with everything still in it rather than costing the player a
// nine-line they will now have to type twice. See the reject handler in
// XEH_postInit.
// THE CC IS IN THE TUPLE. It is an addressee like any other and a refusal that
// put the card back without it would send the second attempt to fewer people
// than the first - silently.
GVAR(composePending) = [_threadId, GVAR(composeTemplate), +GVAR(composeValues), +GVAR(composeGridText), GVAR(composeTo), GVAR(composeCc), +GVAR(composePin)];

GVAR(composeOn) = false;
GVAR(composePick) = false;
GVAR(composeToPick) = false;
GVAR(composeMarker) = "";

GVAR(composePin) = [];

GVAR(composePinPick) = false;
GVAR(composeValues) = createHashMap;
GVAR(composeGridText) = createHashMap;
GVAR(composeTemplate) = "";
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
