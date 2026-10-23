#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes one order from the support page and either flies it or says why not.
 *
 * THE SUPPORT CORE'S PROVIDER TASK SIGNATURE (addons/support/README.md):
 * EFUNC(support,request) gates and validates, then calls whichever provider
 * owns the id without caring which one that is. Air
 * assets there read the first entries of the parameter array; this reads the
 * two that are its own.
 *
 * INGRESS AND EGRESS ARE PLACES, NOT HEADINGS. They were headings on a pair of
 * steppers, and a heading is a thing you have to convert in your head from the
 * map you are already looking at - the ridge you want the run behind is a
 * POINT, not 285 degrees. So both are picked the same way the target is: click
 * the map, or take a placed marker off the list. The aircraft appears at the
 * ingress point and leaves towards the egress point.
 *
 * EITHER MAY BE LEFT UNSET AND THE RUN STILL FLIES. Unset ingress means the
 * aircraft comes in from the caller's side of the target, which is the sane
 * default and the one a man in contact would ask for without thinking; unset
 * egress means it carries straight on through. Requiring three map picks
 * before anything could be called in would make the fast case slow.
 *
 * THE REFUSAL IS THE SAME QUESTION THE ROW ASKED. FUNC(available) answers
 * both, so a row that draws IDLE cannot be an order this then rejects.
 *
 * LOITER IS THE OTHER THING A DRONE IS FOR. The page has always offered it
 * beside the attack run and this addon flew both as a strike - an asset asked
 * to hold overhead put its bombs down and left. It is now its own task: the
 * aircraft holds an orbit over the point and the gunner's seat goes to the
 * drone controller who asked for it, so what happens next is a man on a
 * terminal rather than a script with a target list. See FUNC(request).
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Task token <STRING> - "rtb" sends it home, "LOITER" holds it overhead the
 *    point, anything else is a strike on the point
 * 2: Target position <ARRAY> - the grid; terminal guidance may move it
 * 3: The support page's parameter array <ARRAY> - ingress POSITION at index 8,
 *    egress position at 9, [] for either meaning auto. Those two slots are past
 *    everything ALiVE's own tasking reads, so one array serves both kinds of
 *    asset and the page does not have to know which it is filling in.
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, "" when accepted <STRING>
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "cas", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];
private _ingress = _prm param [8, []];
private _egress = _prm param [9, []];
// THE ORDNANCE CHOICE RIDES AT 10, past ALiVE's own slots and past the two
// points, for the same reason those two do: one parameter array serves every
// kind of asset and the page fills in the slots its own row asked about. It is
// an INDEX into the list this addon published on the row - the airframe's own
// stores behind a leading AUTO - so the page never learns what it selects.
private _ord = _prm param [10, 0];
if !(_ord isEqualType 0) then {_ord = 0};
if !(_ingress isEqualType []) then {_ingress = []};
if !(_egress isEqualType []) then {_egress = []};

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {
    WARNING_1("task: no asset behind id '%1'",_assetId);
    [false, "that asset is gone"]
};

// SENT HOME IS ALWAYS ALLOWED, and never blocked by the availability gate -
// an aircraft you want to recall is by definition one that is busy.
// Hoisted: a comma inside a macro argument reads as an argument separator.
private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];

if (_task isEqualTo "rtb") exitWith {
    [QGVAR(abort), [_logic]] call CBA_fnc_serverEvent;
    INFO_1("%1 recalled",_callsign);
    [true, ""]
};

// THE INDEX BECOMES A STORE HERE, and never travels as a number. The page
// sends back a position in the list FUNC(entityRow) published; that list is
// FUNC(stores) read off this module's airframe class, so it is read again here
// off the same class and the answer is a magazine the aircraft is carrying.
// Resolving it now rather than at release means the run carries what was
// asked for by name, and a list that changes shape can never point an old
// index at a different store.
private _stores = [_logic getVariable [QGVAR(cls), ""]] call FUNC(stores);
_ord = (round _ord) max 0 min (count _stores);
private _mag = if (_ord > 0) then {(_stores select (_ord - 1)) param [0, ""]} else {""};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {
    INFO_2("task refused for %1 - %2",_callsign,_why);
    [false, _why]
};

if (_pos isEqualTo []) exitWith {[false, "no target grid"]};

// WHAT THE AIRCRAFT IS BEING ASKED TO DO. The page's own three tasks come
// through as its own words; only LOITER means something different here, and
// everything else - SAD, ATTACK RUN, a token this addon has never heard of -
// is the strike this asset has always flown.
private _mode = ["strike", "loiter"] select (toUpper _task isEqualTo "LOITER");

// THE ORDER GOES TO THE SERVER AND THE RUN IS FLOWN THERE. A client that
// spawned its own aircraft would own an airframe nobody else could see hit.
[QGVAR(request), [_logic, _pos, _ingress, _egress, player, _mag, _mode]] call CBA_fnc_serverEvent;

[true, ""]
