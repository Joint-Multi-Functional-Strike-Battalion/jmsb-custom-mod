#include "script_component.hpp"

if (is3DEN) exitWith {};

[player] call FUNC(enableSafety);

// The grenade-bind warner is safe_grenades' job now - this addon shipped a
// byte-identical copy with its OWN don't-ask-again flag, so players got two
// stacked modals and dismissing one forever still left the other.
