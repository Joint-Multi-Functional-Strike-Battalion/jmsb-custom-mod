// THE AIRCRAFT PICKER - the same variant of jmfsb_main's class picker that
// support_air's cargo modules use ('air_transport'), declared again here
// because Eden honours the handlers only on the control class, and a class of
// support_air's would tie this module's Eden page to that addon's.
class Cfg3DEN {
    class Attributes {
        class jmfsb_ClassPick_Base_Single;
        class GVAR(pickCargo): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'air_transport','','Aircraft class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
        // The drone escorts (user, 2026-11-01), as support_air's modules pick them.
        class GVAR(pickEscortPlane): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'uav_plane','','Fixed-wing escort drone class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
        class GVAR(pickEscortHeli): jmfsb_ClassPick_Base_Single {
            attributeLoad = QUOTE([ARR_7(_this,'uav_heli','','Rotary escort drone class:',-1,true,_value)] call EFUNC(common,edenClassPickLoad));
            attributeSave = QUOTE([ARR_2(_this,true)] call EFUNC(common,edenClassPickSave));
        };
    };
};
