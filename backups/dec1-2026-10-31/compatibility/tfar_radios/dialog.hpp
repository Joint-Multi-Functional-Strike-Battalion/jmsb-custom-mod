// THE MPU5's OPEN-RADIO SCREEN under TFAR (restored from the 1268 build). What
// TFAR shows when the player opens the radio: the set and its PTT unit as a
// picture, and on the PTT unit's two knobs the only two things the user wanted
// on it - the left knob changes channel, the right one volume (user,
// 2026-10-18: "only add a volume control and the other knob a channel
// changer"). No frequency entry, no keypad: frequencies are the set's business
// (docs/SPEC_TACNET.json, D2).
//
// IT IS TFAR's OWN MECHANISM, on our picture. tf_dialog on the item names
// this class; TFAR createDialogs it with TF_sw_dialog_radio set to the radio,
// and its functions do the rest: setChannelViaDialog / setVolumeViaDialog take
// the mouse button (0 left = down, 1 right = up) exactly as its PRC-152
// rotator does, and updateSWDialogToChannel writes the channel into whatever
// control carries idc 1604 - so the readout is that control, on the radio's
// black slab where a display would be. The background carries TFAR's own
// background idc, which its night-texture swap looks for.
//
// THE PICTURE IS A 1024 SQUARE (jmfsb_radios' data\mpu5_dialog_ca.paa,
// tools/gen_radios.py) and every rectangle below is in ITS pixels, converted
// here: the dialog is drawn at most of the screen height and square on screen -
// a UI x unit is three quarters of a y unit - so the pixels map straight. Knob
// centres were measured off the generated canvas: channel 516,388, volume
// 578,385.

#define IDD_MPU5_RADIO_DIALOG 8990
// TFAR's: TF_IDD_BACKGROUND and SW_CHANNEL in tfar_core's defines.hpp.
#define IDC_MPU5_BACKGROUND 67676
#define IDC_MPU5_CHANNEL 1604

#define MPU5_DLG_H (0.92 * safezoneH)
#define MPU5_DLG_W (MPU5_DLG_H * 0.75)
#define MPU5_DLG_X (safezoneX + (safezoneW - MPU5_DLG_W) / 2)
#define MPU5_DLG_Y (safezoneY + (safezoneH - MPU5_DLG_H) / 2)
// A rectangle in canvas pixels: left, top, width, height.
#define MPU5_AT(px,py,pw,ph) \
    x = QUOTE(MPU5_DLG_X + (px / 1024) * MPU5_DLG_W); \
    y = QUOTE(MPU5_DLG_Y + (py / 1024) * MPU5_DLG_H); \
    w = QUOTE((pw / 1024) * MPU5_DLG_W); \
    h = QUOTE((ph / 1024) * MPU5_DLG_H)

class RscBackPicture;
class RscEditLCD;
class HiddenRotator;

class jmfsb_mpu5_radio_dialog {
    idd = IDD_MPU5_RADIO_DIALOG;
    movingEnable = 1;
    controlsBackground[] = {};
    objects[] = {};
    onUnload = "['OnRadioOpen', [player, TF_sw_dialog_radio, false, 'jmfsb_mpu5_radio_dialog', false]] call TFAR_fnc_fireEventHandlers;";
    controls[] = {
        "background",
        "channel_edit",
        "channel_knob",
        "volume_knob"
    };

    class background: RscBackPicture {
        idc = IDC_MPU5_BACKGROUND;
        text = QPATHTOEF(radios,data\mpu5_dialog_ca.paa);
        MPU5_AT(0,0,1024,1024);
        moving = 1;
    };

    // The channel, on the radio's black slab. TFAR writes "C3" here, or "A3"
    // when the additional channel is the active one.
    class channel_edit: RscEditLCD {
        idc = IDC_MPU5_CHANNEL;
        MPU5_AT(222,318,70,26);
        moving = 1;
        font = "TFAR_font_dots";
        colorText[] = {0.55, 1, 0.55, 1};
        shadow = 0;
        canModify = 0;
        tooltip = "Channel";
    };

    // The left knob: channel. Left click down, right click up.
    class channel_knob: HiddenRotator {
        idc = -1;
        MPU5_AT(494,366,44,44);
        tooltip = "Channel - left click down, right click up";
        onMouseButtonDown = "[_this select 1, false] call TFAR_fnc_setChannelViaDialog;";
    };

    // The right knob: volume. Left click down, right click up.
    class volume_knob: HiddenRotator {
        idc = -1;
        MPU5_AT(556,363,44,44);
        tooltip = "Volume - left click down, right click up";
        onMouseButtonDown = "[_this select 1, false] call TFAR_fnc_setVolumeViaDialog;";
    };
};
