#define COMPONENT support
#define COMPONENT_BEAUTIFIED Support
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_SUPPORT
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_SUPPORT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_SUPPORT
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// An asset id is "<provider kind>:<the provider's own id>". The kind is what
// routes a request back to the provider that listed the row.
#define ID_SEP ":"

// Row status a core cooldown writes over a provider's "idle".
#define STATUS_IDLE "idle"
#define STATUS_COOLDOWN "cooldown"

// The task token that recalls an asset. Never gated by availability or by a
// cooldown: an asset you want home is by definition one that is busy.
#define TASK_RTB "rtb"

// The server's machine id - a cooldown is booked there by remoteExec, and
// the longest a booking may hold an asset, in seconds (review S6). No
// module's own cooldown comes near it.
#define SERVER_OWNER 2
#define COOLDOWN_MAX 3600

// Order of a declared asset type nobody gave an order to - after every
// type that did.
#define TYPE_ORDER_LAST 1000

// REACH (FUNC(reach), docs/DESIGN_SUPPORT_V2.md section 6, 2026-11-01): one
// row per asset for one map point, [assetId, can, eta, why, effect, tasks].
// An ETA nobody can give is -1 and sorts after every known one. A provider's
// "reach" answer shorter than its five fields, or none, is not an answer: the
// asset cannot (the core's own reading went with the ALiVE provider, user,
// 2026-11-02).
#define ETA_UNKNOWN -1
#define REACH_FIELDS 5
// The reasons the core itself gives when an asset cannot reach.
#define REACH_WHY_COOLDOWN_FOR "COOLDOWN %1 S"
#define REACH_WHY_NOT_AVAILABLE "NOT AVAILABLE"

// --- Threads (2026-11-01, design D6: one mailbox per asset) -----------------
// A support request is a messaging thread filed to the asset's own box,
// "B:SUPPORT:<assetId>"; the server answers it AS THE ASSET. See README,
// "Threads".
#define SUPPORT_BOX_PREFIX "B:SUPPORT:"
// The states a provider moves the asset's open thread to (FUNC(state)) - the
// messaging thread statuses the reply cards transition to.
#define STATE_RECEIPT "RECEIPT"
#define STATE_ACCEPTED "ACCEPTED"
#define STATE_IN_PROGRESS "IN_PROGRESS"
#define STATE_CLOSED "CLOSED"
#define STATE_DECLINED "DECLINED"
#define STATES [STATE_RECEIPT, STATE_ACCEPTED, STATE_IN_PROGRESS, STATE_CLOSED, STATE_DECLINED]
// The way a thread moves. A state at or behind where the thread already is
// is not said again (an ack per say of support_air's is not a WILCO each).
#define STATE_ORDER ["OPEN", "ISSUED", STATE_RECEIPT, STATE_ACCEPTED, STATE_IN_PROGRESS]
// Where a thread is over: nothing more is said in it, and the asset's link
// to it is dropped. ABORTED is the issuer's own reply card.
#define STATES_OVER [STATE_CLOSED, STATE_DECLINED, "ABORTED"]
// Where nobody has accepted the order yet - the only statuses a refusing ack
// turns into DECLINED (FUNC(ack)).
#define STATES_UNACCEPTED ["OPEN", "ISSUED", STATE_RECEIPT]
// Card kinds that answer in a thread, and field types the reason can go in.
#define CARD_KIND_REPLY "reply"
#define TEXT_TYPES ["text", "textarea"]
// The longest asset call sign the server keeps from a client (FUNC(srvCallsign)).
#define CALLSIGN_MAX 32
// What a reply's nonce starts with - one per reply, never a repeat.
#define NONCE_PREFIX "support"

// --- Assets as mailboxes (2026-11-01, DESIGN_SUPPORT_MESSAGING build step 2) --
// The SUPPORT group of TAC//MSG's TO picker (FUNC(mailboxes)). One entry per
// asset type listed there: [type key, the word the row reads, the deck cards
// that open the picker on that type, the card an @ mention of the asset opens
// in the composer]. CAS first (user, 2026-11-01: "make the cas units
// selectable as message receivers"); every type since the @ mentions (user,
// 2026-11-01: "need to have the proper template also for the type of unit").
// The fires provider's cruise missiles and loitering munitions take the call
// for fire, as its artillery does. 2026-11-02 (user): a battery takes the
// three calls for fire - "break arty in to 3 reports grid polar and shift
// fire" - and is mentioned with CFF GRID; CAS takes CAS REQUEST alone - "CAS
// REQUEST and CAS 9-line do not need both"; a transport takes the PICKUP (its
// mention) and the INSERTION after it (user, 2026-11-08: the pickup report
// split in two), the EXTRACTION, the CASEVAC and the PARADROP.
// The jump aircraft (user, 2026-11-02: "change the halo/haho/static app in to
// a message based one") takes the JUMP REQUEST; jmfsb_jumpmaster lists it to
// squad leaders and admins only, so nobody else sees the row.
#define MAILBOX_TYPES [ \
    ["cas", "CAS", ["cas", "onstation"], "cas"], \
    ["arty", "ARTY", ["callforfire", "cffpolar", "cffshift"], "callforfire"], \
    ["cruise", "CRUISE", ["callforfire", "cffpolar", "cffshift"], "callforfire"], \
    ["loiter", "LOITER", ["callforfire", "cffpolar", "cffshift"], "callforfire"], \
    ["transport", "TRANS", ["pickup", "hlz", "extract", "casevac", "airdrop"], "pickup"], \
    ["logistics", "LOGI", ["resupply"], "resupply"], \
    ["qrf", "QRF", ["qrf"], "qrf"], \
    ["jump", "JUMP", ["jump"], "jump"] \
]
// ON STATION FIRST (doc 1.1): an asset whose row says it must be asked on
// station before a strike (assets field 9 - a fixed-wing CAS aircraft the AI
// flies) is mentioned with this card until its row reads MAILBOX_STATE_STATION.
#define MAILBOX_CARD_STATION "onstation"
#define MAILBOX_STATE_STATION "ON STATION"
#define ROW_STATION_FIRST 9
// A row's status (field 4) as the state the row reads; anything not listed is
// at work. "cooldown" is also the core's own word over an idle row. ON STATION
// (2026-11-01): a fixed-wing at its hold, a drone over its grid - the one a
// `cas` card is sent to.
#define MAILBOX_STATES [["idle", "IDLE"], ["cooldown", "REARMING"], ["rearming", "REARMING"], ["replacing", "REARMING"], ["rtb", "RTB"], ["expended", "LOST"], ["gone", "LOST"], ["lost", "LOST"], ["on station", MAILBOX_STATE_STATION], ["station", MAILBOX_STATE_STATION]]
#define MAILBOX_STATE_BUSY "TASKED"
// A BATTERY'S STOCK, BRIEFLY (user, 2026-11-02): an asset row of these types
// carries what it has left as row field 9 (FUNC(mailboxes)) - "12 HE, 6
// SMOKE", the first MAILBOX_STOCK_SHOWN round types of the provider's row
// field 5 ([[name, rounds left, key], ...]), unlimited as UNL - so the TO
// picker reads ARTY - IDLE - 12 HE, 6 SMOKE - ETA 1:20.
#define MAILBOX_STOCK_TYPES ["arty"]
#define MAILBOX_STOCK_SHOWN 3
#define MAILBOX_STOCK_ITEM "%1 %2"
#define MAILBOX_STOCK_SEP ", "
#define MAILBOX_STOCK_UNLIMITED "UNL"
#define ROW_ORDNANCE 5
// PLAYER CREWS (decision D8, user 2026-11-01): a player in a crew seat of a
// gun or an aircraft is listed in the SUPPORT group under the type his
// vehicle is - a gun with an artillery computer ARTY, an aircraft with seats
// to carry TRANS, any other aircraft CAS - with his own player box, state
// PLAYER and, as row field 9, the vehicle. No provider acts on a player box.
#define MAILBOX_PLAYER_STATE "PLAYER"
#define MAILBOX_PLAYER_BOX "P:"
#define MAILBOX_PLAYER_GUN "arty"
#define MAILBOX_PLAYER_LIFT "transport"
#define MAILBOX_PLAYER_AIR "cas"
#define MAILBOX_PLAYER_NOT_CREW ["cargo"]
// The box id forms FUNC(boxName) takes as they are; anything else is a bare
// shared box name, as EFUNC(messaging,srvBox) reads it.
#define BOX_PREFIXES ["P:", "G:", "B:"]
#define BOX_PREFIX_SHARED "B:"
// How often a box's call sign is read again from the viewer's rows
// (FUNC(boxName)), seconds - the board's own poll.
#define BOX_NAMES_POLL 2

