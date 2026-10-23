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

class Extended_PostInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_postInit));
    };
};

// Every drone40 variant of this addon: the machine that made it tells the
// server who launched it.
class Extended_InitPost_EventHandlers {
    class GVAR(base) {
        class ADDON {
            init = QUOTE(call FUNC(init));
        };
    };
};
