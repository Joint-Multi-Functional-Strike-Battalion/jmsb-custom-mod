#include "script_component.hpp"
/*
 * Author: YonV
 * Does an audience tag name this man?
 *
 * ONE RULE, BOTH ENDS. The server asks it of every player to find out who a tag
 * reaches (see FUNC(srvTagged)); a client asks it of itself to find out whether
 * the message that just arrived was addressed to it by name (see
 * FUNC(cltReceive)). If those two answers could ever differ, a player would be
 * pushed a message the alert stayed silent about - so there is one function and
 * they cannot.
 *
 * WHAT A TAG MAY BE, in the order it is tried:
 *   a job       MED reaches every medic, LDR every section commander - the same
 *               short tags FUNC(roleTag) stamps on traffic, so the tag you can
 *               see on a message is the tag you can address
 *   a squad     NOMAD 2-3 reaches everybody in that group
 *   a platoon   NOMAD reaches every squad the mission files under it - see
 *               FUNC(platoonTags). Without this a platoon was unaddressable:
 *               the groups are NOMAD 2-1 to 2-4 and nothing is called NOMAD, so
 *               waking a platoon on the platoon's own net took four tags
 *   a man       his call sign as the roster shows it, or his UID
 *
 * CASE AND SPACES ARE NOISE. A tag is typed in a hurry on a net; "nomad",
 * "NOMAD" and " Nomad " are the same tag, and a group called "Alpha 1-2" is
 * reachable as ALPHA1-2 as well, because nobody types the space the same way
 * twice.
 *
 * NOT ALERT LEVELS. FLASH and ROUTINE are the template's business - see
 * FUNC(registerTemplate) - and a sender who could type his own urgency would
 * type FLASH on everything by the third mission.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Tag <STRING>
 *
 * Return Value:
 * The tag names him <BOOL>
 *
 * Example:
 * private _hit = [player, "NOMAD"] call jmfsb_messaging_fnc_tagMatch
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_tag", "", [""]]];

if (isNull _unit) exitWith {false};

private _wanted = toUpper (trim _tag);
if (_wanted isEqualTo "") exitWith {false};

private _fnc_tight = {toUpper ((_this splitString " ") joinString "")};

// THE BACKEND DEFINES the composer's job chips lean on (user, 2026-09-03:
// "leaders medics, demo, isr, pilots, jfo"). Six trades, and a tag has to
// reach every man doing one of them wherever he stands - a CASEVAC calling
// MEDICS does not know whose medic.
//
// THREE SOURCES, ASKED IN THIS ORDER, because no single one is reliable across
// missions:
//
//   1. THE MISSION'S OWN FLAG, where it keeps one. isLeader, isJFO and isISR
//      are customVariables the role configs already set, and they are the same
//      flags the role screen and TAC//SUPPORT gate on.
//   2. AN ENGINE TRAIT, where the game carries one. medic and
//      explosiveSpecialist are set by every mission one way or another, so
//      these work on a mission that has never heard of jmfsb.
//   3. THE ROLE CLASS NAME. FUNC(setupPlayer) writes the chosen class to
//      YMF_role publicly, so pilotTalon answers PILOTS and demoBanshee answers
//      DEMO with no flag at all. This is what PILOTS runs on: nothing in the
//      framework sets isPilot, and roleDescription is not used here, so the
//      old check reached nobody.
//
// OLD NAMES STILL ANSWER. HQ was the leader tag and AVIATION the pilot one;
// traffic sent before the chips were renamed still resolves.
private _role = toUpper (_unit getVariable ["YMF_role", ""]);
private _fnc_roleHas = {_role find _this > -1};

private _defined = switch (_wanted) do {
    case "LEADER";
    case "LEADERS";
    case "LDR";
    case "HQ": {
        ((_unit getVariable ["isLeader", false]) isEqualTo true)
        || {"TEAMLEAD" call _fnc_roleHas}
        || {GVAR(commandGroup) isNotEqualTo ""
            && {((groupId (group _unit)) call _fnc_tight) isEqualTo (GVAR(commandGroup) call _fnc_tight)}}
    };
    case "MEDIC";
    case "MEDICS";
    case "MED": {
        (_unit getVariable ["ace_medical_medicClass", 0] > 0)
        || {_unit getUnitTrait "medic"}
        || {"MEDICAL" call _fnc_roleHas}
    };
    case "DEMO";
    case "EOD": {
        ((_unit getVariable ["ace_isEOD", false]) isEqualTo true)
        || {_unit getUnitTrait "explosiveSpecialist"}
        || {"DEMO" call _fnc_roleHas}
    };
    case "ISR": {
        ((_unit getVariable ["isISR", false]) isEqualTo true)
        || {"ISR" call _fnc_roleHas}
    };
    case "PILOT";
    case "PILOTS";
    case "AVIATION": {
        (_unit getVariable ["isPilot", false])
        || {"PILOT" call _fnc_roleHas}
        || {"COPILOT" call _fnc_roleHas}
    };
    case "JFO";
    case "JTAC": {
        ((_unit getVariable ["isJFO", false]) isEqualTo true)
        || {"JFO" call _fnc_roleHas}
        || {"JTAC" call _fnc_roleHas}
    };
    default {false};
};
if (_defined) exitWith {true};

private _group = groupId (group _unit);
if (toUpper _group isEqualTo _wanted) exitWith {true};

private _tightGroup = _group call _fnc_tight;
private _tightWanted = _wanted call _fnc_tight;
if (_tightGroup isEqualTo _tightWanted) exitWith {true};

// A PLATOON NAMES ITS SQUADS. Asked after the squad itself, so a mission that
// calls a group and a platoon the same word still reaches the group first.
if ((([] call FUNC(platoonTags)) findIf {
    ((_x select 0) isEqualTo _tightWanted) && {_tightGroup in (_x select 1)}
}) > -1) exitWith {true};

if (([_unit] call FUNC(roleTag)) isEqualTo _wanted) exitWith {true};

if (toUpper (name _unit) isEqualTo _wanted) exitWith {true};
if (getPlayerUID _unit isEqualTo _wanted) exitWith {true};

false
