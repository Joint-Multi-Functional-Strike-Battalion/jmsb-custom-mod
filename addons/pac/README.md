# TAC//PAC

`jmfsb_pac`

The tacpad's drawing grammar - row heights, padding, rule weights - so the PAC app is drawn in the same hand as every other app in the suite.

**Inside the tablet.** TAC//PAC (the admin page, `uiOpen`) is one root controls
group, `jmfsb_pac_shell`, with every control as a child; the dialog is that
group at the full safe zone. In tablet mode with a device open, `uiHost`
creates the same group on the device dialog at the tablet's map area, places
the bar and the confirm box at their config fractions, scales the type by the
host's ratio to the safe zone, and adopts it as the tablet's open app
(`jmfsb_tacpad_fnc_appHost`, id `pacAdmin`) - ESC, CLOSE (`uiClose`) or a tile
close it and leave the tablet up. Every control is found through the group
(`uiCtrl`) and placed in fractions of it (`uiPlace`), so the pages are the same
on both hosts.

**One writer, one state** (review 2026-10-31, B1-B4, P4).
- No store write before the boot has loaded the store (`storeReady`, boot step 6).
  `storeSave` refuses until then, and so does the mission-end save.
- Connects and disconnects during the boot are queued and replayed in step 6
  (`playerJoin`, `sessionEnd`). Their logon reaches the database with the next
  database write (logoff, SAVE, mission end), not at once.
- Sessions left open by the last run are closed, and the manual op window
  restored, in boot step 6 after the store is loaded.
- A roster publish re-applies rank and skills only (`reapplyLocal`). Seeding,
  slotting and the kept loadout run on first spawn and respawn
  (`applyOnClient`). A player whose row arrives after he spawned gets them once,
  on that publish.
- `applySkills` sets a variable or trait only when its value changes.
- One pacdb request at a time on the server: `svcLoad` queues callers on a
  ticket, and a timed-out request blocks the next until its late answer arrives
  (at most `PAC_SVC_STALE` s). `svcSave` sends a whole chunked put in one
  unscheduled step, so two saves cannot mix.
- The heartbeat (`PAC_HEARTBEAT`) updates attendance, recomputes the roster's
  time totals and promotion list (`rosterTotals`), publishes if that list
  changed, and writes a save the debounce held back.
- `publish` sends `opordArchive` only when it changed.

**Small fixes** (review 2026-10-31, L1).
- Headless clients are never seeded or given a session: `PlayerConnected` skips
  them (`getUserInfo`), and the heartbeat leaves them out.
- The heartbeat keys sessions with `uid`, the same id as everything else.
- KICK and BAN on a player's page go by player id, not name (`#kick <id>`,
  `#exec ban <id>`). They need you logged in as the server's admin (`#login`);
  without it the page says so, and nothing is logged unless the server took it.
- The OPORD is marked posted when the admin asked to post it says it went out,
  not when he is asked. While he is asked, no other admin is, for
  `PAC_OPORD_ASK_WAIT` s (120).

**Base stations** (user, 2026-10-20). PAC bridges the radio plan into RF
(`netPlanSync`), and it puts up the base stations the same way:
`baseStation [site, side, owner]` (server) registers an RF node of profile
`base` at a staging zone or a patrol base - on the site's object, or on an
invisible helper at a position - holding every plan net, DATA and the default
C2, relay and TX on, for the players' side unless told otherwise. One station
per object or position; MPKilled and Deleted take it down, as does
`baseStationRemove [object, owner]`; `netPlanSync` re-registers every station
(`baseStationRegister`) when the plan changes. Called by `jmfsb_mission`
(staging zones) and `jmfsb_patrol_base`, each behind its own setting. Without
RF it does nothing. See docs/DESIGN_RF.md "Base stations".

