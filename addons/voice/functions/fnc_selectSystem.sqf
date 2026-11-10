#include "script_component.hpp"
/*
 * Author: YonV
 * Decides which system carries the voice (jmfsb_voice_system: "livekit" or
 * "von", "none" when the server's cannot run here; jmfsb_voice_active: a
 * game-voice system is running - the core's own nets, calls and cut-offs)
 * from a choice and what this machine has loaded (jmfsb_voice_loaded: the
 * voice server's adapter when its extension answers), then puts that
 * system's adapter in use (FUNC(applyAdapter)).
 *
 * THE VOICE SERVER IS THE VOICE (user, 2026-10-31: "livekit was to be the
 * VON", "no in-game VON"). Automatic is the voice server when its extension is
 * here, else the game's VON - the fallback for a machine without the
 * extension. Mumble and LiveKit are both system "livekit" (one adapter, one
 * extension; which server is adapter_livekit's to read from the setting). A
 * system chosen but not loaded falls back to Automatic, with a warning; Game
 * VON by choice runs whatever is loaded. TFAR and ACRE were removed (DEC1,
 * 2026-10-31): a server or profile that still holds "tfar" or "acre" gets
 * Automatic, with a warning.
 *
 * Called in XEH_preInit with Automatic, so every reader has an answer before
 * the settings are in (and again by adapter_livekit's preInit once it has
 * announced itself), and at CBA_settingsInitialized with the setting
 * (jmfsb_voice_defaultSystem). THE SERVER'S ANSWER IS EVERYONE'S: a client
 * then follows the system the server published (FUNC(followServer), "none"
 * when it cannot run it), and only then does anything of any system start
 * (the jmfsb_voice_systemReady event).
 *
 * Arguments:
 * 0: Choice: "auto", "mumble", "livekit", "von" or "none" <STRING> (default: "auto")
 *
 * Return Value:
 * The system chosen <STRING>
 *
 * Example:
 * ["auto"] call jmfsb_voice_fnc_selectSystem
 *
 * Public: No
 */

params [["_choice", SYSTEM_AUTO, [""]]];

private _auto = [SYSTEM_VON, SYSTEM_LIVEKIT] select (SYSTEM_LIVEKIT in GVAR(loaded));

private _system = _auto;
switch (true) do {
    // the server's system cannot run here (FUNC(followServer))
    case (_choice isEqualTo SYSTEM_NONE): {_system = SYSTEM_NONE};
    case (_choice isEqualTo SYSTEM_VON): {_system = SYSTEM_VON};
    // Mumble and LiveKit are both the voice server's adapter
    case (_choice in [SYSTEM_LIVEKIT, SYSTEM_MUMBLE] && {SYSTEM_LIVEKIT in GVAR(loaded)}): {_system = SYSTEM_LIVEKIT};
    case (_choice in [SYSTEM_LIVEKIT, SYSTEM_MUMBLE]): {
        WARNING_2("voice: %1 chosen but not loaded - Automatic: %2 carries the voice",_choice,_auto);
    };
    // DEC1: a stored "tfar" / "acre" (or anything else unknown) is Automatic
    case (_choice isNotEqualTo SYSTEM_AUTO): {
        WARNING_2("voice: %1 is not a voice system (TFAR and ACRE removed, DEC1) - Automatic: %2 carries the voice",_choice,_auto);
    };
};

private _changed = _system isNotEqualTo (missionNamespace getVariable [QGVAR(system), ""]);
GVAR(system) = _system;
GVAR(active) = _system in SYSTEM_GAME_IDS;
if (_changed) then {
    if (GVAR(active)) then {
        INFO_3("voice: %1 carries the voice (choice %2, loaded %3)",_system,_choice,GVAR(loaded));
    } else {
        WARNING_1("voice: none - the server's system cannot run here (loaded %1): voice unavailable",GVAR(loaded));
    };
};
[] call FUNC(applyAdapter);
_system
