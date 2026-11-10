// OPERATION VALUES, every one set on the server. Where the jump goes is the
// leader's JUMP REQUEST (2026-11-02); who jumps is his squad at the pickup.
//
// THE JMSB - JUMP AIRCRAFT MODULE (user, 2026-11-02) carries its own class,
// call sign, altitudes, passes, exit and bay. The altitudes, passes, exit and
// bay here fly only a side's own jump aircraft - the one a side has while no
// module of that side is placed. Which aircraft is never a setting: the Jump
// aircraft class setting is retired (WHAT, not an operation value), and a
// side's own flies the side's cargo aircraft.

[
    QGVAR(haloAltitude), "SLIDER",
    ["HALO / HAHO altitude", "How high a side's own jump aircraft flies a HALO or HAHO run, metres over the ground - a side with no JMSB - Jump Aircraft module. 6000 by default, above the reach of the game's air defences."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [ALT_FREEFALL_MIN, ALT_FREEFALL_MAX, ALT_FREEFALL_DEFAULT, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(staticAltitude), "SLIDER",
    ["Static line altitude", "How high a side's own jump aircraft flies a static-line run, metres over the ground - a side with no JMSB - Jump Aircraft module: the lowest a round canopy opens from without injury, plus 50 m. The line pulls it 1 second after exit."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [ALT_STATIC_MIN, ALT_STATIC_MAX, ALT_STATIC_DEFAULT, 0],
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
    ["Wind drift factor", "How much of the wind a canopy drifts with: the jump aircraft shifts its run upwind by the drift, so the stick lands on the green light asked for. 1 is the wind as it blows; 0 turns the drift and the shift off."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [0, 2, 1, 1],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(maskClasses), "EDITBOX",
    ["HALO masks", "Comma-separated. The goggles-slot items that count as an oxygen mask: a HALO or HAHO jumper without one is not ready, and the jump aircraft answers CANTCO."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    "G_AirPurifyingRespirator_01_F,G_AirPurifyingRespirator_02_black_F,G_AirPurifyingRespirator_02_olive_F,G_AirPurifyingRespirator_02_sand_F,G_RegulatorMask_F",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(chuteClasses), "EDITBOX",
    ["Parachutes", "Comma-separated. The backpacks that count as a parachute: a jumper without one is not ready, and the jump aircraft answers CANTCO."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    "B_Parachute,ACE_NonSteerableParachute",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(passesDefault), "SLIDER",
    ["Passes by default", "How many passes over the drop zone a side's own jump aircraft flies a JUMP REQUEST with no PASSES - a side with no JMSB - Jump Aircraft module. The stick is split evenly across them, in squad order."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [PASSES_MIN, PASSES_MAX, 1, 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(exitDefault), "LIST",
    ["Exit by default", "How the stick leaves a side's own jump aircraft when a JUMP REQUEST ticks no EXIT - a side with no JMSB - Jump Aircraft module: automatically at the green light, one man every 0.7 s, or each man exits himself (JUMP in his action menu from the red light). JUMP is always there, whichever is set."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [[EXIT_AUTO, EXIT_MANUAL], ["Automatic at the green light", "Manual - each man exits himself"], 0],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(bay), "LIST",
    ["In the aircraft", "Where the stick rides in a side's own jump aircraft - a side with no JMSB - Jump Aircraft module. Seats: everyone in a cargo seat. Standing: everyone on his feet in the bay, fixed to the hull in two files - the engine does not carry a walking man in a moving aircraft, so he stands where he is put."],
    ["JMSB - Mission & Admin", "Jumpmaster"],
    [[BAY_SEATS, BAY_STAND], ["Seats", "Standing in the bay"], 0],
    true
] call CBA_fnc_addSetting;
