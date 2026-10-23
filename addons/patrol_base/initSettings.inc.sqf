// CBA settings for the Patrol Base system. Category: 1st Joint Multi-Functional Strike Battalion > Patrol Base.

[
    QGVAR(enabled),
    "CHECKBOX",
    ["Enabled", "Enable the patrol base system."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(radioRelay),
    "CHECKBOX",
    ["Patrol base radio relay", "A built patrol base carries a base station: it relays the side's radio nets round the base and links by satellite to the staging zone and the other bases while its mast has open sky."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(maxCount),
    "SLIDER",
    ["Max patrol bases", "How many patrol bases may exist at once."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    [1, 10, 3, 0, true],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(kitCount),
    "SLIDER",
    ["Kits required", "How many Patrol Base Kits must be dropped within range to build one base."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    [1, 10, 4, 0, true],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(kitRange),
    "SLIDER",
    ["Kit gather range (m)", "Radius the dropped kits must lie within to count."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    [1, 30, 5, 1, true],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(beaconClass),
    "EDITBOX",
    ["Base object", "Class spawned at the base on deploy - it marks the location and carries the Unbuild action. Defaults to jmfsb's own SatCom mast; if that class is not loaded it falls back to the vanilla SatelliteAntenna_01_Black_F rather than spawning nothing."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    "jmfsb_satcom_deployed",
    1
] call CBA_fnc_addSetting;

[
    QGVAR(onDeployCode),
    "EDITBOX",
    ["On-deploy init (SQF)", "SQF run on the server after a base is built. Passed: [_beacon, _pos, _name, _side, _builder]. Blank = nothing."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    "params ['_base', '_pos', '_name', '_side']; [_base, 15] remoteExec ['jmfsb_mission_fnc_addStagingZone', 0, true]; [_base, _name, _side] call jmfsb_teleport_fnc_addPoint;",
    1
] call CBA_fnc_addSetting;

[
    QGVAR(onUndeployCode),
    "EDITBOX",
    ["On-undeploy init (SQF)", "SQF run on the server while the base beacon still exists (before it is deleted). Passed: [_beacon, _pos, _name, _side]. Blank = nothing."],
    ["1st Joint Multi-Functional Strike Battalion", "Patrol Base"],
    "params ['_object']; [_object] remoteExec ['jmfsb_mission_fnc_removeStagingZone', 0]; [_object] call jmfsb_teleport_fnc_deletePoint;",
    1
] call CBA_fnc_addSetting;
