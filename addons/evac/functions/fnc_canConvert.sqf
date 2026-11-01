#include "script_component.hpp"
/*
 * Author: JMSB
 * Gate for the medic "Evacuate (Reinforce)" action. True only when the
 * target is a downed (ACE-unconscious) living player that hasn't already
 * been evacuated, and - if the Medics Only setting is on - the caller is an
 * ACE medic.
 *
 * The server runs it again for the sending medic (FUNC(evacServer), review
 * S6) without the claim flag: the client sets that flag before it asks, and
 * the server keeps its own guard.
 *
 * Arguments:
 * 0: The unit doing the evac (the interacting player) <OBJECT>
 * 1: The downed player being evacuated (the ACE target) <OBJECT>
 * 2: Skip the claim flag - the server's check (optional, default false) <BOOL>
 *
 * Return Value:
 * May evacuate <BOOL>
 *
 * Example:
 * [player, cursorTarget] call jmfsb_evac_fnc_canConvert
 *
 * Public: No
 */

params [["_medic", objNull, [objNull]], ["_casualty", objNull, [objNull]], ["_server", false, [false]]];

if !(GVAR(enabled)) exitWith { false };
// ACM brings its own evacuation; ours stands down behind it (see XEH_postInit).
if (missionNamespace getVariable [QEGVAR(patches,usesACM), false]) exitWith { false };
if (_medic isEqualTo _casualty) exitWith { false };
if !(isPlayer _casualty) exitWith { false };
if !(alive _casualty) exitWith { false };
if !(_casualty getVariable ["ACE_isUnconscious", false]) exitWith { false };
if (!_server && {_casualty getVariable [QGVAR(claimed), false]}) exitWith { false };
if (GVAR(medicOnly) && {!([_medic] call ace_medical_treatment_fnc_isMedic)}) exitWith { false };

true
