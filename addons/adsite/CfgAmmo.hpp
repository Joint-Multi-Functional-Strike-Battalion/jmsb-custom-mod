class CfgAmmo {
    class HelicopterExploSmall;

    // THE INTERCEPT. A flash and a bang where the round died and nothing else -
    // no damage, no crater. The model is a tracer so nothing but the effect is
    // drawn. The same trick jmfsb_aps uses for its hard kill.
    class GVAR(blast): HelicopterExploSmall {
        model = "\A3\Weapons_f\Data\bullettracer\tracer_white";
        caliber = 0;
        CraterEffects = "";
        CraterWaterEffects = "ImpactEffectsWaterExplosion";
        directionalExplosion = 0;
        explosionEffects = "HERocketExplosion";
        explosionSoundEffect = "DefaultExplosion";
        explosionType = "explosive";
        hit = 0;
        indirectHit = 0;
        indirectHitRange = 0;
    };
};
