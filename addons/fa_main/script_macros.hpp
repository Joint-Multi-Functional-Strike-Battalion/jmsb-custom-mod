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

// Pass as the _script argument of CBA_fnc_addSetting so a config-declared
// faction override is re-asserted whenever CBA refreshes or a player edits the
// setting in the CBA menu. See docs/faction_setting_overrides.md.
#define SETTING_OVERRIDE_HOOK {if !(isNil QEFUNC(fa_main,applySettingOverrides)) then {[true] call EFUNC(fa_main,applySettingOverrides)}}

// JMFSB Debug macros
#include "\z\jmfsb\addons\fa_main\script_debug.hpp"

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

#define GRAVITY 9.8066

#define SD_TO_MIN_MAX(d) ((d) * 3.371) // Standard deviation -> min / max of random [min, mid, max]

// Angular unit conversion
#define MRAD_TO_MOA(d) ((d) * 3.43774677)
#define MOA_TO_MRAD(d) ((d) * 0.29088821)
#define DEG_TO_MOA(d) ((d) * 60)
#define MOA_TO_DEG(d) ((d) / 60)
#define DEG_TO_MRAD(d) ((d) * 17.45329252)
#define MRAD_TO_DEG(d) ((d) / 17.45329252)
#define MOA_TO_RAD(d) ((d) * 0.00029088)

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
