#include "script_component.hpp"
/*
 * Author: YonV
 * Everyone an audience tag list reaches, right now.
 *
 * A TAG IS AN ALERT, NOT AN ADDRESS. This is the whole point of tags and it is
 * worth being plain about: a C2 message tagged NOMAD stays in C2. It is not
 * copied to a Nomad net, it does not leave the net it was spoken on, and
 * everybody on C2 sees it and sees Nomad's answer. What the tag does is reach
 * into Nomad's pockets and make their tablets go off, and make them able to
 * reply into a thread they were not otherwise part of.
 *
 * That is what a man does when he says a call sign out loud on a net: the net
 * still hears all of it, but one particular section knows to listen.
 *
 * RESOLVED AT SEND, NOT STORED. Membership of a squad changes mid-mission, so
 * asking now is the only answer that is true now - the same reason
 * FUNC(srvMembers) derives a mailbox's members instead of keeping a list.
 *
 * Arguments:
 * 0: Tags <ARRAY> of <STRING>
 *
 * Return Value:
 * Players the tags reach <ARRAY>
 *
 * Example:
 * private _who = [["NOMAD", "MED"]] call jmfsb_messaging_fnc_srvTagged
 *
 * Public: No
 */

params [["_tags", [], [[]]]];

if (_tags isEqualTo []) exitWith {[]};

private _out = [];

{
    private _unit = _x;
    if (alive _unit && {_tags findIf {_x isEqualType "" && {[_unit, _x] call FUNC(tagMatch)}} >= 0}) then {
        _out pushBackUnique _unit;
    };
} forEach allPlayers;

_out
