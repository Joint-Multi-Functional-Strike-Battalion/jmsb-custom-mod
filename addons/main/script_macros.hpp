#include "\x\cba\addons\main\script_macros_common.hpp"
#define DFUNC(module) TRIPLES(ADDON,fnc,module)
#ifdef DISABLE_COMPILE_CACHE
    #undef PREP
    #define PREP(fncName) DFUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #undef PREP
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

// ACE3 reference macros
#define ACE_PREFIX ace
#define ACE_ADDON(module) DOUBLES(ACE_PREFIX,module)

#define ACEGVAR(module,var)         TRIPLES(ACE_PREFIX,module,var)
#define QACEGVAR(module,var)        QUOTE(ACEGVAR(module,var))

#define ACEFUNC(module,function)    TRIPLES(DOUBLES(ACE_PREFIX,module),fnc,function)
#define QACEFUNC(module,function)   QUOTE(ACEFUNC(module,function))

#define ACELSTRING(module,string)   QUOTE(TRIPLES(STR,DOUBLES(ACE_PREFIX,module),string))
#define ACECSTRING(module,string)   QUOTE(TRIPLES($STR,DOUBLES(ACE_PREFIX,module),string))

// JMFSB macros
#define IS_MOD_LOADED(modclass)     (isClass (configFile >> "CfgPatches" >> #modclass))

// Display text for the mod's own 3DEN furniture. Literals rather than a
// stringtable: these four are English-only and the mod inlines its display
// strings everywhere else.
#define JMFSB_ATTRIBUTES            "1st Joint Multi-Functional Strike Battalion Attributes"
#define JMFSB_CATEGORY              "1st Joint Multi-Functional Strike Battalion"

// Drawn from when an intel product does not name a colour, so two circles up at
// the same time can be told apart instead of merging into one red smear. Every
// entry is a CfgMarkerColors class that reads clearly as an OUTLINE on both the
// satellite and the topographic map - no black, no white, nothing that vanishes
// over a town. Lives here rather than in one addon because both the renderer
// (common) and the ladder that keeps a colour per site (hacking) need it.
#define INTEL_CIRCLE_COLOURS ["ColorRed", "ColorOrange", "ColorYellow", "ColorGreen", "ColorBlue", "ColorPink", "ColorBrown"]

#define JMFSB_TOOLBAR               "1st Joint Multi-Functional Strike Battalion"
#define JMFSB_TOOLBAR_WIKI          "Wiki"

// JMFSB Debug macros
#include "\z\jmfsb\addons\main\script_debug.hpp"

// Items
#define ITEMS_2(var) QUOTE(var), QUOTE(var)
#define ITEMS_3(var) QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_4(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_5(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_6(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_7(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_8(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_9(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_10(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_11(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)
#define ITEMS_12(var) QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var), QUOTE(var)

#define MACRO_ADDWEAPON(WEAPON,COUNT) \
    class _xx_##WEAPON { \
        weapon = #WEAPON; \
        count = COUNT; \
    }

#define MACRO_ADDITEM(ITEM,COUNT) \
    class _xx_##ITEM { \
        name = #ITEM; \
        count = COUNT; \
    }

#define MACRO_ADDMAGAZINE(MAGAZINE,COUNT) \
    class _xx_##MAGAZINE { \
        magazine = #MAGAZINE; \
        count = COUNT; \
    }

#define MACRO_ITEM_COMMON \
        dlc = QUOTE(PREFIX); \
        scope = 2; \
        scopeCurator = 2; \
        scopeArsenal=2; \
        ACE_GForceCoef = 1;     

#define MACRO_UNIFORM_COMMON \
        author = QAUTHOR; \
        scope = 2; \
        scopeCurator = 2; \
        scopeArsenal=2; \

#define MACRO_ADDBACKPACK(BACKPACK,COUNT) \
    class _xx_##BACKPACK { \
        backpack = #BACKPACK; \
        count = COUNT; \
    }

#define MACRO_LANDVEHICLE_CARGO \
    class TransportBackpacks {}; \
    class TransportItems { \
        MACRO_ADDITEM(FirstAidKit,8); \
    }; \
    class TransportMagazines { \
        MACRO_ADDMAGAZINE(SmokeShell,6); \
        MACRO_ADDMAGAZINE(SmokeShellBlue,2); \
        MACRO_ADDMAGAZINE(SmokeShellRed,2); \
    }; \
    class TransportWeapons {};

