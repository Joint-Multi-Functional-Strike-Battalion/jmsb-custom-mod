class Extended_PreStart_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preStart));
    };
};
class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preInit));
    };
};
class Extended_DisplayLoad_EventHandlers {
    // RscDisplayStart
    // RscDisplayLoadMission
    // RscDisplayNotFreeze
    class RscDisplayLoading {
        ADDON = QUOTE(with uiNamespace do {call COMPILE_SCRIPT(XEH_loadingDisplay)});
    };
};
