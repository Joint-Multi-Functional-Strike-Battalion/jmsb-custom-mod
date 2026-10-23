#include "script_component.hpp"

// The plan's nets are made in RF by jmfsb_pac (fnc_netPlanSync); nothing here
// runs on a dedicated server.

// CLIENT: this player's sets as RF nodes, state mirrored on change; the voice
// override (RF link quality onto TFAR's range levers); TFAR's own popups off;
// our PTT; and the voice API's view of his nets (fnc_poll).
if (hasInterface) then {
    ["CBA_settingsInitialized", {
        [{_this call FUNC(poll)}, POLL_S] call CBA_fnc_addPerFrameHandler;

        // TFAR's radio popups off (fnc_tfarUi), and kept off: a player who
        // changes one of TFAR's two hint settings has his new value kept for
        // when ours goes off, and the override put back.
        GVAR(uiReady) = true;
        [] call FUNC(tfarUi);
        ["CBA_SettingChanged", {
            params ["_setting", "_value"];
            if !(_setting in TFAR_UI_SETTINGS) exitWith {};
            if (_setting in GVAR(tfarUiKept)) then {GVAR(tfarUiKept) set [_setting, _value]};
            [] call FUNC(tfarUi);
        }] call CBA_fnc_addEventHandler;
    }] call CBA_fnc_addEventHandler;

    // His slice changed: the nets he hears got better or worse.
    [QEGVAR(rf,linkChanged), {[] call FUNC(applyVoice)}] call CBA_fnc_addEventHandler;

    // Another player keyed or released a set (pushed by him, fnc_tangent).
    [QGVAR(keyed), {_this call FUNC(keyed)}] call CBA_fnc_addEventHandler;

    // The tangent: the sending lever for the keyed net, RF's tx state, and the
    // key pushed to the others.
    [TFAR_EH_ID, "OnBeforeTangent", {((_this select [0, 5]) + [true]) call FUNC(tangent)}, objNull] call TFAR_fnc_addEventHandler;
    [TFAR_EH_ID, "OnTangent", {((_this select [0, 5]) + [false]) call FUNC(tangent)}, objNull] call TFAR_fnc_addEventHandler;

    // The radio card TFAR draws with no setting to ask (cycling radios, its
    // dialogs' speaker and additional-channel buttons): taken down with TFAR's
    // own TFAR_fnc_hideHint the frame after TFAR's event, since TFAR draws it
    // just after firing the event. Only these events, never every frame.
    {
        [TFAR_EH_ID, _x, {
            if (missionNamespace getVariable [QGVAR(hideTfarUi), false]) then {[{call TFAR_fnc_hideHint}] call CBA_fnc_execNextFrame};
        }, objNull] call TFAR_fnc_addEventHandler;
    } forEach TFAR_UI_EVENTS;

    // Our PTT and net keys.
    #include "initKeybinds.inc.sqf"

    // The PTT keys with extra modifiers held (sprinting): see fnc_pttKey.
    [{!isNull (findDisplay 46)}, {
        (findDisplay 46) displayAddEventHandler ["KeyDown", {(_this + [true]) call FUNC(pttKey)}];
        (findDisplay 46) displayAddEventHandler ["KeyUp", {(_this + [false]) call FUNC(pttKey)}];
    }] call CBA_fnc_waitUntilAndExecute;
};
