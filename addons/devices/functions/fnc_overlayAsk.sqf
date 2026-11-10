#include "script_component.hpp"
/*
 * Author: YonV
 * The walking view's quick-answer strip, as structured text (user, 2026-11-06:
 * "using 6-9 when the phone is open and not the tablet ... the choice should be
 * displayed on the phone till answered"). Two lines over the map, above the
 * call strip:
 *
 *   RAVEN  READY TO LAND - CLEARED?                         1 OF 2
 *   NUM 6 CLEARED TO LAND   NUM 7 HOLD   NUM 8 ABORT        NUM 0/. 1/2
 *
 * Who asks in bold - red when FLASH - then what; which question of how many
 * wait. Then each device key as the player has it bound (F1-F4, numpad 5-8 by
 * default) with its answer, and the page keys (numpad 0 / .) with the page
 * when there is more than one. After a press: SENT and the word, until the
 * answer comes back. A crew's list reads ASK <requester>. Data from
 * jmfsb_tacpad_fnc_askView; "" when nothing is on the keys.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Structured text, "" for none <STRING>
 *
 * Example:
 * private _line = [] call jmfsb_devices_fnc_overlayAsk
 *
 * Public: No
 */

if (isNil QEFUNC(tacpad,askView)) exitWith {""};
private _view = [] call EFUNC(tacpad,askView);
if (_view isEqualTo createHashMap) exitWith {""};

private _fnc_safe = {[_this] call EFUNC(tacpad,xmlSafe)};
private _fnc_key = {
    params ["_label"];
    private _key = [format ["%1_%2", QGVAR(button), _label]] call FUNC(keyLabel);
    [_key, toUpper _label] select (_key in [KEY_LABEL_UNBOUND, KEY_LABEL_NONE])
};

private _mode = _view get "mode";
private _who = toUpper (_view get "who");
private _head = switch (_mode) do {
    case ASK_VIEW_CREW: {format [ASK_CREW_HEAD, _who]};
    default {_who};
};
private _whoColour = [HTML_TEXT, HTML_TX] select (_view get "flash");
private _first = format ["<t font='RobotoCondensedBold' color='%1'>%2</t> <t color='%3'>%4</t>",
    _whoColour, _head call _fnc_safe, HTML_TEXT, (toUpper (_view get "text")) call _fnc_safe];
if ((_view get "of") > 1) then {
    _first = _first + format [" <t color='%1'>%2 OF %3</t>", HTML_DIM, _view get "n", _view get "of"];
};

private _sent = _view get "sent";
private _second = if (_sent isNotEqualTo "") then {
    format ["<t color='%1'>SENT</t> <t font='RobotoCondensedBold' color='%2'>%3</t>", HTML_DIM, HTML_OK, _sent call _fnc_safe]
} else {
    private _parts = [];
    {
        if (_x isEqualTo "") then {continue};
        _parts pushBack format ["<t color='%1'>%2</t> <t font='RobotoCondensedBold' color='%3'>%4</t>",
            HTML_DIM, [ASK_KEY_LABELS select _forEachIndex] call _fnc_key, HTML_TEXT, _x call _fnc_safe];
    } forEach (_view get "words");
    if ((_view get "pages") > 1) then {
        _parts pushBack format ["<t color='%1'>%2/%3 %4/%5</t>", HTML_DIM,
            [ASK_PAGE_LABELS select 0] call _fnc_key, [ASK_PAGE_LABELS select 1] call _fnc_key,
            _view get "page", _view get "pages"];
    };
    _parts joinString "   "
};

format ["%1<br/>%2", _first, _second]
