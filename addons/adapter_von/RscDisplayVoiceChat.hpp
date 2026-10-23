// THE GAME'S TALKING POPUP, OURS (user, 2026-10-21: "when we use the game voip
// there is a pop up for talking, can we overwrite that pop up"). Vanilla's
// RscDisplayVoiceChat is a microphone square in the bottom left while the
// player transmits; under game voice FUNC(voiceChatLoad) hides it and shows
// this chip in its place - a red dot, TX and the net he is keying ("TX GHOST 1",
// "TX GLOBAL"). Under TFAR / ACRE (voice stood down) the vanilla one stays.
class RscStructuredText;

class RscDisplayVoiceChat {
    onLoad = QUOTE(call FUNC(voiceChatLoad));
    class controls {
        class GVAR(tx): RscStructuredText {
            idc = IDC_VOICECHAT_TX;
            x = "SafeZoneX";
            y = "(SafeZoneH + SafeZoneY) - 0.04";
            w = 0.24;
            h = 0.04;
            colorBackground[] = VOICECHAT_BG;
            size = 0.032;
            text = "";
            class Attributes {
                font = "RobotoCondensedBold";
                color = "#FFFFFF";
                align = "left";
                valign = "middle";
                shadow = 0;
            };
        };
    };
};
