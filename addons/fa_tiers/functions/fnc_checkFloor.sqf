#include "script_component.hpp"
/*
 * Author: YonV
 * Checks every tier 2 round against the base game round it descends from, and
 * reports any that came out weaker.
 *
 * THIS IS THE ONE CHECK THAT CANNOT BE DONE IN A TEXT EDITOR. The rule is that
 * a tier 2 round must never be worse than base game ammunition - but the base
 * game's CfgAmmo lives in the engine's own config, not in any file this repo
 * has. A running mission has both loaded side by side, so this is where the
 * comparison belongs.
 *
 * THE ANCESTOR IS THE FIRST NON-FA CLASS UP THE CHAIN. A tier 2 round inherits
 * from an FA round, which inherits from a vanilla one - possibly through
 * several FA classes. Walking to the first class whose name does not begin
 * FA_ finds the base game round the whole family is built on.
 *
 * A ROUND WITH NO VANILLA ANCESTOR IS NOT A FAILURE. Some FA rounds descend
 * from other mods' ammunition, and "not worse than base game" has no meaning
 * there - those are counted and named, not flagged.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The report <STRING>
 *
 * Example:
 * [] call jmfsb_fa_tiers_fnc_checkFloor
 *
 * Public: No
 */

private _props = ["hit", "indirectHit", "indirectHitRange", "caliber"];

private _checked = 0;
private _noBase = 0;
private _bad = [];

{
    private _cfg = _x;
    private _name = configName _cfg;

    // Only the ones this addon generated.
    if ((_name select [-3]) isNotEqualTo "_t2") then {continue};
    _checked = _checked + 1;

    // Up the chain to the first class that is not ours.
    private _base = inheritsFrom _cfg;
    while {!isNull _base && {(configName _base) select [0, 3] isEqualTo "FA_"}} do {
        _base = inheritsFrom _base;
    };

    if (isNull _base) then {
        _noBase = _noBase + 1;
        continue;
    };

    {
        private _p = _x;
        // A property the vanilla round does not declare has no floor to fail.
        if (!isNumber (_base >> _p)) then {continue};

        private _mine = getNumber (_cfg >> _p);
        private _theirs = getNumber (_base >> _p);

        // Rounding at the fourth decimal is what the generator writes, so a
        // difference smaller than that is the format, not a regression.
        if (_mine < (_theirs - 0.0001)) then {
            _bad pushBack format ["%1: %2 %3 < %4 (%5)",
                _name, _p, _mine, _theirs, configName _base];
        };
    } forEach _props;
} forEach ("true" configClasses (configFile >> "CfgAmmo"));

{diag_log text format ["[jmfsb_fa_tiers] %1", _x]} forEach _bad;

if (_bad isEqualTo []) exitWith {
    format ["tier 2 floor OK: %1 round(s) checked, none below their base game ancestor (%2 had none)",
        _checked, _noBase]
};

format ["tier 2 floor BROKEN on %1 of %2 round(s) - full list in the RPT. First: %3",
    count _bad, _checked, _bad select 0]
