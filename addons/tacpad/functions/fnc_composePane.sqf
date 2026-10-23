#include "script_component.hpp"
/*
 * Author: JMSB
 * The reader's right pane, in compose. Header, addressing, the message or the
 * inserted template's card, and SEND at the foot.
 *
 * THE MESSAGE IS THE DEFAULT STATE. The pane opens on a box you can type into,
 * and a report is INSERTED with the TEMPLATE button - the design's + TEMPLATE,
 * not a picker standing between the player and the keyboard. Most traffic on a
 * net is a sentence; the deck is for the traffic that is not.
 *
 * NOTHING TYPED SURVIVES A REDRAW ON ITS OWN. Every press here harvests first -
 * see FUNC(composeHarvest) - because the pane is rebuilt whole on every press.
 *
 * Arguments:
 * 0: [x, width] of the pane, in the content group's own coordinates <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_pane", [0, 0], [[]], 2]];

_pane params ["_dx", "_dw"];

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

// The thread view's reply box belongs to the thread view. Deleted rather
// than parked: it is a runtime control now (see FUNC(readerInput)), and the
// thread view makes itself a fresh one every time it draws.
private _input = _display displayCtrl IDC_RD_INPUT;
if (!isNull _input) then {ctrlDelete _input};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _h = (ctrlPosition _root) # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _btnH = ([TEXT_TITLE] call FUNC(textH)) + 2 * _padY;
private _fontH = ([TEXT_TITLE] call FUNC(textH)) / 1.25;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

private _threadId = GVAR(composeThread);
private _reply = _threadId isNotEqualTo "";
private _templateId = GVAR(composeTemplate);
private _template = if (_templateId isEqualTo "") then {
    createHashMap
} else {
    [_templateId] call EFUNC(messaging,template)
};

// Where it is going, by default the net the reader is on. ALL is a view rather
// than a net and cannot be addressed, so FUNC(netBox) falls it back to the first
// mailbox the mission named.
if (GVAR(composeTo) isEqualTo "") then {
    GVAR(composeTo) = [GVAR(readerNet), true] call FUNC(netBox);
};

// SAID OFF THE ADDRESS, NOT OFF THE RAIL. This line used to read GVAR(readerNet)
// while the addressee stayed on whatever box the pane opened on - so pressing a
// net in the rail retitled the pane and sent the message somewhere else. It now
// says what is actually in the TO line, and a press in the rail moves both.
private _toLabel = [GVAR(composeTo)] call FUNC(netLabel);

// A person is not a net, and "SEND ON SGT DOE NET" is not a sentence.
private _addressed = ((GVAR(composeTo) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
private _onNet = (_addressed findIf {(_x select [0, 2]) isEqualTo "P:"}) < 0;

// ---------------------------------------------------------------- header ---
private _y = _padY * 2;

private _cancelW = _dw * 0.15;
// One slot in from the pane's edge: the corner is CLOSE, drawn by
// FUNC(readerDraw) for every view (user, 2026-09-05).
private _cancelX = _dx + _dw - 2 * _cancelW - 2 * _pad;

[
    _root, [_dx + _pad, _y, _dw - 2 * _cancelW - 4 * _pad, _rowH * 1.2],
    ["NEW MESSAGE", "REPLY"] select _reply,
    _ink, TEXT_TITLE, true
] call FUNC(drawText);

[_root, [_cancelX, _y, _cancelW, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
[_root, [_cancelX + _pad, _y, _cancelW - 2 * _pad, _btnH], "CANCEL", _ink, TEXT_BODY, true, "center"] call FUNC(drawText);
[_root, [_cancelX, _y, _cancelW, _btnH], {
    GVAR(composeOn) = false;
    GVAR(composePick) = false;
    GVAR(composeToPick) = false;
    GVAR(composeMarker) = "";

    GVAR(composePin) = [];
    GVAR(composePinPick) = false;
    GVAR(composeValues) = createHashMap;
    GVAR(composeGridText) = createHashMap;
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);

_y = _y + _rowH * 1.25;

private _sendLine = if (_reply) then {
    format ["IN THREAD %1", _threadId]
} else {
    [format ["SEND TO %1", _toLabel], format ["SEND ON %1 NET", _toLabel]] select _onNet
};

[
    _root, [_dx + _pad, _y, _dw - 2 * _pad, _rowH * 0.8],
    _sendLine, _mute, TEXT_LABEL, true, "left", true
] call FUNC(drawText);

_y = _y + _rowH;
[_root, [_dx + _pad, _y, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);
_y = _y + _padY * 2;

// ---------------------------------------------------------------- picker ---
if (GVAR(composePick)) exitWith {
    [[_dx, _dw, _y]] call FUNC(composePicker);
};

// Two pickers, two flags, one at a time: the template deck and the addressee
// list ask different questions and both own the pane below the header while they
// are up.
if (GVAR(composeToPick)) exitWith {
    [[_dx, _dw, _y]] call FUNC(composeToPicker);
};

// -------------------------------------------------------------- addressing --
// ONE COLUMN FOR THE ADDRESS ROWS. TO, CC and TAG all hang off the same label
// width rather than each row picking its own indent.
private _labW = _dw * 0.08;
private _fieldX = _dx + _pad + _dw * 0.09;
private _fieldW = _dw - _dw * 0.09 - _cancelW - 4 * _pad;

if (!_reply) then {
    // ONE LINE, NOT A GRID OF CHIPS. Every net, every squad and every player on
    // side was a pressable chip across the top of the pane - fourteen of them and
    // counting, two rows deep - and they ate the space the message is written in.
    //
    // THE RAIL ON THE LEFT IS THE SELECTOR. It is already the list of nets with
    // the current one lit, so a press there retargets an open message - see the
    // rail handler in FUNC(readerDraw) - and this line reads back what that press
    // did. CHANGE is for the addressees the rail cannot offer: a person, or a net
    // this player is not currently reading.
    private _changeW = _dw * 0.15;
    private _changeX = _dx + _dw - _changeW - _pad;

    [_root, [_dx + _pad, _y, _labW, _btnH], "TO", _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);
    [
        _root, [_fieldX, _y, _changeX - _fieldX - _pad, _btnH],
        _toLabel, _accent, TEXT_BODY, true
    ] call FUNC(drawText);

    [_root, [_changeX, _y, _changeW, _btnH], _line, RULE_THIN] call FUNC(drawFrame);
    [_root, [_changeX + _pad, _y, _changeW - 2 * _pad, _btnH], "CHANGE", _mute, TEXT_BODY, true, "center"] call FUNC(drawText);
    [_root, [_changeX, _y, _changeW, _btnH], {
        [] call FUNC(composeHarvest);
        GVAR(composeToPick) = true;
        GVAR(composeMarker) = "";

        GVAR(composePin) = [];
        GVAR(composePinPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
} else {
    [
        _root, [_dx + _pad, _y, _dw - 2 * _pad, _btnH],
        "ADDRESSED TO EVERYONE ON THE THREAD", _mute, TEXT_BODY, false
    ] call FUNC(drawText);
};

_y = _y + _btnH + _padY;

// -------------------------------------------------------------------- cc ----
// A CC ONLY EXISTS ON A ROOT. FUNC(composeSend) discards addressees outright on a
// reply - the thread already decides who can read it - so a CC line drawn there
// would look like it worked and send nowhere. It is not drawn there.
//
// @ OFFERS BOTH KINDS. A net and a man are the same sort of thing to address, and
// nobody should have to remember which list a call sign is on. The completions
// are built off this box's own KeyUp - see FUNC(composeCcDrop) - and never through
// a redraw, which would delete the box being typed into.
if (!_reply) then {
    [_root, [_dx + _pad, _y, _labW, _btnH], "CC", _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);
    [_root, [_fieldX, _y, _fieldW, _btnH], _line, RULE_THIN] call FUNC(drawFrame);

    private _cc = _display ctrlCreate ["RscEdit", -1, _root];
    _cc ctrlSetPosition [_fieldX + _pad, _y + _padY * 0.5, _fieldW - 2 * _pad, _btnH - _padY];
    _cc ctrlSetBackgroundColor [0, 0, 0, 0];
    _cc ctrlSetTextColor _ink;
    _cc ctrlSetFontHeight _fontH;
    _cc ctrlSetText GVAR(composeCc);
    _cc ctrlSetTooltip "Type @ for a list of nets, squads and players. Everybody named here is addressed on the thread as well - separate them with commas.";
    _cc setVariable [QGVAR(ccField), true];

    // Where the completions drop, in this group's own coordinates, and how tall
    // one of them is. The drop is built on a keystroke, long after this geometry
    // has gone out of scope, so it travels on the control.
    _cc setVariable [QGVAR(ccDrop), [_fieldX, _y + _btnH, _fieldW, _rowH * 0.95]];
    _cc ctrlAddEventHandler ["KeyUp", {
        params ["_ctrl"];
        [_ctrl] call FUNC(composeCcDrop);
        false
    }];
    _cc ctrlCommit 0;

    [
        _root, [_dx + _dw - _cancelW - _pad, _y, _cancelW, _btnH],
        "@ TO ADD", _dim, TEXT_LABEL, true, "right", true
    ] call FUNC(drawText);

    _y = _y + _btnH + _padY * 0.5;
};

// ------------------------------------------------------------------ tags ---
// ON A REPLY TOO, which is the difference between this row and TO. Addressees
// are fixed the moment a thread exists - a reply cannot narrow or widen who can
// read a conversation - but calling somebody into one halfway down is exactly
// what a net does out loud, and a man who has just been asked for by name on a
// thread he was not on can answer it.
[_root, [_dx + _pad, _y, _labW, _btnH], "TAG", _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);
[_root, [_fieldX, _y, _fieldW, _btnH], _line, RULE_THIN] call FUNC(drawFrame);

private _tags = _display ctrlCreate ["RscEdit", -1, _root];
_tags ctrlSetPosition [_fieldX + _pad, _y + _padY * 0.5, _fieldW - 2 * _pad, _btnH - _padY];
_tags ctrlSetBackgroundColor [0, 0, 0, 0];
_tags ctrlSetTextColor _accent;
_tags ctrlSetFontHeight _fontH;
_tags ctrlSetText GVAR(composeTags);
_tags ctrlSetTooltip "Call signs, squads or jobs to alert, separated by commas - NOMAD, MED. They are woken up and may answer; the message stays on this net.";
_tags setVariable [QGVAR(tagField), true];
_tags ctrlCommit 0;

[
    _root, [_dx + _dw - _cancelW - _pad, _y, _cancelW, _btnH],
    "ALERTS", _dim, TEXT_LABEL, true, "right", true
] call FUNC(drawText);
_y = _y + _btnH;

// SAID ON THE PANE, NOT IN A TOOLTIP. What a tag IS lived in hover text, so
// the row read as an unlabelled box nobody could name the purpose of - the
// screenshot said exactly that, in yellow.
[
    _root, [_fieldX, _y, _fieldW, _btnH * 0.55],
    "WAKES WHOEVER IT NAMES. TRAFFIC STAYS ON THIS NET. PRESS TO TAG:",
    _dim, TEXT_LABEL, false
] call FUNC(drawText);
_y = _y + _btnH * 0.55;

// PRE-BUILT, pressed on and off - the design's tags are a set you pick from,
// not a spelling test.
//
// IT WAS EVERY SQUAD IN THE TASK FORCE (user, 2026-09-03: "you cleaned up the
// nets but not the tags"), which is fifteen chips plus four jobs sharing one
// row - each about a finger wide and none of them readable. It is his own
// squad, the platoons whose net he is on, and the jobs now:
// EFUNC(messaging,tagSet).
//
// THE BOX ABOVE STILL TAKES ANYTHING by hand - a callsign, a job, a man, a UID.
// The chips are the set worth one press, not the set that is legal.
private _tagSet = [];
if (!isNil QEFUNC(messaging,tagSet)) then {_tagSet = [player] call EFUNC(messaging,tagSet)};
if (_tagSet isNotEqualTo []) then {
    private _picked = ((GVAR(composeTags) splitString ",") apply {toUpper (trim _x)}) select {_x isNotEqualTo ""};
    private _chipH = _btnH * 0.75;
    private _chipW = (_dw - 2 * _pad) / ((count _tagSet) max 4) - _pad;

    {
        private _on = _x in _picked;
        private _sx = _dx + _pad + _forEachIndex * (_chipW + _pad);

        if (_on) then {
            [_root, [_sx, _y, _chipW, _chipH], _accent] call FUNC(drawFill);
        } else {
            [_root, [_sx, _y, _chipW, _chipH], _line, RULE_THIN] call FUNC(drawFrame);
        };
        [_root, [_sx + _pad * 0.5, _y, _chipW - _pad, _chipH], _x, ([_mute, _ground] select _on), TEXT_LABEL, true, "center"] call FUNC(drawText);

        private _hit = [_root, [_sx, _y, _chipW, _chipH], {
            params ["_ctrl"];
            [] call FUNC(composeHarvest);
            private _tag = _ctrl getVariable [QGVAR(tagChip), ""];
            private _now = ((GVAR(composeTags) splitString ",") apply {toUpper (trim _x)}) select {_x isNotEqualTo ""};
            if (_tag in _now) then {
                _now = _now select {_x isNotEqualTo _tag};
            } else {
                _now pushBack _tag;
            };
            GVAR(composeTags) = _now joinString ", ";
            {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
        }] call FUNC(drawHit);
        _hit setVariable [QGVAR(tagChip), _x];
    } forEach _tagSet;

    _y = _y + _chipH + _padY * 0.5;
};

_y = _y + _padY;

// ------------------------------------------------------------- the insert ---
// One button, and what it did last. A template is something added to a message,
// so it can be taken off again without losing what was typed around it.
private _actW = _dw * 0.24;

[_root, [_dx + _pad, _y, _actW, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
[
    _root, [_dx + _pad * 2, _y, _actW - 3 * _pad, _btnH],
    ["+ TEMPLATE", "CHANGE TEMPLATE"] select (_templateId isNotEqualTo ""),
    _ink, TEXT_BODY, true, "center"
] call FUNC(drawText);
[_root, [_dx + _pad, _y, _actW, _btnH], {
    [] call FUNC(composeHarvest);
    GVAR(composePick) = true;
    GVAR(composeMarker) = "";

    GVAR(composePin) = [];
    GVAR(composePinPick) = false;
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);

if (_templateId isNotEqualTo "") then {
    private _dropX = _dx + _pad * 2 + _actW;
    private _dropW = _dw * 0.16;

    [_root, [_dropX, _y, _dropW, _btnH], _line, RULE_THIN] call FUNC(drawFrame);
    [_root, [_dropX + _pad, _y, _dropW - 2 * _pad, _btnH], "REMOVE", _mute, TEXT_BODY, true, "center"] call FUNC(drawText);
    [_root, [_dropX, _y, _dropW, _btnH], {
        [] call FUNC(composeHarvest);
        GVAR(composeTemplate) = "";
        GVAR(composeMarker) = "";

        GVAR(composePin) = [];
        GVAR(composePinPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
};

// The template's own name is the card's header now - its tag box and title,
// FUNC(composeCardHead) - so it is said here only for the plain box.
private _priority = _template getOrDefault ["priority", "normal"];
if (_templateId isEqualTo "") then {
    [_root, [_dx + _dw * 0.5, _y, _dw * 0.5 - _pad, _btnH], "PLAIN MESSAGE", _mute, TEXT_BODY, true, "right", true] call FUNC(drawText);
};

_y = _y + _btnH + _padY;
[_root, [_dx + _pad, _y, _dw - 2 * _pad, RULE_THIN * pixelH], _line] call FUNC(drawFill);
_y = _y + _padY * 2;

// ------------------------------------------------------------- the content --
private _footH = _btnH + _padY * 3;
private _contentH = _h - _footH - _y;

if (_templateId isEqualTo "") then {
    // ---------------------------------------------------------- the map pin --
    // A REPORT ANCHORS ON A FIELD; A MESSAGE HAS NOTHING TO POINT AT. The deck's
    // cards carry a `grid` field and name it in `anchor`, which is what pins the
    // thread to the map. A plain message has one text box, so the pin is
    // thread-level state - GVAR(composePin) - and travels BESIDE the payload
    // rather than in it: EFUNC(messaging,validate) drops any key the template
    // does not declare, so a pin smuggled in as a field would be thrown away on
    // the way to the server. See EFUNC(messaging,srvThreadFor).
    private _pinned = GVAR(composePin) isNotEqualTo [];
    private _pinW = _dw * 0.24;

    [
        _root, [_dx + _pad, _y, _dw - 2 * _pinW - 4 * _pad, _btnH],
        // if/then, not select: select evaluates both halves, and mapGridPosition of
        // an empty pin threw on every redraw with no pin set (rpt 2026-10-08).
        if (_pinned) then {format ["MAP PIN - %1", mapGridPosition GVAR(composePin)]} else {"MAP PIN - NONE"},
        [_mute, _accent] select _pinned, TEXT_LABEL, true, "left", true
    ] call FUNC(drawText);

    // One button for both halves: pinning where you stand and taking the pin
    // off again are the same press twice.
    private _hereX = _dx + _dw - 2 * _pinW - 2 * _pad;
    [_root, [_hereX, _y, _pinW, _btnH], [_line, _accent] select _pinned, [RULE_THIN, RULE_THICK] select _pinned] call FUNC(drawFrame);
    [_root, [_hereX + _pad, _y, _pinW - 2 * _pad, _btnH], ["CURRENT LOC", "CLEAR PIN"] select _pinned, [_ink, _accent] select _pinned, TEXT_LABEL, true, "center"] call FUNC(drawText);
    [_root, [_hereX, _y, _pinW, _btnH], {
        [] call FUNC(composeHarvest);
        // Pinned where his GPS says he is (jmfsb_ew_fnc_gpsHere): the false
        // fix when spoofed, no pin and a word on the rail when denied.
        GVAR(composePin) = if (GVAR(composePin) isNotEqualTo []) then {[]} else {
            if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[true] call EFUNC(ew,gpsHere)}
        };
        GVAR(composePinPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);

    // The same marker list the deck's grid fields offer, so a man who has
    // already drawn the spot on his map does not read a grid off it and retype
    // it into a sentence.
    private _mkX = _dx + _dw - _pinW - _pad;
    private _pickOpen = GVAR(composePinPick);
    [_root, [_mkX, _y, _pinW, _btnH], [_line, _accent] select _pickOpen, [RULE_THIN, RULE_THICK] select _pickOpen] call FUNC(drawFrame);
    [_root, [_mkX + _pad, _y, _pinW - 2 * _pad, _btnH], "MAP MARKER", [_ink, _accent] select _pickOpen, TEXT_LABEL, true, "center"] call FUNC(drawText);
    [_root, [_mkX, _y, _pinW, _btnH], {
        [] call FUNC(composeHarvest);
        GVAR(composePinPick) = !GVAR(composePinPick);
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);

    _y = _y + _btnH + _padY;

    if (GVAR(composePinPick)) then {
        private _markers = [8] call FUNC(markerGrids);
        if (_markers isEqualTo []) then {
            [_root, [_dx + _pad * 2, _y, _dw - 3 * _pad, _rowH * 0.9], "NO MAP MARKERS", _dim, TEXT_BODY] call FUNC(drawText);
            _y = _y + _rowH * 0.9;
        } else {
            {
                _x params ["_label", "_pos"];
                private _my = _y + _forEachIndex * _rowH * 0.9;
                [_root, [_dx + _pad * 2, _my, _dw * 0.5, _rowH * 0.9], _label, _ink, TEXT_BODY] call FUNC(drawText);
                [_root, [_dx + _dw * 0.55, _my, _dw * 0.4 - _pad, _rowH * 0.9], mapGridPosition _pos, _mute, TEXT_BODY, false, "right"] call FUNC(drawText);
                [_root, [_dx + _pad, _my + _rowH * 0.9 - RULE_THIN * pixelH, _dw - 2 * _pad, RULE_THIN * pixelH], _line] call FUNC(drawFill);
                private _hitP = [_root, [_dx + _pad, _my, _dw - 2 * _pad, _rowH * 0.9], {
                    params ["_ctrl"];
                    [] call FUNC(composeHarvest);
                    private _at = _ctrl getVariable [QGVAR(markerPos), []];
                    if (_at isEqualTo []) exitWith {};
                    GVAR(composePin) = _at;
                    GVAR(composePinPick) = false;
                    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
                }] call FUNC(drawHit);
                _hitP setVariable [QGVAR(markerPos), _pos];
            } forEach _markers;
            _y = _y + (count _markers) * _rowH * 0.9;
        };
        _y = _y + _padY;
    };

    // The box takes whatever the pin row and its list left.
    _contentH = _h - _footH - _y;

    // The plain message. One field, and it is the one the freetext template
    // already defines - the key is read off the template rather than spelled
    // here, so renaming the line cannot break sending.
    private _key = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];

    [_root, [_dx + _pad, _y, _dw - 2 * _pad, _rowH], "MESSAGE", _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);

    private _boxY = _y + _rowH;
    private _boxH = _contentH - _rowH - _padY;

    [_root, [_dx + _pad, _boxY, _dw - 2 * _pad, _boxH], _line, RULE_THIN] call FUNC(drawFrame);

    private _multi = ["RscEdit", "RscEditMulti"] select (isClass (configFile >> "RscEditMulti"));
    private _edit = _display ctrlCreate [_multi, -1, _root];
    _edit ctrlSetPosition [_dx + _pad * 2, _boxY + _padY, _dw - 4 * _pad, _boxH - 2 * _padY];
    _edit ctrlSetBackgroundColor [0, 0, 0, 0];
    _edit ctrlSetTextColor _ink;
    _edit ctrlSetFontHeight _fontH;
    _edit ctrlSetText (GVAR(composeValues) getOrDefault [_key, ""]);
    _edit setVariable [QGVAR(fieldKey), _key];
    _edit ctrlCommit 0;
} else {
    [[_dx, _dw, _y, _contentH]] call FUNC(composeCard);
};

// ------------------------------------------------------------------ send ----
private _sendY = _h - _footH + _padY;
[_root, [_dx + _pad, _sendY - _padY, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);

// SEND IS AN INK CELL, the handoff's: the accent is the hover, not the rest
// state - a card is mostly accent-free so REQ and a high-priority tag read.
// Hover is accent-600 (the theme's accentHover), set on the fill itself by the
// hit and its label, since a label over a hit takes the mouse as well.
private _sendW = _dw * 0.22;
private _sendFill = [_root, [_dx + _pad, _sendY, _sendW, _btnH], _ink] call FUNC(drawFill);
private _sendLabel = [
    _root, [_dx + _pad * 2, _sendY, _sendW - 3 * _pad, _btnH],
    ["SEND", "SEND - FLASH"] select (_priority isEqualTo "high"),
    _ground, TEXT_TITLE, true, "center"
] call FUNC(drawText);
private _sendHit = [_root, [_dx + _pad, _sendY, _sendW, _btnH], {
    [] call FUNC(composeHarvest);
    [] call FUNC(composeSend);
}] call FUNC(drawHit);

{
    _x setVariable [QGVAR(hoverFill), _sendFill];
    _x ctrlAddEventHandler ["MouseEnter", {
        params ["_ctrl"];
        (_ctrl getVariable [QGVAR(hoverFill), controlNull]) ctrlSetBackgroundColor (["accentHover"] call FUNC(theme));
    }];
    _x ctrlAddEventHandler ["MouseExit", {
        params ["_ctrl"];
        (_ctrl getVariable [QGVAR(hoverFill), controlNull]) ctrlSetBackgroundColor (["ink"] call FUNC(theme));
    }];
} forEach [_sendHit, _sendLabel];

// WHY IT WOULD NOT SEND, where the press was. Anything else is behind this
// screen - see FUNC(composeSend).
//
// The link state stands in the same spot before the press: the player with a
// finger over SEND is the one player who needs to know the send will crawl or
// bounce. A refusal that has already happened still outranks it. There is no
// "* REQUIRED" legend any more - required is the REQ meta inside the field,
// which needs no key to read.
private _hint = "";
([] call EFUNC(messaging,linkState)) params ["_link"];
if (_link > 0) then {
    _hint = ["LINK DEGRADED - SENDS TRANSMIT LATE", "LINK NONET - POSITION JAMMED"] select (_link > 1);
};
if (GVAR(composeError) isNotEqualTo "") then {
    _hint = toUpper GVAR(composeError);
};

[
    _root, [_dx + _sendW + _pad * 3, _sendY, _dw - _sendW - _pad * 4, _btnH],
    _hint,
    ([_mute, _accent] select (GVAR(composeError) isNotEqualTo "" || _link > 0)),
    TEXT_LABEL, true, "right", true
] call FUNC(drawText);
