// CBA Settings [ADDON: jmfsb_common]

[
    QGVAR(isrVariable), "EDITBOX",
    ["ISR unit variable", "Name of the unit variable marking someone as an ISR operator. Gates the hacking tablet and Intel Hunt processing. Set it on a unit with: this setVariable ['isISR', true]"],
    ["JMSB - Mission & Admin", "Common"],
    "isISR",
    true
] call CBA_fnc_addSetting;

// THE TICK TIMINGS (code review R9, 2026-10-31): the RF mesh and the APS watch
// once a minute in the RPT, against their budgets (FUNC(perfReport)).
[
    QGVAR(perfLog), "CHECKBOX",
    ["Log tick timings", "Once a minute, write how long the costly ticks took - the RF mesh and the APS watch: runs, average and worst ms, and how often they went over budget - to the RPT. For load tests."],
    ["JMSB - Mission & Admin", "Common"],
    true,
    true
] call CBA_fnc_addSetting;

// The threat board's own debug - every contact filed, in the RPT.
[
    QGVAR(boardDebug), "CHECKBOX",
    ["Threat Board Debug", "Log every contact jmfsb's sensors file on a side's threat board - what that side knows, where, how wrong it might be, and which sensor said so."],
    ["JMSB - Mission & Admin", "Common"],
    false,
    true
] call CBA_fnc_addSetting;
