// TAC//PAC boot screen - a full-plate overlay a client sees while the unit
// initialises, the way ALiVE shows its init: the mark, "INITIALISING THE
// UNIT", a progress bar, and the boot steps as the server reports them,
// until READY. Shown on an RscTitles layer (cutRsc) so it sits over the
// loading/briefing without being a dialog; FUNC(bootScreen) drives it and
// fades it out. The look is the suite's - flat ground, one accent, the
// hairline rule, RobotoCondensed - so it is not a different mod's poster.

class RscTitles {
    class GVAR(bootScreen) {
        idd = -1;
        movingEnable = 0;
        duration = 1e9;                  // held open until FUNC(bootScreen) cuts it
        fadein = 0;
        fadeout = 0.6;
        onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(bootDisp),_this select 0)]);
        onUnload = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(bootDisp),displayNull)]);

        class controls {
            class Ground: RscText {
                idc = -1;
                x = "safezoneXAbs"; y = "safezoneY"; w = "safezoneWAbs"; h = "safezoneH";
                colorBackground[] = {0.05, 0.05, 0.05, 0.96};
            };

            // SQUARE, whatever the aspect: pixelW and pixelH are one real pixel
            // each, so equal counts of them are a square - the main menu's own
            // idiom. Stretching w/h in safezone fractions is what squished it.
            //
            // AND IT KEEPS THE TOP THIRD TO ITSELF. At 30 grid units the mark
            // stood nearly half the screen tall, from 0.30 to 0.78, and the
            // title, the rule and the boot lines were all laid out inside it -
            // white text over a picture, and the progress bar drawn straight
            // across the artwork (user, 2026-09-06: "not right"). 16 units ends
            // it well above the title.
            class Logo: RscPicture {
                idc = PAC_IDC_BS_LOGO;
                text = QPATHTOEF(media,images\logo_512.paa);
                x = "0.5 - 8 * (pixelW * pixelGridNoUIScale)";
                y = "0.10 * safezoneH + safezoneY";
                w = "16 * (pixelW * pixelGridNoUIScale)";
                h = "16 * (pixelH * pixelGridNoUIScale)";
            };

            // Two lines - the mark's name, then what it is doing.
            class Title: RscStructuredText {
                idc = PAC_IDC_BS_TITLE;
                text = "";
                x = "0.25 * safezoneW + safezoneX"; y = "0.420 * safezoneH + safezoneY";
                w = "0.50 * safezoneW"; h = "0.115 * safezoneH";
            };

            // The rule under the title, and the progress bar drawn over its
            // left. The bar's width is 0.30 of safezoneW in FUNC(bootScreen)
            // too - keep the two agreed.
            class Rule: RscText {
                idc = -1;
                x = "0.35 * safezoneW + safezoneX"; y = "0.535 * safezoneH + safezoneY";
                w = "0.30 * safezoneW"; h = "0.003 * safezoneH";
                colorBackground[] = {0.35, 0.35, 0.34, 1};
            };
            class Bar: RscText {
                idc = PAC_IDC_BS_BAR;
                x = "0.35 * safezoneW + safezoneX"; y = "0.535 * safezoneH + safezoneY";
                w = "0"; h = "0.003 * safezoneH";
                colorBackground[] = {0.761, 0.659, 0.471, 1};   // the unit's tan
            };

            // THE BOOT LINES NEED THE ROOM THEY ACTUALLY TAKE. Five entries,
            // each long enough to wrap twice, never fitted 0.10 of the screen
            // and the last was cut mid-sentence (user, 2026-09-06: "cut off").
            // Wider so they wrap less, and tall enough for ten laid-out lines.
            class Step: RscStructuredText {
                idc = PAC_IDC_BS_STEP;
                text = "";
                x = "0.18 * safezoneW + safezoneX"; y = "0.555 * safezoneH + safezoneY";
                w = "0.64 * safezoneW"; h = "0.245 * safezoneH";
            };

            // THE DOCUMENTS, three rows of ten (user, 2026-09-10: "make a bit
            // more structured 3 rows to 10 columns evening spaces") - a cell
            // each, so the columns line up, which one block of text cannot do.
            // Idcs 210-239, row-major; the line under them is 240.
            // WIDER THAN THE STEP LIST (user, 2026-11-01: "lets make this 9
            // across or make it wider, I like wider"): 0.04 to 0.96 of the safe
            // zone, a cell 0.092 wide - at 0.064 "arsenal versions 8/8" wrapped
            // its count onto a second line.
            class Doc00: RscStructuredText {
                idc = 210;
                text = "";
                x = "0.0400 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc01: RscStructuredText {
                idc = 211;
                text = "";
                x = "0.1320 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc02: RscStructuredText {
                idc = 212;
                text = "";
                x = "0.2240 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc03: RscStructuredText {
                idc = 213;
                text = "";
                x = "0.3160 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc04: RscStructuredText {
                idc = 214;
                text = "";
                x = "0.4080 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc05: RscStructuredText {
                idc = 215;
                text = "";
                x = "0.5000 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc06: RscStructuredText {
                idc = 216;
                text = "";
                x = "0.5920 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc07: RscStructuredText {
                idc = 217;
                text = "";
                x = "0.6840 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc08: RscStructuredText {
                idc = 218;
                text = "";
                x = "0.7760 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc09: RscStructuredText {
                idc = 219;
                text = "";
                x = "0.8680 * safezoneW + safezoneX"; y = "0.812 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc10: RscStructuredText {
                idc = 220;
                text = "";
                x = "0.0400 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc11: RscStructuredText {
                idc = 221;
                text = "";
                x = "0.1320 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc12: RscStructuredText {
                idc = 222;
                text = "";
                x = "0.2240 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc13: RscStructuredText {
                idc = 223;
                text = "";
                x = "0.3160 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc14: RscStructuredText {
                idc = 224;
                text = "";
                x = "0.4080 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc15: RscStructuredText {
                idc = 225;
                text = "";
                x = "0.5000 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc16: RscStructuredText {
                idc = 226;
                text = "";
                x = "0.5920 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc17: RscStructuredText {
                idc = 227;
                text = "";
                x = "0.6840 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc18: RscStructuredText {
                idc = 228;
                text = "";
                x = "0.7760 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc19: RscStructuredText {
                idc = 229;
                text = "";
                x = "0.8680 * safezoneW + safezoneX"; y = "0.838 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc20: RscStructuredText {
                idc = 230;
                text = "";
                x = "0.0400 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc21: RscStructuredText {
                idc = 231;
                text = "";
                x = "0.1320 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc22: RscStructuredText {
                idc = 232;
                text = "";
                x = "0.2240 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc23: RscStructuredText {
                idc = 233;
                text = "";
                x = "0.3160 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc24: RscStructuredText {
                idc = 234;
                text = "";
                x = "0.4080 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc25: RscStructuredText {
                idc = 235;
                text = "";
                x = "0.5000 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc26: RscStructuredText {
                idc = 236;
                text = "";
                x = "0.5920 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc27: RscStructuredText {
                idc = 237;
                text = "";
                x = "0.6840 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc28: RscStructuredText {
                idc = 238;
                text = "";
                x = "0.7760 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            class Doc29: RscStructuredText {
                idc = 239;
                text = "";
                x = "0.8680 * safezoneW + safezoneX"; y = "0.864 * safezoneH + safezoneY";
                w = "0.092 * safezoneW"; h = "0.024 * safezoneH";
            };
            // The line under the grid starts where the grid does.
            class DocLine: RscStructuredText {
                idc = PAC_IDC_BS_DOCLINE;
                text = "";
                x = "0.04 * safezoneW + safezoneX"; y = "0.892 * safezoneH + safezoneY";
                w = "0.92 * safezoneW"; h = "0.050 * safezoneH";
            };
        };
    };
};