// --- The asset acts on its thread (2026-11-01, DESIGN_SUPPORT_MESSAGING steps
// 3 and 4) ------------------------------------------------------------------
// A provider's "thread" hook is told about a TASK card filed to its asset's
// box (a thread whose root moves it into a state - messaging's thread kind
// "task"); a plain message is not one. Its answer is [ok, why]; anything
// shorter is "not mine" and the thread stays at RECEIPT.
#define THREAD_KIND_TASK "task"
#define ANSWER_FIELDS 2
// Provider kinds a no-fire area blocks (jmfsb_c2_fnc_inNoFire, FUNC(srvFiled)).
#define NO_FIRE_KINDS ["fires", "cas"]
// What the core itself answers a refused thread with when the provider gave no
// reason.
#define WHY_UNABLE "UNABLE"
// The CANTCO words the core and the card reader give (doc section 5.2).
#define WHY_NO_TARGET "NO TARGET LOCATION"
#define WHY_DANGER_CLOSE "DANGER CLOSE NOT ACKNOWLEDGED"
// The cards the core reads into an order (FUNC(readOrder)), by field key - line
// titles are field keys. A strike card: [card id, target, label, ingress,
// egress, description, friendlies (m), danger close tick, mark, code,
// munition, remarks]; "" where the card has no such line. A remark saying
// DANGER CLOSE still acknowledges it, as on the net. The cas card's MAP
// REFERENCE (Line 2) left the deck in the review; an older deck's is still
// read. One CAS card (user, 2026-11-02: "CAS REQUEST and CAS 9-line do not
// need both"): CAS REQUEST.
// THE TRUE 9-LINE (docs/DESIGN_MESSAGE_TEMPLATES.md, decision 3, 2026-11-09):
// the keys follow JP 3-09.3's line numbers - Line 1 the IP / BP (ingress),
// Line 5 the description, Line 6 the target, Line 7 the mark and code, Line 8
// the friendlies (A the auto direction and distance, text; B the DANGER CLOSE
// tick), Line 9 the egress; the TYPE OF CONTROL line (its ticks, 1 2 3) and
// the TOT last. No label, no munitions line (munitions are in the remarks).
#define STRIKE_CARDS [ \
    ["cas", "Line6.A", "", "Line1.A", "Line9.A", "Line5.A", "Line8.A", "Line8.B", "Line7.A", "Line7.B", "", "Remarks.A", "Control", "TOT.A"] \
]
// The TYPE OF CONTROL line's ticks in letter order (order key "control": 1, 2,
// 3; 0 none ticked - the provider's own default).
#define CAS_CONTROL_TYPES [1, 2, 3]
// REQUEST ON STATION (doc 1.1, user 2026-11-01): [card id, minutes, area,
// remarks].
#define STATION_CARDS [["onstation", "Line1.A", "Line2.A", "Remarks.A"]]
#define ORDER_STRIKE "strike"
#define ORDER_STATION "station"
// What the remarks of a card without a DC tick must say to acknowledge it.
#define DANGER_CLOSE_WORDS "DANGER CLOSE"
// Danger close for a strike card that sets no `dangerClose` option of its own
// (doc 5.3: "under 300 m (the cas template's own threshold)"), and what the
// friendlies are looked for among (the side's units on the ground - the
// server's blue force tracker).
#define DANGER_CLOSE_CAS 300
#define FRIENDLY_KINDS ["CAManBase", "LandVehicle", "Ship", "StaticWeapon"]
// A typed grid: this many figures, spaces allowed (FUNC(gridPos)).
#define GRID_FIGURES [6, 8, 10]
#define CHAR_ZERO 48
#define CHAR_NINE 57
#define CHAR_SPACE 32
// THE ISSUER'S FOLLOW-UPS, as the one word a provider's "reply" hook is handed
// (FUNC(srvFollowUp)): CLEARED HOT by its card id (DESIGN_SUPPORT_V2 D2, a
// reply that keeps the thread's state, so its id is all there is), "stop" for
// anything that ends what the asset is doing - any reply moving the thread to
// CLOSED or ABORTED, and the RTB / ABORT cards by id where the deck has them.
#define CARD_CLEARED_HOT "clearedhot"
// ABORT IS NOT RTB (docs/DESIGN_MESSAGE_TEMPLATES.md, command definitions,
// 2026-11-09): "stop what you are doing now ... the asset then asks for
// intentions" - its own word, WORD_ABORT (FOLLOW_UP_WORDS). RTB is the stop.
#define CARDS_STOP ["rtb"]
#define TRANSITIONS_STOP ["CLOSED", "ABORTED"]
#define WORD_CLEARED "cleared"
#define WORD_STOP "stop"
#define WORD_ABORT "abort"
// "ETA m:ss" (FUNC(etaText)).
#define ETA_MINUTE 60
#define ETA_SECONDS_PAD 10
#define ETA_WORD "ETA"
// REQUEST ON STATION IS AN ORDER TO GET IN THE AIR (user, 2026-11-02: "on
// station is not a fire mission its just an order to get in the air"): its
// WILCO is "LAUNCHING - ON STATION IN m:ss" (FUNC(stationWilco)).
#define STATION_LAUNCHING "LAUNCHING"
#define STATION_ETA_WORD "ON STATION IN"
#define STATION_WILCO_SEP " - "
// ROGER, WILCO IS ONE MESSAGE (user, 2026-11-01: "did get 2 messages roger
// wilco which is one message"): the receipt waits this long (s) for the
// asset's answer (FUNC(srvFiled)); an answer of these states inside it is the
// only message (FUNC(srvReply)), the WILCO with the ROGER in its text.
#define RECEIPT_HOLD 2
#define STATE_ISSUED "ISSUED"
#define RECEIPT_FOLDS [STATE_ACCEPTED, STATE_DECLINED]
#define RECEIPT_WILCO "ROGER, WILCO"
#define RECEIPT_WILCO_WITH "ROGER, WILCO - %1"

// --- The cards the mod carries (user, 2026-11-01, FUNC(builtinCards)) ---------
// THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02): every support card is
// built in and is the one used (EFUNC(messaging,registerBuiltins)); the
// TAC//PAC deck adds only the ids the mod does not have. tools/
// check_invariants.py fails the build when a card id the providers, the
// prompts' quick replies or the card reader name is not built in. The root
// cards answer to the task set (BUILTIN_REPLIES, messaging's REPLIES_TASK), a
// report to the open set; CAS also CLEARED HOT; the resupply card lists this
// many items; the longest time on station asked.
#define BUILTIN_REPLIES ["roger", "wilco", "inprogress", "cantco", "freetext", "close", "frago", "status", "hold", "abort", "rtb", "copy"]
#define BUILTIN_OPEN_REPLIES ["roger", "freetext", "close"]
#define BUILTIN_CAS_REPLIES ["clearedhot", "clearedengage", "continue", "allattack", "move", "bda"]
#define BUILTIN_QRF_REPLIES ["move", "sitrep", "escort"]
// WHERE A COMMAND IS OFFERED (2026-11-09, the template option "roots",
// EFUNC(messaging,registerTemplate)): the thread's current tasking card must
// be one of these. The landing and lift commands in the transport threads,
// the CAS commands in a flight's, the fires commands in a battery's; MOVE in
// transport, CAS and QRF threads; ESCORT in every transport's (user,
// 2026-11-09: "no mater the phase or tasking").
#define ROOTS_LIFT ["pickup", "hlz", "extract", "casevac"]
#define ROOTS_TRANSPORT ["pickup", "hlz", "extract", "casevac", "airdrop", "qrf", "resupply", "jump"]
#define ROOTS_CAS ["cas", "onstation", "checkin"]
#define ROOTS_FIRES ["callforfire", "cffpolar", "cffshift"]
#define ROOTS_MOVE ["pickup", "hlz", "extract", "casevac", "airdrop", "qrf", "cas", "onstation", "checkin"]
#define ROOTS_EXECUTE ["pickup", "hlz", "extract", "casevac", "airdrop", "callforfire", "cffpolar", "cffshift"]
#define ROOTS_DROP ["airdrop", "jump"]
#define ROOTS_BDA ["cas", "onstation", "checkin", "callforfire", "cffpolar", "cffshift"]
#define BUILTIN_RESUPPLY_ITEMS 4
// MOVE's bounds: altitude (m) and time (min).
#define BUILTIN_MOVE_ALT_MAX 10000
#define BUILTIN_MOVE_TIME_MAX 240
// LAND HEADING (deg).
#define BUILTIN_HEADING_MAX 360
#define BUILTIN_STATION_MAX_MIN 120
// The calls for fire (2026-11-02) answer to the root set and these; the lift
// cards (LIFT REQUEST, EXTRACTION, PARADROP) to the root set and CONFIRM /
// ABORT / RTB. Their bounds: rounds per gun, the friendlies' distance, guns, a
// direction (deg), a polar distance and a shift (m), passengers.
// RECORD AS TARGET (user, 2026-11-02): the observer's `record` too.
#define BUILTIN_CFF_REPLIES ["adjust", "ffe", "repeat", "checkfire", "record"]
#define BUILTIN_LIFT_REPLIES ["execute", "move", "escort", "clearedland", "continueapp", "goaround"]
// The lift's own answers (user, 2026-11-02): ALL IN at the troop load on the
// LIFT REQUEST and the EXTRACTION, and the extraction's EXTRACT that calls it
// in from its station.
#define BUILTIN_HLZ_REPLIES ["allin"]
#define BUILTIN_EXTRACT_REPLIES ["allin", "extractnow"]
// The CAS REQUEST's friendlies (m), the AIRFRAME CHECK-IN's altitude (m) and
// time on station (min), a laser code's range.
#define BUILTIN_CHECKIN_ALT_MAX 20000
#define BUILTIN_CHECKIN_TOS_MAX 999
#define BUILTIN_LASER_MIN 1111
#define BUILTIN_LASER_MAX 1788
// What a QRF does at the link-up (the review's pick).
#define BUILTIN_QRF_ACTIONS ["CORDON", "BLOCK", "CCP", "REINFORCE", "ASSAULT"]
#define BUILTIN_CFF_ROUNDS_MAX 200
#define BUILTIN_CFF_FRIENDLIES_MAX 5000
#define BUILTIN_CFF_GUNS_MAX 99
#define BUILTIN_CFF_DIRECTION_MAX 360
#define BUILTIN_CFF_POLAR_MAX 30000
#define BUILTIN_CFF_SHIFT_MAX 5000
// TARGET SHAPE and METHOD OF FIRE (user, 2026-11-02): a shape's size (m), an
// interval (s), volleys, a continuous fire (min) - the card's bounds; the
// battery's module holds each to its own.
#define BUILTIN_CFF_SIZE_MAX 5000
#define BUILTIN_CFF_INTERVAL_MAX 600
#define BUILTIN_CFF_VOLLEYS_MAX 99
#define BUILTIN_CFF_CONTINUOUS_MAX 60
#define BUILTIN_EXTRACT_PAX_MAX 99
// The JUMP REQUEST (user, 2026-11-02) answers to the root set and these - GO
// to the aircraft's hold over the DZ, ABORT and RTB to stand it down, BOARD
// (2026-11-02) to put the stick aboard the aircraft on station - and flies 1
// to BUILTIN_JUMP_PASSES_MAX passes.
#define BUILTIN_JUMP_REPLIES ["board", "go", "nodrop", "escort"]
#define BUILTIN_JUMP_PASSES_MIN 1
#define BUILTIN_JUMP_PASSES_MAX 4
// Where the composer fills RESUPPLY's item picks from (2026-11-02, a field's
// choicesFrom - tacpad's CHOICE_SOURCES): the logistics catalog.
#define CHOICES_LOGI_CATALOG "logiCatalog"
// ONE MARKING VOCABULARY (report-card review, 2026-11-02, D45): what marks a
// point on the ground for an aircraft. The providers read the words (popWord,
// support_air MARKING_SIGNALS, support_logistics MARK_WORDS - a word they do
// not know is the module's own mark).
#define MARKS_GROUND ["SMOKE", "IR STROBE", "PANEL", "CHEMLIGHT", "FLARE", "NONE", "OTHER"]
// ...and what marks a target for a strike (the CAS REQUEST's MARKED BY).
#define MARKS_TARGET ["SMOKE", "LASER", "IR", "TRACER", "NONE"]
// An observer's correction, either axis (the `adjust` card).
#define ADJUST_WORDS ["ADD", "DROP", "LEFT", "RIGHT"]

