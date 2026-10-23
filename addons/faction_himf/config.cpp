#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(APC_Pandur), QGVAR(Rifleman), QGVAR(Rifleman_Unarmed), QGVAR(SquadLeader), QGVAR(TeamLeader), QGVAR(Autorifleman), QGVAR(AmmoBearer), QGVAR(Grenadier), QGVAR(Rifleman_AT), QGVAR(Rifleman_AA), QGVAR(Rifleman_AAA), QGVAR(Marksman), QGVAR(HeavyGunner), QGVAR(Medic), QGVAR(Engineer), QGVAR(ExplosiveSpecialist), QGVAR(Officer), QGVAR(RadioOperator), QGVAR(MortarGunner), QGVAR(MortarAssistant), QGVAR(Crew), QGVAR(Helipilot), QGVAR(Helicrew), QGVAR(Pilot), QGVAR(Recon), QGVAR(Recon_TL), QGVAR(Recon_AR), QGVAR(Recon_GL), QGVAR(Recon_AT), QGVAR(Recon_M), QGVAR(Recon_Medic), QGVAR(Recon_JTAC), QGVAR(Recon_Demo), QGVAR(UAV_01_Bag), QGVAR(UAV_06_Bag), QGVAR(B_Carryall_Titan_AA), QGVAR(UAVOperator), QGVAR(PelicanOperator), QGVAR(Boat), QGVAR(Boat_Armed), QGVAR(Mortar), QGVAR(HMG), QGVAR(HMG_High), QGVAR(Mortar_Mk6), QGVAR(AT_Dragon), QGVAR(LM_Tube_300), QGVAR(LM_Tube_600), QGVAR(UAV_Hunter_SP), QGVAR(Heli_Light), QGVAR(Heli_Light_Armed), QGVAR(Offroad), QGVAR(Offroad_LMG), QGVAR(Offroad_AT), QGVAR(Plane_Civil), QGVAR(Quadbike), QGVAR(UAV_Darter), QGVAR(UAV_Falcon), QGVAR(UAV_Pelican), QGVAR(UGV_Stomper), QGVAR(UGV_Stomper_RCWS), QGVAR(UGV_Pelter), QGVAR(USV_Magura), QGVAR(UAV_Raven)
        };
        weapons[] = {
        };
        requiredVersion = REQUIRED_VERSION;
        // Every man inherits Atlas's own HIMF - since 2026-10-04 the copies
        // imported into jmfsb_uniform (tools/aegis_port --seeds), so Atlas is
        // no longer required. The tier magazines are still named as STRINGS,
        // so jmfsb_fa_tiers is not required.
        requiredAddons[] = {"jmfsb_main", "jmfsb_uniform", "jmfsb_vehicle", "jmfsb_weapons"};
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgFactionClasses.hpp"
#include "CfgWeapons.hpp"
#include "CfgVehicles.hpp"
#include "CfgGroups.hpp"
