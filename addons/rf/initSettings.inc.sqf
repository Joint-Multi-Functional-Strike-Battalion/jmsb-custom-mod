// CBA Settings [ADDON: jmfsb_rf]
// OPERATION VALUES ONLY: dB, tick rates, switches. Nothing here says where or
// who - nets, keys and nodes come from the adapters and the signal plan.
// All are global (server-forced): the server is the only machine that computes.

[
    QGVAR(tickPlayers), "SLIDER",
    ["Player tick (sec)", "How often links involving a moving node are recomputed."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Tick"],
    [0.5, 10, DEFAULT_TICK_PLAYERS, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(tickStatic), "SLIDER",
    ["Static tick (sec)", "How long a link between nodes that have not moved is reused before it is recomputed."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Tick"],
    [1, 60, DEFAULT_TICK_STATIC, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(aiNodes), "CHECKBOX",
    ["AI nodes counted", "Off: nodes held by AI men take no part in the mesh unless the node is flagged. Vehicles and placed nodes always count."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Tick"],
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(debugOverlay), "CHECKBOX",
    ["Debug map overlay", "Lines on the map between linked nodes, red to green by quality. Sends every link to every client while on."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Tick"],
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(vhfExp), "SLIDER",
    ["VHF path-loss exponent", "Log-distance exponent for the VHF band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [2, 6, VHF_EXP, 2],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(vhfRef), "SLIDER",
    ["VHF loss at 1 m (dB)", "Path loss at the 1 m reference for the VHF band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [0, 80, VHF_REF, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(vhfFloor), "SLIDER",
    ["VHF noise floor (dBm)", "Receiver noise floor for the VHF band, before any interference."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [-130, -80, VHF_FLOOR, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(uhfExp), "SLIDER",
    ["UHF path-loss exponent", "Log-distance exponent for the UHF band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [2, 6, UHF_EXP, 2],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(uhfRef), "SLIDER",
    ["UHF loss at 1 m (dB)", "Path loss at the 1 m reference for the UHF band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [0, 80, UHF_REF, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(uhfFloor), "SLIDER",
    ["UHF noise floor (dBm)", "Receiver noise floor for the UHF band, before any interference."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [-130, -80, UHF_FLOOR, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(satExp), "SLIDER",
    ["SAT path-loss exponent", "Log-distance exponent for ground emitters on the SAT band (jammers, intercept). The satellite link itself has no path loss."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [2, 5, SAT_EXP, 2],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(satRef), "SLIDER",
    ["SAT loss at 1 m (dB)", "Path loss at the 1 m reference for ground emitters on the SAT band (jammers, intercept). The satellite link itself has no path loss."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [20, 80, SAT_REF, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(satFloor), "SLIDER",
    ["SAT noise floor (dBm)", "Receiver noise floor for the SAT band, before any interference."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [-130, -80, SAT_FLOOR, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(satFadeDb), "SLIDER",
    ["SAT rain fade (dB)", "How much the satellite link loses in full rain. An overcast sky with no rain counts a quarter of it. 0 = weather never touches SAT."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [0, 20, DEFAULT_SAT_FADE_DB, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(videoExp), "SLIDER",
    ["VIDEO path-loss exponent", "Log-distance exponent for the VIDEO band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [2, 5, VIDEO_EXP, 2],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(videoRef), "SLIDER",
    ["VIDEO loss at 1 m (dB)", "Path loss at the 1 m reference for the VIDEO band."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [20, 80, VIDEO_REF, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(videoFloor), "SLIDER",
    ["VIDEO noise floor (dBm)", "Receiver noise floor for the VIDEO band, before any interference."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [-130, -80, VIDEO_FLOOR, 0],
    1,
    {[] call FUNC(updateBands)}
] call CBA_fnc_addSetting;

[
    QGVAR(thr), "SLIDER",
    ["Quality threshold (dB SNR)", "SNR at which link quality is 0. Open item: the spec says 6 dB, the tablet mockups 3 dB."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [0, 20, DEFAULT_THR_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(span), "SLIDER",
    ["Quality span (dB)", "SNR above the threshold at which link quality is 1."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Bands"],
    [5, 40, DEFAULT_SPAN_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(terrainDb), "SLIDER",
    ["Terrain per blocked sample (dB)", "Loss for each of the three path samples the ground blocks."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Obstacles"],
    [0, 40, DEFAULT_TERRAIN_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(wallDb), "SLIDER",
    ["Wall (dB)", "Loss for each building or structure on the path."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Obstacles"],
    [0, 40, DEFAULT_WALL_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(treeDb), "SLIDER",
    ["Tree (dB)", "Loss for each tree or bush on the path."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Obstacles"],
    [0, 40, DEFAULT_TREE_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(proneDb), "SLIDER",
    ["Prone (dB)", "Loss at an end whose holder is prone."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Obstacles"],
    [0, 40, DEFAULT_PRONE_DB, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(vehicleDb), "SLIDER",
    ["Inside a vehicle (dB)", "Loss at an end whose holder is inside a vehicle on a handheld set."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Obstacles"],
    [0, 40, DEFAULT_VEHICLE_DB, 0],
    1
] call CBA_fnc_addSetting;
