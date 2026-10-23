#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT: the two variables behind one point row - where the point is,
 * and the marker it was taken from. Every place that reads or writes a point
 * (the form's rows, the map click, the marker list, CLR and CONFIRM) asks
 * here, so no two of them can disagree on which variable a row owns.
 *
 * A POINT ROW IS KEYED by SUP_SLOT_TARGET / SUP_SLOT_INGRESS / SUP_SLOT_EGRESS
 * (the three rows the screen has always had, under their original variable
 * names), or by the parameter-array slot a provider's point declaration
 * writes (task declaration field 7, addons/support/README.md). Declared
 * slots SUP_PARAM_INGRESS and SUP_PARAM_EGRESS are the INGRESS and EGRESS
 * rows themselves - see SUP_POINT_KEY.
 *
 * Arguments:
 * 0: Row key <NUMBER>
 *
 * Return Value:
 * [point variable, marker-name variable] <ARRAY of STRINGs>
 *
 * Example:
 * ([14] call jmfsb_tacpad_apps_fnc_supportPointVars) params ["_pv", "_nv"]
 *
 * Public: No
 */

params [["_key", SUP_SLOT_TARGET, [0]]];

if (_key >= 0 && {_key < count SUP_SLOT_VARS}) exitWith {SUP_SLOT_VARS select _key};

[format ["%1%2", QGVAR(supportPt), _key], format ["%1%2", QGVAR(supportPtName), _key]]
