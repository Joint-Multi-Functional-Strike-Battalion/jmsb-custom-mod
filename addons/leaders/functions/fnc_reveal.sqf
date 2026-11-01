#include "script_component.hpp"
/*
 * Author: JMSB
 * The interrogation pays out: ONE other leader's current safe house, exactly.
 *
 * The only moment the chain gives a position rather than a circle - and it is
 * bought with a live prisoner rather than a hack, which is why it is allowed
 * to be exact.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

private _up = GVAR(leaders) select {
    (_x select 2) isEqualTo "up" && {!isNull (_x select 0)}
};

if (_up isEqualTo []) exitWith {
    ["INTERROGATION", "He had nobody left to give up."] call EFUNC(notify,broadcast);
};

private _pick = selectRandom _up;
private _at = getPosATL (_pick select 0);

// The map marker is hacking's intel product, sent by remoteExec from the
// server (review S7). Hacking is optional for leaders: without it the
// prisoner still talks, but nothing is drawn.
if (!isNil "jmfsb_hacking_fnc_sendProduct") then {
    ["icons",
        format [QGVAR(reveal_%1), round CBA_missionTime],
        [[+_at, "mil_warning"]], "ColorRed", GVAR(asymSide) call {
            // The players' side, not the insurgency's: the reveal is for whoever
            // took him, and every player hostile to the chain qualifies.
            private _s = playerSide;
            {
                if ((side group _x) getFriend GVAR(asymSide) < 0.6) exitWith {
                    _s = side group _x;
                };
            } forEach allPlayers;
            _s
        }] call jmfsb_hacking_fnc_sendProduct;
};

["INTERROGATION", "He talked. Another leader's location is on your map."]
    call EFUNC(notify,broadcast);

INFO_1("interrogation revealed a leader at %1",mapGridPosition _at);
