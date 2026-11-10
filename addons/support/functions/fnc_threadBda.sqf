#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the last BDA filed in a support thread (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 5: "the BDA answer is kept on the
 * thread and passed to the provider"). FUNC(srvFollowUp) keeps it on the
 * thread record when a `bda` card is passed on; a CAS provider reads it back
 * here for a re-attack - its target, when the BDA gave one, is where the
 * aircraft goes in again.
 *
 * Arguments:
 * 0: Thread id <STRING>
 *
 * Return Value:
 * The BDA as FUNC(readOrder) reads it (kind "bda": target, targetText,
 * effect, count, reattack, remarks) with "from" and "at"; empty when none
 * <HASHMAP>
 *
 * Example:
 * (["T0042"] call jmfsb_support_fnc_threadBda) getOrDefault ["target", []]
 *
 * Public: Yes
 */

params [["_threadId", "", [""]]];

if (!isServer || _threadId isEqualTo "") exitWith {createHashMap};

private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
+(_thread getOrDefault [THREAD_BDA, createHashMap])
