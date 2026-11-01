[
    QGVAR(highJogCoefEnabled),
    "CHECKBOX",
    ["Enable custom high jog coefficient", "Enables custom high jog coefficient when moving with weapon ready. Requires ACE Advanced Fatigue working."],
    ["JMSB - Gear & Vision", "Fatigue"],
    false,
    1,
    {[_this] call FUNC(toggleHighJogFactor)}
] call CBA_fnc_addSetting;

[
    QGVAR(highJogCoef),
    "SLIDER",
    ["Custom high jog coefficient", "Additional stamina used coefficient when moving with weapon ready. 100% is default ACE, 80% it's like you had low weapon ready."],
    ["JMSB - Gear & Vision", "Fatigue"],
    [0.8, 1, 0.9, 0, true],
    1
] call CBA_fnc_addSetting;