#define MACRO_AIRVEHICLE_CARGO \
    class TransportBackpacks { \
        MACRO_ADDBACKPACK(B_Parachute,2); \
    }; \
    class TransportItems { \
        MACRO_ADDITEM(FirstAidKit,8); \
        MACRO_ADDITEM(ItemGPS,1); \
        MACRO_ADDITEM(ToolKit,1); \
    }; \
    class TransportMagazines { \
        MACRO_ADDMAGAZINE(SmokeShell,6); \
        MACRO_ADDMAGAZINE(SmokeShellBlue,2); \
        MACRO_ADDMAGAZINE(SmokeShellRed,2); \
    }; \
    class TransportWeapons {};


// LOADOUT DEFINES

#define TRANSPORT_MAGAZINE(id,qty) class _xx_##id { magazine = #id; count = qty; };
#define TRANSPORT_ITEM(id,qty) class _xx_##id { name = #id; count = qty; };
#define TRANSPORT_WEAPON(id,qty) class _xx_##id { weapon = #id; count = qty; };
#define TRANSPORT_BACKPACK(id,qty) class _xx_##id { backpack = #id; count = qty; };

// item types
#define TYPE_DEFAULT 0
#define TYPE_MUZZLE 101
#define TYPE_OPTICS 201
#define TYPE_FLASHLIGHT 301
#define TYPE_BIPOD 302
#define TYPE_FIRST_AID_KIT 401
#define TYPE_FINS 501 // not implemented
#define TYPE_BREATHING_BOMB 601 // not implemented
#define TYPE_NVG 602
#define TYPE_GOGGLE 603
#define TYPE_SCUBA 604 // not implemented
#define TYPE_HEADGEAR 605
#define TYPE_FACTOR 607
#define TYPE_RADIO 611
#define TYPE_HMD 616
#define TYPE_BINOCULAR 617
#define TYPE_MEDIKIT 619
#define TYPE_TOOLKIT 620
#define TYPE_UAV_TERMINAL 621
#define TYPE_VEST 701
#define TYPE_UNIFORM 801
#define TYPE_BACKPACK 901

#ifdef DISABLE_COMPILE_CACHE
    #undef PREP
    #define PREP(fncName) DFUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #undef PREP
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

#define PREP_MODULE(folder) [] call compile preprocessFileLineNumbers QPATHTOF(folder\__PREP__.sqf)

#define SOCOMD_DEFIB_isHC (!hasInterface && !isDedicated)

#define IDC_STAMINA_BAR 193

#define SOCOMD_DEFIB_DEPRECATED(arg1,arg2,arg3) WARNING_3("%1 is deprecated. Support will be dropped in version %2. Replaced by: %3",arg1,arg2,arg3)

#define PFORMAT_10(MESSAGE,A,B,C,D,E,F,G,H,I,J) \
    format ['%1: A=%2, B=%3, C=%4, D=%5, E=%6, F=%7, G=%8, H=%9, I=%10 J=%11', MESSAGE, RETNIL(A), RETNIL(B), RETNIL(C), RETNIL(D), RETNIL(E), RETNIL(F), RETNIL(G), RETNIL(H), RETNIL(I), RETNIL(J)]
#ifdef DEBUG_MODE_FULL
#define TRACE_10(MESSAGE,A,B,C,D,E,F,G,H,I,J) \
    [THIS_FILE_, __LINE__, PFORMAT_10(MESSAGE,A,B,C,D,E,F,G,H,I,J)] call CBA_fnc_log
#else
   #define TRACE_10(MESSAGE,A,B,C,D,E,F,G,H,I,J) /* disabled */
#endif

#define GRAVITY 9.8066

#define SD_TO_MIN_MAX(d) ((d) * 3.371) // Standard deviation -> min / max of random [min, mid, max]

