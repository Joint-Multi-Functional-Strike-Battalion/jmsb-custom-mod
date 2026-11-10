#include "script_component.hpp"
/*
 * Author: YonV
 * Every machine: an FPV class's wrecks are taken away as soon as they blow
 * (FUNC(fpvWreck)). Our IED Pelican from preInit, every class on Drongo's
 * Drone Tweaks' FPV list once DDT is ready. A Killed handler fires where the
 * drone is local - the server for an AI's, the operator's machine for one a
 * player flies - so it goes on everywhere. Once per class.
 *
 * Arguments:
 * 0: FPV class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jmfsb_uas_UAV_06_IED_I"] call jmfsb_uas_fnc_fpvWatch
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "" || {_class in GVAR(fpvWatched)}) exitWith {};
GVAR(fpvWatched) pushBack _class;
[_class, "Killed", {_this call FUNC(fpvWreck)}, true, [], true] call CBA_fnc_addClassEventHandler;
