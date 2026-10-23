#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "audience": every player VON lets hear a speaker on a net's
 * channel - so each can set his volume, including those who must hear him
 * at 0. Group: the players of his Arma group (with a set or not); Vehicle:
 * the players aboard his vehicle (passengers too); a custom channel: every
 * player on any net that rides it (all C2-kind nets share the C2 channel).
 * Direct and the rest: nobody (never touched). He is not in it.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Players <ARRAY>
 *
 * Example:
 * [player, "C2"] call jmfsb_adapter_von_fnc_audience
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (isNull _unit) exitWith {[]};
private _ch = [_net] call FUNC(channel);

private _out = switch (true) do {
    case (_ch isEqualTo CH_GROUP): {(units group _unit) select {isPlayer _x}};
    case (_ch isEqualTo CH_VEHICLE): {
        private _vehicle = vehicle _unit;
        [(crew _vehicle) select {isPlayer _x}, []] select (_vehicle isEqualTo _unit)
    };
    case (_ch > CH_DIRECT): {
        private _key = [_net] call FUNC(channelKey);
        allPlayers select {
            _x isKindOf "CAManBase" && {(([_x] call EFUNC(voice,nets)) findIf {([_x select 0] call FUNC(channelKey)) isEqualTo _key}) >= 0}
        }
    };
    default {[]};
};
_out - [_unit]
