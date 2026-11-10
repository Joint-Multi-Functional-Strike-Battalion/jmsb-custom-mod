#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_serverPick

Description:
    Server end of the choice menu. Builds the snapshot for the chosen product and
    broadcasts the render. Everything that decides WHAT the intel is happens
    here, on one machine, so two clients can never disagree about it.

Parameters:
    _product : STRING - "package" | "aa" | "arty" | "camp" | "hub" |
               "installation" | "coastal" | "radar" | "jam" | "leader".
    _pos     : ARRAY  - where the hack happened.
    _side    : SIDE   - who earned it.
    _caller  : OBJECT - the hacker.
    _device  : OBJECT - what was hacked. The package lives on it.

Author:
    JMSB
---------------------------------------------------------------------------- */
if (!isServer) exitWith {};

params ["_product", "_pos", "_side", "_caller", ["_device", objNull, [objNull]]];

private _ok = switch (_product) do {
    // THE MISSION'S OWN INTEL, off the terminal that was hacked. A share of the
    // package a JMSB - Intel Package module put on it - see
    // FUNC(productPackage). This is what replaced LOCATE AA, ARTILLERY, CAMP,
    // LOGISTICS, RADAR and INSTALLATION: those six asked ALiVE what it had
    // simulated and drew a circle round it, so what a hack told you was decided
    // by the simulation rather than by anybody. A mission maker can write a
    // document now.
    case "package": { [_device, _side, _caller] call FUNC(productPackage) };

    // AND THE SIX THAT ASK ALiVE, back beside it. They are not a replacement
    // for the package and the package is not a replacement for them: a mission
    // maker's document and a commander's order of battle are different
    // questions, and FUNC(intelOptions) offers whichever have anything in them.
    // Each returns false on an empty pool, which is an honest "there is nothing
    // out there" rather than a broken product.
    case "aa":      { [_pos, _side] call FUNC(productLocateAA) };
    case "arty":    { [_pos, _side] call FUNC(productLocateArty) };
    // The rear: where the men not on the line sleep, and where what feeds the
    // line comes from.
    case "camp":    { [_pos, _side] call FUNC(productLocateCamp) };
    case "hub":     { [_pos, _side] call FUNC(productLocateHub) };
    // The other half of the asymmetric hunt: the things the chain needs to keep
    // working, beside the men who run it.
    case "installation": { [_pos, _side] call FUNC(productInstallation) };

    // The coastal network, split into the launchers and the eyes that feed
    // them - killing one does not kill the other, so they are two hunts. The
    // launchers are jmfsb's own objects, never ALiVE's, which is why that one
    // survived the split; the radar pool merges ours with ALiVE's profiles.
    case "coastal": { [_pos, _side] call FUNC(productLocateCoastal) };
    // LOCATE RADAR HAD NO CASE AT ALL. FUNC(intelOptions) offers it, and
    // FUNC(productLocateRadar) is PREP'd and works, but this switch never named
    // it - so every LOCATE RADAR fell through to `default {false}` and told the
    // player the product failed, every time. That is a DIVINER bug and the fix
    // belongs there too.
    case "radar":   { [_pos, _side] call FUNC(productLocateRadar) };

    // The jammers holding the quiet up - hack one and its zone dies quietly,
    // blow it and everyone knows you were there.
    case "jam": {
        !isNil "jmfsb_jamming_fnc_productLocateJammer"
            && {[_pos, _side] call jmfsb_jamming_fnc_productLocateJammer}
    };

    // The asymmetric chain: a circle on a safe house, never on the man.
    case "leader": {
        !isNil "jmfsb_leaders_fnc_productLeader"
            && {[_pos, _side] call jmfsb_leaders_fnc_productLeader}
    };

    default { false };
};

// THE PACKAGE HAS ALREADY SPOKEN. It names the folder and how many files came
// off it, which is the whole point of a package over a circle, and a second
// generic line under it would just be noise.
if (_product isEqualTo "package") exitWith {};

// The message never differs either. A player who learns that a poisoned product
// phrases its confirmation differently has been handed the tell for free.
private _msg = ["Nothing to report.", "Intel plotted - check your map."] select _ok;
[_msg, _side] remoteExecCall [QFUNC(pickResult), 0];

INFO_3("Hacking: product '%1' by %2 -> %3",_product,name _caller,_ok);
