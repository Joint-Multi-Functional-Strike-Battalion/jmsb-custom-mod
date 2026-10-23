#include "script_component.hpp"
/*
 * Author: JMSB
 * OUR PTT: a JMSB keybind (or the tablet's PTT, later) keys or releases a
 * TFAR tangent through TFAR's own key handlers - the same functions TFAR's
 * keybinds call (core/functions/events/keys/fnc_on*TangentPressed.sqf), so
 * TFAR's own rules hold: one tangent at a time, the half-second guard after
 * a long-range key, no radio in hand = nothing.
 *
 *   sr     active net          TFAR_fnc_onSwTangentPressed / Released
 *   srAlt  alternate net       TFAR_fnc_onAdditionalSwTangentPressed / Released
 *   lr     long range net      TFAR_fnc_onLRTangentPressed / Released
 *   lrAlt  long range alt net  TFAR_fnc_onAdditionalLRTangentPressed / Released
 *
 * RF DOES NOT GATE THE KEY. A net with no link still keys: what RF thinks of
 * the link is already on TFAR's sending lever, set by fnc_tangent on TFAR's
 * OnBeforeTangent, so a cut net goes out at a few metres instead of being
 * refused. The two checks made here are TFAR's own, made first so its
 * "unable to use radio" and single-player popups never show: they would not
 * have keyed anyway.
 *
 * A key is pressed once and released once: the CBA keybind and the
 * sprint/modifier hook (fnc_pttKey) can both see the same press.
 *
 * Arguments:
 * 0: Action: "sr" | "srAlt" | "lr" | "lrAlt" <STRING>
 * 1: Down (true) or up (false) <BOOL>
 *
 * Return Value:
 * false - the key is not consumed, as TFAR's own handlers return <BOOL>
 *
 * Example:
 * ["sr", true] call jmfsb_adapter_tfar_fnc_ptt
 *
 * Public: Yes
 */

params [["_action", PTT_SR, [""]], ["_down", true, [false]]];

if (!hasInterface || {isNil "TFAR_fnc_onSwTangentPressed"}) exitWith {false};

if (_down) exitWith {
    if (GVAR(pttHeld) isNotEqualTo "") exitWith {false};
    if (!isMultiplayer || {!(call TFAR_fnc_isAbleToUseRadio)}) exitWith {false};
    // TFAR's own key is down: its tangent is not ours to release.
    if (missionNamespace getVariable ["TF_tangent_sw_pressed", false] || {missionNamespace getVariable ["TF_tangent_lr_pressed", false]}) exitWith {false};
    GVAR(pttHeld) = _action;
    switch (_action) do {
        case PTT_SR: {call TFAR_fnc_onSwTangentPressed};
        case PTT_SR_ALT: {call TFAR_fnc_onAdditionalSwTangentPressed};
        case PTT_LR: {call TFAR_fnc_onLRTangentPressed};
        case PTT_LR_ALT: {call TFAR_fnc_onAdditionalLRTangentPressed};
    };
    false
};

if (GVAR(pttHeld) isNotEqualTo _action) exitWith {false};
GVAR(pttHeld) = "";
switch (_action) do {
    case PTT_SR: {call TFAR_fnc_onSwTangentReleased};
    case PTT_SR_ALT: {call TFAR_fnc_onAdditionalSwTangentReleased};
    case PTT_LR: {call TFAR_fnc_onLRTangentReleased};
    case PTT_LR_ALT: {call TFAR_fnc_onAdditionalLRTangentReleased};
};
false
