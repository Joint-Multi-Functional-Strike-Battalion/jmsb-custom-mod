#include "script_component.hpp"
/*
 * Author: YonV
 * In-game diagnostic: logs to the RPT which system carries the voice
 * (jmfsb_voice_system; under "none" only that, voice unavailable) and the
 * voice state of the local player (adapter, nets, nodes, active net, cut-off level, roster,
 * calls), then hands over to the adapter's "selfTest" hook - for VON, the five "Tests to run first" of
 * docs/DESIGN_VOICE.md, each logged as it runs: setPlayerVoNVolume per
 * speaker, enableChannel voice-off still hears, getPlayerChannel speed,
 * custom channel add / remove delay, Vehicle channel crew only. Some need a
 * second player and take a few seconds; the RPT lines say what to do.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_selfTest
 *
 * Public: Yes
 */

INFO_4("selfTest: voice system %1, game voice active %2 (setting %3; loaded %4)",GVAR(system),GVAR(active),GVAR(defaultSystem),GVAR(loaded));
if (!hasInterface || isNull player) exitWith {
    WARNING("selfTest needs a player");
};
if (!GVAR(active)) exitWith {
    WARNING_1("selfTest: no game-voice system here (%1): voice unavailable",GVAR(system));
};

INFO_2("selfTest: adapter %1, %2 players",GVAR(adapterId),count allPlayers);
INFO_2("selfTest: RF nodes %1, plan nets %2",GVAR(myNodes),count GVAR(plan));
{
    INFO_1("selfTest: net %1",_x);
} forEach ([] call FUNC(netState));
INFO_2("selfTest: active %1, radio silence %2",GVAR(activeNetId),GVAR(blocked));
INFO_3("selfTest: cut-off level %1 (%2), keyed on %3",GVAR(level),GVAR(blockReason),GVAR(keyNet));
INFO_2("selfTest: roster rows %1, calls %2",count GVAR(roster),count GVAR(callTable));
INFO_1("selfTest: slots %1",[] call FUNC(callSlots));

[] call HOOK("selfTest");
