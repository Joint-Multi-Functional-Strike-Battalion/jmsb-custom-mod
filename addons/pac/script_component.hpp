#define COMPONENT pac
#define COMPONENT_BEAUTIFIED TAC//PAC
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_PAC
    #define DEBUG_MODE_FULL
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's drawing grammar - row heights, padding, rule weights - so the
// PAC app is drawn in the same hand as every other app in the suite.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ---------------------------------------------------------------------------
// TAC//PAC's own logic uses VANILLA PLUMBING, per the design handoff: mission
// event handlers, remoteExec, profileNamespace, createHashMap, scheduled loops.
// No CBA settings, no CBA events, no CBA per-frame handlers.
//
// It cannot be literally CBA-free and still be an addon in this mod - PREP is
// CBA_fnc_compileFunction and every PBO here requires cba_xeh - so the rule is
// read as its intent: nothing in PAC's behaviour depends on CBA, and its
// configuration is CfgGFA_PAC - with ONE exception, asked 2026-09-05: where
// the pacdb service is (initSettings.inc.sqf), because a rented game server
// can take a CBA server setting and cannot take a file in its root.
// ---------------------------------------------------------------------------

// THE STORE. Keys in the server's profileNamespace, exactly as the handoff
// names them - they are the backup format as much as the runtime one, so they
// are not ours to rename. The profile is always the store; the service
// (sync = "service") is on top of it.
#define PAC_KEY_PLAYERS   "gfa_pac_players"
#define PAC_KEY_SESSIONS  "gfa_pac_sessions"
#define PAC_KEY_WINDOWS   "gfa_pac_windows"
#define PAC_KEY_META      "gfa_pac_meta"
#define PAC_KEY_OPORDS    "gfa_pac_opords"
#define PAC_KEY_STRUCTURE "gfa_pac_structure"
#define PAC_KEY_LOG       "gfa_pac_log"

// The action log keeps this many rows; older ones drop off (a record's own
// actions are never dropped).
#define PAC_LOG_MAX       2000

// How long the boot waits for the pacdb service before running on the local copy.
#define PAC_SVC_TIMEOUT   20

// The boot checklist (FUNC(bootDoc)) goes to clients at most this often, in
// seconds - it changes two or three times per document read.
#define PAC_BOOT_PUBLISH_EVERY 0.5

#define PAC_SCHEMA        1

// Saves are debounced - phase 2's target, honoured from the start because a
// saveProfileNamespace per edit is the hitch it warns about.
#define PAC_SAVE_DEBOUNCE 30

// The attendance heartbeat, for crash safety: a session that never saw a
// disconnect is closed at the last beat rather than lost.
#define PAC_HEARTBEAT     60

// Application questions: the gap between two stored "order" values (the
// website numbers them 10, 20, ...), and how many checkboxes a "skills"
// question puts on one line of the tile's APPLICATION tab.
#define QUESTION_ORDER_STEP 10
#define APPLY_SKILL_COLUMNS 2

// TAC//PAC INSIDE THE TABLET (FUNC(uiHost)): the id it is adopted under as the
// tablet's open app (jmfsb_tacpad_fnc_appHost). Not the PAC tile's "pac" - that
// is the member's app, this is the admin page.
#define PAC_APP "pacAdmin"

// The admin page addresses its controls by these.
#include "ui\idcs.inc.hpp"

// THE NET PLAN (FUNC(netPlan)). Voice is game VoIP: the plan's rows name nets
// on slots, nothing is tuned. Every voice net is VHF; a long range net is named
// by its slot, as is a fallback slot no row names.
#define NET_NO_SLOT -1
#define NET_VOICE_BAND "VHF"
#define NET_KIND_SR "sr"
#define NET_KIND_LR "lr"
#define NET_SR_FORMAT "SR %1"
#define NET_LR_FORMAT "LR %1"
// THE VON PLAN (2026-10-20): jmfsbFR_radio_vonNets rows are [net, kind,
// [squad, ...]], kind one of these two; ten rows at most (the engine's custom
// channels). A plan net of kind a2g keeps the VON kind name.
// The engine's own unit traits (setUnitTrait), lower case: a skill's
// "trait:<name>" naming one of these sets the trait, anything else a variable.
#define ENGINE_TRAITS ["uavhacker", "medic", "engineer", "explosivespecialist", "audiblecoef", "camouflagecoef", "loadcoef"]
#define VON_KIND_C2 "c2"
#define VON_KIND_A2G "a2g"
#define VON_MAX_NETS 10
// A VON net row's columns (2026-10-21, skill based comms): [net, kind,
// [squads], [roles], [skills]] - a man is on it by his squad, his role id or a
// skill he holds. A testing role copy ("<id>_t") answers to its base id.
#define VON_COL_SQUADS 2
#define VON_COL_ROLES 3
#define VON_COL_SKILLS 4
#define ROLE_TEST_SUFFIX "_t"
#define NET_KIND_A2G VON_KIND_A2G
// the slot columns of a tfarNets row [net, sr slot, lr slot]
#define NET_COL_SR 1
#define NET_COL_LR 2

// BASE STATIONS (FUNC(baseStation), user 2026-10-20): an RF node of the
// "base" profile at a staging zone or a patrol base, holding every plan net
// plus DATA and the default plan's C2 (the net voice gives a squad the plan
// does not name), relay on. A zone given as a position gets an invisible
// helper object to carry the antenna.
#define BASE_PROFILE        "base"
#define BASE_HELPER_CLASS   "Land_HelipadEmpty_F"
#define BASE_ID_FORMAT      "base_%1"
#define BASE_POS_FORMAT     "%1:%2"
#define BASE_EXTRA_NETS     ["DATA", "C2"]
// the side when the caller names none and the mission has no player slots
#define BASE_SIDE_DEFAULT   west
