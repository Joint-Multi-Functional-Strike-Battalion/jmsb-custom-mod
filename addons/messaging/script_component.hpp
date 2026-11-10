#define COMPONENT messaging
#define COMPONENT_BEAUTIFIED Messaging
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// RECORD SHAPES. Every record is a HashMap with the keys listed here, and every
// one of them lives on the server only. HashMaps are used rather than positional
// arrays because a message has thirteen fields and nobody can read
// `_msg select 11` correctly at two in the morning. They are converted to arrays
// by toArray at the network boundary and rebuilt with createHashMapFromArray on
// the far side, because a HashMap is not guaranteed to survive remoteExec.
//
//  message  id seq threadId parentId fromUid fromCallsign templateId payload
//           sentTime gameTime priority transition readBy
//  thread   id kind subject rootTemplateId status issuerUid claimedBy
//           participants boxes anchorPos anchorLabel parentThreadId
//           lastActivity closed messages
//  box      id kind displayName roles uids retention forwardToAlive threads
//  index    threadId boxId subject status priority claimedBy lastActivity unread
//
// A TEMPLATE is also a HashMap, but it is built from templates.inc.sqf in
// preInit on every machine and never crosses the wire at all.

// Zero padding on generated ids, so M0042 sorts next to M0041 in a log.
#define ID_PAD 4

// Seconds between sweeps. The sweep only walks threads, so it is cheap; the
// interval is about how quickly an abandoned thread tidies itself, not load.
#define SWEEP_INTERVAL 60

// Hard caps. A long session must not grow the store without bound, and a client
// that has been connected for six hours must not be handed a six-hour index.
#define BOX_THREAD_MAX 200
#define INDEX_MAX 200

// Audience tags per message. Every tag is asked of every player on the server
// once per delivery, and a message that calls out eight different call signs is
// a message addressed to nobody in particular.
#define TAG_MAX 8

// The priorities a server's own call may file a message under in place of the
// template's (FUNC(srvSubmit) argument 10, 2026-11-01): a support asset's
// prompt is FLASH ("high") only while it waits to release or is about to leave.
#define PRIORITY_OVERRIDES ["high", "normal"]

// A CARD FILED INTO AN OPEN THREAD (FUNC(onThreadCard), FUNC(srvThreadFor),
// 2026-11-02): the word a hook answers to take a ROOT card into the thread -
// a support asset's re-task or NEXT LIFT - and the card kind that otherwise
// only opens a thread.
#define THREAD_CARD_TAKE "take"
#define KIND_ROOT "root"

// The server's machine id - where a client sends a request by remoteExecCall
// (review S7). CBA events carry no sender, so nothing that needs trust uses one.
#define SERVER_OWNER 2

// remoteExecCall target for "every machine" - a server push the whole server
// takes, such as a marker removed with its thread.
#define TARGET_ALL 0

// A template's dangerClose option (metres) when the card sets none: no
// per-card threshold (user, 2026-11-01, D8 - callforfire carries 600 in the deck).
#define DANGER_CLOSE_NONE 0

// A typed grid (FUNC(fieldPos), report-card review 2026-11-02): this many
// figures, spaces allowed; the character codes it is read by.
#define GRID_FIGURES [6, 8, 10]
#define CHAR_ZERO 48
#define CHAR_NINE 57
#define CHAR_SPACE 32

// A grid field only a map marker answers (FUNC(validate), user 2026-11-02:
// "REQUEST ON STATION should require a map marker"): what an empty or typed one
// is refused with, the line's label in it - PICK A MAP MARKER FOR THE AREA.
#define MARKER_ONLY_WHY "PICK A MAP MARKER FOR THE %1"
#define MARKER_POS_MIN 2

// A subject whose optional field was left empty (FUNC(subject)): the joiner it
// leaves dangling at either end, and a doubled space, are taken out.
#define SUBJECT_DANGLING "^[\s\-]+|[\s\-]+$"
#define SUBJECT_SPACES "\s{2,}"

// Accent colours handed to the notification widget, so a warning from messaging
// looks like every other warning in the mod.
#define COLOUR_NORMAL [0.871, 0.361, 0.188, 1]
#define COLOUR_HIGH [1, 0.30, 0.30, 1]

