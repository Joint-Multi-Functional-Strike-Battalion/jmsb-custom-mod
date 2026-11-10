#include "script_component.hpp"

// THE LIVEKIT ADAPTER: THE VOICE (user, 2026-10-31: "livekit was to be the
// VON", "no in-game VON") - every net, call and local voice over our own
// LiveKit server, through the jmsb_voice extension; the voice adapter
// "livekit" of jmfsb_voice, and the echo test.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_voice",
            "jmfsb_notify",
            "cba_main",
            "cba_xeh"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