// Angular unit conversion
#define MRAD_TO_MOA(d) ((d) * 3.43774677) // Conversion factor: 54 / (5 * PI)
#define MOA_TO_MRAD(d) ((d) * 0.29088821) // Conversion factor: (5 * PI) / 54
#define DEG_TO_MOA(d) ((d) * 60) // Conversion factor: 60
#define MOA_TO_DEG(d) ((d) / 60) // Conversion factor: 1 / 60
#define DEG_TO_MRAD(d) ((d) * 17.45329252) // Conversion factor: (50 * PI) / 9
#define MRAD_TO_DEG(d) ((d) / 17.45329252) // Conversion factor: 9 / (50 * PI)
#define MOA_TO_RAD(d) ((d) * 0.00029088) // Conversion factor: PI / 10800

#define QPATHTOF_SOUND(var1) QUOTE(PATHTOF2_SYS(PREFIX,COMPONENT,var1))
#define QQPATHTOF_SOUND(var1) QUOTE(QPATHTOF_SOUND(var1))

#define HEARING(CLASSNAME) \
    class CLASSNAME: ItemCore { \
        ace_hearing_protection = 0.75; \
        ace_hearing_lowerVolume = 0; \
    }

#define HEARING_PARENT(CLASSNAME,PARENT) \
    class CLASSNAME: PARENT { \
        ace_hearing_protection = 0.75; \
        ace_hearing_lowerVolume = 0; \
    }

#define MACRO_ACE_HEARING \
        ace_hearing_protection = 0.80; \
        ace_hearing_lowerVolume = 0.60; \
        ace_hearing_hasEHP = 1;

// JMFSB'S PROTECTION, ONCE. The HitpointsProtectionInfo every jmfsb combat
// helmet and plate carrier wears, so a pack ported in later (MIG, 2026-10-07)
// lands on the same numbers as the gear already here instead of its own.
// Goes inside `class ItemInfo: ItemInfo { ... };` - mass and load stay the item's.
#define JMFSB_HELMET_STANDARD_PROTECTION \
    class HitpointsProtectionInfo { \
        class Head { \
            hitpointName = "HitHead"; \
            armor = 6; \
            passThrough = 0.5; \
        }; \
    };

#define JMFSB_PLATE_CARRIER_STANDARD_PROTECTION \
    class HitpointsProtectionInfo { \
        class Chest { \
            hitpointName = "HitChest"; \
            armor = 29; \
            passThrough = 0.085; \
        }; \
        class Body { \
            hitpointName = "HitBody"; \
            passThrough = 0.085; \
        }; \
        class Diaphragm { \
            hitpointName = "HitDiaphragm"; \
            armor = 29; \
            passThrough = 0.085; \
        }; \
        class Abdomen { \
            hitpointName = "HitAbdomen"; \
            armor = 19; \
            passThrough = 0.255; \
        }; \
        class Arms { \
            hitpointName = "HitArms"; \
            armor = 12; \
            passThrough = 0.55; \
        }; \
        class Legs { \
            hitpointName = "HitLegs"; \
            armor = 12; \
            passThrough = 0.55; \
        }; \
    };

#define JMFSB_PLATE_CARRIER_HEAVY_PROTECTION \
    class HitpointsProtectionInfo { \
        class Chest { \
            hitpointName = "HitChest"; \
            armor = 34; \
            passThrough = 0.06; \
        }; \
        class Body { \
            hitpointName = "HitBody"; \
            passThrough = 0.06; \
        }; \
        class Diaphragm { \
            hitpointName = "HitDiaphragm"; \
            armor = 34; \
            passThrough = 0.06; \
        }; \
        class Abdomen { \
            hitpointName = "HitAbdomen"; \
            armor = 24; \
            passThrough = 0.21; \
        }; \
        class Arms { \
            hitpointName = "HitArms"; \
            armor = 14; \
            passThrough = 0.5; \
        }; \
        class Legs { \
            hitpointName = "HitLegs"; \
            armor = 14; \
            passThrough = 0.5; \
        }; \
    };


// THE SEVEN ARMA RANKS, IN ORDER, ONCE. Every gate, rank set and rank compare
// in the mod used to carry its own copy of this list; a copy that disagreed
// would have let a rank through or held one back with nobody the wiser.
#define ARMA_RANKS ["PRIVATE","CORPORAL","SERGEANT","LIEUTENANT","CAPTAIN","MAJOR","COLONEL"]
#define ARMA_RANK_INDEX(r) (ARMA_RANKS find toUpper (r))
