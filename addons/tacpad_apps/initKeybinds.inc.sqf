// TROOPS IN CONTACT, ON A KEY.
//
// NUMPAD - BY DEFAULT (user, 2026-10-30: "- is tic"; it was numpad 9 from
// 2026-10-20, docs/SPEC_TACNET.json D16, until 6-9 became the device keys).
// It was unbound (user, 2026-09-01: "leave the key empty let the player set
// it") until the numpad became the device's key block. Still a CBA keybind,
// so a player rebinds or clears it in Configure Addons. The device dialog
// passes it through while the tablet is up (jmfsb_devices_fnc_keyDown),
// because CBA's keys do not reach the mission display under a dialog.
//
// SAME CODE PATH AS THE MAP BUTTON - see FUNC(ticSend), which is where the
// send, the command-net check and the shared cooldown live. Pressing this with
// the map open and pressing the cell on the map are the same action.
//
// LOUD ON REFUSAL. The cell on the map draws its own reasons - NO COMMAND NET
// CONFIGURED, SENT - 12s - because it is being looked at. A key has no screen,
// so a refusal has to say itself.
//
// DIK_NUMPAD9 and friends: JMSB's macro header does not pull the key codes in.
#include "\a3\ui_f\hpp\definedikcodes.inc"

// F10 BY DEFAULT since the F-row layout (user, 2026-11-08); numpad - in the
// numpad layout. The device's key layout names it (jmfsb_devices_fnc_keyDefault).
private _ticKey = [DIK_SUBTRACT, [false, false, false]];
if (!isNil QEFUNC(devices,keyDefault)) then {_ticKey = [QGVAR(ticKey), _ticKey] call EFUNC(devices,keyDefault)};
[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(ticKey),
    ["Troops In Contact", "Files a contact report from where you stand: marks the map, alerts your side and files the thread on the command net. The same button that is under the reader on the map screen. While a call is ringing you, it answers the call instead. F10 by default (numpad layout: Numpad -)."],
    {
        // A RINGING CALL FIRST (user, 2026-10-24: "press ... 9 on the key pad to
        // answer"): the devices addon answers it when one rings; otherwise TIC.
        if (!isNil QEFUNC(devices,voiceAnswer) && {[] call EFUNC(devices,voiceAnswer)}) exitWith {true};
        [true] call FUNC(ticSend);
        true
    },
    {false},
    _ticKey
] call CBA_fnc_addKeybind;
