// THE EW JAMMER MODULE: the jammer of DESIGN_EW. In a vehicle's cargo it lets
// the crew jam from the vehicle, from the EA tab of the EW app. Worn it does
// nothing - there are no man packs (user, 2026-10-21). Still the Contact radio
// bag and still jmfsb_ew_jammerPack, so missions that stock it keep loading.
class CfgVehicles {
    class B_RadioBag_01_black_F;

    class GVAR(jammerPack): B_RadioBag_01_black_F {
        scope = 2;
        scopeCurator = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "EW Jammer Module (vehicle cargo)";
        maximumLoad = 60;
        mass = 120;
    };
};
