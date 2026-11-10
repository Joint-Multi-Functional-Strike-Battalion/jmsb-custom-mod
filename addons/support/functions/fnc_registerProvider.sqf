#include "script_component.hpp"
/*
 * Author: YonV
 * Registers a support provider: one kind of asset source (the CAS drone
 * modules, support_air, support_fires, support_logistics, jumpmaster) that
 * lists rows on TAC//SUPPORT and executes the tasks it is given.
 *
 * THE CORE KNOWS NO ASSET KIND. Everything kind-specific - what a row is, what
 * a task does, which tasks exist and what they ask for - is in the declaration
 * handed over here. The full contract is addons/support/README.md.
 *
 * Call it on EVERY machine (postInit), not only the server: the screen is drawn
 * on the client and reads its rows locally. Registering a kind again replaces
 * the earlier declaration.
 *
 * Arguments:
 * 0: Kind - the asset-id prefix the provider's ids carry, no ":" <STRING>
 * 1: Declaration <HASHMAP>
 *    "assets"    <CODE> [] -> rows (required)
 *    "task"      <CODE> [assetId, task, pos, params] -> [ok, why, cooldown] (required)
 *    "sitrep"    <CODE> [assetId] -> [ok, line] (optional)
 *    "available" <CODE> [assetId] -> [ok, why] (optional)
 *    "tasks"     <CODE> [assetId, row] -> task declarations (optional)
 *    "preview"   <CODE> [assetId, task, pos, params] -> [ok, line] (optional)
 *    "overlay"   <CODE> [assetId, row] -> map shapes (optional)
 *    "reach"     <CODE> [assetId, pos] -> [can, eta, why, effect, tasks] (optional, 2026-11-01;
 *                without it the assets are NOT AVAILABLE in the TO picker, 2026-11-02)
 *    "side"      <CODE> [assetId] -> SIDE, server-safe (optional, 2026-11-01)
 *    "thread"    <CODE> [assetId, thread, root message, issuer] -> [ok, why], [] not its card - server (optional, 2026-11-01)
 *    "reply"     <CODE> [assetId, thread, message, issuer, word] - server (optional, 2026-11-01)
 *    "cardPreview" <CODE> [assetId, order] -> [ok, line, marker specs], [] none - the
 *                composer's preview before SEND, client (optional, 2026-11-02; FUNC(cardPreview))
 *    "types"   <ARRAY> of type declarations (optional)
 *    "status"  <CODE> [assetId, threadId] -> [vehicle, task text, minutes left on
 *                station (-1 none)] - the STATUS REPLY's facts, server (optional,
 *                2026-11-09; FUNC(statusReply))
 *    "threadCards" <ARRAY> [[root card id, [card ids]], ...] - the root cards
 *                it takes as a new task inside a thread opened with that root
 *                (a re-task, a NEXT LIFT); FUNC(threadCards) (optional, 2026-11-02)
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * ["cas", createHashMapFromArray [["assets", {[]}], ["task", {[false, "no"]}]]] call jmfsb_support_fnc_registerProvider
 *
 * Public: Yes
 */

params [["_kind", "", [""]], ["_decl", createHashMap, [createHashMap]]];

if (_kind isEqualTo "" || {ID_SEP in _kind}) exitWith {
    WARNING_1("registerProvider: refused - kind '%1' is empty or contains the id separator",_kind);
    false
};

if !((_decl getOrDefault ["assets", 0]) isEqualType {} && {(_decl getOrDefault ["task", 0]) isEqualType {}}) exitWith {
    WARNING_1("registerProvider: refused - '%1' has no assets or no task code",_kind);
    false
};

{
    if (!((_decl getOrDefault [_x, {}]) isEqualType {})) then {
        WARNING_2("registerProvider: '%1' key '%2' is not code - ignored",_kind,_x);
        _decl deleteAt _x;
    };
} forEach ["sitrep", "available", "tasks", "preview", "overlay", "reach", "side", "thread", "reply", "cardPreview", "status"];

if !((_decl getOrDefault ["types", []]) isEqualType []) then {
    WARNING_1("registerProvider: '%1' types is not an array - ignored",_kind);
    _decl deleteAt "types";
};

if (_kind in GVAR(providers)) then {
    INFO_1("registerProvider: '%1' registered again - the new declaration replaces the old",_kind);
};

GVAR(providers) set [_kind, _decl];
GVAR(badRowSaid) = GVAR(badRowSaid) - [_kind];
INFO_2("registerProvider: '%1' registered (%2)",_kind,keys _decl);

true
