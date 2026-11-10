// TFAR needs <radio>_1 .. _1000 instance classes. TFAR ships the macro that
// declares them; use it. QUOTE comes from our script_macros.hpp.
#include "\z\tfar\addons\handhelds\radio_ids.hpp"

class CfgWeapons {
    class TFAR_anprc152;

    // THE HANDHELDS AS TFAR SHORT RANGE RADIOS. Everything TFAR needs to run
    // one - range, encryption, the digital subtype, the dialog - comes from the
    // PRC-152 they now inherit (the model too: the generated MPU5 mesh is not
    // worn, see jmfsb_radios); name, icon and RF profile stay jmfsb_radios'.
    // tf_parent names the class itself so the per-ID instances resolve back to
    // it, and tf_prototype marks it as the arsenal item TFAR swaps for a
    // numbered instance when a player picks it up.
    class jmfsb_mpu5: TFAR_anprc152 {
        tf_prototype = 1;
        tf_parent = "jmfsb_mpu5";
        // Its own screen - the set and the PTT unit, two knobs. dialog.hpp.
        tf_dialog = "jmfsb_mpu5_radio_dialog";
    };

    class jmfsb_tw950: TFAR_anprc152 {
        tf_prototype = 1;
        tf_parent = "jmfsb_tw950";
    };

    // The numbered instances TFAR hands out, one per radio in play.
    TF_RADIO_IDS(jmfsb_mpu5,[JMSB] MPU5)
    TF_RADIO_IDS(jmfsb_tw950,[JMSB] TW-950)
};
