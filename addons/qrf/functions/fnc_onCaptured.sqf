#include "script_component.hpp"
/*
 * Author: YonV
 * The reply. Which commander answers is whichever is hostile to the captors -
 * and what it can send depends on what kind of war it fights.
 *
 * Arguments (the capture event):
 * 0: Objective name <STRING>
 * 1: Capturing side <SIDE>
 * 2: Position <ARRAY>
 * 3: Radius <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_name", "_side", "_pos", "_radius"];

if (!isServer) exitWith {};

// THE MODULE IS THE ENABLE, and the waves read its values. Reaction's
// burn-through calls here on a mission with no QRF module placed, where those
// values do not exist; without ALiVE that is now reached (user, 2026-11-02).
if (!GVAR(moduleUp)) exitWith {
    INFO_1("'%1' taken - no QRF module placed, nobody sent",_name);
};

// The first ALiVE commander hostile to the captors - or, without ALiVE, the
// mission's enemy with the faction its men wear and no kind of war, so no
// guns to ask (user, 2026-11-02: "works with or without").
([_side] call EFUNC(common,hostileCommander)) params ["_answering", "_ctype", "_faction"];

if (_answering isEqualTo sideUnknown) exitWith {
    INFO_1("'%1' taken - nobody hostile to answer it",_name);
};

INFO_4("QRF: %1 (%2) answers '%3' taken by %4",_answering,_ctype,_name,_side);

[_answering, _ctype, _pos, _radius] call FUNC(waveArty);
[_answering, _pos] call FUNC(waveDrones);
[_answering, _faction, _pos] call FUNC(waveSquads);