// --- On the way in (user, 2026-11-01, FUNC(inbound), FUNC(etaTo)) -------------
// "need more information like after rw inbound eta etc etc and an alert to pop
// smoke when its close": INBOUND with the ETA every TRANSPORT_ETA_UPDATE_S s,
// 1 MIN OUT - POP SMOKE (FLASH, and the issuer's popup) ONE_MIN_OUT s out.
#define TRANSPORT_ETA_UPDATE_S 60
#define ONE_MIN_OUT 60
#define ONE_MIN_OUT_TEXT "1 MIN OUT - POP %1"
#define ONE_MIN_OUT_ASKS "%1 - %2"
#define CARD_INBOUND "inbound"
#define INBOUND_TEXT_KEY "Text.A"
#define INBOUND_SEP " - "
// The card's marking words, as what the issuer pops: [word, what is said].
#define POP_SEPARATORS " ,;/-"
#define POP_WORDS [["IR", "IR"], ["STROBE", "IR"], ["FLARE", "FLARE"], ["PYRO", "FLARE"], ["CHEMLIGHT", "CHEMLIGHT"], ["SMOKE", "SMOKE"]]
#define POP_DEFAULT "SMOKE"
// The popup's title (FUNC(alertLocal)) - the notify rail's support word.
#define ALERT_TITLE "SUPPORT"
// An ETA from where the aircraft is (FUNC(etaTo)): never slower than this
// share of its top speed, nor than ETA_MIN_MS m/s.
#define ETA_KMH_PER_MS 3.6
#define ETA_CRUISE_SHARE 0.7
#define ETA_MIN_MS 10

// --- AIRFRAME CHECK-IN (user, 2026-11-02, FUNC(checkIn)) -----------------------
// "an aircraft when it arrives on station needs to send an AIRFRAME CHECK-IN":
// the deck's `checkin` card, filed as the aircraft, by field key. Line titles
// are field keys; a key the registered card does not have is left out, so an
// older deck (no Capabilities, no Laser line) takes what it has.
#define CARD_CHECKIN "checkin"
#define CHECKIN_CALLSIGN "Line1.A"
#define CHECKIN_TYPE "Line2.A"
#define CHECKIN_POSITION "Line3.A"
#define CHECKIN_ALTITUDE "Line3.B"
#define CHECKIN_ORDNANCE "Line4.A"
#define CHECKIN_TIME "Line5.A"
#define CHECKIN_ABORT "Line6.A"
#define CHECKIN_REMARKS "Line7.A"
// The CAPABILITIES ticks are found by their prefix on the card's Capabilities
// line; the LASER CODE is the Laser line's field.
#define CHECKIN_CAPS_LINE "Capabilities"
#define CHECKIN_LASER "Laser.A"
#define CAP_FMV "FMV"
#define CAP_LASER "LASER"
#define CAP_IR "IR"
#define CAP_NVG "NVG"
// "1x <airframe>", and the card's own bounds on the numbers.
#define CHECKIN_TYPE_FORMAT "1x %1"
#define CHECKIN_ALT_MAX 20000
#define CHECKIN_MINUTES_MAX 999
// A new abort code every sortie: four figures.
#define ABORT_CODE_MIN 1000
#define ABORT_CODE_SPAN 9000
// The laser code: ACE's code on the airframe where it is set, else ACE's own
// default; inside the card's 1111-1788.
#define ACE_LASER_CODE_VAR "ace_laser_code"
#define LASER_CODE_DEFAULT 1111
#define LASER_CODE_MIN 1111
#define LASER_CODE_MAX 1788
// What a laser designator's ammunition is to the engine, and the vision modes
// that are thermal and night vision in an optic's visionMode[].
#define SIM_LASER "laserdesignate"
#define VISION_THERMAL "ti"
#define VISION_NVG "nvg"
// ORDNANCE (FUNC(ordnanceLeft)): the live rounds of what can strike the
// ground - these simulations, heaviest first, air-to-air only (airLock 2)
// left out - short names, "NAME xN" joined by ", "; nothing: NONE.
#define ORDNANCE_RANK ["shotbomb", "shotsubmunitions", "shotmissile", "shotrocket", "shotshell", "shotbullet"]
#define ORDNANCE_AIR_ONLY 2
#define ORDNANCE_NAME_MAX 18
#define ORDNANCE_ITEM "%1 x%2"
#define ORDNANCE_SEP ", "
#define ORDNANCE_NONE "NONE"

