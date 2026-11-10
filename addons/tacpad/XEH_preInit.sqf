#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// Registries. Panels and apps are filled by whatever addons are loaded, in
// preInit, so by the time a map can be opened the shell already knows the whole
// suite - no addon has to announce itself twice.
//
// appHandlers, NOT apps. GVAR(apps) here expands to jmfsb_tacpad_apps, which is
// the ADDON flag of the jmfsb_tacpad_apps addon - its `ADDON = true` overwrote
// this HashMap with a Bool and every registerApp call then failed on a live
// server. A GVAR in addon A must never spell the name of an addon A_B.
GVAR(panels) = createHashMap;
GVAR(appHandlers) = createHashMap;
GVAR(order) = [];

GVAR(open) = createHashMap;
// THE HOST STARTS AS THE SAFE ZONE. The HOST_* macros index this without
// checking and FUNC(textH) is called from outside the suite - see FUNC(setHost).
GVAR(host) = [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
// The host's fixed panel places, empty on the vanilla map - see FUNC(setHost).
GVAR(hostPlaces) = createHashMap;
GVAR(diaryOpen) = false;

// One switch that clears the whole suite off the map, for when the map is
// wanted as a map. Panels whose id is in `pinned` survive it - that is how the
// settings strip stays on screen to be pressed a second time, which is the
// difference between a hide toggle and a one-way trip.
GVAR(hideAll) = false;
GVAR(pinned) = [];

// Which thread the reader dialog is showing.
GVAR(readerThread) = "";
GVAR(readerNet) = "ALL";
GVAR(readerTab) = "all";

// What the thread list is narrowed to, as typed - see FUNC(readerList).
GVAR(readerFilter) = "";

// The FLASH banner showing, as [index row, message], [] for none - see
// FUNC(readerFlash).
GVAR(readerFlashEntry) = [];

// COMPOSING IS A STATE OF THE RIGHT PANE. `composeOn` is what the pane draws
// instead of a thread; `composeThread` says whether it is a reply or a new
// message; `composeTemplate` is "" for the plain message the pane opens on and a
// template id once one has been inserted.
// Whether the thread view's + MARKER list is dropped down.
GVAR(readerMarkers) = false;
// The quick replies' distance pick, open under an ADJUST tile: [thread id,
// direction], [] when shut - see FUNC(readerQuickTiles).
GVAR(readerAdjust) = [];

GVAR(composeOn) = false;
GVAR(composeThread) = "";
GVAR(composeTemplate) = "";
// REAL WORLD / SIMPLE (2026-11-09): the view of the card open now (true -
// SIMPLE), seeded each time one opens (FUNC(composeShortDefault)).
GVAR(composeShortOn) = false;
// A FRAGO being written (2026-11-09, FUNC(composeFrago)): [the order's card,
// the values it opened with], [] when the card is not a FRAGO.
GVAR(composeFrago) = [];
GVAR(composeScroll) = []; // [card, thread, vertical scroll] - FUNC(readerDraw)
GVAR(composePick) = false;

// Whether the addressee picker is up. Its own flag rather than a mode of
// `composePick`, which means the TEMPLATE deck: they ask different questions and
// both own the pane below the header while they are showing.
GVAR(composeToPick) = false;

// THE PICKER'S SUPPORT GROUP (2026-11-01): the rows last asked for -
// [asked at, card, may task, card goes to support, rows], [] to ask afresh -
// and whether its two-second poll is waiting to run. See
// FUNC(composeToSupport) and FUNC(composeToSupportTick).
GVAR(toSupport) = [];
GVAR(toSupportArmed) = false;

// What the pressed controls have answered, and what has been typed: a redraw
// deletes every edit on the pane, so anything typed is harvested into here
// first - see FUNC(composeHarvest).
GVAR(composeValues) = createHashMap;

// A grid the player did not type. The value is a real position, so the thread
// anchors somewhere the map can pin; this is the text that position was shown
// as, so harvest can tell "left as picked" from "typed over".
GVAR(composeGridText) = createHashMap;

// Which grid field has its marker list open, "" for none. One at a time: the
// list is drawn under the field it belongs to.
GVAR(composeMarker) = "";

// THE PIN ON A MESSAGE THAT IS NOT A REPORT. A template carries its map anchor
// in a `grid` field; a plain message has no fields to carry one, so the pin is
// thread-level state instead of a payload key - see FUNC(composeSend) and
// EFUNC(messaging,srvThreadFor). [] is no pin.
GVAR(composePin) = [];
GVAR(composePinPick) = false;

// The addressees of a new message, kept out of the edit so a redraw cannot lose
// them.
GVAR(composeTo) = "";

// Who else is copied in, AS THE PLAYER TYPED IT - "@HQ, @REAPER, @SGT DOE". Held
// as names rather than as mailbox ids so the line the player reads back is the
// line they wrote; FUNC(composeCcIds) turns it into addressees at the send. They
// really are addressees, not tags: a CC files the thread in their box.
GVAR(composeCc) = "";

// Who is being called out by name on it. Not addressees: a tagged squad does
// not get a copy of the thread, they get woken up about the one it is already
// on, and the right to answer in it. See jmfsb_messaging_fnc_srvTagged.
GVAR(composeTags) = "";

// @ MENTIONS OF SUPPORT ASSETS (2026-11-01, FUNC(composeMention)): the
// question asked before a card switch drops typed text - [card, call sign,
// fields lost], [] for none - and the status line's word when the deck has no
// card for the asset's type, "" for none.
GVAR(composeMentionAsk) = [];
GVAR(composeNote) = "";

// The last card that was sent, held until the server has either taken it or
// refused it - a refusal arrives as an event, after the pane has tidied up, and
// this is what lets the card come back with everything still in it.
GVAR(composePending) = [];

// Why the last send was refused. It is drawn beside SEND rather than only sent
// to the notification stack: the stack is an RscTitles layer and the reader is a
// dialog, so a dialog is always in front of it - the one message telling you why
// nothing happened was behind the screen it was about.
GVAR(composeError) = "";

// THE CARD'S VERDICT BEFORE SEND (user, 2026-11-02; FUNC(composeFire)): what
// it was last asked for - address, card, values - the answer, [ok, line] or
// [], and whether the poll that clears its footprint is armed.
GVAR(composeFireKey) = [];
GVAR(composeFire) = [];
GVAR(composeFireArmed) = false;

// The required fields the last refused SEND found empty, framed in the accent
// on the card until they are filled - see FUNC(composeSend).
GVAR(composeMissing) = [];
GVAR(tickPFH) = -1;

// AFTER CONTACT, A SITREP (user, 2026-11-02: "after contact a sitrep should be
// sent"). The sender's own TIC thread being watched for the contact ending, ""
// for none; when the last sign of contact was; whether CONTACT OVER? has been
// said for it; whether a quiet check is queued; the event handlers on his
// group's units, [unit, type, id]; the index's thread ids already looked at
// for a new TIC near his group. See FUNC(contactArm).
GVAR(contactThread) = "";
GVAR(contactLast) = 0;
GVAR(contactPrompted) = false;
GVAR(contactPending) = false;
GVAR(contactHandlers) = [];
GVAR(contactSeen) = [];

// QUICK ANSWERS ON THE WALKING VIEW (user, 2026-11-06): the questions waiting
// for this player by thread id (or a local choice's key), the support
// requests he is the crew for, the question on the keys now, its page, the
// ADJUST distance pick [id, direction], and the last press [id, word, time].
// See FUNC(askTraffic), FUNC(askView), FUNC(askKey).
GVAR(asks) = createHashMap;
GVAR(askCrew) = createHashMap;
GVAR(askShown) = "";
GVAR(askPage) = 0;
GVAR(askPick) = [];
GVAR(askSent) = [];

ADDON = true;
