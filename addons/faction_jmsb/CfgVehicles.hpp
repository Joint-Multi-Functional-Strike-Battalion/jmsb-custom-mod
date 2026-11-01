// ONE MAN, AND THAT IS THE WHOLE FACTION.
//
// THE 1ST JMSB IS A PLAYER FACTION. Almost everything about a player is set in the
// mission - the slot's loadout, its gear, its vehicle - so a config roster of
// thirty specialists would be thirty classes nobody ever spawns. One scout is
// what a slot needs in order to exist; the mission does the rest.
//
// THE LOADOUT IS AN ARRAY, NOT A PILE OF weapons[] LINES. That is the
// authoring loop the faction builder handoff describes (section 9): an arsenal
// export becomes a getUnitLoadout array and a spawn hook applies it. The
// weapons[]/linkedItems[] underneath are what the EDITOR reads for its preview
// and what the man carries before the hook runs - they mirror the array rather
// than competing with it.
//
// THE ARRAY IS THE USER'S OWN EXPORT (2026-10-08, "this is the default load
// out"): SF fatigues in OCP, the Ferro Bison carrier in multicam with a PRC-152
// and two spare magazines in it, the OCP boonie, a VP9. The vest and the pistol
// come from MIG and SPS, which is why config.cpp requires both.

// CBA'S EXTENDED EVENT HANDLERS, DECLARED SO THEY CAN BE KEPT.
// A class that writes its own EventHandlers REPLACES the parent's, and the
// parent's is where CBA put its XEH hooks - so every one of these men was
// reported as "does not support Extended Event Handlers" and dropped out of
// everything built on them. Inheriting the class below inside our own
// EventHandlers keeps both: CBA's hooks and our loadout init.
class CBA_Extended_EventHandlers;

class CfgVehicles {
    // FORWARD DECLARATION, NOT A DEPENDENCY. B_CTRG_Soldier_F is the base
    // game's (Apex), defined in an addon that is not this one; declaring it
    // is what lets this config inherit from it. It replaced Aegis's
    // B_CTRG_Soldier_v2_F when Aegis left the load order.
    class B_CTRG_Soldier_F;

    class GVAR(ocp_ReconScout): B_CTRG_Soldier_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Recon Scout";
        side = 1;
        faction = QGVAR(ocp);
        editorSubcategory = "EdSubcat_Personnel_SpecialForces";

        uniformClass = "jmfsb_uniform_sof_SOF_U_B_SFFatigues_Shortsleeve_ocp";
        identityTypes[] = {"Head_NATO","LanguageENG_F","G_NATO_default"};

        // PISTOL ONLY, BY DESIGN. He observes and leaves; the VP9 is what he
        // has when leaving stops being an option.
        weapons[] = {"sps_hk_vp9_stnd_green", "Throw", "Put"};
        respawnWeapons[] = {"sps_hk_vp9_stnd_green", "Throw", "Put"};
        magazines[] = {"16Rnd_9x21_Mag", "16Rnd_9x21_Mag", "16Rnd_9x21_Mag"};
        respawnMagazines[] = {"16Rnd_9x21_Mag", "16Rnd_9x21_Mag", "16Rnd_9x21_Mag"};
        // No ACRE handheld any more (DEC1).
        items[] = {"jmfsb_medbags_FirstAid", "optic_NVS"};
        respawnItems[] = {"jmfsb_medbags_FirstAid", "optic_NVS"};
        linkedItems[] = {"jmfsb_vests_mig_MIG_FERRO_BISON_MC","jmfsb_headware_H_Booniehat_ocp_F","ItemMap","ItemGPS","ItemCompass","ACE_Altimeter"};
        respawnLinkedItems[] = {"jmfsb_vests_mig_MIG_FERRO_BISON_MC","jmfsb_headware_H_Booniehat_ocp_F","ItemMap","ItemGPS","ItemCompass","ACE_Altimeter"};

        ALiVE_orbatCreator_loadout[] = {{},{},{"sps_hk_vp9_stnd_green","","","",{"16Rnd_9x21_Mag",17},{},""},{"jmfsb_uniform_sof_SOF_U_B_SFFatigues_Shortsleeve_ocp",{{"jmfsb_medbags_FirstAid",1},{"optic_NVS",1}}},{"jmfsb_vests_mig_MIG_FERRO_BISON_MC",{{"16Rnd_9x21_Mag",2,17}}},{},"jmfsb_headware_H_Booniehat_ocp_F","",{},{"ItemMap","ItemGPS","","ItemCompass","ACE_Altimeter",""}};

        class EventHandlers {
            class CBA_Extended_EventHandlers: CBA_Extended_EventHandlers {};
            class GVAR(loadout) {
                init = "if (local (_this select 0)) then {_apply = {(_this select 0) spawn {sleep 0.2;if !(_this getVariable ['ALiVE_OverrideLoadout',false]) then {_loadout = getArray(configFile >> 'CfgVehicles' >> (typeOf _this) >> 'ALiVE_orbatCreator_loadout'); _this setUnitLoadout _loadout;reload _this}}};_this call _apply;(_this select 0) addMPEventHandler ['MPRespawn', _apply];};";
            };
        };
    };
};