// --- Call for fire (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6) --------------
// The CALL FOR FIRE cards (FUNC(readOrder), kind "fire"): [card id, observer,
// observer's grid, mission line, size of element, grid (the target, or a
// shift's known point), polar tick, shift tick, polar line, shift line, shift
// lines, description, engagement line, danger close line, control line, TOT,
// remarks]. A "line" entry is the line's key: its fields are its letters in
// card order (Warno1.A adjust ... Warno1.D immediate suppression). THREE CARDS
// (user, 2026-11-02: "break arty in to 3 reports grid polar and shift fire"):
// CFF GRID is `callforfire` - its old polar and shift lines (Target 2 / 3, the
// Warno 3B / 3C ticks) are still read, so a deck the script has not reached
// keeps working; CFF POLAR reads its Polar line (A direction, B distance); CFF
// SHIFT its known point and the shift lines [lateral, range, vertical], each a
// word (A) and metres (B). TARGET SHAPE and METHOD OF FIRE (user,
// 2026-11-02), last: the shape line (A-D the shape's tick, E its size), the
// end line (A the far end, B the attitude) and the method line (A interval,
// B volleys, C continuous minutes) - an older deck without them reads a
// point, fired once.
#define FIRE_CARDS [ \
    ["callforfire", "Observer.A", "", "Warno1", "Warno2.A", "Warno3A.A", "Warno3B.A", "Warno3C.A", "Target2", "Target3", [], "Description.A", "Engagement", "DangerClose", "Control", "TOT.A", "Remarks.A", "Shape", "End", "Method"], \
    ["cffpolar", "Observer.A", "Observer.B", "Warno1", "Warno2.A", "", "", "", "Polar", "", [], "Description.A", "Engagement", "DangerClose", "Control", "TOT.A", "Remarks.A", "Shape", "End", "Method"], \
    ["cffshift", "Observer.A", "Observer.B", "Warno1", "Warno2.A", "Known.A", "", "", "", "", ["Lateral", "Range", "Vertical"], "Description.A", "Engagement", "DangerClose", "Control", "TOT.A", "Remarks.A", "Shape", "End", "Method"] \
]
// The Shape line's ticks in letter order; its letter after them is the size.
#define FIRE_SHAPES ["point", "area", "linear", "creeping"]
#define ORDER_FIRE "fire"
#define FIELD_LETTERS ["A", "B", "C", "D", "E", "F", "G"]
// The words a ticked letter reads as, in letter order: Warno 1 (the mission),
// Engagement (the shell; its letter after the shells is the number of rounds)
// and Control (the method of fire control).
#define FIRE_MISSIONS ["adjust", "ffe", "suppress", "immediate"]
#define FIRE_SHELLS ["HE", "SMOKE", "ILLUM", "CLUSTER", "GUIDED", "AIRBURST"]
#define FIRE_CONTROLS ["ready", "command", "tot", "cannot", "checkfire", "again"]
// How the target was given: a grid, polar from the observer, a shift from a
// known point (the grid line then holds the known point).
#define FIRE_BY_GRID "grid"
#define FIRE_BY_POLAR "polar"
#define FIRE_BY_SHIFT "shift"
// A shift's words: LEFT / L and DROP (or a minus) move it left and short;
// DOWN lowers it (CFF SHIFT's UP / DOWN - the guns are laid for the known
// point's height plus it, support_fires layHeight).
#define SHIFT_LEFT_WORDS ["L"]
#define SHIFT_DROP_WORDS ["DROP"]
#define SHIFT_DOWN_WORDS ["DOWN"]
#define SHIFT_MINUS "-"
// A lateral shift is square to the observer-target line, right positive (deg).
#define SHIFT_RIGHT 90
#define NUMBER_PATTERN "\d+(\.\d+)?"
// Danger close for a fire card with no `dangerClose` option of its own (doc
// 5.3 and D5: 600 m).
#define DANGER_CLOSE_ARTY 600
// The observer a card names (FUNC(observer)): [card id, its call sign field].
// The composer fills it with the sender's group id (autoFill ownCallsign).
#define OBSERVER_FIELDS [["callforfire", "Observer.A"], ["cffpolar", "Observer.A"], ["cffshift", "Observer.A"]]
// The observer's corrections and calls, read by FUNC(readOrder) off the reply
// cards: [card id, direction, distance, the other axis's direction, its
// distance] (the second pair: report-card review, 2026-11-02, decision 10) and
// [card id, rounds].
#define ADJUST_CARDS [["adjust", "Direction.A", "Distance.A", "Second.A", "Second.B"]]
#define FFE_CARDS [["ffe", "Rounds.A"]]
#define ORDER_ADJUST "adjust"
#define ORDER_FFE "ffe"
// D6 (user, 2026-11-01): follow-ups are taken from the issuer, the card's
// observer and anyone on the FIRES net - a man who can read the FIRES box or
// one of its sub-nets (FIRES.arty ...), by messaging's own read rule.
#define FIRES_BOX "B:FIRES"
#define FIRES_BOX_SUB "B:FIRES."
// The follow-up cards a provider is told about by word, besides CLEARED HOT
// and the stops: [card id, word].
// Step 7 (2026-11-01): the answers to the transport, casevac, airdrop and QRF
// prompts, and the CASEVAC's DESTINATION. A task card filed in the thread (a
// NEXT LIFT) is WORD_TASK (FUNC(srvFollowUp)).
// 2026-11-02: the answers to a landing's prompts (FUNC(lzClearReply)); GO,
// the answer to the jump aircraft's MEN STILL ABOARD - HOLDING OVER THE DZ;
// ALL IN, the troop load done (user, 2026-11-02: "troop load, all in"), and
// EXTRACT, an extraction on station called in. RECORD AS TARGET (user,
// 2026-11-02), a battery's answer to its end-of-mission questions. BOARD
// (user, 2026-11-02), the jump aircraft's stick put aboard on station.
// THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): EXECUTE
// replaces CONFIRM and is still told as "confirm", so every provider's hot LZ,
// AT MY COMMAND and drop answer is unchanged; MOVE replaces DESTINATION
// ("move"); STATUS, ABORT (no longer a stop), CONTINUE APPROACH, GO AROUND,
// NO DROP, CLEARED TO ENGAGE, CONTINUE, ESCORT and FRAGO are new words.
#define FOLLOW_UP_WORDS [["adjust", "adjust"], ["ffe", "ffe"], ["repeat", "repeat"], ["checkfire", "checkfire"], ["execute", "confirm"], ["bda", "bda"], ["cold", "cold"], ["hot", "hot"], ["paxoff", "paxoff"], ["hold", "hold"], ["received", "received"], ["notfound", "notfound"], ["no", "no"], ["move", "move"], ["correct", "correct"], ["wrong", "wrong"], ["nosmoke", "nosmoke"], ["clearedland", "clearedland"], ["go", "go"], ["board", "board"], ["allin", "allin"], ["extractnow", "extractnow"], ["record", "record"], ["allattack", "allattack"], ["status", "status"], ["abort", "abort"], ["continueapp", "continueapproach"], ["goaround", "goaround"], ["nodrop", "nodrop"], ["clearedengage", "clearedengage"], ["continue", "continue"], ["escort", "escort"], ["frago", "frago"]]
#define WORD_TASK "task"
#define WORD_MOVE "move"
#define WORD_STATUS "status"
#define WORD_CONTINUE_APP "continueapproach"
#define WORD_GO_AROUND "goaround"
#define WORD_NO_DROP "nodrop"
#define WORD_CLEARED_ENGAGE "clearedengage"
#define WORD_CONTINUE "continue"
#define WORD_ESCORT "escort"
#define WORD_FRAGO "frago"
// FRAGO (2026-11-09): the card, and where the core finds what it changes - the
// thread's current tasking card id and the changed keys ride on it as open
// fields (messaging's FRAGO_CARD_KEY); the provider is handed the tasking
// card re-filed with the merged values, word WORD_FRAGO.
#define CARD_FRAGO "frago"
#define FRAGO_CARD_KEY "Card.A"
#define FRAGO_REASON_KEY "Reason.A"
#define FRAGO_WAS "#was"
// STATUS (2026-11-09): the asset's STATUS REPLY, by field key, and the words
// the core fills it with (FUNC(statusReply)). A provider's optional "status"
// hook ([assetId, threadId] -> [vehicle, task text, minutes left on station
// (-1 none)]) gives the task and the time; without it the asset's sitrep line
// is the task. Fuel a percentage, ammo FUNC(ordnanceLeft), pax the cargo.
#define CARD_STATUS_REPLY "statusreply"
#define STATUS_KEY_POSITION "Position.A"
#define STATUS_KEY_TASK "Task.A"
#define STATUS_KEY_TIME "Station.A"
#define STATUS_KEY_FUEL "Fuel.A"
#define STATUS_KEY_AMMO "Ammo.A"
#define STATUS_KEY_PAX "Pax.A"
#define STATUS_FUEL_FORMAT "%1 PCT"
#define STATUS_TIME_FORMAT "%1 MIN"
#define STATUS_NONE "NONE"
#define STATUS_PERCENT 100
#define STATUS_HOOK_FIELDS 3
// STATE INTENTIONS (2026-11-09): what an asset asks after an ABORT or a HOLD
// ends - an ASSET ASKS (FUNC(askIntentions)), the next tasking among its
// answers. The starters the asset flies are offered by the reader beside them.
#define PROMPT_INTENTIONS "STATE INTENTIONS"
#define PROMPT_INTENTIONS_WHY "%1 - STATE INTENTIONS"
#define ANSWERS_INTENTIONS "move,hold,frago,rtb"
// ESCORT (user, 2026-11-09: "make sure there is a way to call in escorts to
// all transports no mater the phase or tasking"): the word WORD_ESCORT goes to
// the provider, which calls support_air's escortCall.
// A SUPPORT STARTER FILED IN A REPORT (decision 4, 2026-11-09): a CAS, fires,
// CASEVAC or QRF request filed in a TIC, SALUTE or MIST thread pulls the asset
// into that thread and stays there (FUNC(srvThreadCard), FUNC(srvFiled)).
#define REPORT_HOSTS ["tic", "contactrep", "mist"]
// A CARD FILED INTO AN ASSET'S OPEN THREAD (2026-11-02, FUNC(srvThreadCard),
// FUNC(threadCards)). A provider's "threadCards" declaration lists, per root
// card, the root cards it takes as a new task inside a thread opened with it:
// [[root card id, [card ids]], ...] - CAS re-tasked by a new CAS REQUEST, a
// transport's NEXT LIFT. Messaging takes a root card into a thread only on
// THREAD_CARD_TAKE (EFUNC(messaging,onThreadCard)). The states only the asset
// moves its thread to - ROGER, WILCO, ON TASK, CANTCO - are never filed by a
// player there, nor by the issuer of a support card into his own thread
// (a player crew's): THREAD_ASSET_STATES.
#define THREAD_CARD_TAKE "take"
#define THREAD_CARDS_KEY "threadCards"
#define CARD_KIND_ROOT "root"
#define THREAD_ISSUER_WHY "only the issuer may send %1 into this thread"
#define THREAD_ASSET_STATES [STATE_RECEIPT, STATE_ACCEPTED, STATE_IN_PROGRESS, STATE_DECLINED]
#define THREAD_ASSET_WHY "%1 is the asset's to send"

