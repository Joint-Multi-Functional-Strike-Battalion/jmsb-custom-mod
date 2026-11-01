#include "script_component.hpp"
/*
 * Author: JMSB
 * Fills both slots with whatever they are set to.
 *
 * DRAWN WITH THE TACPAD'S OWN VOCABULARY - drawFill, drawFrame, drawText - so
 * the HUD and the map screens cannot drift apart in type, rule weight or colour.
 * There is one design in this mod and one implementation of it; a HUD that
 * merely resembled the panels would be a second design nobody maintained.
 *
 * BUILT ONCE, UPDATED IN PLACE (review P5 / R8). The readouts no longer make
 * controls; they push draw ops - the same helper arguments they always passed -
 * onto a list, and FUNC(paint) makes the controls the first time and only
 * changes text, colour and size on the ticks after, rebuilding when the slot's
 * key or the list's shape changes. The controls are kept on the slot control,
 * so nothing walks the mission display to find them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_hud_fnc_draw
 *
 * Public: No
 */

// IT RAISES THE HUD IF IT IS NOT UP. The slots are controls on the mission
// display now, so there is a window at mission start where there is nothing to
// draw on yet - and the keybinds only ever call this, never FUNC(open). A draw
// that merely gave up there was a HUD that stayed dead for the whole mission
// however many times the player pressed Shift + [. This runs once a second off
// the tick in XEH_postInit, so a HUD that fails to come up on the first attempt
// comes up on the next one.
private _display = uiNamespace getVariable [QGVAR(display), displayNull];
if (isNull _display) then {
    [] call FUNC(open);
    _display = uiNamespace getVariable [QGVAR(display), displayNull];
};
if (isNull _display) exitWith {};

// NOTHING IS REBUILT BEHIND A SCREEN, AND THAT IS THE HALF OF THE ADMIN-CONSOLE
// FIX THAT MATTERS. A rebuild creates fresh controls; run while a dialog is
// open, every pass that did put them back on top of it - which is why the
// SCANNER tile printed over the console's own rows however the slots were
// hidden. FUNC(setShown) redraws on the way back, so a skipped pass here costs
// nothing but the work.
if ([] call FUNC(hidden)) exitWith {};

private _theme = [] call EFUNC(tacpad,theme);
_theme params ["_ground", "_ink", "_accent", "_line"];

// EVERYTHING THE LOOK HANGS ON THAT IS NOT IN THE OPS THEMSELVES - the scheme,
// the ground's opacity, the type scale and the host it is set against, and
// the screen's own units. Any of them moving rebuilds the slot outright, so a
// scheme or scale change is never left to the in-place path.
private _look = [
    _theme, GVAR(opacity), EGVAR(tacpad,textScale), EGVAR(tacpad,uiScale), EGVAR(tacpad,host),
    [safeZoneW, safeZoneH, pixelW, pixelH, pixelGrid]
];

{
    private _slot = _x;
    private _ctrl = _display displayCtrl ([IDC_HUD_LEFT, IDC_HUD_RIGHT] select _slot);
    if (isNull _ctrl) then {continue};

    ([_slot] call FUNC(slotState)) params ["_ring", "_i"];
    (_ring select _i) params ["_id", "_label", "_drawer", ["_when", {true}]];

    // OFF, or a readout that has nothing to say right now - the APS tile on
    // foot. The slot control itself is hidden as well as emptied, so nothing
    // of it - not its outline, not its hit area - is on the screen. Shown
    // again here, because FUNC(setShown) shows both slots and then calls
    // this, so this is the last word on each slot. Emptied by painting no ops
    // under a key of its own, which deletes what was there once and is a
    // no-op on every tick after.
    private _vacant = _id isEqualTo "off" || {!(call _when)};
    _ctrl ctrlShow !_vacant;
    if (_vacant) then {
        [_ctrl, [_id], []] call FUNC(paint);
        continue;
    };

    // THE LAYOUT EDITOR'S BOX, READ EVERY DRAW. The control was placed by its
    // grid expression when the layer was created; moving or resizing it in
    // Options > Game > Layout changes only the profile variables, and nothing
    // raises an event about it - so a slot that was ever moved kept drawing at
    // its creation-time size, which is the screenshot's "not resized". The
    // handset re-reads its grid every time it lays out - see
    // EFUNC(hacking,scannerLayout) - and this is the same rule.
    private _grid = ["grid_jmfsb_hudLeft", "grid_jmfsb_hudRight"] select _slot;
    private _pos = ctrlPosition _ctrl;
    {
        private _v = profileNamespace getVariable [format ["IGUI_%1_%2", _grid, _x], ""];
        if (_v isEqualType 0) then {_pos set [_forEachIndex, _v]};
    } forEach ["X", "Y", "W", "H"];
    // Moved only when the box did - the same position and commit as before,
    // just not sent to the engine sixty times a minute when nothing moved.
    if (_pos isNotEqualTo (_ctrl getVariable [QGVAR(box), []])) then {
        _ctrl ctrlSetPosition _pos;
        _ctrl ctrlCommit 0;
        _ctrl setVariable [QGVAR(box), _pos];
    };

    // The ground, at the player's own opacity. A HUD that cannot be seen through
    // at all is a window blocked off; one that cannot be read is decoration.
    private _w = _pos # 2;
    private _h = _pos # 3;

    private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
    private _pad = PAD * safeZoneW;
    private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

    // THE TILE AS A LIST OF DRAW OPS, ground first - see FUNC(paint), which
    // turns it into controls once and then only changes what changed.
    private _ops = [
        [HUD_OP_FILL, [[0, 0, _w, _h], [_ground # 0, _ground # 1, _ground # 2, GVAR(opacity)]]],
        [HUD_OP_FRAME, [[0, 0, _w, _h], _ink, RULE_THIN]],
        // The heading names the readout, because a slot that can show three
        // things has to say which one it is showing.
        [HUD_OP_TEXT, [[_pad, 0, _w - 2 * _pad, _rowH], _label, _mute, 0.62, true, "left", true]],
        [HUD_OP_FILL, [[_pad, _rowH, _w - 2 * _pad, RULE_THIN * pixelH], _line]]
    ];

    [_ops, _rowH * 1.3, _w, _h] call _drawer;

    [_ctrl, [_id, _pos] + _look, _ops] call FUNC(paint);
} forEach [HUD_SLOT_LEFT, HUD_SLOT_RIGHT];
