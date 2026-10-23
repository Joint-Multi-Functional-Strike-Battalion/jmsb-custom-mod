// The 40 mm shell. GX's base shell carries the deploy handler; GX_Drone[] is
// the drone it unfolds into, {east, west, independent}.
class CfgAmmo {
    class GX_DRONE40_BASE_SHELL;
    class GVAR(relay_shell): GX_DRONE40_BASE_SHELL {
        author = QAUTHOR;
        GX_Drone[] = {QGVAR(O_relay), QGVAR(B_relay), QGVAR(I_relay)};
    };
    class GVAR(decoy_shell): GX_DRONE40_BASE_SHELL {
        author = QAUTHOR;
        GX_Drone[] = {QGVAR(O_decoy), QGVAR(B_decoy), QGVAR(I_decoy)};
    };
    class GVAR(jammer_shell): GX_DRONE40_BASE_SHELL {
        author = QAUTHOR;
        GX_Drone[] = {QGVAR(O_jammer), QGVAR(B_jammer), QGVAR(I_jammer)};
    };
};
