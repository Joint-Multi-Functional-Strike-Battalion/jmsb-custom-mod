// CBA Keybinds [ADDON: jmfsb_adapter_tfar]
// OUR PTT AND NET KEYS, in Configure Addons > 1st Joint Multi-Functional
// Strike Battalion. Each PTT key calls TFAR's own tangent handler for that
// tangent (fnc_ptt).
//
// DEFAULTS: unbound - TFAR's own PTT keybinds (CapsLock, T, Ctrl+CapsLock,
// Ctrl+T) stay as they are, and TFAR has no setting to turn them off, so a
// default here would key the same tangent twice from one key. A PTT key takes
// TFAR's default only when TFAR's own keybind for that tangent has been left
// with no key, read here at mission start: unbind TFAR's, and ours picks the
// key up next mission. A key the player sets himself is his either way.
// Not hold keys (CBA's holdKey false, as TFAR's own PTT): one press, one call.

{
    _x params ["_action", "_tfarAction", "_name", "_tfarDefault"];
    private _tfarKeybind = ["TFAR", _tfarAction] call CBA_fnc_getKeybind;
    private _tfarKeys = if (isNil "_tfarKeybind") then {[]} else {_tfarKeybind param [8, [], [[]]]};
    private _tfarBound = (_tfarKeys findIf {(_x param [0, 0]) > 0}) >= 0;
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(ptt), _action],
        [_name, "Keys the radio while held, through TFAR. A net RF cannot reach still keys; the link quality sets how far it carries. Unbound by default while TFAR's own key for this is bound."],
        compile format ["['%1', true] call %2", _action, QFUNC(ptt)],
        compile format ["['%1', false] call %2", _action, QFUNC(ptt)],
        [NO_KEY, _tfarDefault] select !_tfarBound,
        false
    ] call CBA_fnc_addKeybind;
} forEach PTT_KEYS;

{
    _x params ["_kind", "_step", "_action", "_name"];
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QUOTE(ADDON), _action],
        [_name, "Moves the set to the next or previous net it is filled with."],
        compile format ["['%1', %2] call %3; true", _kind, _step, QFUNC(stepNet)],
        {false},
        NO_KEY,
        false
    ] call CBA_fnc_addKeybind;
} forEach NET_STEP_KEYS;
