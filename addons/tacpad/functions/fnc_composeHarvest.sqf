#include "script_component.hpp"
/*
 * Author: YonV
 * Reads everything typed on the compose pane into the answer map.
 *
 * IT IS CALLED BEFORE EVERY REDRAW, and that is the whole point of it. The pane
 * is thrown away and rebuilt on every press - picking a choice, opening a marker
 * list, inserting a template - and a rebuilt pane has new edits with nothing in
 * them. Without this, ticking a box halfway down a 9-line wiped the eight lines
 * above it, which the old compose form did on every single press.
 *
 * THE ADDRESS IS NOT HARVESTED. TO is pressed rather than typed - on the reader's
 * left rail, or in the picker behind CHANGE - so there is no control to read it
 * off, and the branch that used to try was left over from a typed TO field that
 * nothing has created for a long time. The CC line beside it IS typed, and is.
 *
 * A GRID THE PLAYER DID NOT TYPE IS A POSITION. CURRENT LOC and the marker list
 * store a real position so the thread anchors somewhere the map can pin, and the
 * text they were shown as is kept beside it - if the edit still reads as it was
 * shown, the position stands; if it has been typed over, the typing wins.
 *
 * ONLY CONTROLS THAT HOLD TEXT ARE READ, and this is load-bearing. A field's
 * fieldKey is on its EDIT and on every HIT AREA that answers it - a bool tick,
 * a choice segment, CURRENT LOC, MAP MARKER - because the press handlers need
 * to know which key they are setting. ctrlText on a hit area is always "", and
 * an empty read here means "the player cleared it", so this walked the card
 * deleting the answer behind every button on it. Three symptoms, one cause
 * (user, 2026-09-03):
 *
 *   - setting CASEVAC line 4 cleared line 5, and setting 5 cleared 4
 *   - SEND cleared the location and then refused the report for not having one
 *   - any tick or choice was wiped by the next press anywhere on the card
 *
 * FUNC(composeCard) marks the one control per field that actually holds typing.
 * A hit area is skipped here and keeps its fieldKey for the handler that needs
 * it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_composeHarvest
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

{
    private _ctrl = _x;

    if (_ctrl getVariable [QGVAR(tagField), false]) then {
        GVAR(composeTags) = ctrlText _ctrl;
        continue;
    };

    // THE CC LINE, AND NOT INTO composeTo. It is kept as the player typed it -
    // "@HQ, @REAPER" - and resolved to mailbox ids at the send; writing it into
    // the addressee would replace who the message is FOR with who is copied on
    // it. See FUNC(composeCcIds).
    if (_ctrl getVariable [QGVAR(ccField), false]) then {
        GVAR(composeCc) = ctrlText _ctrl;
        continue;
    };

    // Not an edit - a tick, a segment, CURRENT LOC, MAP MARKER. It carries a
    // fieldKey for its own press handler and holds no text to read.
    if !(_ctrl getVariable [QGVAR(fieldEdit), false]) then {continue};

    private _key = _ctrl getVariable [QGVAR(fieldKey), ""];
    if (_key isEqualTo "") then {continue};

    private _text = trim (ctrlText _ctrl);

    // An emptied box is an unanswered field, not an empty string - otherwise a
    // cleared required field still passes validation.
    if (_text isEqualTo "") then {
        GVAR(composeValues) deleteAt _key;
        GVAR(composeValues) deleteAt (_key + MARKER_NAME_SUFFIX);
        GVAR(composeGridText) deleteAt _key;
        continue;
    };

    if (_text isEqualTo (GVAR(composeGridText) getOrDefault [_key, ""])) then {continue};

    // Typed over: the grid is his own now, no marker's name with it.
    GVAR(composeGridText) deleteAt _key;
    GVAR(composeValues) deleteAt (_key + MARKER_NAME_SUFFIX);
    GVAR(composeValues) set [_key, _text];
} forEach (allControls _display);
