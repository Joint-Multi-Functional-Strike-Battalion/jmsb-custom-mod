// TAC//PAC - control ids.
//
// ONE DIALOG (ui/pac.inc.hpp, 2026-09-09). The website is one page shell with
// a bar across the top and the page drawn under it, and the game is the same:
// one display, one set of controls, and every page redraws them. So there is
// one id space here and no per-screen blocks - the three dialogs this replaced
// (the personnel panel, EDIT STRUCTURE, MANAGE) each had their own.

// ---- the shell ------------------------------------------------------------
#define PAC_IDC_BACKGROUND      1
#define PAC_IDC_BAR_BG          2
#define PAC_IDC_BAR_LINE        3
#define PAC_IDC_BRAND           4
#define PAC_IDC_UNIT            5
#define PAC_IDC_WHO             6
#define PAC_IDC_CLOSE           7

// THE SHELL GROUP every control above and below is a child of - ui/pac.inc.hpp,
// GVAR(shell). In the dialog it is the whole screen; inside the tablet it is
// ctrlCreate'd onto the device dialog at the tablet's map area (FUNC(uiHost)).
// Every control is found through it (FUNC(uiCtrl)), never through the display.
#define PAC_IDC_SHELL           8

// The nav bar - the website's, in its order. Ten slots; the pages a mission
// without the service cannot serve are hidden and the rest close up.
#define PAC_IDC_NAV1            10
#define PAC_IDC_NAV2            11
#define PAC_IDC_NAV3            12
#define PAC_IDC_NAV4            13
#define PAC_IDC_NAV5            14
#define PAC_IDC_NAV6            15
#define PAC_IDC_NAV7            16
#define PAC_IDC_NAV8            17
#define PAC_IDC_NAV9            18
#define PAC_IDC_NAV10           19
#define PAC_IDC_NAV_UL          20      // the accent underline under the page you are on

#define PAC_IDC_CRUMB           21
#define PAC_IDC_PAGE_TITLE      22
#define PAC_IDC_HINT            23
#define PAC_IDC_FILTER          24
#define PAC_IDC_FILTER_LABEL    25

// Sub-tabs - the website's .vbar of links under a page title (ORBAT's
// platoons / squads / roles..., a config's versions).
#define PAC_IDC_SUB1            30
#define PAC_IDC_SUB2            31
#define PAC_IDC_SUB3            32
#define PAC_IDC_SUB4            33
#define PAC_IDC_SUB5            34
#define PAC_IDC_SUB6            35
#define PAC_IDC_SUB7            36
#define PAC_IDC_SUB8            37

// The dashboard's tiles: a panel, an accent hairline along its top, the number
// and its label.
#define PAC_IDC_TILE_BG1        40
#define PAC_IDC_TILE_BG2        41
#define PAC_IDC_TILE_BG3        42
#define PAC_IDC_TILE_BG4        43
#define PAC_IDC_TILE_LINE1      44
#define PAC_IDC_TILE_LINE2      45
#define PAC_IDC_TILE_LINE3      46
#define PAC_IDC_TILE_LINE4      47
#define PAC_IDC_TILE_TXT1       48
#define PAC_IDC_TILE_TXT2       49
#define PAC_IDC_TILE_TXT3       50
// 58, not 51: inside the tablet these controls live on the device dialog,
// whose map is idc 51 - and a second 51 there is a displayCtrl coin toss for
// everything that looks the map up.
#define PAC_IDC_TILE_TXT4       58
#define PAC_IDC_TILE_BG5        52
#define PAC_IDC_TILE_BG6        53
#define PAC_IDC_TILE_LINE5      54
#define PAC_IDC_TILE_LINE6      55
#define PAC_IDC_TILE_TXT5       56
#define PAC_IDC_TILE_TXT6       57

// The form: sixteen rows of label / edit / combo. A page shows the rows it
// needs and hides the rest; the edit is multi-line capable, so a row that
// holds prose is simply given more height.
#define PAC_IDC_FORM_BASE       60
#define PAC_IDC_FORM_ROWS       16
#define PAC_IDC_FORM_LABEL(n)   (PAC_IDC_FORM_BASE + 3 * (n))
#define PAC_IDC_FORM_EDIT(n)    (PAC_IDC_FORM_BASE + 3 * (n) + 1)
#define PAC_IDC_FORM_COMBO(n)   (PAC_IDC_FORM_BASE + 3 * (n) + 2)
// 60 .. 107 are the form rows

// The actions row along the foot: BACK, then up to six page buttons.
#define PAC_IDC_BACK            110
#define PAC_IDC_BTN1            111
#define PAC_IDC_BTN2            112
#define PAC_IDC_BTN3            113
#define PAC_IDC_BTN4            114
#define PAC_IDC_BTN5            115
#define PAC_IDC_BTN6            116

// "Are you sure?" - every delete on the website asks, so every delete here
// asks, in the same words, in a box over the page.
#define PAC_IDC_CONFIRM_DIM     120
#define PAC_IDC_CONFIRM_BOX     121
#define PAC_IDC_CONFIRM_TEXT    122
#define PAC_IDC_CONFIRM_YES     123
#define PAC_IDC_CONFIRM_NO      124

// The tables and the text blocks a page is built from.
#define PAC_IDC_LIST            150
#define PAC_IDC_LIST_HEAD       151
#define PAC_IDC_LIST2           152
#define PAC_IDC_LIST2_HEAD      153
#define PAC_IDC_LIST3           154
#define PAC_IDC_LIST3_HEAD      155
#define PAC_IDC_TEXT            156
#define PAC_IDC_TEXT_HEAD       157
#define PAC_IDC_BIGEDIT         158
#define PAC_IDC_BIGEDIT_HEAD    159

// The boot screen (ui/bootscreen.hpp) - RscTitles, its own idc space
#define PAC_IDC_BS_LOGO         200
#define PAC_IDC_BS_TITLE        201
#define PAC_IDC_BS_BAR          202
#define PAC_IDC_BS_STEP         203
#define PAC_IDC_BS_DOC0         210     // 210-239: the 3 x 10 document grid
#define PAC_IDC_BS_DOCLINE      240

// ---- the layout grid ------------------------------------------------------
// Safezone fractions. The content column is what a page draws in; the bar,
// the title and the sub-tab row are above it, the flash line and the actions
// row below.
#define PAC_UI_X        0.012
#define PAC_UI_W        0.976
#define PAC_UI_TOP      0.186
#define PAC_UI_BOTTOM   0.900
#define PAC_UI_ROW      0.032
#define PAC_UI_GAP      0.006
#define PAC_UI_LABEL_W  0.170
