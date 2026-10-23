// Geometry: where a frame and its screen land on this monitor.
PREP(layout);

// The dialog's own lifecycle - handing the host to the shell and taking it back.
PREP(onLoad);
PREP(onUnload);

// The frame's keys: F1-F4 to an app, left/right round the apps.
PREP(keyDown);
PREP(keyButtons);
PREP(softKey);
PREP(tabletRadioTab);
PREP(tabletReframe);

// THE TABLET SCREEN: its rows round the map, the tick that keeps them, what
// each row draws, the notification line's click, and the vehicle's ON BOARD rail.
PREP(tabletRows);
PREP(tabletChrome);
PREP(tabletTick);
PREP(tabletBar);
PREP(tabletNotify);
PREP(tabletLog);
PREP(tabletNets);
PREP(tabletTalk);
PREP(tabletStack);
PREP(vehicleName);
PREP(vehicleSeats);
PREP(panelOnBoard);

// VEHICLE STATUS, the vehicle tablet's own app: the reads it is made of, the
// lines it draws, a column of them, the page and its live tile.
PREP(vehicleDamage);
PREP(vehicleFuel);
PREP(vehicleAmmo);
PREP(vehicleRf);
PREP(vehicleLines);
PREP(vehicleColumn);
PREP(appVehicle);
PREP(vehicleTile);

// The way in and out.
PREP(open);
PREP(close);
PREP(toggle);

// THE WALKING VIEW: the phone and side devices as a title layer.
// Which device is assigned, where it lands, and the layer's lifecycle.
PREP(overlayDevice);
PREP(overlayLayout);
PREP(overlayOpen);
PREP(overlayClose);
PREP(overlayPlace);
PREP(overlayRows);
PREP(overlayHidden);
PREP(overlaySetShown);
// The tick that keeps it honest, and what it draws.
PREP(overlayTick);
PREP(overlayDraw);
PREP(overlayDrawRings);
PREP(overlayFollow);
PREP(overlayNets);
PREP(overlayRf);
PREP(overlaySquad);
PREP(overlayTalker);
// The ways in and the player's choices: the key, the edge a side device sits
// on, the six buttons printed on the frame (by keybind - the layer takes no
// mouse), and the rows the tablet's SETTINGS shows for all of it.
PREP(overlayToggle);
PREP(overlaySetEdge);
PREP(overlayButton);
PREP(settingsRows);

// GAME VOICE on the devices: who is talking, the notification line's call
// business, the walking view's voice keys, and the RADIO app on the phone and
// side devices - its toggle, its rows, its keys and its drawing.
PREP(voiceTalkers);
PREP(voiceLine);
PREP(voiceAction);
PREP(radioApp);
PREP(radioRows);
PREP(radioKey);
PREP(radioDraw);

// DRONE CONTROL WITHOUT A UAV TERMINAL: who may fly which drone, who holds
// one, the link and the seat, and the tick that lets go of them.
PREP(uavCan);
PREP(uavOperator);
PREP(uavControl);
PREP(uavTick);
// Its orders (GO TO / ORBIT / RTB / LASE), run where the drone is local, the
// designator it carries and the home RTB flies to.
PREP(uavOrder);
PREP(uavLaser);
PREP(uavHome);
PREP(overlayGrid);
PREP(netOutline);
PREP(netSelect);
PREP(channelText);
PREP(deviceFacts);
PREP(overlayStatus);
PREP(overlayProviders);