// --- Transport, casevac, airdrop, resupply, QRF (2026-11-01, step 7) ----------
// The cards FUNC(readOrder) reads, by field key (line titles are field keys).
// HLZ: [card id, pickup (D4), LZ, LZ name / marker, carry, marking, the ROUTE
// line, the EGRESS line, wind, obstacles, remarks]. THE FLIGHT PATH IS ON THE
// CARD (user, 2026-11-02: "up to 4 route points from pickup to the LZ and up to
// 4 egress points after the drop"): the ROUTE and EGRESS lines are line stems
// whose fields A to D (ROUTE_POINTS_MAX) are the points in order - Line6.A and
// Line7.A are the old single INGRESS and EGRESS, so an older deck still reads.
// The INSERT line (user, 2026-11-08: "on insertion we also need to add a fast
// rope option ... also add a simplex like repel"): its ticked letter, as
// INSERT_METHODS - land, ACE fast rope, or the transport's own rappel.
// THE PICKUP IS ITS OWN CARD (user, 2026-11-08: "split the transport in to two
// things, pick up with the helo lands turns off, insertion happens after a
// pickup"): the INSERTION has no pickup line ("" here) - filed in a PICKUP's
// thread it flies from that pickup, filed alone it picks up at the sender.
// PICKUP: [card id, pickup, pax / load, marking, wind, obstacles, remarks].
// LAND HEADING (2026-11-09): the last key on PICKUP and INSERTION (degrees,
// -1 none - order key "heading").
#define PICKUP_CARDS [["pickup", "Pickup.A", "Pax.A", "Marking.A", "Wind.A", "Obstacles.A", "Remarks.A", "Heading.A"]]
#define LIFT_CARDS [["hlz", "","Line1.A", "Line2.A", "Line3.A", "Line5.A", "Line6", "Line7", "Wind.A", "Obstacles.A", "Remarks.A", "Insert", "Heading.A"]]
#define INSERT_METHODS ["land", "rope", "rappel"]
#define ROUTE_POINTS_MAX 4
// CASEVAC: [card id, pickup site, patients ("" - the sum of the precedence
// line), the precedence line (its letters: URGENT, URGENT-SURG, PRIORITY,
// ROUTINE), the marking keys, remarks, special equipment, the patient type
// line (A litter, B ambulatory), nationality, CBRN / terrain, call sign] - THE
// 9-LINE (ATP 4-02.2 Table C-1; docs/DESIGN_MESSAGE_TEMPLATES.md decision 1,
// 2026-11-09: it replaces the 6-line). LZ SECURITY is line 6, N / P / E / X
// (FUNC(lzSecurity), LZ_SECURITY_CHOICES). The mark's colour is not on the
// request: the crew calls it (FUNC(lzClear)).
#define CASEVAC_CARDS [["casevac", "Line1.A", "", "Line3", ["Line7.A"], "Remarks.A", "Line4.A", "Line5", "Line8.A", "Line9.A", "Line2.A"]]
// The 9-line's precedence letters: urgent, urgent-surg, priority, routine.
#define CASEVAC_PRECEDENCE 4
// AIRDROP is a PARADROP since the report-card review (2026-11-02, decision 3):
// flown by a transport, supplies go by RESUPPLY. [card id, drop point,
// contents (who or what jumps), marking, ingress, egress, remarks]. The DZ
// name, altitude, friendlies and winds lines are gone - nothing read them.
#define DROP_CARDS [["airdrop", "Line1.A", "Contents.A", "Marking.A", "Line6.A", "Line7.A", "Remarks.A"]]
// RESUPPLY: [card id, the item lines' stem (ItemN.A name, ItemN.B count),
// delivery point, method, marking, its colour, remarks]; Item 1 to
// SUPPLY_ITEMS_MAX are read.
// The colour came off the card (2026-11-09: "the crew calls the colour") -
// "" here; an older deck's Marking.B is not read.
#define SUPPLY_CARDS [["resupply", "Item", "Location.A", "Method.A", "Marking.A", "", "Remarks.A"]]
#define SUPPLY_ITEMS_MAX 9
// QRF LINK-UP: [card id, who links up, link-up point, route, attachments,
// action on arrival, remarks].
#define QRF_CARDS [["qrf", "Line1.A", "Line2.A", "Line3.A", "Line4.A", "Line5.A", "Remarks.A"]]
// EXTRACTION (HLZ) (user, 2026-11-02: "need a pick up version where the pick up
// is the hot zone"): [card id, pickup HLZ, passengers, marking, wind,
// obstacles, remarks, the STATION, the EGRESS line]; LZ SECURITY by its line's
// label (FUNC(lzSecurity)). The STATION (user, 2026-11-02: "1) on station 2)
// extraction 3) troop load, all in 4) egress") is a map marker near the HLZ
// where it holds until EXTRACT; the EGRESS line's fields A to D
// (ROUTE_POINTS_MAX) are flown from the HLZ on the way home. No destination
// (user, 2026-11-08: "rtb on all in").
#define EXTRACT_CARDS [["extract", "Pickup.A", "Passengers.A", "Marking.A", "Wind.A", "Obstacles.A", "Remarks.A", "Station.A", "Egress"]]
// The CASEVAC's DESTINATION answer: [card id, field, free text]. The
// destination card's empty grid is DEFAULT; a message is read for a grid or a
// marker, or for the word DEFAULT.
// DESTINATION IS RETIRED (2026-11-09, into MOVE): a message still answers
// DESTINATION? with a grid, a marker or DEFAULT; a MOVE gives its POINT.
#define DESTINATION_CARDS [["freetext", "Text.A", true]]
// MOVE (2026-11-09, new): [card id, point, the ON ARRIVAL line (its letters:
// MOVE_ARRIVALS), the ROUTE line (A-D, ROUTE_POINTS_MAX), altitude (m), time
// (min), remarks]. Read by FUNC(readOrder), kind ORDER_MOVE: point, arrival
// (a MOVE_ARRIVALS word, "" none), route, altitude (-1 none), minutes (-1 -
// until told), remarks.
#define MOVE_CARDS [["move", "Point.A", "Arrival", "Route", "Altitude.A", "Time.A", "Remarks.A"]]
#define MOVE_ARRIVALS ["LOITER", "LAND", "HOVER", "HOLD"]
#define ORDER_MOVE "move"
// RTB'S LANDING POINT (user, 2026-11-09: "a way to set an rtb landing location
// if an aircraft has players on board"): [card id, the LAND AT grid]. Read by
// FUNC(readOrder), kind ORDER_RTB: land ([] - base). The word is still
// WORD_STOP; a provider with players aboard reads the RTB message for it
// (FUNC(rtbLanding)) and lands there before it goes home.
#define RTB_CARDS [["rtb", "Land.A"]]
#define ORDER_RTB "rtb"
#define DESTINATION_DEFAULT "DEFAULT"
#define WORD_SEPARATORS " ,;"
// A marking line holding a number is not a marking (the 9-line's Line 5 counts
// litters).
#define NUMBER_ONLY_PATTERN "^-?\d+(\.\d+)?$"
#define ORDER_PICKUP "pickup"
#define ORDER_LIFT "lift"
#define ORDER_CASEVAC "casevac"
#define ORDER_DROP "drop"
#define ORDER_SUPPLY "supply"
#define ORDER_QRF "qrf"
#define ORDER_EXTRACT "extract"
#define ORDER_DESTINATION "destination"
// JUMP REQUEST (user, 2026-11-02: "change the halo/haho/static app in to a
// message based one"): [card id, the type line (its letters: HALO, HAHO,
// STATIC), passes, the exit line (its letters: auto, manual), red light,
// green light, pickup, remarks]. The words are the ones jmfsb_jumpmaster
// flies by.
#define JUMP_CARDS [["jump", "Type", "Passes.A", "Exit", "Red.A", "Green.A", "Pickup.A", "Remarks.A"]]
#define JUMP_TYPES ["HALO", "HAHO", "STATIC"]
#define JUMP_EXITS ["auto", "manual"]
#define ORDER_JUMP "jump"
// The 9-line MEDEVAC's SECURITY choice, by its first letter (FUNC(lzSecurity)).
#define LZ_SECURITY_CHOICES [["N", "GREEN"], ["P", "YELLOW"], ["E", "RED"], ["X", "RED"]]
// THE ASSET ASKS (doc 5.4, FUNC(prompt)): the `prompt` card and its keys, and
// D9 (user, 2026-11-01) - silent PROMPT_HOLD s: asked again, NO RESPONSE -
// HOLDING; silent PROMPT_END s: the provider's own end (RTB, closed).
#define CARD_PROMPT "prompt"
#define PROMPT_TEXT_KEY "Text.A"
#define PROMPT_ANSWERS_KEY "Answers.A"
#define PROMPT_NO_RESPONSE "NO RESPONSE - HOLDING"
#define PROMPT_HOLD 180
#define PROMPT_END 300
// FLASH (step 5, 2026-11-01): the priority a prompt is filed under while the
// asset waits to release or is about to leave (EFUNC(messaging,srvSubmit)
// argument 10).
#define PRIORITY_FLASH "high"

