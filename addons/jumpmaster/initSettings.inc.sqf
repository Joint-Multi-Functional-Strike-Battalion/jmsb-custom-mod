// OPERATION VALUES, every one set on the server. Where the jump goes is the
// leader's plan on the map; who jumps is his squad.

[
    QGVAR(haloAltitude), "SLIDER",
    ["HALO / HAHO altitude", "How high the aircraft flies a HALO or HAHO run, metres over the ground. 6000 by default, above the reach of the game's air defences."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [1000, 10000, 6000, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(staticAltitude), "SLIDER",
    ["Static line altitude", "How high the aircraft flies a static-line run, metres over the ground: the lowest a round canopy opens from without injury, plus 50 m. The line pulls it 1 second after exit."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [100, 500, 150, 0],
    true
] call CBA_fnc_addSetting;

// THE WIND (user, 2026-10-30): where the stick lands is worked out from the
// seconds under canopy, which on a HALO start at the pull altitude.
[
    QGVAR(haloOpenAltitude), "SLIDER",
    ["HALO pull altitude", "Metres over the ground a HALO stick is expected to pull at: the wind drift is worked out from there down, and the phone's ALT readout turns amber there and red at half of it."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [150, 2000, 300, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(windFactor), "SLIDER",
    ["Wind drift factor", "How much of the wind a canopy drifts with, for the LAND point on the map and SHIFT PATH FOR WIND. 1 is the wind as it blows; 0 turns the drift off."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [0, 2, 1, 1],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(maskClasses), "EDITBOX",
    ["HALO masks", "Comma-separated. The goggles-slot items that count as an oxygen mask: a HALO or HAHO jumper without one is not ready."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    "G_AirPurifyingRespirator_01_F,G_AirPurifyingRespirator_02_black_F,G_AirPurifyingRespirator_02_olive_F,G_AirPurifyingRespirator_02_sand_F,G_RegulatorMask_F",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(chuteClasses), "EDITBOX",
    ["Parachutes", "Comma-separated. The backpacks that count as a parachute: a jumper without one is not ready."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    "B_Parachute,ACE_NonSteerableParachute",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(passesDefault), "SLIDER",
    ["Passes by default", "How many passes over the drop zone a jump is planned with until the leader changes it on the page. The stick is split evenly across them, in squad order."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [PASSES_MIN, PASSES_MAX, 1, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(exitDefault), "LIST",
    ["Exit by default", "How the stick leaves the aircraft until the leader changes it on the page: automatically at the green light, one man every 0.7 s, or each man exits himself (JUMP in his action menu from the red light). JUMP is always there, whichever is set."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [[EXIT_AUTO, EXIT_MANUAL], ["Automatic at the green light", "Manual - each man exits himself"], 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aircraft), "EDITBOX",
    ["Jump aircraft", "The aircraft class the squad is put in. Empty: the side's own cargo aircraft (the Blackfish for BLUFOR and independents, the Xi'an for OPFOR)."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    "",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(bay), "LIST",
    ["In the aircraft", "Seats: everyone in a cargo seat. Standing: everyone on his feet in the bay, fixed to the hull in two files - the engine does not carry a walking man in a moving aircraft, so he stands where he is put."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [[BAY_SEATS, BAY_STAND], ["Seats", "Standing in the bay"], 0],
    true
] call CBA_fnc_addSetting;
