// CBA Settings [ADDON: jmfsb_medbags]

// WHAT IS IN EACH BAG, AS SETTINGS. Every bag's contents used to be a column of
// hardcoded EFUNC(common,addItem) calls in its own fnc_doUnpack* - so changing
// what a Trauma Kit holds meant editing SQF and rebuilding the mod, for a
// number. The five lists below are the same items in the same order; the
// functions now read them.
//
// FORMAT: class:count, comma separated. Whitespace around either is ignored.
//
// ORDER IS SIGNIFICANT and DUPLICATES ARE KEPT. The list is issued top to
// bottom into a man who runs out of room partway down, so what is early in the
// list is what he ends up carrying. That is also why MedicKit and Trauma name
// ACE_fieldDressing and ACE_tourniquet more than once: those repeats are in the
// original lists, they land in different containers as earlier ones fill, and
// collapsing them into one bigger number is not the same issue.
//
// A CLASS NOTHING DEFINES IS SKIPPED, with a line in the RPT - see
// fnc_issueContents. It is not silently dropped and it does not litter the
// ground with an empty holder.

[
    QGVAR(contentsFirstAid), "EDITBOX",
    ["Boo Boo Bag contents", "class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "ACE_fieldDressing:6, ACE_quikClot:6, ACE_tourniquet:2, ACE_EarPlugs:1, ACE_salineIV_500:1, ACE_splint:1",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(contentsMedicKit), "EDITBOX",
    ["Medic Bag contents", "class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "ACE_fieldDressing:18, ACE_elasticBandage:14, ACE_packingBandage:14, ACE_quikClot:14, ACE_salineIV_500:8, ACE_tourniquet:8, ACE_splint:8, ACE_fieldDressing:6, ACE_tourniquet:4, ACE_EarPlugs:2, ACE_plasmaIV_500:4, ACE_tourniquet:4, ACE_suture:12",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(contentsTrauma), "EDITBOX",
    ["Trauma Kit contents", "class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "ACE_fieldDressing:28, ACE_elasticBandage:24, ACE_packingBandage:24, ACE_quikClot:24, ACE_salineIV:12, ACE_tourniquet:12, ACE_splint:12, ACE_fieldDressing:24, ACE_tourniquet:10, ACE_EarPlugs:2, ACE_plasmaIV:8, ACE_tourniquet:12, ACE_suture:24, ACE_surgicalKit:1",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(contentsFluid), "EDITBOX",
    ["Fluid Kit contents", "class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "ACE_salineIV:24, ACE_plasmaIV:12, ACE_bloodIV:8",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(contentsDrugKit), "EDITBOX",
    ["Drug Kit contents", "class:count, comma separated. Issued in order, top first, so the front of the list is what a man with no room left keeps."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "ACE_morphine:16, ACE_adenosine:8, ACE_epinephrine:8",
    true
] call CBA_fnc_addSetting;

// The suit is not in this list: each MOPP bag issues its own camo first
// (its GVAR(suit) config value), then this.
[
    QGVAR(contentsMopp), "EDITBOX",
    ["MOPP Bag contents", "class:count, comma separated, issued after the bag's own CBRN suit. Respirator and the ACM CBRN self-aid autoinjectors."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    "JCA_G_AirPurifyingRespirator_03_black_clear_F:1, ACM_Autoinjector_ATNA:2, ACM_Autoinjector_Midazolam:1",
    true
] call CBA_fnc_addSetting;

// THESE ARE THE ACE-ONLY DEFAULTS. With ACM loaded, jmfsb_acm re-defaults all
// five to ACM's kit at preInit (addons/acm/XEH_preInit.sqf) - one list per
// bag, pitched at who opens it. Anyone opens the Boo Boo Bag, a Combat
// Lifesaver (ACE medic class 1) the Medic Bag, a Medic (class 2) the Trauma,
// Fluid and Drug kits - fnc_canUnpack*.

// ---- where it goes --------------------------------------------------------

// ONE ORDER FOR EVERY BAG. Each fnc_doUnpack* carried its own private _order
// and private _overflow, identical in four of the five and never read from
// anywhere - a setting in all but name. It is now one, because a unit's kit
// should not land somewhere different depending on which bag it came out of.
//
// The numbers are EFUNC(common,addItem)'s container codes: 1 uniform, 2 vest, 3
// backpack. First that will take the item wins.
[
    QGVAR(fillOrder), "LIST",
    ["Fill order", "Which container an unpacked item goes in first. The rest are tried in turn as each fills up. Applies to every bag, and to bags taken off a casualty."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    [
        ["3,2,1", "1,2,3", "2,3,1", "2,1,3"],
        ["Backpack, vest, uniform", "Uniform, vest, backpack", "Vest, backpack, uniform", "Vest, uniform, backpack"],
        0
    ],
    true
] call CBA_fnc_addSetting;

// OFF MEANS THE SURPLUS IS GONE. On, anything that will not fit in any
// container is dropped in a holder at the man's feet - which is what every bag
// did before this was a setting, and why unpacking a Trauma Kit in a fireteam
// leader's uniform is survivable. Off, the count that did not fit is simply not
// issued: tidier, and a way to stop a man unpacking a medic bag he cannot carry
// and leaving the surplus on the ground for nobody.
[
    QGVAR(fillOverflow), "CHECKBOX",
    ["Overflow to the ground", "What will not fit is dropped at the unit's feet. Off: the surplus is not issued at all. Never drops anything in a vehicle or in deep water."],
    ["1st Joint Multi-Functional Strike Battalion", "MedBags"],
    true,
    true
] call CBA_fnc_addSetting;
