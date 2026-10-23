// CBA Settings [ADDON: jmfsb_adapter_von]
// OPERATION VALUES ONLY.

[
    QGVAR(volumeFloor), "SLIDER",
    ["Volume at the weakest link", "VON volume of a radio speaker whose link quality is just above zero; it rises to full at quality 1. At quality 0 he is muted."],
    ["1st Joint Multi-Functional Strike Battalion", "Voice - VON"],
    [0, 1, DEFAULT_VOLUME_FLOOR, 2],
    1
] call CBA_fnc_addSetting;
