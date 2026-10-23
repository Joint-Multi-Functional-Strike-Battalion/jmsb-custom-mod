// THE AIRCRAFT PICKER. The CAS drone module picks its airframe out of the
// class picker in jmfsb_main (CfgEdenDrone.hpp), and these modules should
// look the same in Eden - but every variant there is a drone, a static or an
// ammo list, and these take any aircraft, crewed or not. So this is one more
// variant of the same window: the shared single-select base, fed with the
// "vehicle" kind and its side and faction filters. The handlers are
// jmfsb_common's, as for every other variant; Eden honours them only on the
// control class, so the variant is a class of its own.
class Cfg3DEN {
    class Attributes {
        class jmfsb_ClassPick_Base_Single;
        // One list per job, aircraft only (user, 2026-10-19: land vehicles,
        // boats and parachutes were in the CAS and transport lists).
        class GVAR(pickCas): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'aircraft','','CAS aircraft class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
        class GVAR(pickHeli): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'heli_transport','','Transport helicopter class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
        class GVAR(pickCargo): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'air_transport','','Aircraft class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
    };
};
