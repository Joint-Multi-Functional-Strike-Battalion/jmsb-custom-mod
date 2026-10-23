# TFAR Adapter

`jmfsb_adapter_tfar`

TFAR's side of voice and of RF's backend seam (docs/DESIGN_VOICE.md,
docs/DESIGN_RF.md). **Optional**: it requires `tfar_core` and carries
`skipWhenMissingDependencies`, so without TFAR the PBO is skipped and voice is
game VoIP (VON). Restored 2026-10-20 from the 1268 build ("keep the ACRE and
TFAR"). NOT RUN IN GAME.

## The voice adapter "tfar"

With TFAR loaded `jmfsb_voice_system` is `"tfar"`, VON stands down, and this
addon registers as the voice core's `"tfar"` adapter (external-radio mode,
addons/voice/README.md). The core reads, through the hooks:

| Hook | Here |
|---|---|
| `nets` | the nets his sets HEAR - each set's active and additional channel (handheld, backpack, the rack of his crew seat), read back from frequencies; the first set to carry a net keeps it |
| `netState` | per net: active (the picked set's active channel), muted (that set's TFAR volume is 0), ear (TFAR's stereo setting of that channel: both / left / right), reachable (set on, and RF does not say "no link") |
| `current` / `setActive` | the active net is the active channel of the picked set (handheld first); `setActive` moves the set that hears the net onto it (`fnc_selectNet`) and picks that set |
| `setEar` | `TFAR_fnc_setSwStereo` / `setAdditionalSwStereo` / `setLrStereo` / `setAdditionalLrStereo` |
| `setMute` | the set's volume to 0 and back (TFAR has one volume per set: both its nets) |
| `talking` | other players keying a net he hears: each speaker PUSHES his key-down / key-up to his side (`jmfsb_adapter_tfar_keyed`, from TFAR's `OnTangent`), kept until key-up, death or respawn. TFAR's own range is not checked here |
| `ptt` | his own key: `[true, net]` while one of his tangents is down |
| `linkQuality` | RF's quality on the net from the node of the set that hears it (`jmfsb_rf_fnc_quality`; the net's, not the speaker's own path); unknown = 1 |
| `selfTest` | sets, plan, view, heard speakers and the range levers to the RPT |

All of it is rebuilt by the client poll every second (`fnc_voiceView`) and at
once after any change made here. Calls are VON only: none under TFAR.

## RF nodes

**Client, every second:** the active SR radio, an LR backpack, and the LR rack
of the crew seat he is in become RF nodes `tfar_<uid>_sr|lr|veh`, with the
profile the class names in config (`jmfsb_rf_profile` via
`jmfsb_rf_fnc_itemProfile`: MPU5 handheld, TW-950 legacy, the radio bags
manpack), else handheld / manpack; a rack is the vehicle set, on the vehicle.
Fill: the nets its channels carry, plus DATA. On/off, the active and monitor
(additional) channel and `tx` (from TFAR's `OnTangent`, at once) are RF state.
The plan's nets are made in RF by `jmfsb_pac_fnc_netPlanSync`, not here.

## Nets over frequencies: the PAC net plan

The one plan is `jmfsb_pac_fnc_netPlan` (VON plan or tfarNets plan alike).
`fnc_planNets` gives each plan net a TFAR set kind (`sr` nets the handheld,
`lr` and `a2g` nets the long range sets) and a channel: its slot when it has
one, else the next free channel of its set kind in plan order (a net with no
channel left is still loadable by a fill).

- **A net's frequency** (`fnc_netFrequency`): a slotted net takes the plan's
  TFAR frequency list entry for its slot (`jmfsbFR_radio_tfarSrFreqs` /
  `tfarLrFreqs`), else one 0.1 MHz slot of TFAR's band (SR 30-512, LR 30-87
  MHz) hashed from the net id - every machine derives the same number.
- **Read back** (`fnc_radioNets`): each channel's frequency names a net; a
  channel that names none falls back to the plan's channel number.
- **`jmfsb_adapter_tfar_fnc_fill [srNets, lrNets]`** (public): net id per
  channel onto every set he carries, through `TFAR_fnc_setChannelFrequency`.
- **`jmfsb_adapter_tfar_fnc_selectNet [net, kind, alternate]`** (public).
- **`jmfsb_adapter_tfar_fnc_tune [teamNet, lrNet]`** (public): the TFAR path of
  `jmfsb_players_fnc_setRadioChannel` (login, group join, respawn, radio
  reset): the plan's fill on every set, his squad's nets
  (`jmfsb_pac_fnc_netPlanSquad`, the platoon's long range from
  `lrPlatoonChannel` when the squad has no row) on the last channel if the plan
  had none left, and selected as the active channels.
- **`jmfsb_adapter_tfar_fnc_activeRadio [class]`** (public): the TFAR path of
  `jmfsb_players_fnc_setActiveRadio` - an instance of that arsenal class in
  hand (the PAC plan's `tfarActiveRadio`).
- **`jmfsb_adapter_tfar_fnc_sideDefaults`** (public): the TFAR path of
  `jmfsb_gear_fnc_setupRadios` - TFAR's side default frequency lists
  (`TFAR_defaultFrequencies_sr_*` / `lr_*`, west, east, independent) from the
  plan, so an issued set starts on the plan's nets.
- **New sets** (setting **Fill new sets from the plan**, on): a handheld or
  backpack set first seen with no channel on a known net frequency gets the
  plan's fill. Racks, sets already on the plan and captured sets are left.

## Voice override

RF link quality drives TFAR's per-unit range levers,
`tf_sendingDistanceMultiplicator` (read when the tangent goes down) and
`tf_receivingDistanceMultiplicator`. A net's quality becomes a range factor:
RF unknown = TFAR's own range; at or below **Cut at quality** = cut (0.001 of
range); above it **Range at the weakest link** rising linearly to 1. Sending is
per net (`OnBeforeTangent`), receiving per unit (the best of the nets he
hears); the factor is split between the ends (sqrt(f) each way). **RF voice
override** off puts both levers back to 1. Jamming reaches TFAR voice this way.

## TFAR's UI hidden, our PTT

- **Hide TFAR's radio UI** (on): `TFAR_showTransmittingHint` and
  `TFAR_showChannelChangedHint` false in missionNamespace for the session (the
  player's saved values kept and restored; his changes meanwhile kept); the
  radio card TFAR draws with no setting is taken down a frame after its
  `OnSWChange`, `OnLRChange`, `On*channelSet`, `On*speakersSet` with
  `TFAR_fnc_hideHint`.
- **PTT keybinds** (active net, alternate, long range, long range alternate)
  call TFAR's own tangent handlers; **unbound by default**, taking TFAR's
  default key only when TFAR's own keybind for that tangent is empty at
  mission start. A display hook keys them with extra modifiers held. Next /
  previous net, short and long range, unbound.

## TFAR radios

The MPU5, TW-950 and the radio bags are plain items without TFAR; the optional
patch `jmfsb_compatibility_tfar_radios` (and `_tfar_cdlc_ws` for the WS bag)
makes them TFAR sets when TFAR is loaded (addons/compatibility).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_rf`
- `jmfsb_voice`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_
- `tfar_core` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

29 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_adapter_tfar_voiceEnabled` | CHECKBOX | RF voice override |
| `jmfsb_adapter_tfar_voiceCut` | SLIDER | Cut at quality |
| `jmfsb_adapter_tfar_voiceFloor` | SLIDER | Range at the weakest link |
| `jmfsb_adapter_tfar_hideTfarUi` | CHECKBOX | Hide TFAR's radio UI |
| `jmfsb_adapter_tfar_fillOnIssue` | CHECKBOX | Fill new sets from the plan |

## Functions

<details><summary>29</summary>

- `jmfsb_adapter_tfar_fnc_activeRadio`
- `jmfsb_adapter_tfar_fnc_applyVoice`
- `jmfsb_adapter_tfar_fnc_fill`
- `jmfsb_adapter_tfar_fnc_keyed`
- `jmfsb_adapter_tfar_fnc_linkQuality`
- `jmfsb_adapter_tfar_fnc_netFrequency`
- `jmfsb_adapter_tfar_fnc_netTable`
- `jmfsb_adapter_tfar_fnc_planNets`
- `jmfsb_adapter_tfar_fnc_poll`
- `jmfsb_adapter_tfar_fnc_profileFor`
- `jmfsb_adapter_tfar_fnc_program`
- `jmfsb_adapter_tfar_fnc_ptt`
- `jmfsb_adapter_tfar_fnc_pttKey`
- `jmfsb_adapter_tfar_fnc_radioKind`
- `jmfsb_adapter_tfar_fnc_radioNets`
- `jmfsb_adapter_tfar_fnc_radios`
- `jmfsb_adapter_tfar_fnc_selectNet`
- `jmfsb_adapter_tfar_fnc_selfTest`
- `jmfsb_adapter_tfar_fnc_setActive`
- `jmfsb_adapter_tfar_fnc_setEar`
- `jmfsb_adapter_tfar_fnc_setMute`
- `jmfsb_adapter_tfar_fnc_sideDefaults`
- `jmfsb_adapter_tfar_fnc_stepNet`
- `jmfsb_adapter_tfar_fnc_talking`
- `jmfsb_adapter_tfar_fnc_tangent`
- `jmfsb_adapter_tfar_fnc_tfarUi`
- `jmfsb_adapter_tfar_fnc_tune`
- `jmfsb_adapter_tfar_fnc_voiceFactor`
- `jmfsb_adapter_tfar_fnc_voiceView`

</details>
