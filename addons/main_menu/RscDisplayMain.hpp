class RscActivePictureKeepAspect;
class RscDisplayMain: RscStandardDisplay {
    class ControlsBackground {
        // SIX UNITS, CENTRED ON THE BUTTON ROW. It was ten wide and ten tall
        // with its x built from a five-unit half-width, so it was neither
        // centred nor small enough - it ran up behind the game's own menu bar
        // and sat off to one side of the servers underneath it. The width
        // halves the same number it is drawn with, and the height is measured
        // UP from the button row (0.37) so the two always read as one block
        // whatever the screen.
        // THE CREST IS THE HOLIDAY'S IN ITS WINDOW (user, 2026-10-31: "and
        // the menu page"): XEH_mainDisplay swaps this picture for the crest
        // jmfsb_loading's Holidays table names for today; this text is the
        // unit's crest, which stands the rest of the year.
        class GVAR(logo61): RscActivePictureKeepAspect {
            idc = IDC_MAINMENU_LOGO;
            text = QPATHTOEF(media,images\logo_512.paa);
            x = "0.5 - (0.5 * 5) * (pixelW * pixelGridNoUIScale * 2)";
            y = "0.37 - (10) * (pixelH * pixelGridNoUIScale * 2)";
            w = "5 * (pixelW * pixelGridNoUIScale * 2)";
            h = "5 * (pixelH * pixelGridNoUIScale * 2)";
            color[] = {1,1,1,1};
            background = 1;
        };
    };

    // THE QUICK CONNECT ROW. What each button says and where it points are NOT
    // here any more. Name, address, port and password were a text property and
    // an onButtonClick string on each of these, so moving a server was an edit
    // and a PBO, and a unit running its own could not use the menu without
    // forking the mod. All twelve are CBA settings now - four per button - and
    // XEH_mainDisplay fills them in when the display loads: it names the button,
    // sets the click, and hides any whose address is empty or whose port is 0.
    // A build pointed at nothing shows no buttons at all.
    //
    // WHAT IS STILL CONFIG: where they sit and what colour they are. The idc is
    // the join, and it is named for the position rather than the server, because
    // the position is the part a setting cannot move.
    //
    // THE text= LINES ARE A FALLBACK, not the source. They are what the button
    // says if its name setting is empty, and they are also what it says for the
    // one frame before this display's handler runs. The class names below record
    // which server shipped in which slot; they are not what it says now.
    class controls {
        class GVAR(quickConnectToServer_main): RscButton {
            idc = IDC_QUICKCONNECT_CENTRE;
            x = "0.5 - (0.5 * 10) * (pixelW * pixelGridNoUIScale * 2)";
            y = "0.37 - (10 / 2) * (pixelH * pixelGridNoUIScale * 2)";
            // The opening bracket here was missing on all three of these, so the
            // width read as "10 * pixelW * pixelGridNoUIScale * 2)" - unbalanced,
            // and not the expression the x beneath it is built to match.
            w = "10 * (pixelW * pixelGridNoUIScale * 2)";
            h = "1 * (pixelH * pixelGridNoUIScale * 2)";
            text = "JMSB Operations Server";
            tooltip = "Don't forget your beer!";
            // THE UNIT'S COLOURS (user, 2026-10-08: "the server buttons need to
            // match the unit colors"): tan ground, green text, as the website's
            // buttons. The ground is a fallback - the colour settings paint it.
            colorBackground[] = {0.761,0.659,0.471,1};   // #C2A878, the unit's tan
            colorText[] = {0.125,0.149,0.110,1};         // #20261C, the unit's green
            // HOVERED: white text on the unit's ranger green (user, 2026-10-08:
            // "make the hovered text white"). The text swap is done in
            // XEH_mainDisplay - RscButton has no hover text colour of its own.
            colorBackgroundActive[] = {0.227,0.267,0.200,1};   // #3A4433
        };
        class GVAR(quickConnectToServer_train): GVAR(quickConnectToServer_main) {
            idc = IDC_QUICKCONNECT_LEFT;
            x = "0.5 - (1.5 * 10) * (pixelW * pixelGridNoUIScale * 2) - (2 * pixelW)";
            y = "0.37 - (10 / 2) * (pixelH * pixelGridNoUIScale * 2)";
            w = "10 * (pixelW * pixelGridNoUIScale * 2)";
            h = "1 * (pixelH * pixelGridNoUIScale * 2)";
            text = "JMSB Training Server";
            tooltip = "Training Server (may not always be running)";
            colorBackground[] = {0.761,0.659,0.471,1};   // #C2A878, the unit's tan
        };
        class GVAR(quickConnectToServer_events): GVAR(quickConnectToServer_main) {
            idc = IDC_QUICKCONNECT_RIGHT;
            x = "0.5 + (0.5 * 10) * (pixelW * pixelGridNoUIScale * 2) + (2 * pixelW)";
            y = "0.37 - (10 / 2) * (pixelH * pixelGridNoUIScale * 2)";
            w = "10 * (pixelW * pixelGridNoUIScale * 2)";
            h = "1 * (pixelH * pixelGridNoUIScale * 2)";
            text = "JMSB Events Server";
            tooltip = "Unicorns!";
            colorBackground[] = {0.761,0.659,0.471,1};   // #C2A878, the unit's tan
        };
    };
};
