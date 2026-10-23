// THE BOXES ARE UI CONTROLS (user, 2026-10-17: "not a box its 4 lines that do
// not line up"). drawIcon3D strips are sized in units nobody could pin down, so
// a box's four sides never met; controls on the mission display (46) are
// placed in the screen's own units, snapped to whole pixels. Created with
// ctrlCreate by FUNC(drawBoxes), so they die with the mission - root-level
// because that is where ctrlCreate looks.

class RscText;
class RscStructuredText;

// One side of a box: a plain filled strip, its colour set per frame.
class GVAR(strip): RscText {
    idc = -1;
    text = "";
    colorBackground[] = {1, 1, 1, 1};
};

// The AiTR label under a box - and a friendly player's net card under that -
// as structured text, each line centred, its colours in the text itself.
class GVAR(label): RscStructuredText {
    idc = -1;
    shadow = 2;
    size = QUOTE(LABEL_PIXELS * pixelH);
    colorBackground[] = {0, 0, 0, 0};
    text = "";
    class Attributes {
        font = "RobotoCondensedBold";
        color = "#ffffff";
        align = "center";
        shadow = 2;
    };
};

// The compass's labels and heading readout (FUNC(drawCompass)): one line of
// centred text, its colour and height set per frame.
class GVAR(compassText): RscText {
    idc = -1;
    style = ST_CENTER;
    font = "RobotoCondensedBold";
    shadow = 2;
    text = "";
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
};
