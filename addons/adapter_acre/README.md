# ACRE Adapter

`jmfsb_adapter_acre`

ACRE2's side of voice and of RF's backend seam (docs/DESIGN_VOICE.md,
docs/DESIGN_RF.md). **Optional**: it requires `acre_main` and carries
`skipWhenMissingDependencies`, so without ACRE the PBO is skipped. Uses ACRE's
public API (`acre_api_fnc_*`) and ACRE's own speaking events only; every name
was checked against the ACRE2 source (d:\Git\acre2, `c920bac1`). Radios are
still programmed by `jmfsb_gear_fnc_setupRadios` from the PAC plan. NOT RUN IN
GAME.

## The voice adapter "acre"

With ACRE loaded `jmfsb_voice_system` is `"acre"` (unless TFAR is loaded too),
VON stands down, and this addon registers as the voice core's `"acre"` adapter
(external-radio mode, addons/voice/README.md):

| Hook | Here |
|---|---|
| `nets` | one net per radio he carries (`acre_api_fnc_getCurrentRadioList`): the label of its current channel (`acre_api_fnc_getRadioChannel`) in the PAC plan's ACRE tier for its base class (`acre_api_fnc_getBaseRadio`; `jmfsbFR_radio_sr/mr/lrRadios` and their `Channels` rows - what setupRadios programs), else `<TIER> CH <n>`. Kind: the PAC net plan's when the label names a plan net, else c2 on the long range tier and team on the others |
| `netState` | active = the radio in hand (`acre_api_fnc_getCurrentRadio`), muted = its volume is 0 (`acre_api_fnc_getRadioVolume`), ear = its spatial zone (`acre_api_fnc_getRadioSpatial`: LEFT / CENTER / RIGHT), reachable = it is on (`acre_api_fnc_getRadioOnOffState`) |
| `current` / `setActive` | the net of the radio in hand; `setActive` puts the radio on that net in hand (`acre_api_fnc_setCurrentRadio`) |
| `setEar` | `acre_api_fnc_setRadioSpatial` |
| `setMute` | `acre_api_fnc_setRadioVolume` to 0, and back to what it was |
| `talking` | others on a radio: ACRE's `acre_remoteStartedSpeaking` `[unit, speakingType, radioId]` (radio type 1) / `acre_remoteStoppedSpeaking`, with the net of the speaker's radio, listed while it is one of his radios' nets |
| `ptt` | his own: `acre_startedSpeaking` `[unit, onRadio, radioId, type]` / `acre_stoppedSpeaking` |
| `linkQuality` | **1**: who hears whom, and how well, is ACRE's own signal model; RF does not grade ACRE voice |
| `selfTest` | each radio, its base class, channel and net, the view, the speakers heard |

Rebuilt by the client poll every second (`fnc_voiceView`) and at once after a
change made here. Calls are VON only: none under ACRE.

## RF nodes

Every second each ACRE radio he carries is an RF node (`acre_<uid>_<radio
id>`) on DATA only, with a profile from its base class (PRC-152/148 handheld,
PRC-117F/77 manpack, anything else legacy); radios that are gone are
unregistered. RF does not grade ACRE voice.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_rf`
- `jmfsb_voice`
- `cba_xeh` _(external)_
- `acre_main` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

9 functions.

## Functions

<details><summary>9</summary>

- `jmfsb_adapter_acre_fnc_heard`
- `jmfsb_adapter_acre_fnc_poll`
- `jmfsb_adapter_acre_fnc_radioNet`
- `jmfsb_adapter_acre_fnc_selfTest`
- `jmfsb_adapter_acre_fnc_setActive`
- `jmfsb_adapter_acre_fnc_setEar`
- `jmfsb_adapter_acre_fnc_setMute`
- `jmfsb_adapter_acre_fnc_talking`
- `jmfsb_adapter_acre_fnc_voiceView`

</details>
