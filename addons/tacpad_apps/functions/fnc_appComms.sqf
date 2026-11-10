#include "script_component.hpp"
/*
 * Author: YonV
 * The full comms app, opened over the map. This is the only place a message can
 * be sent - the docked reader can show a thread beside the map, but it cannot
 * answer one.
 *
 * That split is deliberate and it is the whole reason this exists as a separate
 * screen. Reading wants the map underneath it; sending wants room, and it wants
 * a deliberate act. A quick reply fired off a rail you were only scanning is
 * how a WILCO ends up on somebody else's task.
 *
 * The quick-reply row is the handoff's six-up, mapped onto the messaging
 * engine's own reply templates - so what the button offers and what the server
 * will accept are the same list. A reply the thread's state does not allow is
 * not drawn.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 * 1: App id <STRING>
 * 2: Arguments - [threadId], "" to start from the list <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_app", "", [""]], ["_args", [], [[]]]];

if (isNull _display) exitWith {};

private _threadId = _args param [0, ""];

private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []];
private _subject = if (_cached isEqualTo []) then {"NEW MESSAGE"} else {(_cached # 0) get "subject"};

// Centred, and deliberately not full screen: the map stays visible around it,
// so closing the app is not the only way to see where you are.
([_display, format ["COMMS - %1", toUpper _subject], 0.46, 0.62] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

private _row = 0;

if (_cached isEqualTo []) then {
    // No thread means this was reached by NEW. Composing lives in the reader's
    // right pane now, which is where the traffic and the map are - this hands
    // over rather than growing a second composer nobody would maintain.
    [_body, _row, "COMPOSE OPENS IN TAC//MSG", "", [], true, {
        ["", "", false] call EFUNC(tacpad,composeOpen);
    }] call FUNC(row);
    _row = _row + 1;
    [_body, _row, "The message box, the deck and SEND are the reader's right pane.", "", [], false] call FUNC(row);
} else {
    _cached params ["_thread", "_messages"];

    {
        private _message = _x;
        [
            _body,
            _row,
            _message get "fromCallsign",
            ([_message get "templateId"] call EFUNC(messaging,template)) getOrDefault ["short", ""],
            [],
            (_message get "priority") == "high"
        ] call FUNC(row);
        _row = _row + 1;

        {
            if (_x != "") then {
                [_body, _row, _x, "", [], false] call FUNC(row);
                _row = _row + 1;
            };
        } forEach ([_message get "templateId", _message get "payload", false] call EFUNC(messaging,render) splitString endl);
    } forEach _messages;

    // THE QUICK REPLIES. Asked of the engine rather than listed here, so a
    // button is only ever offered when the server would actually accept it -
    // the reader's own rule (2026-11-02, jmfsb_tacpad_fnc_threadLegal): an
    // asset's own cards to its thread's issuer, never the asset's words.
    private _replies = [_threadId, _thread] call EFUNC(tacpad,threadLegal);

    _row = _row + 1;
    [_body, _row, "REPLY", "", [], true] call FUNC(row);
    _row = _row + 1;

    {
        private _template = [_x] call EFUNC(messaging,template);

        // A reply with fields of its own opens the card rather than sending
        // blank, so the row says which kind of press it is going to be.
        private _hasFields = (_template getOrDefault ["order", []]) isNotEqualTo [];

        private _ctrl = [
            _body,
            _row,
            _template get "title",
            ["", "OPENS THE CARD"] select _hasFields,
            [],
            false,
            {
                params ["", "_ctrl"];
                private _t = _ctrl getVariable [QGVAR(replyTemplate), ""];
                private _th = _ctrl getVariable [QGVAR(replyThread), ""];
                if (_t == "" || _th == "") exitWith {};

                // A reply with fields of its own is a card to fill in, and the
                // card is the reader's right pane.
                if (_ctrl getVariable [QGVAR(replyNeedsForm), false]) exitWith {
                    [_th, _t, false] call EFUNC(tacpad,composeOpen);
                };

                [_t, [], [], _th] call EFUNC(messaging,submit);

                // The shell's variable, not this addon's - see FUNC(appHack).
                // Asking for jmfsb_tacpad_apps_appGroup got controlNull, so this
                // button deleted nothing and the app would not close.
                private _g = uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull];
                if (!isNull _g) then {ctrlDelete _g};
                uiNamespace setVariable [QEGVAR(tacpad,appGroup), controlNull];

                [_th, {[] call EFUNC(tacpad,rebuild)}] call EFUNC(messaging,open);
            }
        ] call FUNC(row);

        _ctrl setVariable [QGVAR(replyTemplate), _x];
        _ctrl setVariable [QGVAR(replyThread), _thread get "id"];
        _ctrl setVariable [QGVAR(replyNeedsForm), _hasFields];

        _row = _row + 1;
    } forEach _replies;
};
