#include "script_component.hpp"
/*
 * Author: YonV
 * Wave 1: shells, scaled to the ground taken.
 *
 * A conventional commander is ASKED - an ARTY_REQUEST to its own guns, which
 * it services only if it has a battery in range with ammunition. The request
 * is backed by a contact count scaled to the ground taken, and what that
 * buys is the battery's own decision. There is no fallback barrage here: a
 * commander with no guns should not conjure them, and a mission where nothing
 * answers is telling the players something true about the enemy they are
 * fighting.
 *
 * An asymmetric commander has no gun line at all - 3-4 mortar rounds about
 * half the time, delivered directly, or nothing.
 *
 * Arguments:
 * 0: Answering side <SIDE>
 * 1: Its controltype <STRING>
 * 2: Objective position <ARRAY>
 * 3: Objective radius <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_side", "_ctype", "_pos", "_radius"];

if (_ctype isEqualTo "asymmetric") exitWith {
    if (random 100 >= GVAR(asymMortarChance)) exitWith {
        INFO("QRF arty: the asymmetric commander holds its mortars this time");
    };
    // The common pre-spawn gate: conjured mortars only land on the
    // answering side's own ground, like every other module effect.
    if (!([_side, _pos, "qrf mortars"] call EFUNC(common,taorGate))) exitWith {};
    private _rounds = 3 + floor random 2;
    // [pos, rounds, spread, shell, window] - the refactored signature; the
    // old ammo-first call was a params type error rescued by defaults.
    [_pos, _rounds, 50, QRF_MORTAR, _rounds * 5] call EFUNC(common,fireBarrage);
    INFO_1("QRF arty: %1 mortar round(s)",_rounds);
};

// The ground taken scales the CONTACT COUNT backing the request - that is the
// input the adapter's fire bus actually takes; how many rounds answer it is
// the battery's own business. A roadblock backs one contact, a base four. A
// rounds figure used to be computed here and passed to nothing - the log
// promised shells this function had no way to order.
// WITHOUT ALiVE THERE ARE NO GUNS TO ASK (user, 2026-11-02): the commander's
// battery is ALiVE's, and the rule above holds - nothing is conjured. The same
// with ALiVE loaded but no commanders, once the adapter has given up ("same as
// not loaded"). Asked first, so the line is said in both cases.
if (!(["QRF artillery", "no commander's guns to ask - no shells"] call EFUNC(common,aliveLoaded))
    || {isNil QEFUNC(adapter_alive,requestFire)}) exitWith {};

private _scale = ((_radius / QRF_SIZE_FULL) min 1) max 0;
private _contacts = 1 max round (4 * _scale);

private _asked = [_side, _pos, _contacts] call EFUNC(adapter_alive,requestFire);
INFO_2("QRF arty: asked %1's guns, %2 contact(s) backing the request",_side,_contacts);

if (!_asked) then {
    INFO("QRF arty: the request did not reach the bus - no shells");
};
