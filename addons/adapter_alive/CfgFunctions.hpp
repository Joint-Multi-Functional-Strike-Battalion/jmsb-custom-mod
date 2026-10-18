// ALiVE's ALIVE_fnc_sendHint, re-pointed at our FUNC(sendHint): every hint an
// ALiVE module shows a player becomes a jmfsb_notify notification instead of
// the logo box (user, 2026-10-15). Same class path as ALiVE's own
// (x_lib config.cpp: CfgFunctions >> ALiVE >> x_lib >> sendHint); only the
// file changes, which is why ALiVE_x_lib is in requiredAddons.
class CfgFunctions {
    class ALiVE {
        class x_lib {
            class sendHint {
                file = QPATHTOF(functions\fnc_sendHint.sqf);
            };
        };
    };
};
