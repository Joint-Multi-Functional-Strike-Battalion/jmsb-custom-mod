#include "script_component.hpp"
/*
 * Author: JMSB
 * The scanner sweep, or [] when this player has no set.
 *
 * ONE READ FOR THE WHOLE HUD. The drones tile, the jamming tile and the combined
 * one all want the same sweep, and three calls a second to
 * EFUNC(hacking,scannerRead) to draw one frame is three answers that can differ
 * by a tick. This is the one place any of them asks.
 *
 * HELD FOR HUD_SWEEP_TTL SECONDS (review P5). The sweep walks every entity
 * within two kilometres; the HUD ticks every second and asks once per tile.
 * The answer is kept for a few seconds and read again sooner only when what it
 * depends on changes - a different player unit, or the set picked up or
 * dropped - so swapping the scanner in or out shows at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The sweep, or [] <ARRAY>
 *
 * Example:
 * private _sweep = [] call jmfsb_hud_fnc_sweep
 *
 * Public: No
 */

if (isNil QEFUNC(hacking,scannerRead)) exitWith {[]};

private _has = [player] call EFUNC(hacking,hasScanner);
private _inputs = [player, _has];

(missionNamespace getVariable [QGVAR(sweepCache), []]) params [["_until", -1, [0]], ["_wasInputs", [], [[]]], ["_cached", [], [[]]]];
if (diag_tickTime < _until && _inputs isEqualTo _wasInputs) exitWith {_cached};

private _sweep = if (_has) then {[] call EFUNC(hacking,scannerRead)} else {[]};
missionNamespace setVariable [QGVAR(sweepCache), [diag_tickTime + HUD_SWEEP_TTL, _inputs, _sweep]];

_sweep
