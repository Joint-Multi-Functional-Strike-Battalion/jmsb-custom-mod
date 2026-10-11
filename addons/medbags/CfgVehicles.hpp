class CfgVehicles {

    // INTERACTIONS
    class Man;
    class CAManBase: Man {
        // exceptions[] = {"isNotDead", "isNotUnconscious", "isNotSurrendering", "isNotHandcuffed", "isNotCarrying", "isNotDragging", "isNotEscorting", "isNotSwimming", "isNotRefueling", "isNotOnLadder", "isNotSitting", "isNotInside", "isNotInZeus", "notOnMap"};
        class ACE_SelfActions {
                class GVAR(Medical_Supplies_Action_FirstAid) {
                    displayName = "Unpack Boo Boo Bag";
                    condition = "[_player] call jmfsb_medbags_fnc_canUnpackFirstAid";
                    statement = "[_player] call jmfsb_medbags_fnc_doUnpackFirstAid";
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };

                class GVAR(Medical_Supplies_Action_MedicKit) {
                    displayName = "Unpack Medic Bag";
                    condition = "[_player] call jmfsb_medbags_fnc_canUnpackMedicKit";
                    statement = "[_player] call jmfsb_medbags_fnc_doUnpackMedicKit";
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };

                class GVAR(Medical_Supplies_Action_Trauma) {
                    displayName = "Unpack Trauma Kit";
                    condition = "[_player] call jmfsb_medbags_fnc_canUnpackTrauma";
                    statement = "[_player] call jmfsb_medbags_fnc_doUnpackTrauma";
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };

                class GVAR(Medical_Supplies_Action_Fluid) {
                    displayName = "Unpack Fluid Kit";
                    condition = "[_player] call jmfsb_medbags_fnc_canUnpackFluid";
                    statement = "[_player] call jmfsb_medbags_fnc_doUnpackFluid";
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };

                class GVAR(Medical_Supplies_Action_DrugKit) {
                    displayName = "Unpack Drug Kit";
                    condition = "[_player] call jmfsb_medbags_fnc_canUnpackDrugKit";
                    statement = "[_player] call jmfsb_medbags_fnc_doUnpackDrugKit";
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };
                class GVAR(Medical_Supplies_Action_Mopp) {
                    displayName = "Unpack MOPP Bag";
                    condition = QUOTE([_player] call FUNC(canUnpackMopp));
                    statement = QUOTE([_player] call FUNC(doUnpackMopp));
                    exceptions[] = {"isNotInside", "isNotSitting"};
                    icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                    showDisabled = 0;
                };
        };
        // ON THE CASUALTY, NOT ON YOURSELF. This is the one action here that
        // acts on somebody else, so it is a main action rather than a self
        // action - ACE hands it _target as well as _player, which is the whole
        // point: the bags come off the man on the ground.
        //
        // THE ARGUMENT LIST WAS THE BUG. It read `[(_player, _target)]`, which
        // is not an array of two - it is one parenthesised expression, and SQF
        // parses `_player, _target` there as an error. Both halves also called
        // a function whose PREP was commented out. Fixed together: the pair is
        // a real two-element array and both functions are compiled.
        //
        // isNotUnconscious is NOT in the exceptions. The action exists because
        // the man is unconscious, and ACE blocks interaction on an unconscious
        // target unless the action says otherwise.
        class ACE_MainActions {
            class GVAR(Medical_Supplies_Action_Take) {
                displayName = "Take Medical Bags";
                condition = QUOTE([ARR_2(_player,_target)] call FUNC(canTake));
                statement = QUOTE([ARR_2(_player,_target)] call FUNC(doTake));
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                icon = QPATHTOF(data\icons\medical_cross_ex_ca.paa);
                showDisabled = 0;
            };
        };
    };

    // MEDICAL SUPPLIES
    class Item_Base_F;

    class GVAR(Item_FirstAid): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Boo Boo Bag";
        editorPreview = QPATHTOF(data\previews\firstaid.jpg);
        vehicleClass = "Items";
        class TransportItems {
            // One nested class per item - the engine ignores bare
            // name=/count= here, which left every placed bag empty.
            class Item01 {
                name = QGVAR(FirstAid);
                count = 1;
            };
        };
    };

    class GVAR(Item_MedicKit): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Medic Bag";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        vehicleClass = "Items";
        class TransportItems {
            // One nested class per item - the engine ignores bare
            // name=/count= here, which left every placed bag empty.
            class Item01 {
                name = QGVAR(MedicKit);
                count = 1;
            };
        };
    };

    class GVAR(Item_Trauma): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Trauma Kit";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        vehicleClass = "Items";
        class TransportItems {
            // One nested class per item - the engine ignores bare
            // name=/count= here, which left every placed bag empty.
            class Item01 {
                name = QGVAR(Trauma);
                count = 1;
            };
        };
    };

    class GVAR(Item_Fluid): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Fluid Kit";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        vehicleClass = "Items";
        class TransportItems {
            // One nested class per item - the engine ignores bare
            // name=/count= here, which left every placed bag empty.
            class Item01 {
                name = QGVAR(Fluid);
                count = 1;
            };
        };
    };

    class GVAR(Item_DrugKit): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Drug Kit";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        vehicleClass = "Items";
        class TransportItems {
            // One nested class per item - the engine ignores bare
            // name=/count= here, which left every placed bag empty.
            class Item01 {
                name = QGVAR(DrugKit);
                count = 1;
            };
        };
    };
    class GVAR(Item_Mopp_MTP): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "MOPP Bag (MTP)";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        vehicleClass = "Items";
        class TransportItems {
            class Item01 {
                name = QGVAR(Mopp_MTP);
                count = 1;
            };
        };
    };
    class GVAR(Item_Mopp_Tropic): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "MOPP Bag (Tropic)";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        vehicleClass = "Items";
        class TransportItems {
            class Item01 {
                name = QGVAR(Mopp_Tropic);
                count = 1;
            };
        };
    };
    class GVAR(Item_Mopp_Wdl): Item_Base_F {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "MOPP Bag (Woodland)";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        vehicleClass = "Items";
        class TransportItems {
            class Item01 {
                name = QGVAR(Mopp_Wdl);
                count = 1;
            };
        };
    };
};
