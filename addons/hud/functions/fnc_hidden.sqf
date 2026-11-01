#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the HUD should be off the screen right now.
 *
 * ONE PREDICATE, ASKED FROM THREE PLACES - the per-frame show/hide, the draw
 * tick and FUNC(draw) itself. It used to be two copies of the map test, one in
 * a mission event handler and one in the tick, and copies of a rule are how a
 * HUD ends up hidden but still redrawing.
 *
 * ANY DIALOG, NOT A LIST OF THEM. The admin console is a full-screen dialog and
 * the HUD sat on top of it - the SCANNER slot printed over the panel's own
 * UTILITIES and ADMIN ACTIONS rows. It was not a z-order accident that could be
 * fixed once: FUNC(draw) deleted and recreated the contents of both slots every
 * second then (it rebuilds only on a change now - FUNC(paint)), and each
 * rebuild put fresh controls back above the dialog. Hooking the
 * console's onLoad would have fixed the console and left the other nine
 * screens - the tablet, the reader, the group menu, the teleport and support
 * dialogs, the view-distance menu - to be found one screenshot at a time.
 *
 * `dialog` is the engine's own answer to "is the player in a screen", so a
 * jmfsb dialog written next year is covered by this the day it is written.
 *
 * A HUD IS FOR A MAN LOOKING AT THE WORLD. With a screen open he is not looking
 * at the world, and whatever the screen is telling him it is telling him in more
 * detail than a three-row tile can - which is the same reason the map already
 * took the HUD down.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The HUD should be hidden <BOOL>
 *
 * Public: No
 */

if (GVAR(hideOnMap) && {visibleMap}) exitWith {true};

dialog
