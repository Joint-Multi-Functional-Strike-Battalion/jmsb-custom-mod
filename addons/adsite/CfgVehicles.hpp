class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // Sync air defence vehicles to it: they defend one area together and share
    // one alarm. Both numbers are how they OPERATE - where the Site is and what
    // is in it are the module's position and its sync; nothing names a side.
    class jmfsb_moduleADSite: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "JMSB - Air Defence Site";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleSite));
        functionPriority = 2;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = ADS_ICON;

        class Attributes: AttributesBase {
            class radius: Edit {
                property = QGVAR(radius);
                displayName = "Protected Radius (m)";
                tooltip = "Rounds predicted to land within this distance of a synced vehicle are intercepted. 0: each vehicle's own weapon reach, under the Protect radius cap setting.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('radius',_value)]);
            };
            class interceptChance: Edit {
                property = QGVAR(interceptChance);
                displayName = "Intercept Chance";
                tooltip = "0 to 1, rolled once per intercept attempt by this Site's vehicles. BLANK uses the Intercept chance setting.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('interceptChance',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "An air defence Site: sync the AA guns, CIWS and SAM launchers that make it. They intercept artillery, rockets, missiles and bombs predicted to land inside the protected radius, and share one alarm. Any air defence vehicle defends itself without this module; the module only sets the radius and the intercept chance for its own.";
            sync[] = {"AnyVehicle"};
        };
    };
};
