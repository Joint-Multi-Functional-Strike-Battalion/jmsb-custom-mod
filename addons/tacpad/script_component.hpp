#define COMPONENT tacpad
#define COMPONENT_BEAUTIFIED Tacpad
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// The DIK code that closes an open app (FUNC(appExits)).
#define KEY_ESCAPE 1

// THE READER AS THE OPEN APP. In tablet mode the reader draws inside the device
// dialog and is adopted as the open app under this id (FUNC(openReader),
// FUNC(appHost)); it is not a registered app, so no tile or soft key reaches
// it except through FUNC(openReader).
#define READER_APP "reader"

// THE SCHEME IDS A PROFILE MAY STILL HOLD (XEH_postInit): the one renamed on
// 2026-10-08, and the default it became. The store is CBA's own client
// settings hash in the profile.
#define SCHEME_LEGACY       "nightBrass"
#define SCHEME_DEFAULT      "nightJmsb"
#define CBA_PROFILE_STORE   "cba_settings_hash"

// THE REPORT CARD (FUNC(composeCard), FUNC(composeCardHead), FUNC(composePicker)),
// docs/PLAN_MESSAGING_UI.md phase 2. Sizes are text sizes for FUNC(drawText);
// widths are fractions of the card column.
#define CARD_TAG_SIZE TEXT_LABEL
#define CARD_TITLE_SIZE TEXT_TITLE
#define CARD_BADGE_SIZE TEXT_LABEL
#define CARD_META_SIZE TEXT_LABEL
#define CARD_CELL_SIZE TEXT_LABEL
// One attached grid cell (CUR LOC, MARKER) as a fraction of the column.
#define CARD_CELL_W 0.19
// The header tag box never takes more of the card than this.
#define CARD_TAG_MAX_W 0.3
// The field meta (REQ, range, AUTO, MARKER) never takes more of its box than this.
#define CARD_META_MAX_W 0.5
// A bold glyph's width against its line height, for sizing a box to its word.
#define CARD_GLYPH_W 0.55
// The template priority that paints the header tag in the accent.
#define CARD_PRIORITY_HIGH "high"
// A line whose title or label names one of these is never where the sender
// stands, so its grid carries MARKER only - no CUR LOC.
#define CARD_NO_CUR_WORDS ["INGRESS", "EGRESS"]
// The field-meta word on a field a map marker answers.
#define CARD_META_MARKER "MARKER"

// A CHOICE FILLED AT RUNTIME (user, 2026-11-02: "we have pre made crates so the
// requested items should be a drop down of them"; FUNC(composeChoices)): a
// field's choicesFrom names one of these, [source, the function that answers
// it with [addressees] - the picks, strings]. An addon not loaded answers
// nothing, and the field is typed.
#define CHOICE_SOURCES [["logiCatalog", QEFUNC(support_logistics,catalogNames)]]
// The drop-down (FUNC(composeDrop)): what its cell reads with nothing picked,
// the row that clears an optional one, the most picks it lists, and a pick
// row's height in rows.
#define DROP_EMPTY "PICK ONE"
#define DROP_NONE "NONE"
#define DROP_MAX 12
#define DROP_ROW_K 0.9
// The share of the cell its text may take - REQ sits in the rest.
#define DROP_TEXT_W 0.8

// A REQUIRED EXCLUSIVE TICK GROUP is "tick one" (EFUNC(messaging,validate),
// 2026-11-02): one REQ for the line, on its first tick, and one accent frame
// round the group while SEND found none ticked - not a mark on every tick.
#define GROUP_REQ_TEXT "REQ - TICK ONE"

