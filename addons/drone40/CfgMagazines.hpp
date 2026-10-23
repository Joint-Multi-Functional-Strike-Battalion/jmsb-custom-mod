// The rounds. Each is GX's recon round with its own shell and drone: it keeps
// the recon round's picture, model, mass, count (the drone's battery) and
// deployment flags (placeable, hand-deployable, UGL).
class CfgMagazines {
    class GX_1RND_DRONE40_RECON_M203;
    class GVAR(1Rnd_relay_M203): GX_1RND_DRONE40_RECON_M203 {
        author = QAUTHOR;
        displayName = "Drone40 Relay";
        displayNameShort = "Drone40 Relay";
        descriptionShort = "Deployable UAV carrying a mesh relay: relays its side's nets from the air<br/>Type: Relay<br/>Deployment Methods: Placeable, Hand Deployable, UGL";
        ammo = QGVAR(relay_shell);
        GX_Drone[] = {QGVAR(O_relay), QGVAR(B_relay), QGVAR(I_relay)};
    };
    class GVAR(1Rnd_decoy_M203): GX_1RND_DRONE40_RECON_M203 {
        author = QAUTHOR;
        displayName = "Drone40 Decoy";
        displayNameShort = "Drone40 Decoy";
        descriptionShort = "Deployable UAV emitting like a handheld radio, carrying no traffic<br/>Type: Decoy<br/>Deployment Methods: Placeable, Hand Deployable, UGL";
        ammo = QGVAR(decoy_shell);
        GX_Drone[] = {QGVAR(O_decoy), QGVAR(B_decoy), QGVAR(I_decoy)};
    };
    class GVAR(1Rnd_jammer_M203): GX_1RND_DRONE40_RECON_M203 {
        author = QAUTHOR;
        displayName = "Drone40 Jammer";
        displayNameShort = "Drone40 Jammer";
        descriptionShort = "Deployable UAV carrying a barrage jammer: denies radio and data around it<br/>Type: Jammer<br/>Deployment Methods: Placeable, Hand Deployable, UGL";
        ammo = QGVAR(jammer_shell);
        GX_Drone[] = {QGVAR(O_jammer), QGVAR(B_jammer), QGVAR(I_jammer)};
    };
};
