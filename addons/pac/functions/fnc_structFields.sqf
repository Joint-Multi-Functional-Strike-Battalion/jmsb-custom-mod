#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_structFields

Description:
    THE ONE TABLE of what each editable structure section holds. The config
    loader, the server's editor door and the client's editor screen all read
    it, so a field added here is read from config, coerced on save, and
    offered in the editor with one change.

        [field, kind, label, hint]
        kind   "t" text | "a" array (comma-separated in the editor) |
               "n" number
        label  "" = kept but not shown in the editor (the editor has three
               free rows; ID and NAME are fixed)

    `name` is not listed - every section has it and the editor has its own
    row for it.

Parameters:
    0: Section <STRING>

Returns:
    The field table, [] for an unknown section <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_section", "", [""]]];

// Every row comes back FIVE wide - [field, kind, label, hint, picker] - so no
// reader has to check whether a section bothered to declare a picker. The
// tables below say three or four; this pads the rest.
private _fnc_pad = {
    params ["_rows"];
    _rows apply {
        private _r = +_x;
        while {count _r < 5} do {_r pushBack ""};
        _r
    }
};

private _out = switch (_section) do {
    // insignia rides along unlabelled: a texture path is not typed in game
    // POINTS REQUIRED IS ON THIS SCREEN, exactly as it is a column on the
    // website's ranks page - but it is NOT stored on the rank. It lives where
    // a mission's config_pac.hpp puts it, promotion >> rank_<rankId> >> value,
    // and FUNC(structSelect) reads it from there and FUNC(adminStructure)
    // writes it back there. Editing a rank and finding nowhere to put its
    // points was the whole of "when you go to edit no points" (2026-09-09).
    case "ranks": {[
        ["abbrev", "t", "ABBREV", "e.g. SGT"],
        ["payGrade", "t", "PAY GRADE", "e.g. E-4 - shown on the operator file"],
        ["armaRank", "t", "ARMA RANK", "PRIVATE CORPORAL SERGEANT LIEUTENANT CAPTAIN MAJOR COLONEL"],
        ["points", "n", "POINTS REQUIRED", "promotion points a man needs before he can hold this rank - the promotion document's rank_<id> rung"],
        ["insignia", "t", "", ""]
    ]};
    // colour: the squad panel draws a man's skill letters in it, so MED and
    // CLS read green down the whole section at a glance (user, 2026-09-05).
    case "skills": {[
        ["abbrev", "t", "ABBREV", "2-4 letters for the squad panel, e.g. MED; empty = the id in capitals"],
        ["effects", "a", "EFFECTS", "comma-separated: medic:2, engineer:1, eod:1, trait:isJFO, var:name=value, arsenal:marksman"],
        ["color", "t", "COLOUR", "R,G,B 0-255 for the skill letters on the squad panel, e.g. 76,175,80; empty = the ink colour"]
    ]};
    case "awards": {[
        ["type", "t", "TYPE", "badge / ribbon / medal - free text"],
        ["image", "t", "IMAGE", "texture path, may be empty"],
        ["campaign", "t", "CAMPAIGN", "may be empty"]
    ]};
    case "statuses": {[]};
    case "admins": {[]};
    // THE PROMOTION FORMULA AS DATA (2026-09-05). Every item is {name, value};
    // the id says what the value means - a weight (hour, op, serviceMonth,
    // gradeMonth, training, award = points per unit) or a rung on the ladder
    // (rank_<rankId> = points required to hold that rank). FUNC(promotionPoints)
    // reads it; nothing is hard-coded.
    // THE SUPPLY CATALOGUE. One item per crate, its contents one per line as
    // "classname count" - the same cards the website draws, in the shape a
    // three-box screen can carry. FUNC(structItems) reads the document's SQF
    // into this and FUNC(adminStructure) writes it back.
    case "logistics": {[
        ["contents", "a", "CONTENTS", "one per line: classname count - ACE_fieldDressing 80"]
    ]};
    // PYLON PRESETS. One item per aircraft, its presets one per line as
    // "preset: magazine, magazine".
    case "pylons": {[
        ["presets", "a", "PRESETS", "one per line: preset name: magazine, magazine"]
    ]};
    // NAME is the description here, and it is not editable - the setting's
    // meaning is not the admin's to rewrite. Only VALUE is.
    case "settings": {[
        ["value", "t", "VALUE", "autoSlot 1 or 0 - slotMatch role or slot - arsenalMode role, skills or both - savedLoadouts a count, 0 for off"]
    ]};
    case "promotion": {[
        ["value", "n", "VALUE", "points per unit for a weight (hour and op = operations only, trainingSession, trainingHour, serviceMonth, gradeMonth, training, award); points required for a rank_<rankId> rung"]
    ]};
    // THE TRAINING CATALOGUE (2026-09-05): the courses a unit runs, one item
    // each, keyed by course id. The player page's TRAINING dropdown lists them;
    // a course held is logged on the record by its id, so a rename follows.
    case "trainings": {[
        ["category", "t", "CATEGORY", "free text that groups the list - Medical, Leadership, Fires, Aviation ..."],
        ["description", "t", "DESCRIPTION", "one line - what the course covers"]
    ]};
    // A net's id is its name on the rail and the radio; NAME is the
    // description. ORDER is its place on the rail, first = 0.
    case "nets": {[
        ["order", "n", "ORDER", "position on the rail and in the mailbox list, 0 first"]
    ]};
    // THE TAC//PAD'S OWN COLOURS - the same <unit>.schemes document the
    // website's Colours page edits (2026-09-09). A scheme is three tokens and
    // nothing else: every divider, tint and pressed state is derived from
    // them. They are offered as presets on the settings screen; the six the
    // mod ships are the mod's and are not in here.
    case "schemes": {[
        ["ground", "t", "GROUND", "#rrggbb - what the panel is painted on"],
        ["ink", "t", "INK", "#rrggbb - the text on it"],
        ["accent", "t", "ACCENT", "#rrggbb - the one colour that is neither"]
    ]};
    // A role's id is its Dynamic_Roles class. THE WHOLE ROLE lives here -
    // the three gates the editor shows, and every property the group menu,
    // the slot setup, the net and tile gates read (the mission's
    // config_roles.hpp shape, by the same names - see
    // jmfsb_groups_fnc_roleFields). The unlabelled fields ride along
    // untouched when the editor saves.
    // A ROLE IS EIGHT SCREENS ON ONE SECTION (2026-09-09), the same eight the
    // website has: identity, gates, nets, tiles, traits, variables, loadout,
    // arsenal. Every screen returns the WHOLE field list and labels only its
    // own three - an unlabelled field is not drawn and rides along untouched
    // when the editor saves, which is how a role's loadout survives somebody
    // editing its tiles. FUNC(structBase) maps every one of them to "roles".
    case "roles";
    case "roles_gates";
    case "roles_nets";
    case "roles_tiles";
    case "roles_traits";
    case "roles_vars";
    case "roles_loadout";
    case "roles_arsenal";
    case "roles_items": {
        private _labels = createHashMapFromArray (switch (_section) do {
            case "roles_gates": {[
                ["minRank", ["MIN RANK", "the player's rank must map to this or a higher Arma rank; none = no gate", "ranks"]],
                ["requiredSkills", ["REQUIRED SKILLS", "skills he must hold - pick to add, pick again to remove; empty = no skill gate", "skills"]],
                ["uids", ["LOCKED TO", "Steam ids, comma-separated; non-empty = only these players (and admin grants) may take it", ""]]
            ]};
            case "roles_nets": {[
                ["nets", ["NETS", "the TAC//MSG nets he reads - pick to add, pick again to remove. A net he is not on is a net he cannot see; there is no 'all nets'", "nets"]]
            ]};
            case "roles_tiles": {[
                ["tiles", ["TILES", "the TAC//PAD tiles he sees - pick to add, pick again to remove. A tile not listed is not drawn and its app cannot be reached", "tiles"]]
            ]};
            case "roles_traits": {[
                ["traits", ["TRAITS", "pick to add, pick again to remove. The engine's seven and this unit's own; the custom flag is set from which list the name came off. Anything a PAC skill owns is applied afterwards and ignored here", "traits"]]
            ]};
            case "roles_vars": {[
                ["customVariables", ["CUSTOM VARIABLES", "setVariable on the man when he slots in - pick to add one at its usual value, pick again to remove. Edit a number in the box beside it", "vars"]]
            ]};
            case "roles_loadout": {[
                ["defaultLoadout", ["DEFAULT LOADOUT", "what he spawns in, as the array a config file writes. CAPTURE takes it off you as you stand", ""]]
            ]};
            // NO "GROUP ARSENAL" FIELD (user, 2026-09-09: "Group arsenal
            // Arsenal_Wraith there is no fucking Arsenal_Wraith remeber you
            // were supose to make it part of the fucking role config"). It was
            // a typed pointer at a separate class, and on this unit all five
            // it pointed at were empty. A role's own arsenal is the document
            // role_<CLASS>, derived from its id the way plt_ and sqd_ are, so
            // there is nothing to name and nothing to spell wrong - edit it on
            // the arsenal screen, under that name. Same as the website.
            case "roles_arsenal": {[
                ["arsenalWeapons", ["WEAPONS", "classnames only this role may draw, comma-separated. ON TOP of the common arsenal, never instead of it"]],
                ["arsenalMagazines", ["MAGAZINES", "classnames, comma-separated"]]
            ]};
            case "roles_items": {[
                ["arsenalItems", ["ITEMS", "classnames, comma-separated - ACE_Vector, ACRE_PRC117F"]],
                ["arsenalBackpacks", ["BACKPACKS", "classnames, comma-separated"]]
            ]};
            // "roles" itself is the identity screen; NAME is the box above.
            default {[
                ["description", ["DESCRIPTION", "what the job is - read on the slot card"]],
                ["icon", ["ICON", "a paa path; empty is fine"]],
                ["slotTag", ["SLOT TAG", "how the HUD labels the slot; empty means the class name"]]
            ]};
        });
        private _all = [
            ["name", "t"], ["description", "t"], ["icon", "t"], ["slotTag", "t"],
            ["minRank", "t"], ["requiredSkills", "a"], ["uids", "a"],
            ["nets", "a"], ["tiles", "a"], ["traits", "a"], ["customVariables", "a"],
            ["defaultLoadout", "a"],
            ["arsenalWeapons", "a"], ["arsenalMagazines", "a"],
            ["arsenalItems", "a"], ["arsenalBackpacks", "a"],
            ["arsenalWhitelist", "a"], ["defaultSkills", "a"]
        ];
        _all apply {
            _x params ["_field", "_kind"];
            private _lab = _labels getOrDefault [_field, ["", "", ""]];
            [_field, _kind, _lab # 0, _lab # 1, _lab param [2, ""]]
        };
    };
    // THE UNIT'S OWN TRAIT NAMES (2026-09-09). setUnitTrait's third argument
    // says whether a name is a custom one, and a name with that flag wrong is
    // thrown away without a word. Listing them means a role ticks a name off a
    // list instead of anybody having to remember which is which.
    // A NAMED LIST OF CLASSNAMES - one of the arsenal's lists, or one of the
    // vehicle spawner's. The id is the list's name; see FUNC(structItems).
    case "arsenal": {[
        ["classes", "a", "CLASSNAMES", "comma-separated. The list's name is the id above - a name starting with 'items' is treated as items by the arsenal"]
    ]};
    // THE WELCOME SCREEN - one record, handed to the editor as a list of one
    // by FUNC(structItems). TEXT is Arma structured text: the writer's own
    // returns and his own tags (2026-09-09).
    case "welcome": {[
        ["title", "t", "TITLE", "the big line across the top"],
        ["subtitle", "t", "SUBTITLE", "the line under it"],
        ["text", "t", "TEXT", "the briefing - returns are line breaks, and <t size='1.15' color='#cc4331'>...</t> is a heading"]
    ]};
    // THE MOTORPOOL - the groups the vehicle menu offers, each a heading and
    // the classes under it (2026-09-09: the website could edit this and the
    // game could not, and both write <unit>.motorpool).
    case "motorpool": {[
        ["order", "n", "ORDER", "position in the menu, lowest first"],
        ["displayName", "t", "SHOWN AS", "the heading on the menu - CARS, TRUCKS"],
        ["vehicles", "a", "VEHICLES", "classnames, comma-separated"]
    ]};
    // A PAINT JOB, on two screens: what it is offered on, and the code that
    // puts it on. The code is a line of SQF and needs the whole width.
    case "cosmetics";
    case "cosmetics_code": {
        private _labels = createHashMapFromArray (switch (_section) do {
            case "cosmetics_code": {[
                ["code", ["CODE", "the SQF that paints it - _vehicle is the vehicle it is applied to", ""]]
            ]};
            default {[
                ["order", ["ORDER", "position in the list, lowest first", ""]],
                ["vehicle", ["FOR", "the vehicle base class this paint is offered on", "vehicles"]],
                ["icon", ["ICON", "a paa path; empty is fine", ""]]
            ]};
        });
        private _all = [
            ["name", "t"], ["order", "n"], ["vehicle", "t"], ["icon", "t"], ["code", "t"]
        ];
        _all apply {
            _x params ["_field", "_kind"];
            private _lab = _labels getOrDefault [_field, ["", "", ""]];
            [_field, _kind, _lab # 0, _lab # 1, _lab param [2, ""]]
        };
    };
    case "traits": {[
        ["label", "t", "SHOWN AS", "what the role editor calls it - 'DRA whitelisted'"],
        ["kind", "t", "KIND", "a yes/no or a value", "kinds"],
        ["help", "t", "WHAT IT DOES", "one line, read by whoever is deciding whether a role should have it"]
    ]};
    default {[]};
};

[_out] call _fnc_pad
