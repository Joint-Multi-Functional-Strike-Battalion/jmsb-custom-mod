
if (EGVAR(common,aceTowing)) then {
    [
        QGVAR(addToHeavyDutyVehicles),
        "CHECKBOX",
        ["Add ropes to heavy duty vehicles", "Enables adding ropes to inventories of heavy duty vehicles such as MRAPs, IFVs, APCs and Tanks."],
        ["JMSB - Vehicles & Defence", "Towing"],
        true,
        1,
        {},
        true
    ] call CBA_fnc_addSetting;

    [
        QGVAR(addToCars),
        "CHECKBOX",
        ["Add ropes to cars", "Enables adding ropes to inventories of cars."],
        ["JMSB - Vehicles & Defence", "Towing"],
        false,
        1,
        {},
        true
    ] call CBA_fnc_addSetting;
};