// --- Circle, verify the mark, cleared to land (user, 2026-11-02) --------------
// "support trans needs to circle till smoke is verified, caller pops smoke helo
// verifies color, either way transport needs final permission to land"
// (FUNC(lzClear)). The provider circles its landing point; every LZ_CLEAR_TICK
// s the core looks for the caller's mark inside LZ_MARK_RADIUS m of it: seen -
// I SEE <it> (FLASH; correct / wrong); none for LZ_NAG_S s - CIRCLING - NO
// SMOKE SEEN - POP SMOKE (nosmoke); verified or skipped - READY TO LAND -
// CLEARED? (FLASH; clearedland / hold / abort). A HOLD asks again LZ_HOLD_S s
// later. The record's steps: looking, a mark seen, asked for the clearance,
// held.
#define LZ_CLEAR_TICK 2
#define LZ_MARK_RADIUS 150
#define LZ_NAG_S 45
#define LZ_HOLD_S 30
#define LZ_LOOKING "looking"
#define LZ_SEEN "seen"
#define LZ_ASKED "asked"
#define LZ_HELD "held"
#define LZ_SEEN_TEXT "I SEE %1"
#define LZ_SEEN_ANSWERS "correct,wrong"
#define LZ_NAG_TEXT "CIRCLING - NO %1 SEEN - POP %1"
#define LZ_NAG_ANSWERS "nosmoke"
#define LZ_CLEAR_TEXT "READY TO LAND - CLEARED?"
// CONTINUE APPROACH and GO AROUND (FM 3-21.38 Tables 3-2 and 3-3, 2026-11-09)
// answer it beside CLEARED TO LAND: keep coming, asked again LZ_HOLD_S s on
// (HOLD's old place); do not land, circle, find the mark again and ask again.
#define LZ_CLEAR_ANSWERS "clearedland,continueapp,goaround,abort"
#define WORD_CORRECT "correct"
#define WORD_WRONG "wrong"
#define WORD_NOSMOKE "nosmoke"
#define WORD_CLEARED_LAND "clearedland"
#define WORD_HOLD "hold"
// The marks it knows (FUNC(lzMarks)), in the order one is told apart - an IR
// strobe or a chemlight may be a SmokeShell to the engine: [pop word
// (FUNC(popWord)), classes, what it is called]. Smoke is always looked for;
// the others when the card's marking asks for them.
#define MARK_SMOKE "SMOKE"
#define MARK_IR "IR"
#define MARK_KINDS [[MARK_IR, ["IRStrobeBase", "ACE_IR_Strobe_Effect"], "IR STROBE"], ["CHEMLIGHT", ["Chemlight_base"], "CHEMLIGHT"], ["FLARE", ["FlareCore", "F_40mm_White"], "FLARE"], [MARK_SMOKE, ["SmokeShell"], "SMOKE"]]
// A mark's colour (FUNC(markColour)): the first of these in its class name or
// a parent's (SmokeShellRed - RED). A smoke whose names give none is WHITE
// when its smokeColor is at least SMOKE_WHITE_MIN in each of its first
// RGB_CHANNELS (or it has none, the plain SmokeShell); else no colour is said.
#define MARK_COLOURS ["RED", "GREEN", "YELLOW", "PURPLE", "BLUE", "ORANGE", "WHITE", "BLACK"]
#define MARK_WHITE "WHITE"
#define SMOKE_WHITE_MIN 0.8
#define RGB_CHANNELS 3

// --- CAS prompts and BDA (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step 5) ---
// D9 (user, 2026-11-01): no CLEARED HOT PROMPT_CLEARED s after WILCO -
// AWAITING CLEARED HOT (FLASH, FUNC(promptCleared)); then the prompt's own
// PROMPT_HOLD / PROMPT_END.
#define PROMPT_CLEARED 60
#define PROMPT_AWAITING "AWAITING CLEARED HOT"
#define ANSWERS_AWAITING "clearedhot,abort"
// ALL ATTACK (user, 2026-11-02: "add an all attack for the fixed flight where
// the drones also attack the target or targets in the area"): CLEARED HOT for
// a fixed-wing flight's jet and its escort drones together, offered beside
// CLEARED HOT to a fixed-wing CAS flight (the provider asks with these
// answers); refused with PROMPT_NO_ESCORTS when no escort is up. The OFF after
// it counts what the drones destroyed (PROMPT_BDA_DRONES).
#define ANSWERS_AWAITING_FW "clearedhot,allattack,abort"
#define CAS_NO_ESCORTS "noescorts"
#define PROMPT_NO_ESCORTS "NO ESCORTS - USE CLEARED HOT"
#define PROMPT_BDA_DRONES "OFF - RETURNING TO STATION - DRONES DESTROYED %1 - REQUEST BDA"
#define ANSWERS_REATTACK_FW "clearedhot,allattack,cas,abort"
// What a CAS asset says and asks (FUNC(casPrompt)): IN when the run starts,
// OFF after the release and with it REQUEST BDA, one message; after a BDA its
// RE-ATTACK (n, store) and FURTHER TASKING? (minutes on station, a refusal's
// reason in front when a new card could not be flown); BINGO (FLASH). The
// answers are reply / card ids, the quick replies the reader draws.
#define CAS_IN "in"
#define CAS_OFF "off"
#define CAS_REATTACK "reattack"
#define CAS_TASKING "tasking"
#define CAS_BINGO "bingo"
#define CARD_IN "in"
// THE CAS FLOW (user, 2026-11-02: "cas call, bda while returning to on station,
// reattack or egress (reattack back to 3) rinse and repeat"): after the release
// one message, OFF - RETURNING TO STATION - REQUEST BDA; the BDA's DECISION
// says RE-ATTACK (held for CLEARED HOT again) or EGRESS (the card's egress,
// home). A new CAS REQUEST in the thread re-tasks at either question.
#define PROMPT_BDA "OFF - RETURNING TO STATION - REQUEST BDA"
#define ANSWERS_BDA "bda,cas"
#define PROMPT_REATTACK "RE-ATTACK - %1 %2 LEFT - AWAITING CLEARED HOT"
#define ANSWERS_REATTACK "clearedhot,cas,abort"
#define PROMPT_TASKING "%1 MIN ON STATION - FURTHER TASKING?"
#define PROMPT_TASKING_ANY "FURTHER TASKING?"
#define PROMPT_WHY "%1 - %2"
#define ANSWERS_TASKING "cas,move,rtb,close"
#define PROMPT_BINGO "BINGO IN 2 MIN"
#define ANSWERS_BINGO "rtb,close"
// THE BDA (doc 7, the `bda` card): [card id, target, effect, count, re-attack,
// egress, remarks] by field key. Read by FUNC(readOrder) (kind "bda"), kept on
// the thread record under THREAD_BDA by FUNC(srvFollowUp) and read back with
// FUNC(threadBda). The DECISION line (user, 2026-11-02) keeps the RE-ATTACK
// tick's key, Reattack.A, and adds EGRESS beside it, Reattack.B - one of the
// two, required; an older deck's lone RE-ATTACK tick still reads. Its order
// key "decision": BDA_REATTACK, BDA_EGRESS, or "" (neither - an older BDA).
// THREE PICKS (2026-11-09): RE-ATTACK (Reattack.A), BACK TO STATION
// (Reattack.B) and RTB (Reattack.C - the old EGRESS: the card's egress, home).
// [card id, target, effect, count, re-attack, rtb, remarks, back to station].
#define BDA_CARDS [["bda", "Target.A", "Result.A", "Count.A", "Reattack.A", "Reattack.C", "Remarks.A", "Reattack.B"]]
#define BDA_STATION "station"
#define BDA_REATTACK "reattack"
#define BDA_EGRESS "egress"
#define ORDER_BDA "bda"
#define THREAD_BDA "bda"
// The nearest medical facility (FUNC(medicalNearest)): ACE's own mark, on an
// object or its class, and the terrain's hospital objects.
#define MEDICAL_FACILITY_VAR "ace_medical_isMedicalFacility"
#define MEDICAL_TERRAIN_TYPES ["HOSPITAL"]
#define MEDICAL_WORD_FIELD "FIELD HOSPITAL"
#define MEDICAL_WORD_HOSPITAL "HOSPITAL"

