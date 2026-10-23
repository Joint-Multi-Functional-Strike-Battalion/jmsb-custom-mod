#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_register: puts a node in the registry, or updates it. Idempotent by id -
 * an adapter registers again whenever the set's object, profile or fill
 * changes (respawn, new radio, plan arrived), and the node keeps its state.
 *
 * On a client this forwards to the server (CBA server event) and returns the
 * id it sent, generating one when none was given.
 *
 * Nets are the fill: each entry a net id, or [net id, key] for a set that
 * holds a key other than its side's (a captured set, a tap). A bare id takes
 * the side's key at mesh time (jmfsb_rf_fnc_nodeKey).
 *
 * The holder is the man whose client gets this node's slice; it defaults to
 * the object when that is a man. A vehicle set registered by a crewman names
 * him.
 *
 * Data is the node's extra-data field: [[key, value], ...] merged into what
 * the node already carries, for whatever reads nodes later (EW reads "intent":
 * comms / data / video / jam / spoof / decoy). RF stores it and hands it to the
 * listener hooks; it never acts on it. jmfsb_rf_fnc_setState "data" changes it
 * later. A re-registration keeps keys it does not name.
 *
 * Arguments:
 * 0: Object the antenna is on (unit, vehicle or prop) <OBJECT>
 * 1: Profile id <STRING>
 * 2: Nets <ARRAY of STRINGs or [STRING, STRING]>
 * 3: Node id (optional, default "" = generate) <STRING>
 * 4: Owner, the mod that registered it (optional, default "") <STRING>
 * 5: Holder (optional, default the object when it is a man) <OBJECT>
 * 6: Side (optional, default the object's) <SIDE>
 * 7: Data (optional, default []) <ARRAY of [STRING, ANY] or HASHMAP>
 *
 * Return Value:
 * Node id, "" when refused <STRING>
 *
 * Example:
 * [player, "handheld", ["DATA", "ALPHA"], "node_a", "my_adapter"] call jmfsb_rf_fnc_register
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_profile", "", [""]],
    ["_nets", [], [[]]],
    ["_id", "", [""]],
    ["_owner", "", [""]],
    ["_holder", objNull, [objNull]],
    ["_side", sideUnknown, [west]],
    ["_data", [], [[], createHashMap]]
];

if (_id isEqualTo "") then {_id = "rf_" + ([] call FUNC(newKey))};

if (!isServer) exitWith {
    [QGVAR(register), [_object, _profile, _nets, _id, _owner, _holder, _side, _data]] call CBA_fnc_serverEvent;
    _id
};

if (isNull _object) exitWith {
    WARNING_1("register %1 refused: no object",_id);
    ""
};
if !(_profile in GVAR(profiles)) exitWith {
    WARNING_2("register %1 refused: no profile %2",_id,_profile);
    ""
};

if (isNull _holder && {_object isKindOf "CAManBase"}) then {_holder = _object};
if (_side isEqualTo sideUnknown) then {
    _side = if (isNull group _object) then {side _object} else {side group _object};
};

private _fill = [];
{
    if (_x isEqualType "") then {
        _fill pushBackUnique [_x, ""];
    } else {
        _x params [["_net", "", [""]], ["_key", "", [""]]];
        if (_net isNotEqualTo "") then {_fill pushBackUnique [_net, _key]};
    };
} forEach _nets;

private _node = GVAR(nodes) getOrDefault [_id, createHashMap];
if (count _node == 0) then {
    private _relay = (GVAR(profiles) get _profile) get "relayCapable";
    _node = createHashMapFromArray [
        ["id", _id],
        ["state", createHashMapFromArray [
            ["on", true],
            ["tx", false],
            ["relay", _relay],
            ["activeNet", ""],
            ["monitorNet", ""],
            ["emcon", 0]
        ]],
        ["battery", 1],
        ["ai", false],
        ["data", createHashMap]
    ];
    GVAR(nodes) set [_id, _node];
    TRACE_2("node registered",_id,_profile);
};

_node set ["object", _object];
_node set ["profile", _profile];
_node set ["nets", _fill];
_node set ["owner", _owner];
_node set ["holder", _holder];
_node set ["hasHolder", !isNull _holder];
_node set ["side", str _side];
if (_data isEqualType []) then {_data = createHashMapFromArray _data};
(_node get "data") merge [_data, true];

_id
