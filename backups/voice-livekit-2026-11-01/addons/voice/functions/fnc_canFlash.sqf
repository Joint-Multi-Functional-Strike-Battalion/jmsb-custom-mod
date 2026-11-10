#include "script_component.hpp"
/*
 * Author: YonV
 * Server: whether a player may make a FLASH call that bumps a ROUTINE one -
 * the RTO (FUNC(isRto), the one RTO test: the RTO console is a player job,
 * user 2026-10-20) or a logged-in admin. The permission table's "C2 / A2G,
 * calls, bump" row (docs/DESIGN_VOICE.md), the same right the tablet's CALLS
 * offers FLASH by.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * May bump <BOOL>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_canFlash
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};
if ((admin (owner _unit)) > ADMIN_NONE) exitWith {true};
// The mod's admins by the SERVER'S OWN records (jmfsb_common_fnc_senderIsAdmin:
// #login, the host, the server's admin list), not the public admin flag the
// client-side gate (FUNC(canManageNets)) draws by - any client can write that
// flag, so it is for screens only (review S7). The srv* functions that ask
// this are reached by remoteExec and have checked the sender is this unit's
// machine (jmfsb_common_fnc_senderIs). The server's own re-run of a bumped
// call (FUNC(srvCallTick)) is not remote executed, where senderIsAdmin passes
// everyone, so it is asked only for a remote call. The host of a hosted game,
// whom `admin` does not count, is the line below (user, 2026-10-24: "the make
// new channel did not work").
if (isRemoteExecuted && {[] call EFUNC(common,senderIsAdmin)}) exitWith {true};
if (hasInterface && {_unit isEqualTo player}) exitWith {true};
[_unit] call FUNC(isRto)
