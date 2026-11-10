#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_playerJoin

Description:
    A player has connected: seed the record (or not, per settings
    newPlayers), open the attendance session, and publish. Server only.

    Called by the PlayerConnected handler (XEH_postInit) once the store is
    loaded, and by the boot for every connect it held back while loading -
    those pass false for publish, because the boot publishes once after.

    NEW PLAYERS: settings newPlayers (2026-09-10). "auto" seeds a record the
    moment they arrive; "apply" does not - they apply from the tacpad's PAC
    tile (or the website) and an admin accepts them under APPLICATIONS,
    which is what seeds the record. Somebody already on the roster is never
    touched by the setting.

Parameters:
    0: UID <STRING>
    1: Name <STRING>
    2: Publish afterwards <BOOL> (optional, default true)

Returns:
    Nothing

Example:
    [getPlayerUID player, name player] call jmfsb_pac_fnc_playerJoin

Public: No

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_uid", "", [""]], ["_name", "", [""]], ["_publish", true, [true]]];

if (!isServer || _uid isEqualTo "") exitWith {};

private _mode = toLower (GVAR(settings) getOrDefault ["newPlayers", "auto"]);
if (_mode isEqualTo "apply" && {!(_uid in GVAR(players))}) then {
    INFO_2("%1 (%2) connected and is not on the roster - newPlayers is 'apply', no record seeded",_name,_uid);
} else {
    [_uid, _name] call FUNC(record);
};
[_uid, _name] call FUNC(sessionStart);
if (_publish) then {[] call FUNC(publish)};
