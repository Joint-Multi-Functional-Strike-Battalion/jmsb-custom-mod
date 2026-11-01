// add setting for all gear from settings
{
    private _class = configName _x;
    [
        GEAR_SETTING(_class),
        "CHECKBOX",
        [format ["Use gear from ""%1""", _class], "If disabled gear from this configFile class will be not used. Mission defined gear will be not disabled."],
        ["JMSB - Mission & Admin", "Insurgents"],
        true,
        1,
        {},
        true
    ] call CBA_fnc_addSetting;
} forEach ("true" configClasses (configFile >> QGVAR(gear)));
