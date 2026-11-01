
[
    QGVAR(enabled),
    "CHECKBOX",
    ["Enable remote sensors on clients", "This command will halt raycasting calculations (on the local machine only) for all groups which don't contain any local entities. Units, that are not in a group with at least one local member, will not check visibility of other units. This will cause, that remote units will not have updated knowsAbout and it will save some CPU time. If a group contains a single local entity then calculations will still be performed for the entire group."],
    ["JMSB - EW, Drones & Intel", "Remote Sensors"],
    true,
    true,
    {
        if (isServer || {!hasInterface}) exitWith {
            INFO("Server or HC, skipping");
        };

        INFO_1("disableRemoteSensors - %1",!GVAR(enabled));
        disableRemoteSensors !GVAR(enabled);
    }
] call CBA_fnc_addSetting;
