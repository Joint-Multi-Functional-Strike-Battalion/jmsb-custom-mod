#include "script_component.hpp"
/*
 * Author: YonV
 * The tag chips worth offering one man, in the order they are drawn.
 *
 * THE ROW WAS THE WHOLE ROSTER (user, 2026-09-03: "you cleaned up the nets but
 * not the tags"). Every declared squad, plus four jobs, sharing one line of the
 * compose pane - nineteen chips about a finger wide, none of them readable, and
 * most of them naming elements the man sending has no business waking.
 *
 * WHAT HE GETS INSTEAD, and why each of the three:
 *
 *   his own squad     the people beside him, and the tag he reaches for most
 *   his platoons      the platoons whose ARM NET he is on - see FUNC(railNets).
 *                     A lead carries all four and can wake any of them; a
 *                     rifleman carries his own. Reaching a platoon is what the
 *                     platoon net is for, so the tag follows the net exactly
 *   the jobs          LEADERS, MEDICS, DEMO, ISR, PILOTS, JFO (user,
 *                     2026-09-03) - defined backends in FUNC(tagMatch), and
 *                     they cross every element by design: a man calling for a
 *                     medic does not know whose medic. LEADERS is every leader
 *                     in the task force, not a command group
 *
 * THE CHIPS ARE NOT THE RULE. The box above the row still takes anything a tag
 * may be - a callsign, a job, a man, a UID - and FUNC(tagMatch) still resolves
 * all of it. This is the set worth one press, not the set that is legal.
 *
 * EVERY CHIP HAS TO RESOLVE. A chip that presses on and reaches nobody is worse
 * than no chip, so the platoons here are the ones FUNC(platoonTags) can match -
 * the same table, asked the same way.
 *
 * Arguments:
 * 0: The man <OBJECT> (optional, default player)
 *
 * Return Value:
 * Tags, upper-cased: his squad, his platoons, then the jobs <ARRAY>
 *
 * Example:
 * private _tags = [] call jmfsb_messaging_fnc_tagSet
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

private _out = [];

// His own squad first - the one he presses most.
private _own = groupId (group _unit);
if (_own isNotEqualTo "") then {_out pushBackUnique toUpper _own};

// THE PLATOONS HE IS ON THE NET OF. FUNC(railNets) has already narrowed the
// mission's declared nets by his role, so a platoon he cannot read is a platoon
// he is not offered a chip for - the two lists cannot drift apart.
private _mine = ([_unit] call FUNC(railNets)) apply {toUpper ((_x splitString " ") joinString "")};
{
    _x params ["_tag", "_squads"];
    if (_tag in _mine) then {_out pushBackUnique _tag};
} forEach ([] call FUNC(platoonTags));

// THE TRADES. Always offered, whatever platoon he is in: these name a job
// rather than an element, and the man who needs one does not care whose it is.
// Each has a backend in FUNC(tagMatch) - a mission flag, an engine trait, or
// the role class name - so every one of these reaches somebody.
{_out pushBackUnique _x} forEach ["LEADERS", "MEDICS", "DEMO", "ISR", "PILOTS", "JFO"];

_out
