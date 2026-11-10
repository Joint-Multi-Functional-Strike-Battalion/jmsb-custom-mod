#include "script_component.hpp"
/*
 * Author: YonV
 * The ONE tag to put on a man's notification, out of every tag that named him.
 *
 * A MAN IS CALLED OUT ONCE (user, 2026-09-03: "do not double notify"). The
 * notification used to carry every matching tag joined together, so a team lead
 * on a CASEVAC tagged LEADERS, ISR and JFO read
 * "LEADERS ISR JFO CASEVAC JMSB 6" - one banner that looks like three, and the
 * three words that mattered least pushed the callsign off the end of it.
 *
 * It got worse the day the job tags were widened. A lead carries isLeader,
 * isISR and isJFO because he tasks drones and fires, so three of the six job
 * chips name him and any two of them stack.
 *
 * THE MOST SPECIFIC ONE WINS, because that is the one that tells him something
 * he did not already know:
 *
 *   0  him          his call sign or his UID - somebody wanted HIM
 *   1  his squad    the group he is standing in
 *   2  his platoon  a platoon that lists his squad
 *   3  a job        MEDICS, LEADERS - true of him and of a dozen others
 *
 * TIES KEEP THE SENDER'S ORDER. Two jobs are equally specific, so the first one
 * typed wins; a sender who leads with MEDICS meant MEDICS.
 *
 * NOT A PERMISSION CHECK, and not a filter. Every tag still reaches everyone it
 * names and every one of them is still on the message - see FUNC(tagMatch) and
 * FUNC(srvTagged). This only decides which word goes on the banner.
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: The tags that already matched him <ARRAY> of <STRING>
 *
 * Return Value:
 * One tag, upper-cased, or "" when the list is empty <STRING>
 *
 * Example:
 * private _shout = [player, ["ISR", "JMFSB 6"]] call jmfsb_messaging_fnc_tagCallout
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_tags", [], [[]]]];

if (isNull _unit || {_tags isEqualTo []}) exitWith {""};

// The same comparison the rest of the tag path uses - case and spaces are noise
// on a tag typed in a hurry.
private _fnc_tight = {toUpper ((_this splitString " ") joinString "")};

private _group = (groupId (group _unit)) call _fnc_tight;
private _name = (name _unit) call _fnc_tight;
private _uid = getPlayerUID _unit;
private _platoons = [] call FUNC(platoonTags);

private _best = "";
private _bestRank = 99;

{
    if (!(_x isEqualType "")) then {continue};

    // CAPTURED BEFORE THE findIf BELOW SHADOWS IT.
    private _tag = _x;
    private _tight = _tag call _fnc_tight;

    private _rank = switch (true) do {
        case (_tight isEqualTo _name || _tag isEqualTo _uid): {0};
        case (_tight isEqualTo _group): {1};
        case ((_platoons findIf {
            ((_x select 0) isEqualTo _tight) && {_group in (_x select 1)}
        }) > -1): {2};
        default {3};
    };

    // Strictly less than, so a tie leaves the earlier tag in place.
    if (_rank < _bestRank) then {
        _bestRank = _rank;
        _best = toUpper _tag;
    };
} forEach _tags;

_best
