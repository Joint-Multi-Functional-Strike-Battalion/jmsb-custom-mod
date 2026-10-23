// TROOPS IN CONTACT, ON A KEY.
//
// NUMPAD 9 BY DEFAULT (user, 2026-10-20, docs/SPEC_TACNET.json D16: "9 TIC").
// It was unbound (user, 2026-09-01: "leave the key empty let the player set
// it") until the numpad became the device's key block: 1-4 the device keys,
// 0 / . the arrows, 5 the tablet, 6 the radio app, 7 / 8 tabs, 9 TIC. Still a
// CBA keybind, so a player rebinds or clears it in Configure Addons. The device
// dialog passes it through while the tablet is up (jmfsb_devices_fnc_keyDown),
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

[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(ticKey),
    ["Troops In Contact", "Files a contact report from where you stand: marks the map, alerts your side and files the thread on the command net. The same button that is under the reader on the map screen. Numpad 9 by default."],
    {
        [true] call FUNC(ticSend);
        true
    },
    {false},
    [DIK_NUMPAD9, [false, false, false]]
] call CBA_fnc_addKeybind;
