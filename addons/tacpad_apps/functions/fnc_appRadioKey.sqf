#include "script_component.hpp"
/*
 * Author: JMSB
 * What the RADIO board shows, as one string: the voice API's nets, calls, slots,
 * callbacks and contacts, the minute a live call has run, and the board's own
 * picks. The board redraws only when this changes - a rebuild deletes the
 * buttons, and a button deleted between a press and its release is an eaten
 * press.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Key <STRING>
 *
 * Example:
 * private _key = [] call jmfsb_tacpad_apps_fnc_appRadioKey
 *
 * Public: No
 */

if (isNil QEFUNC(voice,netState)) exitWith {""};

// A live call's clock is shown to the second only while it is on screen; the
// key moves once a second for it, so a board with a call on it ticks.
private _calls = [] call EFUNC(voice,calls);
private _live = (_calls findIf {(_x param [1, ""]) isEqualTo CALL_LIVE}) >= 0;

str [
    [] call EFUNC(voice,netState),
    _calls,
    [] call EFUNC(voice,callSlots),
    [] call EFUNC(voice,callbacks),
    [] call EFUNC(voice,contacts),
    [0, floor CBA_missionTime] select _live,
    uiNamespace getVariable [QGVAR(radioTab), ""],
    uiNamespace getVariable [QGVAR(radioPick), ""],
    uiNamespace getVariable [QGVAR(radioFind), ""],
    uiNamespace getVariable [QGVAR(radioFlash), false],
    // the RTO nets and MANAGE's drafts of them (FUNC(radioCustomPanel), FUNC(radioMembersPanel))
    [] call FUNC(radioCustom),
    uiNamespace getVariable [QGVAR(radioNewName), ""],
    uiNamespace getVariable [QGVAR(radioNewSquads), []],
    uiNamespace getVariable [QGVAR(radioMembersDraft), []]
]