// --- Tactical flight (user, 2026-11-01) --------------------------------------
// Every support aircraft of every provider flies tactically: lights only over
// the airfield it started from, dark everywhere else; helicopters nap of the
// earth; fixed-wing on station 8 km off the map, attacking from 4 km. See
// README, "Tactical flight".
// Lights are allowed this close (m, 2D) to the airfield; the server's watch
// looks at every registered aircraft this often (s).
#define AIRFIELD_LIGHTS_RADIUS 1500
#define TACTICAL_TICK 3
// The phases a provider asks a height for (FUNC(flightHeight)).
#define PHASE_TRANSIT "transit"
#define PHASE_STATION "station"
#define PHASE_ATTACK "attack"
// What takes off, hovers and lands as a helicopter (FUNC(isRotary)): a
// helicopter, or a VTOL (user, 2026-11-08: "vtol are not in the transport
// list") - a VTOL only for that ("helo only in landing and take off"); between
// points it is a plane at VTOL_CRUISE_ALT m (FUNC(flightHeight)).
#define ROTARY_KINDS ["Helicopter", "VTOL_Base_F"]
#define VTOL_CRUISE_ALT 300
// Helicopters: terrain following, m above the ground. A load on the hook
// lifts it by the rope, the load's own height and SLING_CLEARANCE; a load whose
// rope cannot be read is carried at SLING_TRANSIT_HEIGHT (user, 2026-11-01:
// "make sure to add alt for helos that have a sling load").
#define NOE_HEIGHT 30
#define SLING_CLEARANCE 10
#define SLING_TRANSIT_HEIGHT 60
// Fixed-wing, m ATL: the attack, the off-map hold and the flight between.
#define FW_ATTACK_ALT 4000
#define FW_HOLD_ALT 4000
#define FW_TRANSIT_ALT 4000
// How far outside the map edge nearest the task a fixed-wing holds (m).
#define OFF_MAP_HOLD 8000
// Between the transit height and a task's own height (a drop, a jump) the
// aircraft changes height over APPROACH_SLOPE m flown per m of height, and
// over no less than APPROACH_MIN m (FUNC(approachHeight)).
#define APPROACH_SLOPE 5
#define APPROACH_MIN 1000
// VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
// virtual till tasked, then they spawn in at alt over the support module
// location"; it replaced the same day's "on station from the start"). A
// support aircraft is made when it is tasked, in the air at its flight level
// over its module, engines on and flying (FUNC(spawnAirborne)): a plane
// SPAWN_PLANE_SHARE of its top speed, a helicopter SPAWN_HELI_MS m/s - and
// SPAWN_SEP m clear of any other aircraft (rings SPAWN_SEP m apart,
// SPAWN_SEP_BEARING deg steps, SPAWN_SEP_RINGS rings, then stacked higher).
#define SPAWN_PLANE_SHARE 0.6
#define SPAWN_HELI_MS 25
#define SPAWN_KMH_PER_MS 3.6
#define SPAWN_SEP 150
#define SPAWN_SEP_RINGS 4
#define SPAWN_SEP_BEARING 45
#define SPAWN_FULL_CIRCLE 360
// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"): what a support asset answers once its
// last airframe is gone - it leaves the SUPPORT list too.
#define WHY_NO_AIRFRAME "UNABLE - NO AIRFRAME"

// DRONE ESCORTS (user, 2026-11-01, DESIGN_SUPPORT_MESSAGING 1.2): two drones
// with a support aircraft, on its watch (FUNC(escort), FUNC(escortTick)).
#define ESCORT_COUNT 2
#define ESCORT_TICK 2
// The wing slots (m): out to the side of the lead and back behind it - the
// left slots to the escorts furthest left of the lead's heading, so no two
// cross over it to swap sides (2026-11-05: two MQ-8Bs flew into each other).
// Closed up 2026-11-06 (user: "too far away to support"); the stack below
// keeps them apart in height.
#define ESCORT_WING_HELI 80
#define ESCORT_TRAIL_HELI 50
#define ESCORT_WING_PLANE 250
#define ESCORT_TRAIL_PLANE 150
// STACKED (2026-11-05): escort n (from 1) flies n times this many m above its
// kind's tactical height, and is made that far above the lead - no two
// escorts, nor an escort and the lead, share a height.
#define ESCORT_STACK_HELI 40
#define ESCORT_STACK_PLANE 150
// A slot is aimed this many seconds of the lead's speed ahead of it, so a
// wingman does not trail a moving lead by a whole leg.
#define ESCORT_LEAD_TIME 5
// Slower than this (km/h) the lead is holding - landed, hovering, on its
// stand: the escorts orbit it, so far out (m), each aimed so many degrees on
// round the lead from where it is - all the same way round, so an orbit
// never crosses the lead or another escort (2026-11-05: a slot that stepped
// round on its own outran the drones and pulled both through the middle).
#define ESCORT_SLOW_SPEED 30
#define ESCORT_ORBIT_HELI 200
#define ESCORT_ORBIT_PLANE 1500
#define ESCORT_ORBIT_STEP 25
// KEEPING STATION (2026-11-06, user: "lag behind"). A wingman is not sent to
// its slot - an AI pilot brakes for the point it is sent to, so one re-sent to
// a slot a few seconds ahead never matched the lead's pace. It is sent along
// the lead's heading from its slot ESCORT_STEER_TIME s of the lead's speed
// further on, a point it never reaches, and its pace is a speed cap: the
// lead's speed, plus ESCORT_CLOSE_GAIN km/h per m it is behind its slot along
// the lead's heading (less when ahead), never under ESCORT_SPEED_FLOOR of the
// lead's speed nor, for a plane, under ESCORT_STALL_MARGIN of its own landing
// speed. Engaging, attacking, holding or going home the cap is off
// (ESCORT_NO_SPEED_CAP, as the CAS pass lifts its own).
#define ESCORT_STEER_TIME 20
#define ESCORT_CLOSE_GAIN 0.5
#define ESCORT_SPEED_FLOOR 0.7
#define ESCORT_STALL_MARGIN 1.3
#define ESCORT_NO_SPEED_CAP -1
// THREATS: enemies known inside this radius (m, 2D) of the lead, the task
// point or the lead's next waypoint, seen in the last ESCORT_KNOWN_AGE s.
#define ESCORT_COVER_HELI 1500
#define ESCORT_COVER_PLANE 5000
#define ESCORT_KNOWN_AGE 60
// An escort engaging breaks off and comes back this far from the lead (m).
#define ESCORT_LEASH_HELI 2000
#define ESCORT_LEASH_PLANE 8000
// A rotary escort engages from this far off its target (m); a fixed-wing
// one flies its own passes over it.
#define ESCORT_STANDOFF_HELI 800
// What an escort is told about its target: the engine's full knowledge.
#define ESCORT_REVEAL 4
// Whoever fired a missile at the lead or an escort is the first target this
// long (s).
#define ESCORT_SHOOTER_TIME 120
// THE FLARES. A missile of the other side this close to the lead or an
// escort (m) sets them off - the backstop for IncomingMissile. Bursts per
// alarm, the gap between them (s), and no second alarm on one aircraft
// inside ESCORT_FLARE_REST s.
#define ESCORT_MISSILE_KIND "MissileCore"
#define ESCORT_MISSILE_SCAN 2500
#define ESCORT_FLARE_BURSTS 3
#define ESCORT_FLARE_GAP 1
#define ESCORT_FLARE_REST 4
#define ESCORT_CM_SIMULATION "cmlauncher"
#define ESCORT_CM_MODE "Burst"
// Below this a side is hostile (the engine's own getFriend line).
#define ESCORT_FRIEND_LIMIT 0.6
// A fixed-wing escort is made at this share of its top speed - a plane made
// still is a stall, as the providers' own planes.
#define ESCORT_PLANE_START 0.6
#define ESCORT_KMH_PER_MS 3.6
// ALL ATTACK (user, 2026-11-02; FUNC(escortAttack)): the target area's radius
// when the provider gives none (m), how long the escorts may attack before
// they rejoin (s), and the ammo simulation that is a countermeasure, not a
// weapon - an escort with only that left is Winchester.
#define ESCORT_ATTACK_RADIUS 300
#define ESCORT_ATTACK_TIME 300
#define ESCORT_CM_AMMO_SIM "shotCM"
// LEAD LOST: the escorts go back to where they were made and are removed
// inside ESCORT_HOME_RING (m), or after ESCORT_HOME_TIME (s) wherever they are.
#define ESCORT_HOME_RING 1000
#define ESCORT_HOME_TIME 600
// LZ SECURITY on the request card (hlz Line 4, casevac's): a tick on a line
// whose label holds LZ_SECURITY_WORD, the tick's own word one of these.
#define LZ_SECURITY_WORD "SECURITY"
#define LZ_SECURITY_WORDS ["GREEN", "YELLOW", "RED"]

