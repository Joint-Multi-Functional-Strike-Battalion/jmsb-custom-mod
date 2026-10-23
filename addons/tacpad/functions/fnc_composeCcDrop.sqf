#include "script_component.hpp"
/*
 * Author: JMSB
 * The @ completions under the CC line, rebuilt on every keystroke.
 *
 * IT MUST NOT REDRAW THE PANE. Every other interaction on this screen ends in a
 * FUNC(readerDraw), which throws the whole content group away - and that group
 * holds the box being typed into, its text and the caret in it. So the list is a
 * group of its own, deleted and remade in place: nothing else on the pane is
 * touched, and the player types straight through it.
 *
 * ON KeyUp, NOT KeyDown. The engine puts the character in the box between the
 * two, so a completion built on the way down is always one letter behind what is
 * on screen. FUNC(composeCard) drives its live preview off the same event for the
 * same reason.
 *
 * NEWEST IN THE GROUP IS TOPMOST, which is why the list is created here rather
 * than reserved at draw time: it has to cover the rows it drops over.
 *
 * Arguments:
 * 0: The CC edit <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_cc] call jmfsb_tacpad_fnc_composeCcDrop
 *
 * Public: No
 */

params [["_ctrl", controlNull, [controlNull]]];

if (isNull _ctrl) exitWith {};

private _display = ctrlParent _ctrl;
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

// Last keystroke's list goes first. Deleting the group takes its rows with it and
// leaves the edit alone, which is the whole point of it being a group.
private _old = _ctrl getVariable [QGVAR(ccList), controlNull];
if (!isNull _old) then {ctrlDelete _old};
_ctrl setVariable [QGVAR(ccList), controlNull];

// The token being completed is the last one on the line, and only while it is
// still an @ name - so a name already picked is not offered all over again on
// every keystroke that follows it.
private _pieces = (ctrlText _ctrl) splitString ",";
if (_pieces isEqualTo []) exitWith {};

private _last = trim (_pieces select -1);
if ((_last select [0, 1]) isNotEqualTo "@") exitWith {};

private _frag = toUpper (trim (_last select [1]));

// PREFIX, NOT CONTAINS. A list that reorders itself as the middle of a word
// starts matching is a list nobody can aim at. A bare @ matches everything,
// which is how the line answers "who can I even send this to".
private _matches = ([] call FUNC(composeTargets)) select {
    ((_x # 1) select [0, count _frag]) isEqualTo _frag
};
if (_matches isEqualTo []) exitWith {};

// Six deep. A CC is a handful of names, and a drop that reaches the message box
// hides the thing being written.
if (count _matches > 6) then {_matches = _matches select [0, 6]};

private _drop = _ctrl getVariable [QGVAR(ccDrop), []];
if (_drop isEqualTo []) exitWith {};

_drop params ["_dx", "_dy", "_dw", "_rowH"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _pad = PAD * HOST_W;

// OPAQUE, whatever the player's map opacity is. The theme's ground carries that
// opacity, and a see-through dropdown over the rows it covers cannot be read.
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];

private _listH = _rowH * count _matches;

private _list = _display ctrlCreate [QGVAR(panel), -1, _root];
_list ctrlSetPosition [_dx, _dy, _dw, _listH];
_list ctrlCommit 0;
_ctrl setVariable [QGVAR(ccList), _list];

[_list, [0, 0, _dw, _listH], _solid] call FUNC(drawFill);
[_list, [0, 0, _dw, _listH], _accent, RULE_THIN] call FUNC(drawFrame);

{
    _x params ["_id", "_label"];
    private _ry = _forEachIndex * _rowH;

    // WHAT KIND OF THING IT IS. REAPER is a squad, HQ is a mailbox, and a CC to
    // the wrong one of two similar names goes to the wrong tablets.
    private _kind = switch (_id select [0, 2]) do {
        case "G:": {"SQUAD"};
        case "P:": {"MAN"};
        default {"NET"};
    };

    [_list, [_pad, _ry, _dw * 0.68, _rowH], _label, _ink, TEXT_BODY] call FUNC(drawText);
    [_list, [_dw * 0.7, _ry, _dw * 0.3 - _pad, _rowH], _kind, _mute, TEXT_LABEL, true, "right", true] call FUNC(drawText);

    private _hit = [_list, [0, _ry, _dw, _rowH], {
        params ["_row"];

        private _edit = _row getVariable [QGVAR(ccEdit), controlNull];
        if (isNull _edit) exitWith {};

        // THE FRAGMENT IS REPLACED, NOT APPENDED TO. Half the name is already on
        // the line, and a second copy of it is not a CC.
        private _text = ctrlText _edit;
        private _at = -1;
        {
            if (_x isEqualTo "@") then {_at = _forEachIndex};
        } forEach (_text splitString "");

        private _head = "";
        if (_at >= 0) then {_head = _text select [0, _at]};

        // The trailing separator is the invitation to type the next one.
        private _newText = format ["%1@%2, ", _head, _row getVariable [QGVAR(ccPick), ""]];
        GVAR(composeCc) = _newText;
        _edit ctrlSetText _newText;

        // NEXT FRAME. This list holds the button whose handler is running, and
        // deleting a control between the press and the release is what ate the
        // reader's close button for six builds. The keyboard goes back to the box
        // the press took it from, because the next name is typed straight after
        // this one.
        [{
            params ["_group", "_edit"];
            if (!isNull _group) then {ctrlDelete _group};
            _edit setVariable [QGVAR(ccList), controlNull];
            ctrlSetFocus _edit;
        }, [_row getVariable [QGVAR(ccGroup), controlNull], _edit]] call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(ccEdit), _ctrl];
    _hit setVariable [QGVAR(ccGroup), _list];
    _hit setVariable [QGVAR(ccPick), _label];
} forEach _matches;
