// THE JUMP AIRCRAFT PICKER (user, 2026-11-02: "Jump aircraft module"). The
// support modules' class picker - jmfsb_main's single-select base with
// jmfsb_common's handlers - fed with the "air_transport" kind: crewed planes
// and helicopters with seats to carry a stick, no drones, no parachutes.
class Cfg3DEN {
    class Attributes {
        class jmfsb_ClassPick_Base_Single;
        class GVAR(pickAircraft): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'air_transport','','Jump aircraft class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
    };
};
