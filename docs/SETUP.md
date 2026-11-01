# Setting up a jmfsb mission

**The mission maker's guide is the [wiki](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki).**

It covers installation, the smallest mission that boots, every config file, the
cross-file contracts nothing validates for you, and a troubleshooting table.

| | |
|---|---|
| [Installation](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/Installation) | What you need loaded |
| [Mission Setup](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/Mission-Setup) | The smallest mission that boots |
| [How Config Loads](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/How-Config-Loads) | The two paths in |
| [Config Reference](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/Config-Reference) | Every config file |
| [Cross-File Contracts](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/Cross-File-Contracts) | The pairs that must agree |
| [Troubleshooting](https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER/wiki/Troubleshooting) | Symptom → where to look |

It lives on the wiki and not in `docs/` because `docs/` is the **mod's** own
reference — generated from the addon sources by `tools/gen_docs.py` — while the
wiki is written for people building missions on the framework, who are not
necessarily reading the repository at all.

---

## The server (2026-10-31)

**Secrets go in the server's environment, never in a CBA setting.** CBA sends
every server setting to every player. Leave these settings empty and set the
environment variables on the server (the Pelican egg's variables):

| Setting (leave empty) | Environment variable |
|---|---|
| Voice server (LiveKit) > API key | `JMSB_LIVEKIT_KEY` |
| Voice server (LiveKit) > API secret | `JMSB_LIVEKIT_SECRET` |
| TAC//PAC Service > Database | `GHOSTD_PACDB_URL` (or `pacdb.json` in the server's root) |
| TAC//PAC Service > Service key | `GHOSTD_PACDB_KEY` |

Or, logged in as the server's admin (`#login`), type `#jmfsb secrets` in chat:
a small dialog sends each value to the server alone, which keeps it in its own
profile and shows back only SET and the last four characters. Order used: the
setting, then the value entered in game, then the environment.

Every build before 2026-10-31 sent the old values to every player: change the
LiveKit key and secret and the database password.

**The database extension on a Windows server.** The release ships only the
Linux `ghostd_pacdb_x64.so`. A Windows server, or a Windows host with
`sync = "service"`, copies `ghostd_pacdb_x64.dll` from the repo root into the
mod folder by hand (docs/SIGNING.md).

**A mission with a `CfgRemoteExec` whitelist** (mode 1) must allow what the
mod sends. The mod ships none: a mode-1 list in a mod would block ALiVE's and
BI's own remote calls on every mission. Server requests check their sender
themselves (addons/common README, "Who sent a request"), so the whitelist is
a second line, not the first.

Clients to the server:

- common: `jmfsb_common_fnc_adminClaim`, `jmfsb_common_fnc_debugRunServer`,
  `jmfsb_common_fnc_secretSet`, `jmfsb_common_fnc_secretStatus`
- admin console: `admp_fnc_compileAndExec`, `admp_fnc_createZeusModule`,
  `jmfsb_adminpanel_fnc_adminGrant`, `jmfsb_adminpanel_fnc_envTime`,
  `jmfsb_adminpanel_fnc_envWeather`, `jmfsb_adminpanel_fnc_stabilizeLocal`,
  `jmfsb_players_fnc_setRankOverride`, `jmfsb_groups_fnc_toggleRoleGrant`
- TAC//PAC: every `jmfsb_pac_fnc_admin*`, plus `jmfsb_pac_fnc_import`,
  `structureImport`, `csvImport`, `windowSet`, `exportClasses`,
  `ticketRaise`, `ticketReply`, `ticketMine`, `applySubmit`, `applyAsk`,
  `seedFromUnit`, `opordAsk`, `loadoutStore`, `loadoutSend`, `autoSlot`
- voice: `jmfsb_voice_fnc_srvCall`, `srvAdd`, `srvAnswer`, `srvLeave`,
  `srvCallback`, `srvNetAdd`, `srvNetMembers`, `srvNetRemove`;
  `jmfsb_adapter_livekit_fnc_srvRoomToken`, `srvEchoToken`
- support: `jmfsb_support_fnc_bookCooldown`, `jmfsb_support_air_fnc_order`,
  `jmfsb_support_fires_fnc_request`, `jmfsb_support_fires_fnc_abort`,
  `jmfsb_cas_fnc_request`, `jmfsb_cas_fnc_abort`,
  `jmfsb_artydeploy_fnc_preDeploy`, `deploy`, `undeploy`, `clearSpot`
- `jmfsb_evac_fnc_evacServer`; `jmfsb_hacking_fnc_srvHackStart`,
  `srvHackComplete`, `srvDeposit`, `onBodyKilled`
- messaging: `jmfsb_messaging_fnc_srvSubmit`, `srvRequestIndex`,
  `srvRequestThread`, `srvMarkRead`, `srvClaim`
- `jmfsb_notify_fnc_srvBroadcast`; `jmfsb_adminpanel_fnc_stabilizeDone`;
  `jmfsb_systems_fnc_srvHealAll`, `getServerMetrics`;
  `jmfsb_zenmodules_fnc_srvEndexFired`; `jmfsb_rf_fnc_srvRequest`;
  `jmfsb_reaction_fnc_report`, `cbShot`, `cbRadar`; `jmfsb_ew_fnc_jamSet`,
  `decoyPlace`; `jmfsb_adsite_fnc_threat`; `jmfsb_jamming_fnc_disableSite`;
  `jmfsb_tasks_fnc_raise`; `jmfsb_boarding_fnc_board`;
  `jmfsb_mission_fnc_stagingUplink`; `jmfsb_init_fnc_srvEvacuated`;
  `jmfsb_diag_fnc_srvLog`; `jmfsb_equipment_fnc_srvMarker3D`;
  `jmfsb_friendly_fire_fnc_log`; `jmfsb_drone40_fnc_deploy`;
  `jmfsb_medic_fnc_srvMeasure`; `jmfsb_pointing_fnc_srvPoint`;
  `jmfsb_logistics_fnc_doSupplyCrate`
- `jmfsb_jumpmaster_fnc_srvLaunch`, `srvAbort`; `jmfsb_adapter_alive_fnc_probe`,
  `srvRequestATO`; `jmfsb_adapter_von_fnc_testChannel`;
  `jmfsb_back_to_game_fnc_handleConnected`
- `jmfsb_hacking_fnc_srvAlarmAdd`, `srvAlarmDelete`, `srvAlarmsClear`;
  `jmfsb_init_fnc_srvAttendance`; `jmfsb_curator_fnc_editableAdd`
- `jmfsb_curator_fnc_zeusAssign`, `zeusUnassign`, `zeusActivateAddons`;
  `jmfsb_respawn_fnc_forceRespawnRequest`; `jmfsb_teleport_fnc_addPoint`;
  `jmfsb_patrol_base_fnc_dropKits`, `serverBuild`, `serverUnbuild`;
  `jmfsb_devices_fnc_uavOrder`; `jmfsb_zenmodules_fnc_endexRequest`

The server to clients:

- `jmfsb_notify_fnc_notify`, `jmfsb_common_fnc_debugReply`,
  `jmfsb_adminpanel_fnc_secretsShow`,
  `jmfsb_adminpanel_fnc_execLog`, `admp_fnc_compileAndExec`,
  `jmfsb_adminpanel_fnc_envWeather`, `jmfsb_adminpanel_fnc_stabilizeLocal`
- voice: `jmfsb_voice_fnc_callFailed`, `netFailed`, `note`;
  `jmfsb_adapter_livekit_fnc_roomAnswer`, `echoAnswer`
- `jmfsb_hacking_fnc_depositTake`; `jmfsb_messaging_fnc_cltReceive`,
  `cltIndex`, `cltThread`, `cltMarker`, `cltReject`;
  `jmfsb_curator_fnc_zeusAssigned`; `jmfsb_respawn_fnc_forceLocal`;
  `jmfsb_devices_fnc_uavOrder`; `jmfsb_zenmodules_fnc_endexLocal`;
  `jmfsb_teleport_fnc_addAction`, `jmfsb_patrol_base_fnc_addUnbuildAction`
- every `jmfsb_pac_fnc_*Recv` the PAC page uses
- `jmfsb_support_air_fnc_putOut`, `jump`; `jmfsb_respawn_fnc_enable`,
  `disable`, `adjustTimeLocal`; `jmfsb_cas_fnc_onStation`;
  `jmfsb_support_fires_fnc_sayLocal`, `markLocal` (JIP), `unmarkLocal`;
  `jmfsb_init_fnc_attendance`; `jmfsb_hacking_fnc_renderProduct`,
  `pickResult`, `rfReached`, `alarmRing`; `jmfsb_messaging_fnc_cltCacheClear`
- `jmfsb_common_fnc_onAlert`; `jmfsb_cas_fnc_inbound`, `release`,
  `offStation`; `jmfsb_jumpmaster_fnc_jump`, `board`, `light`, `say`;
  `jmfsb_support_air_fnc_sayLocal`; `jmfsb_adsite_fnc_fire`, `kill`;
  `jmfsb_back_to_game_fnc_handleTeleport`
- `jmfsb_spectator_fnc_start`, `stop`, `reloadLocal`; `jmfsb_ew_fnc_aiAlert`,
  `onThreat`; `jmfsb_support_fnc_ackLocal`; `jmfsb_adapter_von_fnc_testResult`;
  `jmfsb_equipment_fnc_show3DMarker`; `jmfsb_safestart_fnc_lowerWeapon`;
  `jmfsb_logistics_fnc_crateDraggable`; `jmfsb_medic_fnc_measureLocal`;
  `jmfsb_pointing_fnc_pointed`
- never `jmfsb_messaging_fnc_onReject` or `onReceive`, nor the hooks
  `jmfsb_adapter_alive_fnc_whenReady`, `onCapture`, `jmfsb_common_fnc_onBarrage`,
  `jmfsb_support_fnc_onAck`, `jmfsb_tasks_fnc_onEvent` (local only)

Engine commands some features send: `moveInCargo`, `moveOut`,
`deleteVehicle`, `hint`, `setRank`.

---

## Maintaining the wiki

A GitHub wiki is a **separate git repository**. The source of truth for it is
`wiki/` **in the DIVINER repo**, not this one - the framework mission and
DIVINER go together, and the wiki documents that pair. It moved there on
2026-09-03.

To publish changes:

```sh
# once, from the DIVINER repo
git clone https://github.com/Joint-Multi-Functional-Strike-Battalion/DIVINER.wiki.git ../DIVINER.wiki

# each time
cp wiki/*.md ../DIVINER.wiki/
cd ../DIVINER.wiki
git add -A
git commit -m "wiki: <what changed>"
git push
```

### Conventions

- Pages are **flat** — no folders. A file called `Comms-Plan.md` becomes the page
  **Comms Plan** at `/wiki/Comms-Plan`.
- `Home.md` is the landing page. `_Sidebar.md` is the navigation shown beside
  every page. `_Footer.md` is the footer.
- Link between pages with `[Comms Plan](Comms-Plan)` — the file name without the
  extension. Anchors work as `[Admins](Other-Systems#admins)`.
- Every page must be reachable from `_Sidebar.md`.