// --- The thread's map pin (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, step 8) --
// A support thread's pin also draws the card's points, legs and danger close,
// and while IN_PROGRESS the provider's overlay and the asset's route
// (FUNC(pinTick)). Local markers - the pin is one - so the game map and the
// tablet's map draw them alike; worked out on a PIN_POLL s poll, never per
// frame. The cards a thread is a support thread by, besides its box.
#define PIN_POLL 2
#define PIN_CARDS ["cas", "onstation", "callforfire", "cffpolar", "cffshift", "pickup", "hlz","extract", "casevac", "airdrop", "resupply", "qrf", "jump"]
// The spec kinds FUNC(pinMarker) draws: [PIN_ICON, at, colour, type, text,
// size], [PIN_RING, centre, colour, radius, brush, alpha], [PIN_LINE, points,
// colour].
#define PIN_ICON "icon"
#define PIN_RING "ring"
#define PIN_LINE "line"
#define PIN_SHAPE_ICON "ICON"
#define PIN_SHAPE_RING "ELLIPSE"
#define PIN_SHAPE_LINE "POLYLINE"
// Markers take CfgMarkerColors classes, not the tablet's RGBA tokens: the ink
// reads black on the map, the fixed status red is red (danger close, impact).
#define PIN_COLOUR_INK "ColorBlack"
#define PIN_COLOUR_ALARM "ColorRed"
#define PIN_ICON_TARGET "mil_destroy"
#define PIN_ICON_LAND "mil_pickup"
#define PIN_ICON_DROP "mil_end"
#define PIN_ICON_STATION "mil_flag"
#define PIN_ICON_LEG "mil_dot"
#define PIN_ICON_LABEL "EmptyIcon"
#define PIN_ICON_SIZE 1
#define PIN_LEG_SIZE 0.6
// A card's point this close to a map marker already there is that marker:
// the pin does not draw its own on top (user, 2026-11-02).
#define PIN_ON_MARKER_M 25
#define PIN_BRUSH_EDGE "Border"
#define PIN_BRUSH_FILL "Solid"
#define PIN_ALPHA_FULL 1
// What each order kind (FUNC(readOrder)) marks: [kind, [[order key, icon,
// word, the order key of its name], ...]]. The first point found is where the
// legs and the danger-close ring are drawn round.
#define PIN_POINTS [ \
    [ORDER_STRIKE, [["target", PIN_ICON_TARGET, "TARGET", "label"]]], \
    [ORDER_FIRE, [["target", PIN_ICON_TARGET, "TARGET", ""]]], \
    [ORDER_STATION, [["area", PIN_ICON_STATION, "STATION", ""]]], \
    [ORDER_PICKUP, [["pickup", PIN_ICON_LAND, "PICKUP", ""]]], \
    [ORDER_LIFT, [["lz", PIN_ICON_LAND, "LZ", "lzName"], ["pickup", PIN_ICON_LAND, "PICKUP", ""]]], \
    [ORDER_EXTRACT, [["pickup", PIN_ICON_LAND, "PICKUP", ""], ["station", PIN_ICON_STATION, "STATION", ""]]], \
    [ORDER_CASEVAC, [["pickup", PIN_ICON_LAND, "PICKUP", ""]]], \
    [ORDER_DROP, [["point", PIN_ICON_DROP, "DZ", ""]]], \
    [ORDER_SUPPLY, [["point", PIN_ICON_DROP, "DELIVERY", ""]]], \
    [ORDER_QRF, [["linkup", PIN_ICON_LAND, "LINK-UP", ""]]], \
    [ORDER_JUMP, [["green", PIN_ICON_DROP, "GREEN LIGHT", ""], ["red", PIN_ICON_DROP, "RED LIGHT", ""], ["pickup", PIN_ICON_LAND, "PICKUP", ""]]] \
]
// The legs: [order key, the word at its far end].
#define PIN_LEGS [["ingress", "IN"], ["egress", "OUT"]]
// THE CARD'S FLIGHT PATH (user, 2026-11-02): a lift's ROUTE and EGRESS points,
// up to ROUTE_POINTS_MAX each, drawn as one line through them in order, each
// point a dot read <word> <n>: [kind, [[order key of the points, the order key
// the line starts at, the one it ends at ("" - it ends at the last point),
// word], ...]]. An order kind listed here draws these instead of PIN_LEGS.
#define PIN_ROUTES [ \
    [ORDER_LIFT, [["route", "pickup", "lz", "RTE"], ["egressRoute", "lz", "", "EGR"]]], \
    [ORDER_EXTRACT, [["egressRoute", "pickup", "", "EGR"]]] \
]
#define PIN_ROUTE_TEXT "%1 %2"
#define PIN_DC_TEXT "DANGER CLOSE %1 M - FRIENDLY %2 M"
// A salvo in the air: a filled ring this wide (m) round where it lands, at
// this alpha, read NAME - SPLASH m:ss.
#define PIN_IMPACT_M 50
#define PIN_IMPACT_ALPHA 0.3
#define PIN_SPLASH_TEXT "SPLASH %1:%2"
#define PIN_SEP " - "
// The overlay contract's shape words (FUNC(overlay)).
#define OVERLAY_RING "ring"
#define OVERLAY_LINE "line"
#define OVERLAY_POINT "point"
#define OVERLAY_ROUND "round"
// The asset row's airframe and plan (README, "assets" fields 7 and 8).
#define PIN_ROW_VEHICLE 7
#define PIN_ROW_PLAN 8

// --- The active LZs and DZs (user, 2026-11-02: "in AiTR lz and drop zones need
// to be highlighted"; FUNC(zones)) -------------------------------------------------
// What a provider says is open on the ground for a thread it flies, published to
// the issuer's side and drawn by each player's AiTR (jmfsb_ecoti, which holds the
// label words for each kind). [kind, its radius (m) when the provider gives none].
// LZs: a lift's pickup and insertion LZ, an extraction's pickup and destination, a
// casevac's pickup and destination, a QRF's landing point. DZs: a paradrop's, a
// QRF's static line, a jump's green light by type, and the jump's release point
// when the wind moved it. Drops: a resupply by airdrop or on a hook.
#define ZONE_RADIUS_LZ 50
#define ZONE_RADIUS_DZ 150
#define ZONE_RADIUS_FREEFALL 300
#define ZONE_RADIUS_RELEASE 100
#define ZONE_RADIUS_DROP 100
#define ZONE_KINDS [ \
    ["pickup", ZONE_RADIUS_LZ], ["insert", ZONE_RADIUS_LZ], ["extract", ZONE_RADIUS_LZ], \
    ["casevac", ZONE_RADIUS_LZ], ["dest", ZONE_RADIUS_LZ], ["qrf", ZONE_RADIUS_LZ], \
    ["qrfdrop", ZONE_RADIUS_DZ], ["para", ZONE_RADIUS_DZ], ["static", ZONE_RADIUS_DZ], \
    ["halo", ZONE_RADIUS_FREEFALL], ["haho", ZONE_RADIUS_FREEFALL], ["release", ZONE_RADIUS_RELEASE], \
    ["resupply", ZONE_RADIUS_DROP], ["sling", ZONE_RADIUS_DROP] \
]
// No zone is drawn wider than this (m), whatever a provider asks.
#define ZONE_RADIUS_MAX 2000
// One JIP entry per side, so a player joining mid-mission gets his side's list
// and a new list replaces the last.
#define ZONE_JIP "%1_zones_%2"
// A JIP client is told before his unit exists: the list waits for it this long (s).
#define ZONE_PLAYER_WAIT 60
// A JUMP'S DZ OUTLASTS ITS THREAD (FUNC(zonesHold)): the thread closes as the
// aircraft leaves the DZ, but the stick is still in the air steering for it. Held
// until every jumper is down - alive and under ZONE_DOWN_AGL m - or dead, looked
// at every ZONE_HOLD_TICK s, ZONE_HOLD_MAX s at most.
#define ZONE_DOWN_AGL 3
#define ZONE_HOLD_TICK 2
#define ZONE_HOLD_MAX 900

// WHAT HAPPENS TO AN AIRCRAFT IS SAID IN ITS THREAD (user, 2026-11-05: "needs
// messaging to notify of events like that"): the core's escort watch and the
// providers' own hit watches raise EVENT_AIRCRAFT [aircraft, line, flash] on
// the server; each provider maps the aircraft to its asset and open threads
// and files the line (FUNC(threadEvent)). One line per EVENT_REPEAT_S per
// aircraft for the repeating kinds (missiles, hits).
#define EVENT_AIRCRAFT      QGVAR(aircraftEvent)
#define EVENT_REPEAT_S      15
#define EVENT_MISSILE_TEXT  "MISSILE - FLARES OUT"
#define EVENT_ESCORT_DOWN   "ESCORT DOWN - %1 LEFT"
// The MESSAGE card an asset files a plain line with (FUNC(threadEvent)) and
// its one field (messaging builtinCards: line "Text", field A).
#define CARD_FREETEXT       "freetext"
#define FREETEXT_KEY        "Text.A"
