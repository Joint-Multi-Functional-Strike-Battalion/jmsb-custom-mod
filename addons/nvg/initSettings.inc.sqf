// CBA Settings [ADDON: jmfsb_nvg]
//
// The phosphor colour settings (jmfsb_nvg_ACE, _Effect, _Blacklist) are still
// declared in XEH_preInit.sqf as they always were; this file holds what came
// after them.
//
// CLIENT-SIDE: each player picks for himself what he sees.

// Every JMSB goggle (jmfsb_nvg_fullScreen = 1 in its config) is full screen by
// config. Off, FUNC(updateMask) puts a tube mask back over the view in NVG mode -
// ACE's own mask for the goggle it was made from.
[
    QGVAR(showFullScreen), "CHECKBOX",
    ["NVG full screen", "On: JMSB goggles fill the whole screen in NVG mode. Off: the view is seen through the tubes - ACE's mask for the goggle the JMSB one was made from."],
    ["1st Joint Multi-Functional Strike Battalion", "NVG"],
    true,
    false,
    {[] call FUNC(updateMask)}
] call CBA_fnc_addSetting;