// THE COMPOSER'S AUTOFILLS (report-card review, user 2026-11-02, decision 5;
// FUNC(composeAutoFill), FUNC(autoValue)). A field's autoFill names a source;
// one with an argument carries it after AUTO_SEP ("squadAce:A"). ownCallsign,
// missionTime and pac: stay with FUNC(composeCard), which shows them in their
// box. The CAS 9-line's heading, distance and elevation went with the card
// (user, 2026-11-02: "CAS REQUEST and CAS 9-line do not need both").
#define AUTO_SEP ":"
#define AUTO_VEHICLE "vehicle"
#define AUTO_DAMAGE "vehicleDamage"
#define AUTO_FUEL "vehicleFuel"
#define AUTO_WIND "wind"
#define AUTO_SQUAD_ACE "squadAce"
#define AUTO_ANCHOR "threadAnchor"
// THE CAS 9-LINE (2026-11-09, FUNC(autoCas)): lines 2-4 from the IP and the
// target, line 8 from the target to the sender.
#define AUTO_IP_HEADING "ipHeading"
#define AUTO_IP_DISTANCE "ipDistance"
#define AUTO_TARGET_ELEVATION "targetElevation"
#define AUTO_FRIENDLIES "friendlies"
#define AUTO_CAS [AUTO_IP_HEADING, AUTO_IP_DISTANCE, AUTO_TARGET_ELEVATION, AUTO_FRIENDLIES]
#define AUTO_SOURCES [AUTO_VEHICLE, AUTO_DAMAGE, AUTO_FUEL, AUTO_WIND, AUTO_SQUAD_ACE, AUTO_ANCHOR, AUTO_IP_HEADING, AUTO_IP_DISTANCE, AUTO_TARGET_ELEVATION, AUTO_FRIENDLIES]
// What was filled, kept INSIDE the answer map under this key (no card has a
// field called that), so every place that starts a new card with an empty map
// starts its autofills again: [card id, {field key: the value it was given}].
// An answer still holding what it was given follows its source; one the player
// changed is his.
#define AUTO_STATE_KEY "#autofill"
#define AUTO_STATE_CARD "#card"
// The state words, best first - DEFREP's ticks (GREEN / YELLOW / RED /
// BLACK) and SITREP's STATUS picks (GREEN / AMBER / RED / BLACK) - and the one
// word that differs between them.
#define AUTO_GREEN "GREEN"
#define AUTO_YELLOW "YELLOW"
#define AUTO_RED "RED"
#define AUTO_BLACK "BLACK"
#define AUTO_STATES [AUTO_GREEN, AUTO_YELLOW, AUTO_RED, AUTO_BLACK]
// The field types a state word is turned into a tick or a pick for.
#define AUTO_WORD_TYPES ["bool", "choice"]
#define AUTO_COLOUR_ALIASES [["YELLOW", "AMBER"], ["AMBER", "YELLOW"]]
// Vehicle damage: under AUTO_DAMAGE_SLIGHT and able to move GREEN; under
// AUTO_DAMAGE_HEAVY and able to move YELLOW; worse, or it cannot move, RED;
// destroyed BLACK. Fuel: at least half GREEN, at least a quarter YELLOW, any
// RED, none BLACK.
#define AUTO_DAMAGE_SLIGHT 0.1
#define AUTO_DAMAGE_HEAVY 0.5
#define AUTO_FUEL_HALF 0.5
#define AUTO_FUEL_QUARTER 0.25
// The wind as it is said: from where (deg, three figures) and how hard (m/s);
// under AUTO_WIND_CALM m/s it is CALM.
#define AUTO_WIND_TEXT "FROM %1 - %2 M/S"
#define AUTO_WIND_CALM 0.5
#define AUTO_WIND_CALM_TEXT "CALM"
#define AUTO_HALF_TURN 180
#define AUTO_FULL_TURN 360
#define AUTO_BEARING_DIGITS 3
// The squad's ACE letters (jmfsb_tacpad_apps' Squad app publishes each man's
// as [A, C, E], 0 best to 3 worst, on him): the letter's place, the C letter's
// place, and what the engine says over a man's own C - unconscious 2, dead 3.
#define AUTO_ACE_LETTERS ["A", "C", "E"]
#define AUTO_ACE_C 1
#define AUTO_ACE_DOWN 2
#define AUTO_ACE_DEAD 3

