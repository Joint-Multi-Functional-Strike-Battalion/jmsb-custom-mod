#include "script_component.hpp"
/*
 * Author: YonV
 * Server: whether the remote-executed request now running may act on this
 * node (review R1) - the sender holds it (its holder is a unit of the sending
 * machine, or the node was registered to the sender's Steam id, so a respawn
 * keeps it his), or the sender is an admin. The server's own calls pass.
 *
 * Worked out from remoteExecutedOwner here rather than through jmfsb_common,
 * which this core addon does not require; the admin test is common's when it
 * is loaded.
 *
 * Arguments:
 * 0: Node <HASHMAP>
 *
 * Return Value:
 * May act on it <BOOL>
 *
 * Example:
 * [_node] call jmfsb_rf_fnc_mayTouch
 *
 * Public: No
 */

params [["_node", createHashMap, [createHashMap]]];

if (!isRemoteExecuted || {remoteExecutedOwner isEqualTo SERVER_OWNER}) exitWith {true};

private _holder = _node getOrDefault ["holder", objNull];
if (!isNull _holder && {(owner _holder) isEqualTo remoteExecutedOwner}) exitWith {true};

private _players = allPlayers;
private _i = _players findIf {(owner _x) isEqualTo remoteExecutedOwner};
private _uid = if (_i < 0) then {""} else {getPlayerUID (_players select _i)};
if (_uid isNotEqualTo "" && {_uid isEqualTo (_node getOrDefault ["holderUid", ""])}) exitWith {true};

!isNil QEFUNC(common,senderIsAdmin) && {[] call EFUNC(common,senderIsAdmin)}
