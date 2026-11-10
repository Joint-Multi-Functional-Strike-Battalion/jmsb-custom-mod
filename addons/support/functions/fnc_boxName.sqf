#include "script_component.hpp"
/*
 * Author: YonV
 * What an asset's mailbox reads as on this machine: its call sign
 * (docs/DESIGN_SUPPORT_MESSAGING.md decision D1, 2026-11-01). TAC//MSG draws
 * "B:SUPPORT:cas:0" through here wherever it shows a box - the TO line, the
 * rail, a thread's header, the FLASH banner - so the JTAC reads HOG, not an id.
 *
 * WORKED OUT ON THE VIEWER'S MACHINE, NOT KEPT ON THE BOX. The server's box
 * record has a display name, but no index row carries it to a client, and the
 * server cannot learn a call sign by itself: `assets` answers for `player`,
 * which a dedicated server has none of (FUNC(srvCallsign)). The viewer's own
 * rows already name every asset he can address, so the name is read from
 * them - at most once per BOX_NAMES_POLL seconds, however many boxes a draw
 * asks for - and remembered, so a box whose asset has since gone still reads
 * as the name it was filed under.
 *
 * Arguments:
 * 0: Box id - "B:SUPPORT:<assetId>", or the bare "SUPPORT:<assetId>" <STRING>
 *
 * Return Value:
 * The call sign; the asset id upper-cased when no row has named it (what the
 * server answers under then); "" when the box is not an asset's <STRING>
 *
 * Example:
 * ["B:SUPPORT:cas:0"] call jmfsb_support_fnc_boxName
 *
 * Public: Yes
 */

params [["_boxId", "", [""]]];

if !((_boxId select [0, 2]) in BOX_PREFIXES) then {
    _boxId = BOX_PREFIX_SHARED + _boxId;
};

private _head = count SUPPORT_BOX_PREFIX;
if ((toUpper (_boxId select [0, _head])) isNotEqualTo SUPPORT_BOX_PREFIX) exitWith {""};

private _assetId = _boxId select [_head];
if (_assetId isEqualTo "") exitWith {""};

if (hasInterface && diag_tickTime >= GVAR(boxNamesDue)) then {
    GVAR(boxNamesDue) = diag_tickTime + BOX_NAMES_POLL;
    {
        _x params [["_id", "", [""]], "", ["_callsign", "", [""]]];
        if (_id isNotEqualTo "" && _callsign isNotEqualTo "") then {
            GVAR(boxNames) set [_id, _callsign];
        };
    } forEach (call FUNC(assets));
};

GVAR(boxNames) getOrDefault [_assetId, toUpper _assetId]