// THE READER (FUNC(readerDraw) and the functions it calls), docs/PLAN_MESSAGING_UI.md
// phase 3, handoff 1a. Pane widths are fractions of the reader's own width, taken
// off the 1280 px canvas (206 / 346 / the rest); sizes are text sizes for
// FUNC(drawText); _PX values are real screen pixels, like the rules.
#define READER_RAIL_W 0.161
#define READER_LIST_W 0.27
// Block insets, in PAD steps: the design's 12-18 px.
#define READER_INSET 3
#define READER_K_SIZE TEXT_LABEL
#define READER_BRAND_SIZE TEXT_TITLE
#define READER_NET_SIZE TEXT_BODY
#define READER_ROSTER_SIZE TEXT_BODY
#define READER_SUBJECT_SIZE TEXT_TITLE
#define READER_PREVIEW_SIZE TEXT_BODY
#define READER_TITLE_SIZE TEXT_TITLE
#define READER_AUTHOR_SIZE TEXT_BODY
#define READER_BODY_SIZE TEXT_BODY
#define READER_TILE_SIZE TEXT_BODY
#define READER_BTN_SIZE TEXT_BODY
// The roster's online square and the selected row's left bar.
#define READER_MARK_PX 7
#define READER_BAR_PX 4
// A chip's padding either side of its word (the word is measured, 2026-11-06).
#define READER_CHIP_PAD_PX 12
// How much of a preview line a list row or the banner carries.
#define READER_PREVIEW_CHARS 72
// The quick-reply row: six tiles, the last one VOICE MSG.
#define READER_TILES 6
// A tile is this many button heights tall (the design's 44 px).
#define READER_TILE_H 1.3
// QUICK REPLIES FOR SUPPORT (docs/DESIGN_SUPPORT_MESSAGING.md 6.2 and 7, user
// 2026-11-01: "per the doc i want to use the messaging system to call ai
// support"). A support card's thread offers its own row: [root card,
// [[reply card, the word on its tile - "" for the card's short name], ...]].
// The row may run onto READER_TILE_ROWS rows of tiles; the first keeps the
// VOICE MSG slot. See FUNC(readerQuickTiles).
// 2026-11-02 (user): the three calls for fire answer alike, and the
// EXTRACTION as the LIFT REQUEST. The JUMP REQUEST (user, 2026-11-02): ABORT
// and RTB stand the jump aircraft down; GO comes with its hold prompt.
// 2026-11-02: EVERY SUPPORT CARD HAS ITS SENDER'S ROW. REQUEST ON STATION,
// RESUPPLY and QRF had none, so the issuer got the general row and its ON
// TASK - his own request moved to IN_PROGRESS. RESUPPLY's RECEIVED / NOT
// FOUND come with its prompt. A BDA is a report (ROGER), not a request.
// 2026-11-02 (user: "troop load, all in" ... "1) on station 2) extraction"):
// the LIFT REQUEST and the EXTRACTION offer ALL IN, the EXTRACTION also
// EXTRACT - the server takes each only at its step. The JUMP REQUEST offers
// BOARD (user, 2026-11-02: "have team leader send a board message then move
// the team to cargo") - taken while the aircraft waits on station for it.
// ALL ATTACK beside CLEARED HOT on the CAS REQUEST (user, 2026-11-02: "add an
// all attack for the fixed flight where the drones also attack the target or
// targets in the area") - a fixed-wing flight with escorts takes it; any other
// CAS asset answers NO ESCORTS - USE CLEARED HOT.
// THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): every
// asset thread carries FRAGO, STATUS, HOLD, ABORT, RTB; EXECUTE replaced
// CONFIRM; the landing's GO AROUND, the drop's NO DROP, the CAS flight's
// CLEARED TO ENGAGE and CONTINUE; MOVE where the asset moves; ESCORT in every
// transport's (user, 2026-11-09: "no mater the phase or tasking"). A tile
// whose card the thread does not take now is not drawn (FUNC(threadLegal)).
#define QUICK_SUPPORT [ \
    ["cas", [["clearedhot", ""], ["clearedengage", "ENGAGE"], ["continue", ""], ["allattack", ""], ["abort", ""], ["move", ""], ["status", ""], ["hold", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["onstation", [["move", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["resupply", [["escort", ""], ["status", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["qrf", [["move", ""], ["escort", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["callforfire", [["adjust", ""], ["ffe", ""], ["repeat", ""], ["checkfire", ""], ["record", ""], ["frago", ""], ["close", "EOM"]]], \
    ["cffpolar", [["adjust", ""], ["ffe", ""], ["repeat", ""], ["checkfire", ""], ["record", ""], ["frago", ""], ["close", "EOM"]]], \
    ["cffshift", [["adjust", ""], ["ffe", ""], ["repeat", ""], ["checkfire", ""], ["record", ""], ["frago", ""], ["close", "EOM"]]], \
    ["pickup", [["execute", ""], ["allin", ""], ["escort", ""], ["move", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["hlz", [["execute", ""], ["allin", ""], ["goaround", ""], ["escort", ""], ["move", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["extract", [["execute", ""], ["extractnow", ""], ["allin", ""], ["goaround", ""], ["escort", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["casevac", [["execute", ""], ["goaround", ""], ["escort", ""], ["move", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["airdrop", [["execute", ""], ["nodrop", ""], ["escort", ""], ["move", ""], ["status", ""], ["hold", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]], \
    ["jump", [["board", ""], ["go", ""], ["nodrop", ""], ["escort", ""], ["status", ""], ["abort", ""], ["frago", ""], ["rtb", ""], ["close", ""]]] \
]
#define READER_TILE_ROWS 2
// The template kind a one-tap reply is (FUNC(readerQuickTiles)).
#define QUICK_KIND_REPLY "reply"
// A NEW TASK IN THE THREAD (2026-11-02): a ROOT card the thread's asset takes
// there (jmfsb_support_fnc_threadCards - a CAS REQUEST answering FURTHER
// TASKING?, a LIFT REQUEST answering HOLD, RTB OR NEXT LIFT?) is a tile that
// opens the composer on that card, filed into the thread (FUNC(taskInThread)),
// and a card on + TEMPLATE - to the thread's issuer, whose job it is.
#define QUICK_KIND_ROOT "root"
#define QUICK_TASK "task"
#define TASK_IN_THREAD_NOTE "IN THREAD %1 - A NEW TASK FOR %2"
#define TASK_NOT_TAKEN "%1 cannot go into this thread."
// THE ASSET'S WORDS ARE THE ASSET'S (2026-11-02, FUNC(threadLegal),
// FUNC(readerQuickTiles)): ROGER, WILCO, ON TASK, CANTCO
// (jmfsb_support_fnc_assetCard) are never offered to the man who asked for
// the support, nor to anyone in a thread an AI asset answers (the asset files
// them; the server refuses them from a player - jmfsb_support_fnc_srvThreadCard).
// A thread in one of these is over: nothing is offered in it.
#define THREAD_OVER_STATES ["CLOSED", "ABORTED"]
// What a tile does when pressed: files its card, opens it in the composer (a
// required line is left), opens the distance pick, closes it, or sends its
// words as free text.
#define QUICK_FILE "file"
#define QUICK_OPEN "open"
#define QUICK_PICK "pick"
#define QUICK_BACK "back"
#define QUICK_PHRASE "phrase"
// ADJUST is four tiles, one per correction; each opens the distance pick and
// a distance files the `adjust` card in that one press. Line titles are the
// field keys' stems (jmfsb_support_fnc_builtinReplies).
#define QUICK_ADJUST "adjust"
#define QUICK_ADJUST_DIR_LINE "Direction"
#define QUICK_ADJUST_DIST_LINE "Distance"
#define QUICK_ADJUST_DIRS ["ADD", "DROP", "LEFT", "RIGHT"]
#define QUICK_ADJUST_METRES [25, 50, 100, 200, 400]
#define QUICK_BACK_WORD "BACK"
// The asset's `prompt` card (doc 7): what it asks, and the reply ids it
// offers as the answers, comma-separated.
#define QUICK_PROMPT "prompt"
#define QUICK_PROMPT_TEXT "Text"
#define QUICK_PROMPT_ANSWERS "Answers"
#define QUICK_ANSWER_SEP ","
// QUICK ANSWERS ON THE PHONE (user, 2026-11-06: "the 6-9 are for fast replys
// with out opening the tablet, the choice should be displayed on the phone till
// answered"). A support question waiting for this player - an asset's `prompt`
// (FUNC(askTraffic), FUNC(askLocal)) - is put on the walking view with its
// answers on the device keys F1-F4 (numpad 6-9), ASK_KEYS a page, the arrows
// (numpad 0 / .) paging. FLASH first, then the newest; answering shows the next.
// It stays until an answer comes back into the thread, a newer question
// replaces it, or the thread is over (ASK_OVER_STATES).
#define ASK_KEYS 4
#define ASK_OVER_STATES ["CLOSED", "ABORTED", "DECLINED"]
// How long a press reads SENT on the strip when nothing comes back to clear it
// (a crew's question, which nobody answers on this machine).
#define ASK_SENT_S 4
// A HUMAN CREW ASKS THE SAME QUESTIONS (user, 2026-11-06: "quick replays for
// human units to ask the same questions"; chose the step list by type). A
// player crew a support card was addressed to (its P:<uid> box) gets, while no
// question waits for him, the questions of the card's type on the keys, in flow
// order: [root cards, [[word on the key, text, answers, card], ...]]. Card ""
// files the `prompt` card with the text and the answers - the requester's
// phone then puts them on his keys; a card id files that card (SHOT, IN).
// The texts are the AI assets' own (support, support_air, support_fires).
#define ASK_CREW_SMOKE ["POP SMOKE", "1 MIN OUT - POP SMOKE", "", ""]
#define ASK_CREW_SEEN ["SMOKE OK?", "I SEE SMOKE - CORRECT?", "correct,wrong", ""]
#define ASK_CREW_CLEARED ["CLEARED?", "READY TO LAND - CLEARED?", "clearedland,continueapp,goaround,abort", ""]
// STATE INTENTIONS (2026-11-09): after an ABORT, the asset asks what next.
#define ASK_CREW_INTENTIONS ["INTENTIONS?", "STATE INTENTIONS", "move,hold,frago,rtb", ""]
#define ASK_CREW_QUESTIONS [ \
    [["pickup"], [["INSERTION?", "ON DECK AT PICKUP, SHUT DOWN - SEND THE INSERTION", "hlz,rtb", ""], ["ALL IN?", "TROOP LOAD - ALL IN?", "allin,abort", ""]]], \
    [["hlz"], [ASK_CREW_SMOKE,["LZ STATUS?", "LZ STATUS?", "cold,hot", ""], ASK_CREW_SEEN, ASK_CREW_CLEARED, ["ALL IN?", "TROOP LOAD - ALL IN?", "allin,abort", ""], ["PAX OFF?", "WHEELS DOWN - PAX OFF?", "paxoff,hold", ""], ASK_CREW_INTENTIONS]], \
    [["extract"], [["READY?", "ON STATION - READY FOR EXTRACTION", "extractnow,abort", ""], ASK_CREW_SMOKE, ["LZ STATUS?", "LZ STATUS?", "cold,hot", ""], ASK_CREW_SEEN, ASK_CREW_CLEARED, ["ALL IN?", "TROOP LOAD - ALL IN?", "allin,goaround,abort", ""], ASK_CREW_INTENTIONS]], \
    [["casevac"], [ASK_CREW_SMOKE, ASK_CREW_SEEN, ASK_CREW_CLEARED, ["DEST?", "PATIENTS ABOARD - DESTINATION?", "move", ""], ASK_CREW_INTENTIONS]], \
    [["airdrop", "resupply"], [ASK_CREW_SMOKE, ["RECEIPT?", "PACKAGE AWAY - CONFIRM RECEIPT", "received,notfound", ""]]], \
    [["callforfire", "cffpolar", "cffshift"], [["SHOT", "", "", "shot"], ["SPLASH", "", "", "splash"], ["ADJUST?", "ADJUST?", "adjust,ffe,close", ""], ["COMPLETE", "ROUNDS COMPLETE - REQUEST BDA", "bda,record,repeat,close", ""], ["EOM?", "END OF MISSION?", "close,record,repeat", ""]]], \
    [["cas", "onstation"], [["IN", "", "", "in"], ["CLEARED?", "AWAITING CLEARED HOT", "clearedhot,continue,abort", ""], ["OFF / BDA", "OFF - REQUEST BDA", "bda,cas", ""], ["TASKING?", "FURTHER TASKING?", "cas,move,rtb,close", ""], ["BINGO", "BINGO IN 2 MIN", "rtb,close", ""], ASK_CREW_INTENTIONS]], \
    [["jump"], [["BOARD?", "ON STATION - SEND BOARD WHEN READY", "board,abort", ""], ["GO?", "MEN STILL ABOARD - HOLDING OVER THE DZ", "go,nodrop", ""], ["RED LIGHT", "", "", "redlight"], ["GREEN LIGHT", "", "", "greenlight"]]], \
    [["qrf"], [["LINKED UP?", "SQUAD DOWN - LINKED UP?", "received,close", ""]]] \
]
// What the strip says - FUNC(askView) hands these to the walking view.
#define ASK_MODE_ANSWER "answer"
#define ASK_MODE_CREW "crew"
#define ASK_CREW_ACT "crew"
// A choice of this machine's own on the same strip (FUNC(askChoice)): the
// ECOTI building mark's colour. Its key in GVAR(asks) never looks like a
// thread id.
#define ASK_MODE_LOCAL "local"
#define ASK_LOCAL_ACT "local"
#define ASK_LOCAL_PREFIX "local:"
// AFTER CONTACT, A SITREP (user, 2026-11-02: "after contact a sitrep should be
// sent"). A TIC thread - its root card carries the template's `broadcast` flag
// CONTACT_BROADCAST - offers SEND SITREP first on its row to the TIC's sender
// and his squad leader (FUNC(readerQuickTiles)); the tile opens the deck's
// SITREP card in the composer, in the thread (FUNC(sitrepAfterTic)). Line
// titles are the field keys' stems. A deck whose SITREP is still a root card
// cannot file it in a thread: a new SITREP thread goes to the TIC's net, the
// TIC named in its REMARKS and on the line beside SEND.
#define QUICK_SITREP "sitrep"
#define SITREP_CARD "sitrep"
#define SITREP_TILE_WORD "SEND SITREP"
#define SITREP_LOCATION_LINE "Location"
#define SITREP_REMARKS_LINE "Remarks"
#define SITREP_NO_CARD "The deck has no SITREP card."
#define SITREP_AFTER_TIC "SITREP AFTER TIC %1 - THREAD %2"
#define SITREP_OWN_THREAD "THE DECK'S SITREP OPENS ITS OWN THREAD - THE TIC IS IN REMARKS"
// The sender's watch for the contact ending (FUNC(contactArm)): no new TIC from
// his group (one anchored within CONTACT_NEAR_M of one of his men) and none of
// CONTACT_EVENTS on his group's units for CONTACT_QUIET_S seconds, then
// CONTACT_PROMPT upper right and as the kicker of the TIC thread's row. A
// thread in a CONTACT_CLOSED state ends the watch.
#define CONTACT_BROADCAST "tic"
#define CONTACT_QUIET_S 180
#define CONTACT_NEAR_M 300
#define CONTACT_EVENTS ["FiredMan", "FiredNear", "Hit", "Suppressed"]
#define CONTACT_CLOSED ["CLOSED", "ABORTED"]
#define CONTACT_PROMPT "CONTACT OVER? SEND SITREP"
#define CONTACT_PROMPT_TEXT "TIC %1 - TAC//MSG, the TIC thread: SEND SITREP"
// A FILED CARD READS IN ONE COLUMN (FUNC(readerKv), FUNC(readerKvRows); user,
// 2026-11-02: "the 2 column view in the message history is hard to read").
// jmfsb_tacpad_apps_fnc_kvRow's layout, which this addon cannot call: the label
// column is its longest label plus READER_KV_GAP_PX, at most READER_KV_LABEL_MAX
// of the width; values at the tile detail size, never smaller (review
// 2026-11-01, R1). A value taller than READER_KV_WRAP_K of its line wraps
// beside its label and is drawn under it across the width instead, the label
// READER_KV_UNDER_PX over it; READER_KV_AIR_PX between rows.
#define READER_KV_VALUE_SIZE ([READER_BODY_SIZE, APP_TEXT_UP_PX] call FUNC(textPx))
#define READER_KV_GAP_PX 10
#define READER_KV_LABEL_MAX 0.4
#define READER_KV_WRAP_K 1.5
#define READER_KV_UNDER_PX 2
#define READER_KV_AIR_PX 10
// How a line's answers are joined, the word a ticked box with no prefix reads
// as, and the strings a box filled as text counts as ticked by (as
// jmfsb_messaging_fnc_render reads them). A root card's line is numbered
// unless its label carries its own number - a digit first ("1. SITUATION") or
// the word READER_KV_LINE_WORD ("LINE 1 - PICK-UP SITE").
#define READER_KV_JOIN ", "
#define READER_KV_YES "YES"
#define READER_KV_TICKED ["true", "yes", "x", "1"]
#define READER_KV_DIGITS ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
#define READER_KV_LINE_WORD "LINE"
// The close button and each header button, as a fraction of the detail pane.
#define READER_HEAD_BTN_W 0.13
// The FLASH banner: its width as a fraction of the view it covers, and the snooze.
#define READER_FLASH_W 0.62
#define READER_FLASH_SNOOZE 60
// Enter on the main keyboard and on the keypad, which apply the filter.
#define READER_KEY_ENTER 28
#define READER_KEY_NUM_ENTER 156
// A sub-net on the rail (FIRES.cas) is drawn under its parent, its own name
// indented this many PAD steps (tablet review 2026-11-01, 3.1).
#define READER_SUBNET_INDENT 4
#define READER_SUBNET_SEP "."

// THE TO PICKER'S SUPPORT GROUP (docs/DESIGN_SUPPORT_MESSAGING.md 6.1, build
// step 2, 2026-11-01). The assets' rows are asked when the picker opens and
// again every TO_SUPPORT_POLL seconds while it is up - the board's own poll -
// and never per frame; a redraw inside that time reuses them. Values are
// never drawn smaller than the tile band's detail size (review 2026-11-01,
// R1); the call sign takes this share of a row, its state and ETA the rest.
#define TO_SUPPORT_POLL 2
// A support card's footprint on the map is checked this often (s) while it
// stands, and taken off once the composer is gone (FUNC(composeFireTick),
// 2026-11-02).
#define COMPOSE_FIRE_POLL 1
#define TO_SUPPORT_SEP " - "
#define TO_SUPPORT_NAME_W 0.4
#define TO_SECS_PER_MIN 60
#define TO_VALUE_SIZE ([TEXT_BODY, APP_TEXT_UP_PX] call FUNC(textPx))

// @ MENTIONS OF SUPPORT ASSETS (user, 2026-11-01: "want to use an @[unit] to
// enable ai support units"). The CC line's @ list offers the assets as well
// (FUNC(composeCcDrop)), CC_DROP_ROWS deep, assets first; the name column
// takes CC_DROP_NAME_K of a target row and TO_SUPPORT_NAME_W of an asset's.
// A mention addresses the asset and opens its card (FUNC(composeMention)).
#define CC_DROP_ROWS 6
#define CC_DROP_NAME_K 0.68
#define CC_DROP_GAP_K 0.02
// Typed text the new card has no line for: the first text value with no home
// moves into the card's empty REMARKS line (line titles are field keys);
// anything else asks first (FUNC(composeMentionAsk)), SWITCH and KEEP a share
// of the pane each.
#define MENTION_NOTE_LINE "REMARKS"
#define MENTION_TEXT_TYPES ["text", "textarea"]
#define MENTION_ASK_BTN_K 0.15
// The status line beside SEND, when the deck has no card for the asset's type.
#define MENTION_NO_CARD "THE DECK HAS NO %1 CARD - CARD KEPT"
// A card the asset's type takes is kept on a mention (user, 2026-11-02: "on
// station is not a fire mission"): a mentioned row's field 10 lists them.
#define MENTION_ROW_CARDS 10

// WHY A SEND WENT NOWHERE (user, 2026-11-02: "arty never replied"). A refused
// SEND reads this beside SEND (EFUNC(messaging,submit) says it upper right and
// in the RPT); a support card sent with no asset on TO is filed on a net that
// no AI answers - said upper right and in the RPT (FUNC(composeSend)).
#define NOT_SENT_LINE "NOT SENT - %1"
#define NO_ASSET_TITLE "NO ASSET ADDRESSED"
#define NO_ASSET_TEXT "%1 sent - no support asset on TO, no AI answers it. @ the asset."

// LETTER TRACKING IS FOR SHORT LABELS ONLY (tablet review 2026-11-01, 2.3):
// column heads and section titles of this many characters or fewer. A longer
// line asked to be tracked is drawn untracked - FUNC(retext) and
// FUNC(chipWidth) both hold to it, so a chip is sized as it is drawn.
#define TRACK_MAX_CHARS 12

// AN APP ON A DEVICE TAKES THE WHOLE MAP AREA (user, 2026-10-21: "apps should
// be more full screen"). The device's own rows - bar, tiles, nets - stay, and
// the app fills everything between them, edge to edge. On the vanilla map the
// app keeps the size it asked for.
#define APP_DEVICE_FILL 1
// The TAC//MSG reader's share of the vanilla map's screen, where it is a dialog.
#define READER_FILL_W 0.97
#define READER_FILL_H 0.90

// A GRID PICKED FROM A MAP MARKER keeps the marker's name (user, 2026-11-05: "if
// a marker was used keep the name of the marker in the message along with the
// grid"): the position stays the field's value - every reader of a position
// is untouched - and the name rides beside it under the field's key + this
// suffix. Written by tacpad's composer, read by messaging's render / subject /
// srvForward and tacpad's readerKvRows. The same word in both addons.
#define MARKER_NAME_SUFFIX "#marker"

// --- The message templates (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09) ----
// An AI asset's mailbox (the support core's SUPPORT_BOX_PREFIX): a thread with
// one among its boxes is an asset's thread (FUNC(threadLegal)).
#define SUPPORT_BOX_PREFIX "B:SUPPORT:"
// A TIC, SALUTE or MIST thread hosts a support request (rule 3, decision 4):
// the starters offered in one, filed into it with the asset on the TO line
// (FUNC(starterInReport)). The support core's REPORT_HOSTS and PIN_CARDS.
#define REPORT_HOSTS ["tic", "contactrep", "mist"]
#define REPORT_STARTERS ["cas", "onstation", "callforfire", "cffpolar", "cffshift", "pickup", "hlz", "extract", "casevac", "airdrop", "resupply", "qrf", "jump"]
// What is filled in from the report: a TIC's LOCATION and a SALUTE's L into
// the request's own anchor field; a MIST, into a CASEVAC's REMARKS.
#define REPORT_POINT_KEYS [["tic", "Location.A"], ["contactrep", "L.A"]]
#define REPORT_MIST "mist"
#define REPORT_MIST_CARD "casevac"
#define REPORT_MIST_REMARKS "Remarks.A"
#define REPORT_MIST_SEP " / "
#define REPORT_NOTE "IN THREAD %1 - %2 TO THE ASSET ON THE TO LINE"
#define REPORT_NO_ASSET "PICK THE SUPPORT ASSET ON THE TO LINE"
// REAL WORLD / SIMPLE (2026-11-09): the composer's switch over a card with a
// short form - the template's shortKeys (EFUNC(messaging,registerTemplate)) -
// worded as TAC//PAC words the unit's option. Seeded each time a card opens
// (FUNC(composeShortDefault)) from the player setting GVAR(composeShort):
// UNIT - the unit's TAC//PAC option (PAC_TEMPLATE_FORM_VAR, "simple" or
// "real", nil real), REAL WORLD, or SIMPLE.
#define SHORT_WORD "SIMPLE"
#define STD_WORD "REAL WORLD"
#define SHORT_SWITCH_W 0.3
#define FORM_UNIT "unit"
#define FORM_REAL "real"
#define FORM_SIMPLE "simple"
#define PAC_TEMPLATE_FORM_VAR "jmfsb_pac_templateForm"
// A line holding a required field says so on its head (2026-11-09).
#define CARD_REQ_WORD "REQ"
// FRAGO (2026-11-09): the order's card reopened with its last values (the
// messaging FRAGO_* keys), its title, the REASON box, and what marks a changed
// line.
#define FRAGO_ID "frago"
#define FRAGO_CARD_KEY "Card.A"
#define FRAGO_REASON_KEY "Reason.A"
#define FRAGO_WAS "#was"
#define FRAGO_TITLE "FRAGO: %1"
#define FRAGO_REASON_LABEL "REASON"
#define FRAGO_REASON_HINT "Why it changes - optional"
#define FRAGO_CHANGED "CHANGED"
#define FRAGO_NO_ORDER "THIS THREAD HAS NO ORDER TO CHANGE"
#define FRAGO_NOTHING "NOTHING CHANGED"
#define FRAGO_NOTE "FRAGO IN THREAD %1 - ONLY THE CHANGED LINES ARE SENT"
// THE CAS 9-LINE'S GAME-FILLED LINES (2026-11-09, FUNC(autoCas)): the IP and
// the target keys they are worked out from, and the eight compass words.
#define CAS_IP_KEY "Line1.A"
#define CAS_TARGET_KEY "Line6.A"
#define CAS_COMPASS ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
#define CAS_COMPASS_STEP 45
#define CAS_DEGREES_FORMAT "%1 DEG"
#define CAS_METRES_FORMAT "%1 M"
#define CAS_FRIENDLIES_FORMAT "%1 %2 M"