// --- The cards the mod carries (user, 2026-11-02: "the mod's own card always
// wins", FUNC(builtinCards), FUNC(registerBuiltins)) ---------------------------
// Every card the mod defines is built in and is the one used; the TAC//PAC
// deck adds only the ids the mod does not have (pac templatesApply). The
// reports and the replies every thread takes are messaging's; the support
// cards are the support core's (jmfsb_support_fnc_builtinCards).
#define KIND_REPLY "reply"
#define KIND_BOTH "both"
#define PRIORITY_FLASH "high"
// What a task answers with, and an open report (a thread with no task in it):
// ROGER, a message, CLOSE (report-card review, 2026-11-02, decision 3).
#define REPLIES_TASK ["roger", "wilco", "inprogress", "cantco", "freetext", "close"]
#define REPLIES_OPEN ["roger", "freetext", "close"]
// The lift's answers on a CASEVAC - the support core's reply cards, offered
// where it is loaded (a reply id with no card is not offered).
#define REPLIES_LIFT ["execute", "move", "escort", "clearedland", "continueapp", "goaround"]
// The 9-LINE CASEVAC's picks (ATP 4-02.2 Table C-1, 2026-11-09): line 4
// special equipment, line 7 the marking method, line 8 nationality and status.
#define CASEVAC_EQUIPMENT ["NONE", "HOIST", "EXTRACTION", "VENTILATOR"]
#define CASEVAC_MARKS ["PANELS", "PYRO", "SMOKE", "NONE", "OTHER"]
#define CASEVAC_NATIONALITY ["MIL", "CIV", "OTHER MIL", "OTHER CIV", "EPW"]
// FRAGO (2026-11-09): its id, the key that names the order it changes, its
// reason, and the suffix the old value of a changed key rides under.
#define FRAGO_ID "frago"
#define FRAGO_CARD_KEY "Card.A"
#define FRAGO_REASON_KEY "Reason.A"
#define FRAGO_WAS "#was"
#define FRAGO_NO_ORDER "FRAGO - the thread has no order to change"
#define FRAGO_WRONG_ORDER "FRAGO - %1 is not the thread's current order"
#define FRAGO_NOTHING "FRAGO - nothing changed"
#define FRAGO_ARROW " -> "
// A card's short form (2026-11-09, the template options shortLines and
// shortFields - FUNC(registerTemplate)).
#define SHORT_LINES_KEY "shortLines"
#define SHORT_FIELDS_KEY "shortFields"
#define STATES_ANY_OPEN ["ISSUED", "RECEIPT", "ACCEPTED", "IN_PROGRESS"]
// ONE MARKING VOCABULARY (report-card review, 2026-11-02, D45) - the same
// words as the support core's MARKS_GROUND.
#define MARKS_GROUND ["SMOKE", "IR STROBE", "PANEL", "CHEMLIGHT", "FLARE", "NONE", "OTHER"]
#define REPORT_STATES ["GREEN", "AMBER", "RED", "BLACK"]
#define CASEVAC_PATIENTS_MAX 99
#define SITREP_COUNT_MAX 999
// Cards retired (report-card review, 2026-11-02): `accepted` and `ontask` -
// `wilco` and `inprogress` carry the DETAIL line; `nineline` - "CAS REQUEST
// and CAS 9-line do not need both". Never built in; a deck's copy is skipped.
// 2026-11-09 (docs/DESIGN_MESSAGE_TEMPLATES.md): `destination` (into MOVE) and
// `confirm` (into EXECUTE).
#define CARDS_RETIRED ["accepted", "ontask", "nineline", "destination", "confirm"]

// A send this machine refused before it left (FUNC(submit); user, 2026-11-02:
// "arty never replied" - the refusal was on the composer's status line only):
// said upper right under this title, and logged.
#define NOT_SENT_TITLE "NOT SENT"

// A GRID PICKED FROM A MAP MARKER keeps the marker's name (user, 2026-11-05: "if
// a marker was used keep the name of the marker in the message along with the
// grid"): the position stays the field's value - every reader of a position
// is untouched - and the name rides beside it under the field's key + this
// suffix. Written by tacpad's composer, read by messaging's render / subject /
// srvForward and tacpad's readerKvRows. The same word in both addons.
#define MARKER_NAME_SUFFIX "#marker"
