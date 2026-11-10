#include "script_component.hpp"
/*
 * Author: YonV
 * The composer's verdict on a support card before SEND (user, 2026-11-02;
 * first for a call for fire to a battery: in range, danger close, time of
 * flight, CANTCO and why) and its footprint on the player's map - asked of
 * the support core (EFUNC(support,cardPreview)), which reads the card the
 * server's way and draws the footprint as local markers. The server still
 * decides when the card is filed.
 *
 * ON A CHANGE, NEVER PER FRAME. Asked by every draw of the pane and by every
 * keystroke in a card's box, it asks the core again only when the address,
 * the card or a value has changed since the last ask; otherwise it hands back
 * the last answer. A keystroke writes the line beside SEND in place - the
 * line FUNC(composePane) drew for it, when nothing else stands there - so the
 * box being typed in keeps its focus. While there is an answer, a slow poll
 * (FUNC(composeFireTick)) clears the footprint once the composer is gone.
 *
 * Arguments:
 * 0: Write the line beside SEND in place - a keystroke <BOOL> (optional, default false)
 *
 * Return Value:
 * [ok, line], [] for none <ARRAY>
 *
 * Example:
 * ([] call jmfsb_tacpad_fnc_composeFire) params [["_ok", true], ["_line", ""]]
 *
 * Public: No
 */

params [["_inPlace", false, [false]]];

if (isNil QEFUNC(support,cardPreview)) exitWith {[]};

private _live = GVAR(composeOn) && GVAR(composeThread) isEqualTo "" && GVAR(composeTemplate) isNotEqualTo "";
private _key = [_live, GVAR(composeTo), GVAR(composeTemplate), GVAR(composeValues) toArray false];
if (_key isNotEqualTo GVAR(composeFireKey)) then {
    GVAR(composeFireKey) = _key;
    if (_live) then {
        GVAR(composeFire) = [GVAR(composeTo), GVAR(composeTemplate), GVAR(composeValues)] call EFUNC(support,cardPreview);
    } else {
        GVAR(composeFire) = [] call EFUNC(support,cardPreview);
    };
    if (GVAR(composeFire) isNotEqualTo []) then {[true] call FUNC(composeFireTick)};
};

if (_inPlace) then {
    private _hint = uiNamespace getVariable [QGVAR(composeHint), controlNull];
    if (isNull _hint || {!(_hint getVariable [QGVAR(fireHint), false])}) exitWith {};
    ([] call FUNC(theme)) params ["", "", "_accent"];
    GVAR(composeFire) params [["_ok", true, [true]], ["_line", "", [""]]];
    [_hint, _line, [_accent, ["muted"] call FUNC(theme)] select _ok, TEXT_LABEL, true, "right", true] call FUNC(retext);
};

+GVAR(composeFire)
