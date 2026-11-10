#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_registerTemplates

Description:
    Registers the two message templates PAC uses, on every machine, as cards
    the mod carries (jmfsb_messaging_fnc_registerBuiltins). THE MOD'S OWN
    CARD ALWAYS WINS (user, 2026-11-02): a mission's own JMFSBFR_Templates
    card of the same id is replaced, and the TAC//PAC deck's is skipped
    (FUNC(templatesApply)).

    "opord"  - what FUNC(opordPost) sends: the OPORD's sections as lines.
    "mettc"  - the METT-TC estimate a leader writes back against it:
               Mission, Enemy, Terrain and weather, Troops and support,
               Time, Civil considerations, and a LOCATION grid drawn from
               the map (the "add marker" control the handoff asks for).
               Mission, Enemy and Civil pre-fill from the current OPORD
               through autoFill = "pac:section.field", which the compose
               card answers with FUNC(opordField). ONLY A LEADER MAY SEND
               ONE - senderMustBe = "leader", which messaging answers off the
               mission's isLeader flag; the picker hides it from anyone else
               and the server refuses it from anyone else.

    Runs in postInit, after messaging's preInit loaded the mission's
    templates. Every machine registers the same thing, which is messaging's
    rule: a template must be identical wherever a message is rendered.

Parameters:
    None

Returns:
    How many were registered <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

if (isNil "jmfsb_messaging_fnc_registerBuiltins") exitWith {0};

private _fnc_text = {
    params ["_hint", ["_auto", "none"]];
    [["", _hint, "text", [["autoFill", _auto]]]]
};

private _cards = [];

_cards pushBack ["opord", "OPORD", "OPORD", [
    ["Header", "OPORD", [["", "Title", "text"], ["", "Date", "text"]]],
    ["Situation", "1. SITUATION", ["Overview / enemy / friendly / civil"] call _fnc_text],
    // Paragraphs 2 and 3 in one line - numbered so (report-card review,
    // 2026-11-02: the numbering jumped 2 -> 4).
    ["Mission", "2-3. MISSION AND EXECUTION", ["Mission / execution"] call _fnc_text],
    ["AdminLog", "4. ADMIN AND LOGISTICS", ["Admin / logistics / special / Arma considerations"] call _fnc_text],
    ["CommandSignal", "5. COMMAND AND SIGNAL", ["Command / signal"] call _fnc_text],
    ["ROE", "ROE", ["Rules of engagement"] call _fnc_text]
], [["kind", "root"], ["priority", "normal"], ["subject", "OPORD {Header.A}"], ["replyableWith", ["mettc", "roger", "freetext"]]]];

// NO CALL SIGN LINE (report-card review, 2026-11-02, D11): the sender is on
// every message. ROGER answers it (an OPEN thread, user 2026-11-02); WILCO is
// a task's answer, not offered.
_cards pushBack ["mettc", "METT-TC", "METT-TC", [
    ["Mission", "M - MISSION", ["Mission as understood", "pac:mission.mission"] call _fnc_text],
    ["Enemy", "E - ENEMY", ["Enemy composition, disposition, strength, intent", "pac:situation.enemy"] call _fnc_text],
    ["Terrain", "T - TERRAIN AND WEATHER", ["Observation, cover, obstacles, key terrain, avenues; weather"] call _fnc_text],
    ["Troops", "T - TROOPS AND SUPPORT", ["Own troops, attachments, support available"] call _fnc_text],
    ["Time", "T - TIME", ["Time available, timings"] call _fnc_text],
    ["Civil", "C - CIVIL CONSIDERATIONS", ["Areas, structures, capabilities, organisations, people, events", "pac:situation.civilTerrain"] call _fnc_text],
    ["Location", "LOCATION", [["", "Grid or marker", "grid", [["source", "mapClick"]]]]]
], [["kind", "both"], ["priority", "normal"], ["subject", "METT-TC {Mission.A}"], ["anchor", "Location.A"], ["senderMustBe", "leader"], ["replyableWith", ["roger", "freetext", "close"]]]];

private _made = [_cards, QUOTE(COMPONENT)] call jmfsb_messaging_fnc_registerBuiltins;
TRACE_1("PAC templates registered",_made);
_made
