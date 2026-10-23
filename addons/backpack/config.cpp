#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(talon_kitbag_coyote),
            QGVAR(talon_kitbag_winter),
            QGVAR(talon_kitbag_khaki),
            QGVAR(TFAR_rt1523g_kitbag),
            QGVAR(kitbag_khaki_west),
            QGVAR(kitbag_coyote_west),
            QGVAR(kitbag_winter_west),
            QGVAR(kitbag_black_west),
            QGVAR(B_RadioBag_01_Multicam),
            QGVAR(B_RadioBag_01_Multicam_Snow),
            QGVAR(B_RadioBag_01_Multicam_Woodland),
            QGVAR(B_RadioBag_01_Solid_CoyoteBrown),
            QGVAR(B_RadioBag_01_Solid_Olive),
            QGVAR(B_RadioBag_01_Solid_Ranger_Green),
            QGVAR(B_RadioBag_01_Solid_Tan),
            QGVAR(B_RadioBag_01_Solid_White),
            QGVAR(AssaultPack_Multicam),
            QGVAR(AssaultPack_Multicam_Snow),
            QGVAR(AssaultPack_Multicam_Woodland),
            QGVAR(AssaultPack_Solid_CoyoteBrown),
            QGVAR(AssaultPack_Solid_Olive),
            QGVAR(AssaultPack_Solid_Ranger_Green),
            QGVAR(AssaultPack_Solid_White),
            QGVAR(AssaultPackEnhanced_Multicam),
            QGVAR(AssaultPackEnhanced_Multicam_Snow),
            QGVAR(AssaultPackEnhanced_Multicam_Woodland),
            QGVAR(AssaultPackEnhanced_Solid_CoyoteBrown),
            QGVAR(AssaultPackEnhanced_Solid_Olive),
            QGVAR(AssaultPackEnhanced_Solid_Ranger_Green),
            QGVAR(AssaultPackEnhanced_Solid_White),
            QGVAR(Backpack_Kitbag_Medic_Coyote),
            QGVAR(Backpack_Kitbag_Medic_Green),
            QGVAR(Backpack_Kitbag_Medic_MTP),
            QGVAR(Backpack_Kitbag_Medic_RGR),
            QGVAR(Backpack_Kitbag_Medic_Sage),
            QGVAR(Backpack_Kitbag_Medic_Tan),
            QGVAR(Backpack_Kitbag_Medic_White),
            QGVAR(Bergen_Multicam),
            QGVAR(Bergen_Multicam_Snow),
            QGVAR(Bergen_Multicam_Woodland),
            QGVAR(Carryall_Multicam),
            QGVAR(Carryall_Multicam_Snow),
            QGVAR(Carryall_Multicam_Woodland),
            QGVAR(Carryall_Solid_CoyoteBrown),
            QGVAR(Carryall_Solid_Olive),
            QGVAR(Carryall_Solid_Ranger_Green),
            QGVAR(Carryall_Solid_White),
            QGVAR(FieldPack_Multicam),
            QGVAR(FieldPack_Multicam_Snow),
            QGVAR(FieldPack_Multicam_Woodland),
            QGVAR(Kitbag_Multicam),
            QGVAR(Kitbag_Multicam_Snow),
            QGVAR(Kitbag_Multicam_Woodland),
            QGVAR(Kitbag_Solid_CoyoteBrown),
            QGVAR(Kitbag_Solid_Olive),
            QGVAR(Kitbag_Solid_Ranger_Green),
            QGVAR(Kitbag_Solid_White),
            QGVAR(TacticalPack_Multicam),
            QGVAR(TacticalPack_Multicam_Snow),
            QGVAR(TacticalPack_Multicam_Woodland),
            QGVAR(TacticalPack_Solid_CoyoteBrown),
            QGVAR(TacticalPack_Solid_Olive),
            QGVAR(TacticalPack_Solid_Ranger_Green),
            QGVAR(TacticalPack_Solid_White),
            QGVAR(AssaultPack_ocp),
            QGVAR(Carryall_ocp),
            QGVAR(Kitbag_ocp)
        };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "A3_Characters_F",
            "A3_Characters_F_Enoch",
            "A3_Supplies_F_Enoch_Bags",
            "A3_Characters_F_Exp",
            "A3_Supplies_F_Exp"
        };
        author = "";
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
#include "CfgWeapons.hpp"
#include "XtdGear.hpp"
