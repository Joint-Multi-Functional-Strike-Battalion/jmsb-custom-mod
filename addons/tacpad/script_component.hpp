#define COMPONENT tacpad
#define COMPONENT_BEAUTIFIED Tacpad
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// The DIK code that closes an open app (FUNC(appExits)).
#define KEY_ESCAPE 1

// THE READER AS THE OPEN APP. In tablet mode the reader draws inside the device
// dialog and is adopted as the open app under this id (FUNC(openReader),
// FUNC(appHost)); it is not a registered app, so no tile or soft key reaches
// it except through FUNC(openReader).
#define READER_APP "reader"

// THE REPORT CARD (FUNC(composeCard), FUNC(composeCardHead), FUNC(composePicker)),
// docs/PLAN_MESSAGING_UI.md phase 2. Sizes are text sizes for FUNC(drawText);
// widths are fractions of the card column.
#define CARD_TAG_SIZE TEXT_LABEL
#define CARD_TITLE_SIZE TEXT_TITLE
#define CARD_BADGE_SIZE TEXT_LABEL
#define CARD_META_SIZE TEXT_LABEL
#define CARD_CELL_SIZE TEXT_LABEL
// One attached grid cell (CUR LOC, MARKER) as a fraction of the column.
#define CARD_CELL_W 0.19
// The header tag box never takes more of the card than this.
#define CARD_TAG_MAX_W 0.3
// The field meta (REQ, range, AUTO, MARKER) never takes more of its box than this.
#define CARD_META_MAX_W 0.5
// A bold glyph's width against its line height, for sizing a box to its word.
#define CARD_GLYPH_W 0.55
// The template priority that paints the header tag in the accent.
#define CARD_PRIORITY_HIGH "high"
// A line whose title or label names one of these is never where the sender
// stands, so its grid carries MARKER only - no CUR LOC.
#define CARD_NO_CUR_WORDS ["INGRESS", "EGRESS"]

// THE READER (FUNC(readerDraw) and the functions it calls), docs/PLAN_MESSAGING_UI.md
// phase 3, handoff 1a. Pane widths are fractions of the reader's own width, taken
// off the 1280 px canvas (206 / 346 / the rest); sizes are text sizes for
// FUNC(drawText); _PX values are real screen pixels, like the rules.
#define READER_RAIL_W 0.161
#define READER_LIST_W 0.27
// Block insets, in PAD steps: the design's 12-18 px.
#define READER_INSET 3
#define READER_K_SIZE TEXT_LABEL
#define READER_BRAND_SIZE TEXT_TITLE
#define READER_NET_SIZE TEXT_BODY
#define READER_ROSTER_SIZE TEXT_BODY
#define READER_SUBJECT_SIZE TEXT_TITLE
#define READER_PREVIEW_SIZE TEXT_BODY
#define READER_TITLE_SIZE TEXT_TITLE
#define READER_AUTHOR_SIZE TEXT_BODY
#define READER_BODY_SIZE TEXT_BODY
#define READER_TILE_SIZE TEXT_BODY
#define READER_BTN_SIZE TEXT_BODY
// The roster's online square and the selected row's left bar.
#define READER_MARK_PX 7
#define READER_BAR_PX 4
// The priority chip, sized to its tracked word: glyph advance against the line
// height, and the padding either side.
#define READER_CHIP_GLYPH 0.46
#define READER_CHIP_PAD_PX 12
// How much of a preview line a list row or the banner carries.
#define READER_PREVIEW_CHARS 72
// The quick-reply row: six tiles, the last one VOICE MSG.
#define READER_TILES 6
// A tile is this many button heights tall (the design's 44 px).
#define READER_TILE_H 1.3
// The template card splits into two columns only when it has at least this many
// lines and no answer longer than this - an OPORD paragraph stays one column.
#define READER_CARD_SPLIT_MIN 4
#define READER_CARD_SPLIT_CHARS 40
// The card's line-number and label columns, as fractions of a column.
#define READER_CARD_NUM_W 0.07
#define READER_CARD_LABEL_W 0.3
// The close button and each header button, as a fraction of the detail pane.
#define READER_HEAD_BTN_W 0.13
// The FLASH banner: its width as a fraction of the view it covers, and the snooze.
#define READER_FLASH_W 0.62
#define READER_FLASH_SNOOZE 60
// Enter on the main keyboard and on the keypad, which apply the filter.
#define READER_KEY_ENTER 28
#define READER_KEY_NUM_ENTER 156

// AN APP ON A DEVICE TAKES THE WHOLE MAP AREA (user, 2026-10-21: "apps should
// be more full screen"). The device's own rows - bar, tiles, nets - stay, and
// the app fills everything between them, edge to edge. On the vanilla map the
// app keeps the size it asked for.
#define APP_DEVICE_FILL 1
// The TAC//MSG reader's share of the vanilla map's screen, where it is a dialog.
#define READER_FILL_W 0.97
#define READER_FILL_H 0.90
