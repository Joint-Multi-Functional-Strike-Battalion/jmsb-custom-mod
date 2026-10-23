#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_radioKeys

Description:
    THE RADIO PLAN'S VOCABULARY: every jmfsbFR_radio_* global the mod
    reads, by the part after the prefix, with the value a machine holds
    when nobody has written one. The structure's "radio" section is this
    map - config_radio.hpp in the database - and FUNC(radioApply) writes
    the globals from it; FUNC(radioFromMission) reads them back off a
    mission that still ships the file.

    The defaults are "no plan": empty channel lists, stock power, channel
    one everywhere. They exist so a bare read (gear's setupRadios,
    players' getRadioChannel) never hits nil on a mission whose plan is
    still on its way from the server.

Parameters:
    None

Returns:
    [[key, default], ...] <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

[
    // which radio is which tier
    ["srRadios", []],
    ["mrRadios", []],
    ["lrRadios", []],
    ["acreActiveRadio", "ACRE_PRC148"],
    // transmit power, mW (-1 = ACRE stock)
    ["srPower", -1],
    ["mrPower", -1],
    ["lrPower", -1],
    // ACRE preset plumbing
    ["acreNoProgram", []],
    ["acreLabelField", []],
    ["acreChannelCount", []],
    // the three plans
    ["srChannels", []],
    ["srGroups", []],
    ["srSquadChannel", []],
    ["srBlockSize", 16],
    ["mrChannels", []],
    ["lrChannels", []],
    ["lrSatChannel", 1],
    ["lrLocalChannel", 1],
    // LONG RANGE, PER PLATOON (2026-09-09). [[platoonId, channel], ...]. Long
    // range used to be one channel for the whole task force, which is right for
    // a detachment net and wrong the moment two platoons want to talk among
    // themselves. A platoon with no row here falls to lrDefault, which is how
    // it behaved before, so a plan that does not use this is unchanged.
    ["lrPlatoonChannel", []],
    // before a man has joined a squad
    ["srFallback", 1],
    ["mrDefault", 1],
    ["lrDefault", 1],
    // THE NET PLAN (game voice, docs/DESIGN_VOICE.md). The keys keep the names
    // they had under TFAR so a saved plan still reads: tfarNets is
    // [[net, sr slot, lr slot], ...] and the two fallbacks are slots
    // (FUNC(netPlan)). Game voice tunes nothing; with TFAR loaded
    // jmfsb_adapter_tfar reads tfarActiveRadio (the handheld put in hand) and
    // the two frequency lists (a slotted net's frequency) - no page here.
    ["tfarActiveRadio", ""],
    ["tfarSrFreqs", []],
    ["tfarLrFreqs", []],
    ["tfarNets", []],
    ["tfarSwFallback", 0],
    ["tfarLrFallback", 0],
    // THE VON PLAN (2026-10-20, the same keys DIVINER and the website write).
    // When vonNets has rows FUNC(netPlan) builds the nets from these instead
    // of tfarNets:
    //   vonTeamNets [[squad, team net], ...] - a squad's TEAM net; no row (or
    //               a blank name) is the squad's own name
    //   vonNets     [[net, "c2" | "a2g", [squad, ...], [role id, ...],
    //               [skill id, ...]], ...] - ten at most; a man is on the
    //               first row of each kind naming his squad, his role or a
    //               skill he holds (FUNC(netPlanUnit))
    //   vonSide / vonCommand / vonGlobalAdminsOnly - carried for the voice
    //               side; missing means false / false / true
    ["vonTeamNets", []],
    ["vonNets", []],
    ["vonSide", false],
    ["vonCommand", false],
    ["vonGlobalAdminsOnly", true]
]
