// The drones. Every variant is GX's recon Drone40 - camera turret and laser
// designator kept, so the operator still sees - with the role this addon reads
// (GVAR(role)) and the round a pickup hands back (GX_DroneMagazine).
class CfgVehicles {
    class GX_DRONE40_UAV_RECON_BASE;
    class GVAR(base): GX_DRONE40_UAV_RECON_BASE {
        author = QAUTHOR;
        scope = 0;
        scopeCurator = 0;
        GVAR(role) = "";
    };
    class GVAR(relay_base): GVAR(base) {
        displayName = "Drone40 Relay";
        GVAR(role) = ROLE_RELAY;
        GX_DroneMagazine = QGVAR(1Rnd_relay_M203);
    };
    class GVAR(B_relay): GVAR(relay_base) {
        scope = 2;
        scopeCurator = 2;
        side = 1;
        faction = "BLU_F";
        crew = "GX_B_UAV_AI";
        typicalCargo[] = {"GX_B_UAV_AI"};
    };
    class GVAR(O_relay): GVAR(relay_base) {
        scope = 2;
        scopeCurator = 2;
        side = 0;
        faction = "OPF_F";
        crew = "GX_O_UAV_AI";
        typicalCargo[] = {"GX_O_UAV_AI"};
    };
    class GVAR(I_relay): GVAR(relay_base) {
        scope = 2;
        scopeCurator = 2;
        side = 2;
        faction = "IND_F";
        crew = "GX_I_UAV_AI";
        typicalCargo[] = {"GX_I_UAV_AI"};
    };
    class GVAR(decoy_base): GVAR(base) {
        displayName = "Drone40 Decoy";
        GVAR(role) = ROLE_DECOY;
        GX_DroneMagazine = QGVAR(1Rnd_decoy_M203);
    };
    class GVAR(B_decoy): GVAR(decoy_base) {
        scope = 2;
        scopeCurator = 2;
        side = 1;
        faction = "BLU_F";
        crew = "GX_B_UAV_AI";
        typicalCargo[] = {"GX_B_UAV_AI"};
    };
    class GVAR(O_decoy): GVAR(decoy_base) {
        scope = 2;
        scopeCurator = 2;
        side = 0;
        faction = "OPF_F";
        crew = "GX_O_UAV_AI";
        typicalCargo[] = {"GX_O_UAV_AI"};
    };
    class GVAR(I_decoy): GVAR(decoy_base) {
        scope = 2;
        scopeCurator = 2;
        side = 2;
        faction = "IND_F";
        crew = "GX_I_UAV_AI";
        typicalCargo[] = {"GX_I_UAV_AI"};
    };
    class GVAR(jammer_base): GVAR(base) {
        displayName = "Drone40 Jammer";
        GVAR(role) = ROLE_JAMMER;
        GX_DroneMagazine = QGVAR(1Rnd_jammer_M203);
    };
    class GVAR(B_jammer): GVAR(jammer_base) {
        scope = 2;
        scopeCurator = 2;
        side = 1;
        faction = "BLU_F";
        crew = "GX_B_UAV_AI";
        typicalCargo[] = {"GX_B_UAV_AI"};
    };
    class GVAR(O_jammer): GVAR(jammer_base) {
        scope = 2;
        scopeCurator = 2;
        side = 0;
        faction = "OPF_F";
        crew = "GX_O_UAV_AI";
        typicalCargo[] = {"GX_O_UAV_AI"};
    };
    class GVAR(I_jammer): GVAR(jammer_base) {
        scope = 2;
        scopeCurator = 2;
        side = 2;
        faction = "IND_F";
        crew = "GX_I_UAV_AI";
        typicalCargo[] = {"GX_I_UAV_AI"};
    };
    // Assembling a round laid on the ground, as GX does for its own rounds.
    class WeaponHolder;
    class GroundWeaponHolder: WeaponHolder {
        class UserActions {
            class GVAR(assemble_relay) {
                displayName = "Assemble Drone40 (Relay)";
                priority = 50;
                radius = 2;
                position = "interact";
                showWindow = 0;
                hideOnUse = 1;
                onlyForPlayer = 0;
                shortcut = "";
                condition = QUOTE([ARR_2(this,QQGVAR(1Rnd_relay_M203))] call GX_fnc_drone_canPlace);
                statement = QUOTE([ARR_4(this,QQGVAR(1Rnd_relay_M203),player,'GROUND')] call GX_fnc_drone_place);
            };
            class GVAR(assemble_decoy) {
                displayName = "Assemble Drone40 (Decoy)";
                priority = 50;
                radius = 2;
                position = "interact";
                showWindow = 0;
                hideOnUse = 1;
                onlyForPlayer = 0;
                shortcut = "";
                condition = QUOTE([ARR_2(this,QQGVAR(1Rnd_decoy_M203))] call GX_fnc_drone_canPlace);
                statement = QUOTE([ARR_4(this,QQGVAR(1Rnd_decoy_M203),player,'GROUND')] call GX_fnc_drone_place);
            };
            class GVAR(assemble_jammer) {
                displayName = "Assemble Drone40 (Jammer)";
                priority = 50;
                radius = 2;
                position = "interact";
                showWindow = 0;
                hideOnUse = 1;
                onlyForPlayer = 0;
                shortcut = "";
                condition = QUOTE([ARR_2(this,QQGVAR(1Rnd_jammer_M203))] call GX_fnc_drone_canPlace);
                statement = QUOTE([ARR_4(this,QQGVAR(1Rnd_jammer_M203),player,'GROUND')] call GX_fnc_drone_place);
            };
        };
    };
};
