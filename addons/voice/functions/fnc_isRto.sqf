#include "script_component.hpp"
/*
 * Author: JMSB
 * THE RTO TEST - the one place that says whether a man holds the RTO job.
 * The RTO console (the RADIO app's MANAGE and the permission table's RTO
 * column) is a player job, not admins only (user, 2026-10-20), so everything
 * that asks "is he the RTO" asks this: the voice contacts' RTO tag, the FLASH
 * right (FUNC(canFlash)) and the tablet's radio role
 * (jmfsb_tacpad_apps_fnc_radioRole).
 *
 * WHAT MAKES HIM THE RTO, any one of:
 *   - the RTO flag on him (RTO_FLAG, "isRTO"): a PAC skill effect
 *     ("trait:isRTO" or "var:isRTO=true", from his own skills or his role's
 *     granted skills) or the mission's own setVariable;
 *   - an RTO skill tag from PAC (its abbreviation, jmfsb_pac_skillTags);
 *   - his slot's role description names a radio job (RTO_WORDS, whole words
 *     of the part before any @).
 * THE JOB IS THE SLOT'S OR PAC'S (user, 2026-10-20: "can we lose the LR"):
 * there are no man packs at all since 2026-10-21, so the RTO is the man PAC
 * (the flag or the tag) or his slot says he is.
 * Admins are not RTOs by this test: the admin column is asked separately.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * He holds the RTO job <BOOL>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_isRto
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};
if ((_unit getVariable [RTO_FLAG, false]) isEqualTo true) exitWith {true};
if (TAG_RTO in (_unit getVariable [QEGVAR(pac,skillTags), []])) exitWith {true};

// "HQ RTO@Crossroads": only the part before the @ is the role
private _described = ((toUpper roleDescription _unit) splitString ROLE_GROUP_MARK) param [0, ""];
private _words = _described splitString ROLE_WORD_SPLIT;
(RTO_WORDS findIf {_x in _words}) >= 0
