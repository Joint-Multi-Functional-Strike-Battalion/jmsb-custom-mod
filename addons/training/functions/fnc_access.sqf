#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a man may use TAC//TRAINING (user, 2026-11-07): on the training
 * server, a player with the Trainer skill or a rank of Sergeant and up.
 *
 * The training server is the one whose TAC//PAC serverId is "training"; the
 * skill is PAC's Trainer, read off the tags PAC puts on the man
 * (jmfsb_pac_skillTags); the rank is the Arma rank PAC sets from his PAC rank.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * May use the app <BOOL>
 *
 * Example:
 * [player] call jmfsb_training_fnc_access
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

private _settings = missionNamespace getVariable [QEGVAR(pac,settings), createHashMap];
if !(_settings isEqualType createHashMap) exitWith {false};
if ((_settings getOrDefault ["serverId", ""]) isNotEqualTo TRAINING_SERVER) exitWith {false};

(TRAINER_TAG in (_unit getVariable [QEGVAR(pac,skillTags), []]))
    || {ARMA_RANK_INDEX(rank _unit) >= ARMA_RANK_INDEX(TRAINER_MIN_RANK)}
