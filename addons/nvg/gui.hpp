// THE TUBE MASK. Created on the MISSION DISPLAY (46) with ctrlCreate, not raised
// as an RscTitles layer - a title layer outlives its mission (jmfsb_hud, ecoti),
// display 46 dies with it. Root-level because that is where ctrlCreate looks.
// The picture, place and fade are set at runtime by FUNC(maskShow).

class RscPicture;

class GVAR(mask): RscPicture {
    idc = -1;
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
    text = "";
};
