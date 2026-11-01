#include "script_component.hpp"
/*
 * Author: JMSB
 * TFAR'S RADIO UI OFF (setting "Hide TFAR's radio UI"): the radio UI is ours -
 * the HUD's RADIO widget and the tablet's net row and RADIO app.
 *
 * Done with TFAR's own client settings, TFAR_UI_SETTINGS
 * (TFAR_showTransmittingHint, TFAR_showChannelChangedHint): TFAR reads each at
 * the moment it would draw the popup, so with them false it never draws it.
 * They are set for this session only - in missionNamespace, where TFAR reads
 * them - not through CBA, so the player's own saved choice is untouched: it is
 * kept here (GVAR(tfarUiKept)) and put back when the setting goes off. When
 * the player changes one of them in Addon Options while ours is on, his new
 * value is kept and the override put back (CBA_SettingChanged, XEH_postInit).
 *
 * Not covered by a TFAR setting, and so left alone: TFAR's radio dialogs (a
 * player opens those on purpose), the "unable to use" and in-water popups
 * from TFAR's own keys (ours check first and do not ask TFAR), and TFAR's
 * voice-server connection warnings (diagnostics, not radio UI). The radio card
 * TFAR draws without a setting (cycling radios, its dialogs' speaker and
 * additional-channel buttons) is taken down a frame later by TFAR_fnc_hideHint
 * on TFAR's own events (TFAR_UI_EVENTS, XEH_postInit).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_tfarUi
 *
 * Public: No
 */

if (!hasInterface || {!GVAR(uiReady)}) exitWith {};

if (GVAR(hideTfarUi)) then {
    {
        if !(_x in GVAR(tfarUiKept)) then {
            GVAR(tfarUiKept) set [_x, missionNamespace getVariable [_x, true]];
        };
        missionNamespace setVariable [_x, false];
    } forEach TFAR_UI_SETTINGS;
} else {
    {
        if (_x in GVAR(tfarUiKept)) then {
            missionNamespace setVariable [_x, GVAR(tfarUiKept) get _x];
            GVAR(tfarUiKept) deleteAt _x;
        };
    } forEach TFAR_UI_SETTINGS;
};
TRACE_1("tfar ui hidden",GVAR(hideTfarUi));