**Holiday crest on the boot screen** (user, 2026-10-31). The mark on the
TAC//PAC boot overlay (`ui/bootscreen.hpp`, `bootScreen`) is the holiday's
crest when the mission loading screen's holiday table says so
(`jmfsb_loading_fnc_holiday`: 7 days before the day through the day; New
Year's Dec 26 to Jan 2), the unit's otherwise. One table for both screens,
so they always agree.

**Quick brief on the loading screen** (user, 2026-10-30). An OPORD class in
the mission's `CfgGFA_PAC >> opords` may carry one optional text attribute
beside its six sections, `quickBrief`: a few lines for the mission loading
screen (`jmfsb_loading`), shown in a QUICK BRIEF panel right of the mission
box while the mission loads, for the OPORD `settings >> currentOpord` names.
Structured text, `<br/>` for a line break. Without a `CfgGFA_PAC`, a current
OPORD or a `quickBrief` the panel shows the mission's `overviewText` instead.
It is read off the mission file (`missionConfigFile`) only: the loading
screen is up before TAC//PAC boots, so a database-held OPORD cannot feed it -
a unit on `sync = "service"` still writes it into `config_pac.hpp`.

```cpp
class CfgGFA_PAC {
    class settings { currentOpord = "op_roomba"; };
    class opords {
        class op_roomba {
            quickBrief = "Clear the Molos airfield by 0600. Air on station from H-hour.<br/>ROE: PID before fire.";
            class header { title = "TASK FORCE ROOMBA"; };
        };
    };
};
```

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_adminpanel`
- `jmfsb_tacpad`
- `jmfsb_notify`
- `jmfsb_loading`

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

203 functions.

## Functions

<details><summary>203</summary>

- `jmfsb_pac_fnc_adminAddOperator`
- `jmfsb_pac_fnc_adminApplication`
- `jmfsb_pac_fnc_adminDoc`
- `jmfsb_pac_fnc_adminDocs`
- `jmfsb_pac_fnc_adminGet`
- `jmfsb_pac_fnc_adminLog`
- `jmfsb_pac_fnc_adminLogAdd`
- `jmfsb_pac_fnc_adminOpord`
- `jmfsb_pac_fnc_adminOrbat`
- `jmfsb_pac_fnc_adminRecv`
- `jmfsb_pac_fnc_adminSave`
- `jmfsb_pac_fnc_adminSet`
- `jmfsb_pac_fnc_adminSetting`
- `jmfsb_pac_fnc_adminStructure`
- `jmfsb_pac_fnc_adminTemplate`
- `jmfsb_pac_fnc_adminText`
- `jmfsb_pac_fnc_adminTicket`
- `jmfsb_pac_fnc_adminTicketKind`
- `jmfsb_pac_fnc_adminsPublish`
- `jmfsb_pac_fnc_app`
- `jmfsb_pac_fnc_applyAsk`
- `jmfsb_pac_fnc_applyOnClient`
- `jmfsb_pac_fnc_applyRank`
- `jmfsb_pac_fnc_applyRecv`
- `jmfsb_pac_fnc_applySkills`
- `jmfsb_pac_fnc_applySubmit`
- `jmfsb_pac_fnc_applyTemp`
- `jmfsb_pac_fnc_attendanceOf`
- `jmfsb_pac_fnc_attendanceReport`
- `jmfsb_pac_fnc_autoSlot`
- `jmfsb_pac_fnc_backupDump`
- `jmfsb_pac_fnc_baseStation`
- `jmfsb_pac_fnc_baseStationRegister`
- `jmfsb_pac_fnc_baseStationRemove`
- `jmfsb_pac_fnc_boot`
- `jmfsb_pac_fnc_bootDoc`
- `jmfsb_pac_fnc_bootFail`
- `jmfsb_pac_fnc_bootLog`
- `jmfsb_pac_fnc_bootScreen`
- `jmfsb_pac_fnc_canTake`
- `jmfsb_pac_fnc_cfgCode`
- `jmfsb_pac_fnc_cfgList`
- `jmfsb_pac_fnc_cfgLists`
- `jmfsb_pac_fnc_csvImport`
- `jmfsb_pac_fnc_docsSort`
- `jmfsb_pac_fnc_exportClasses`
- `jmfsb_pac_fnc_fileFed`
- `jmfsb_pac_fnc_fromJson`
- `jmfsb_pac_fnc_hostRefresh`
- `jmfsb_pac_fnc_import`
- `jmfsb_pac_fnc_isAdminCaller`
- `jmfsb_pac_fnc_leaderNotice`
- `jmfsb_pac_fnc_loadStructure`
- `jmfsb_pac_fnc_loadoutApply`
- `jmfsb_pac_fnc_loadoutSave`
- `jmfsb_pac_fnc_loadoutSend`
- `jmfsb_pac_fnc_loadoutStore`
- `jmfsb_pac_fnc_logAction`
- `jmfsb_pac_fnc_logRecv`
- `jmfsb_pac_fnc_lookup`
- `jmfsb_pac_fnc_managedNames`
- `jmfsb_pac_fnc_minutesStamp`
- `jmfsb_pac_fnc_netPlan`
- `jmfsb_pac_fnc_netPlanSquad`
- `jmfsb_pac_fnc_netPlanSync`
- `jmfsb_pac_fnc_netPlanUnit`
- `jmfsb_pac_fnc_operatorJson`
- `jmfsb_pac_fnc_operatorSeq`
- `jmfsb_pac_fnc_opordAsk`
- `jmfsb_pac_fnc_opordDef`
- `jmfsb_pac_fnc_opordField`
- `jmfsb_pac_fnc_opordPost`
- `jmfsb_pac_fnc_pgAddOperator`
- `jmfsb_pac_fnc_pgApplication`
- `jmfsb_pac_fnc_pgApplications`
- `jmfsb_pac_fnc_pgArsenalList`
- `jmfsb_pac_fnc_pgArsenalLists`
- `jmfsb_pac_fnc_pgBackup`
- `jmfsb_pac_fnc_pgConfigs`
- `jmfsb_pac_fnc_pgDashboard`
- `jmfsb_pac_fnc_pgDeckField`
- `jmfsb_pac_fnc_pgDeckLine`
- `jmfsb_pac_fnc_pgDeckTemplate`
- `jmfsb_pac_fnc_pgDoc`
- `jmfsb_pac_fnc_pgDocs`
- `jmfsb_pac_fnc_pgNewOrder`
- `jmfsb_pac_fnc_pgOpordDef`
- `jmfsb_pac_fnc_pgOrbat`
- `jmfsb_pac_fnc_pgOrbatNew`
- `jmfsb_pac_fnc_pgOrbatOne`
- `jmfsb_pac_fnc_pgOrder`
- `jmfsb_pac_fnc_pgOrders`
- `jmfsb_pac_fnc_pgPlatoon`
- `jmfsb_pac_fnc_pgPlayer`
- `jmfsb_pac_fnc_pgRadioChannels`
- `jmfsb_pac_fnc_pgRadioSettings`
- `jmfsb_pac_fnc_pgRecord`
- `jmfsb_pac_fnc_pgRecordItem`
- `jmfsb_pac_fnc_pgRole`
- `jmfsb_pac_fnc_pgRoster`
- `jmfsb_pac_fnc_pgSquad`
- `jmfsb_pac_fnc_pgTemplates`
- `jmfsb_pac_fnc_pgTicket`
- `jmfsb_pac_fnc_pgTicketKind`
- `jmfsb_pac_fnc_pgTicketKinds`
- `jmfsb_pac_fnc_pgTickets`
- `jmfsb_pac_fnc_pgWindowStart`
- `jmfsb_pac_fnc_playerJoin`
- `jmfsb_pac_fnc_promotionPoints`
- `jmfsb_pac_fnc_publish`
- `jmfsb_pac_fnc_questionsLoad`
- `jmfsb_pac_fnc_radioApply`
- `jmfsb_pac_fnc_radioFromMission`
- `jmfsb_pac_fnc_radioKeys`
- `jmfsb_pac_fnc_rankOf`
- `jmfsb_pac_fnc_reapplyLocal`
- `jmfsb_pac_fnc_record`
- `jmfsb_pac_fnc_recordFields`
- `jmfsb_pac_fnc_recordUpgrade`
- `jmfsb_pac_fnc_registerTemplates`
- `jmfsb_pac_fnc_roleFieldParse`
- `jmfsb_pac_fnc_roleFieldText`
- `jmfsb_pac_fnc_rolesFromMission`
- `jmfsb_pac_fnc_rosterTotals`
- `jmfsb_pac_fnc_seedFromUnit`
- `jmfsb_pac_fnc_seedSample`
- `jmfsb_pac_fnc_sessionEnd`
- `jmfsb_pac_fnc_sessionSkills`
- `jmfsb_pac_fnc_sessionStart`
- `jmfsb_pac_fnc_sessionTick`
- `jmfsb_pac_fnc_skillColor`
- `jmfsb_pac_fnc_sqfText`
- `jmfsb_pac_fnc_stamp`
- `jmfsb_pac_fnc_stampMinutes`
- `jmfsb_pac_fnc_storeAdopt`
- `jmfsb_pac_fnc_storeJson`
- `jmfsb_pac_fnc_storeLoad`
- `jmfsb_pac_fnc_storeSave`
- `jmfsb_pac_fnc_stripComments`
- `jmfsb_pac_fnc_structBase`
- `jmfsb_pac_fnc_structFields`
- `jmfsb_pac_fnc_structItems`
- `jmfsb_pac_fnc_structureAdopt`
- `jmfsb_pac_fnc_structureApply`
- `jmfsb_pac_fnc_structureHash`
- `jmfsb_pac_fnc_structureImport`
- `jmfsb_pac_fnc_structurePersist`
- `jmfsb_pac_fnc_svcConfigure`
- `jmfsb_pac_fnc_svcLoad`
- `jmfsb_pac_fnc_svcPushStructure`
- `jmfsb_pac_fnc_svcSave`
- `jmfsb_pac_fnc_svcSections`
- `jmfsb_pac_fnc_svcStructure`
- `jmfsb_pac_fnc_takeServer`
- `jmfsb_pac_fnc_templatesApply`
- `jmfsb_pac_fnc_textRecv`
- `jmfsb_pac_fnc_ticketMine`
- `jmfsb_pac_fnc_ticketMineRecv`
- `jmfsb_pac_fnc_ticketRaise`
- `jmfsb_pac_fnc_ticketReply`
- `jmfsb_pac_fnc_toJson`
- `jmfsb_pac_fnc_uiAsk`
- `jmfsb_pac_fnc_uiBack`
- `jmfsb_pac_fnc_uiButtons`
- `jmfsb_pac_fnc_uiClick`
- `jmfsb_pac_fnc_uiClose`
- `jmfsb_pac_fnc_uiComboChange`
- `jmfsb_pac_fnc_uiConfirm`
- `jmfsb_pac_fnc_uiConfirmAnswer`
- `jmfsb_pac_fnc_uiCtrl`
- `jmfsb_pac_fnc_uiDraw`
- `jmfsb_pac_fnc_uiEsc`
- `jmfsb_pac_fnc_uiFilter`
- `jmfsb_pac_fnc_uiFilterShow`
- `jmfsb_pac_fnc_uiForm`
- `jmfsb_pac_fnc_uiFormRead`
- `jmfsb_pac_fnc_uiGo`
- `jmfsb_pac_fnc_uiHint`
- `jmfsb_pac_fnc_uiHost`
- `jmfsb_pac_fnc_uiList`
- `jmfsb_pac_fnc_uiListClick`
- `jmfsb_pac_fnc_uiLoaded`
- `jmfsb_pac_fnc_uiName`
- `jmfsb_pac_fnc_uiNav`
- `jmfsb_pac_fnc_uiOpen`
- `jmfsb_pac_fnc_uiPlace`
- `jmfsb_pac_fnc_uiRecv`
- `jmfsb_pac_fnc_uiRefresh`
- `jmfsb_pac_fnc_uiSectionLabel`
- `jmfsb_pac_fnc_uiSet`
- `jmfsb_pac_fnc_uiSlug`
- `jmfsb_pac_fnc_uiSub`
- `jmfsb_pac_fnc_uiSubs`
- `jmfsb_pac_fnc_uiText`
- `jmfsb_pac_fnc_uiTiles`
- `jmfsb_pac_fnc_uiTitle`
- `jmfsb_pac_fnc_uiToggle`
- `jmfsb_pac_fnc_uid`
- `jmfsb_pac_fnc_welcomeShow`
- `jmfsb_pac_fnc_whenReady`
- `jmfsb_pac_fnc_windowCurrent`
- `jmfsb_pac_fnc_windowName`
- `jmfsb_pac_fnc_windowSet`

</details>
