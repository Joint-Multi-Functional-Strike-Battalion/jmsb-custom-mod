// HAND-KEPT - root-level particle effects the Aegis import needs but tools/aegis_port does not bring.
//
// A weapon's GunParticles effectName names a ROOT-level effect class, which points at a CfgCloudlets
// particle. The port carried the BTR-100 30mm's CfgCloudlets particle (imported_config.hpp) but not its
// root class, so the gun logged "No entry 'bin\config.bin.jmfsb_vehicle_BTR100_30mm_Cartridge'" and ejected
// no cases (2026-10-17 RPT). As Aegis writes it (data_f_aegis\ParticleEffects\config.cpp), renamed.
class GVAR(BTR100_30mm_Cartridge) {
    class GVAR(BTR100_30mm_Cartridge) {
        simulation = "particles";
        type = QGVAR(BTR100_30mm_Cartridge);
        position[] = {0, 0, 0};
        intensity = 1;
        interval = 1;
        lifeTime = 0.05;
        qualityLevel = 2;
    };
    class GVAR(BTR100_30mm_CartridgeMed) {
        simulation = "particles";
        type = QGVAR(BTR100_30mm_Cartridge);
        position[] = {0, 0, 0};
        intensity = 1;
        interval = 1;
        lifeTime = 0.05;
        qualityLevel = 1;
    };
};
