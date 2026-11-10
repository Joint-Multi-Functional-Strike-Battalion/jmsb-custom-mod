# TAC//MSG message templates

2026-11-09 · YonV

Companion files: [DESIGN_MESSAGE_TREES.html](DESIGN_MESSAGE_TREES.html) (the flows) and [DESIGN_MESSAGE_TEMPLATE_FORMS.html](DESIGN_MESSAGE_TEMPLATE_FORMS.html) (each template drawn, standard next to short).

## Rules

A template is the form; a card is what a filled template makes in the thread. Every template is one of four classes, every asset has one thread, and every starter has a short and a standard form. The flows are drawn in [DESIGN_MESSAGE_TREES.html](DESIGN_MESSAGE_TREES.html).

| Class | What it is |
| --- | --- |
| Starter | Full template. Opens a thread. Filed in an open thread, it becomes the next tasking. |
| Follow-up | Has fields. Only inside a thread. |
| Command | No fields, one press. |
| Asset says | The asset's side, AI or player pilot. Never in the requester's menu. |

**Threads**

1. One thread per asset, from first call to RTB. Each starter filed in it is the next tasking.
2. FRAGO, STATUS, HOLD, ABORT, RTB and MESSAGE are available in every asset thread while it is open.
3. A support starter filed inside a TIC, SALUTE or MIST thread pulls the asset into that thread, grid prefilled.
4. Today the server refuses a starter in an open thread unless the support core takes it. That rule has to open up.

**Standard and short form**

1. One template, two views. Same id and same field keys, so the asset reads either.
2. Short is only what the asset cannot act without, plus the map pick.
3. Standard is the doctrinal form in the pub's line order. Lines the game knows are filled in: wind, heading, distance, elevation, friendlies.
4. A STD / SHORT switch on the composer. The default is a player setting.
5. The thread shows only filled lines, so both read the same.

## Starters

Short is what you must fill. Standard adds the rest. "Auto" lines are filled by the game.

**Air**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| CAS REQUEST | Target, description, danger close | In 9-line order: type of control, IP, heading (auto), distance (auto), elevation (auto), mark and code, friendlies (auto), egress, restrictions, TOT, munitions | JP 3-09.3 Fig V-11 |
| AIRFRAME CHECK-IN | Call sign, time on station | Number and type, position and altitude, ordnance, abort code, capabilities, laser code | JP 3-09.3 Fig V-10 |
| REQUEST ON STATION | Area marker | Minutes, remarks | mod |

**Transport**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| PICKUP | Pickup point (empty = you) | Pax, mark, land heading, wind (auto), obstacles | FM 3-21.38 ch. 3 |
| INSERTION (HLZ) | LZ, LAND / FAST ROPE / RAPPEL | Route, security, mark, land heading, pax, egress, wind (auto), obstacles | FM 3-21.38 ch. 3 |
| EXTRACTION (HLZ) | HLZ, security | Station, mark, pax, egress, wind (auto), obstacles | FM 3-21.38 ch. 3 |
| PARADROP | DZ | Load, mark, ingress, egress | mod |
| JUMP REQUEST | Type, red light, green light | Passes, exit, pickup | mod |

**Medical**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| CASEVAC | Pickup, patients by precedence, security | Special equipment (none / hoist / extraction / ventilator), litter and ambulatory, marking method, nationality, line 9 | ATP 4-02.2 Table C-1 |
| MIST | One form, as today | | mod |

CASEVAC changes that come with the 9-line: security is N / P / E / X, precedence adds URGENT-SURG, and the mark colour comes off the request. The crew calls the colour and you verify it.

**Fires**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| CALL FOR FIRE, GRID | Target grid, description, mission type | Shape, shell and rounds, method of fire, fire control, TOT, guns, danger close | not checked |
| CALL FOR FIRE, POLAR | Direction, distance, description, mission type | Same as GRID | not checked |
| CALL FOR FIRE, SHIFT | Known point, shift, description, mission type | Same as GRID | not checked |

Danger close stays at 600 m (ATP 3-09.23, 5-53).

**Logistics and QRF**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| RESUPPLY REQUEST | Item 1, delivery point | More items, counts, method, marking | mod |
| REACT / QRF LINK-UP | Link-up, action on arrival | Recognition signals, route, attachments, who links | mod |

**Reports**

| Template | Short | Standard adds | Source |
| --- | --- | --- | --- |
| TIC | Location, one press | Enemy, casualties, intentions, assistance | mod |
| SALUTE | One form, as today | | mod |
| SITREP | Location, four states (auto) | Enemy, friendly, civilian, counts | mod |
| DEFREP | One press, filled from the vehicle | Equipment, remarks, routing | mod |
| UXO / IED 9-LINE | Lines 2, 4, 9 | The other six | mod |
| MESSAGE | Text | | mod |

## Tasking templates, line by line

Each template side by side: what the mod has today, the standard form, and the short form. Where a pub defines the form, its line is the first column. An empty Short cell means the line is not in the short form. "Auto" is filled by the game. `*` marks a required line: the template will not send without it.

The templates drawn as forms, standard next to short, are in [DESIGN_MESSAGE_TEMPLATE_FORMS.html](DESIGN_MESSAGE_TEMPLATE_FORMS.html).

### PICKUP

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Pickup point | Grid or marker; empty = your position | Same | Same |
| Pax / load | Text | Same | |
| Marking | Method pick, plus colour text | Method pick only; the crew calls the colour | |
| Land heading | None | Degrees | |
| Wind | Auto | Same | |
| Obstacles | Text | Same | |
| Remarks | Text | Same | |

### INSERTION (HLZ)

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Route to the LZ | "Line 6": points in order; empty = direct | Same | |
| Drop-off LZ * | "Line 1": grid or marker, required | Same | Same |
| Insertion | LAND / FAST ROPE / RAPPEL | Same | Same |
| Security | "Line 4": GREEN / YELLOW / RED | Same | |
| Marking | "Line 5": method pick, plus colour text | Method pick only | |
| Land heading | None | Degrees | |
| Pax / load | "Line 3": text | Same | |
| Egress | "Line 7": points in order; empty = home direct | Same | |
| Wind | Auto | Same | |
| Obstacles | Text | Same | |
| Remarks | Text | Same | |

### EXTRACTION (HLZ)

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Station | Marker only; empty = 1 km short of the HLZ | Same | |
| Pickup HLZ * | Grid or marker, required | Same | Same |
| Security | GREEN / YELLOW / RED | Same | Same |
| Marking | Method pick, plus colour text | Method pick only | |
| Passengers | Number | Same | |
| Egress | Points in order; empty = direct | Same | |
| Wind | Auto | Same | |
| Obstacles | Text | Same | |
| Remarks | Text | Same | |

### MOVE (new)

Today's column is the DESTINATION reply it replaces.

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Point * | Destination grid | Grid or marker | Same |
| On arrival * | None | LOITER / LAND / HOVER / HOLD | Same |
| Route | None | Points in order; empty = direct | |
| Altitude | None | Metres | |
| Time | None | Minutes to stay; empty = until told | |
| Remarks | None | Text | |

### PARADROP

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Drop zone * | "Line 1": grid or marker, required | Same | Same |
| Load | Who or what jumps | Same | |
| Marking | Method pick, plus colour or code | Method pick only | |
| Ingress | "Line 6": grid or marker | Same | |
| Egress | "Line 7": grid or marker | Same | |
| Remarks | Text | Same | |

### JUMP REQUEST

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Type * | HALO / HAHO / STATIC, required | Same | Same |
| Passes | Number; empty = mission default | Same | |
| Exit | AUTO / MANUAL | Same | |
| Red light * | Grid or marker, required | Same | Same |
| Green light * | Grid or marker, required | Same | Same |
| Pickup | Grid or marker; empty = your position | Same | |
| Remarks | Text | Same | |

### CASEVAC

| Line | ATP 4-02.2 9-line | Today (6-line) | Standard | Short |
| --- | --- | --- | --- | --- |
| 1 * | Location of pickup site | "Line 1": grid or marker, required | Grid or marker | Same |
| 2 | Radio frequency, call sign | None | Auto, from the sender | |
| 3 | Patients by precedence: urgent, urgent-surg, priority, routine, convenience | "Line 3": urgent, priority, routine counts. "Line 2": total | Counts: A urgent, B urgent-surg, C priority, D routine | Same |
| 4 | Special equipment: none, hoist, extraction equipment, ventilator | None | Pick | |
| 5 | Patients by type: litter, ambulatory | None | Two counts | |
| 6 | Security: N, P, E, X | "Line 4": GREEN / YELLOW / RED | N / P / E / X | Same |
| 7 | Marking: panels, pyro, smoke, none, other. Colour is not sent | "Line 5": method pick, plus colour text | Method pick only | |
| 8 | Patient nationality and status | None | Pick | |
| 9 | CBRN contamination, or terrain description | None | Text | |
| Remarks | Not a line. MIST follows the request | MIST, anything the crew must know | Text | |

Line 6 security: N = no enemy troops in the area. P = possible enemy troops, approach with caution. E = enemy troops in the area, approach with caution. X = enemy troops in the area, armed escort required.

### CAS REQUEST

| Line | JP 3-09.3 9-line | Today | Standard | Short |
| --- | --- | --- | --- | --- |
| Control | Type 1, 2 or 3, stated before the brief | None | Pick | |
| 1 | IP / BP | "Line 3": ingress location | Grid or marker | |
| 2 | Heading, offset | None | Auto, IP to target | |
| 3 | Distance | None | Auto, IP to target | |
| 4 | Target elevation | None | Auto | |
| 5 * | Target description | "Line 5": text, required | Text | Same |
| 6 * | Target location | "Line 1": grid or marker, required | Grid or marker | Same |
| 7 | Type mark, code | "Line 7": mark pick, colour or laser code | Same | |
| 8 | Location of friendlies, marked by | "Line 6": range, optional and measured; danger close tick | Auto direction and distance; danger close tick | Danger close tick |
| 9 | Egress | "Line 4": egress location | Direction or marker | |
| Remarks | Restrictions, laser-to-target line | Remarks; munitions as its own optional line | Restrictions, final attack heading, munitions | |
| TOT | Time on target, or time to target | None | Time, or +minutes | |

### AIRFRAME CHECK-IN

Not a tasking, but it opens the CAS thread and a pub defines it.

| Line | JP 3-09.3 check-in | Today | Standard | Short |
| --- | --- | --- | --- | --- |
| 1 | Identification, mission number | Call sign, auto | Same | Same |
| 2 | Number and type of aircraft | Text | Same | |
| 3 | Position and altitude | Grid, altitude | Same | |
| 4 | Ordnance | Text | Same | |
| 5 | Time on station | Minutes | Same | Same |
| 6 | Abort code | Text | Same | |
| Extra | Not in the pub | Capabilities (FMV, laser, IR, NVG), laser code, remarks | Same | |

### REQUEST ON STATION

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Time on station | "Line 1": minutes; empty = what the aircraft has | Same | |
| Area * | "Line 2": map marker only, required | Same | Same |
| Remarks | Threats, what it is wanted for | Same | |

### CALL FOR FIRE (GRID / POLAR / SHIFT)

Three templates that differ only in the target line. No pub column: the call-for-fire format is not in the pubs read.

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Target * | GRID: grid or marker. POLAR: direction and distance. SHIFT: known point, left / right, add / drop | Same | Same |
| Type of mission * | "Warno 1": adjust fire / fire for effect / suppress / immediate suppression | Same | Same |
| Target description | Text | Same | Same |
| Target shape | Point / area / linear / creeping, size | Same | |
| Far end or attitude | Grid, or degrees | Same | |
| Method of engagement | Shell pick, rounds per gun | Same | |
| Danger close | Tick; distance optional and measured | Same | |
| Method of fire | Interval, volleys, or continuous minutes | Same | |
| Fire control | When ready / at my command / time on target / cannot observe | Same | |
| TOT | Time, or +minutes | Same | |
| Observer | Call sign, auto; grid on POLAR | Same | |
| Guns | "Warno 2": number; empty = all | Same | |
| Remarks | Text | Same | |

### RESUPPLY REQUEST

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Item 1 * | Pre-made crate pick, required; count | Same | Same |
| More items | Pre-made crate pick, count | Same | |
| Delivery point * | Grid or marker, required | Same | Same |
| Method | AIRDROP / SLING; empty = the asset's first | Same | |
| Marking | Method pick, plus colour | Method pick only | |
| Remarks | Threats, who receives it | Same | |

### REACT / QRF LINK-UP

| Line | Today | Standard | Short |
| --- | --- | --- | --- |
| Link-up location * | "Line 2": grid or marker, required | Same | Same |
| Action on arrival | "Line 5": pick, plus detail | Same | Same |
| Recognition signals | Far, near | Same | |
| Suggested route | "Line 3": text | Same | |
| Special attachments | "Line 4": text | Same | |
| Who links with who | "Line 1": empty = you and the QRF | Same | |
| Remarks | Text | Same | |

### FRAGO (new)

No lines of its own and nothing today to compare. It opens the thread's current tasking template with the last values filled in. You change what changes; the card it makes shows only the changed lines, old value and new. One added line: reason, optional.

## Follow-ups, commands, asset calls

**Follow-ups** (fields, only in a thread)

| Template | Fields | Where |
| --- | --- | --- |
| FRAGO (new) | The current order reopened; change any line. Short and standard follow the order's own template. | Any asset thread. On CAS only before IP INBOUND; after that, ABORT first. |
| MOVE (new) | Short: point, LOITER / LAND / HOVER / HOLD. Standard adds route, altitude, time. | Transport, CAS (new station), QRF. Replaces DESTINATION. |
| ADJUST FIRE | Direction, distance. Capped at 100 m on a danger-close mission. | Fires |
| FIRE FOR EFFECT | Rounds | Fires |
| BDA | Short: result, decision (RE-ATTACK / BACK TO STATION / RTB). Standard adds target, count, remarks. | CAS, fires |
| SITREP | As the starter | TIC, QRF |
| MIST | As the starter | CASEVAC |
| MESSAGE | Text | Any thread |
| CANTCO | Reason | Assignee |
| CLOSE THREAD | Outcome | Issuer |

**Commands** (no fields)

| Group | Commands |
| --- | --- |
| Any asset thread | STATUS (new), HOLD, ABORT, RTB, ROGER |
| Landing | CLEARED TO LAND, CONTINUE APPROACH (new), GO AROUND (new) |
| Lift | ALL IN, EXTRACT, BOARD |
| Drop and jump | EXECUTE (new, replaces CONFIRM), NO DROP (new), GO |
| CAS | CLEARED HOT, CLEARED TO ENGAGE (new, Type 3), CONTINUE (new), ABORT, ALL ATTACK |
| Fires | REPEAT, CHECK FIRE, RECORD AS TARGET |
| Answers, offered only when the asset asks | HOT, COLD, CORRECT, WRONG, NO SMOKE, RECEIVED, NOT FOUND, NO |

ABORT means different things by thread: on a landing, do not complete it (FM 3-21.38 Table 3-3); on a CAS run, abort the pass and do not release (JP 3-09.3 Fig V-13). After either, the asset asks for intentions.

**Asset says**

| Group | Calls |
| --- | --- |
| Any | WILCO, ON TASK, CANTCO, INBOUND, ASSET ASKS, STATUS REPLY (new): position, task, time left on station, fuel, ammo, pax |
| Transport | WHEELS UP, WHEELS DOWN, IN THE HOVER, PAX OFF, STATE INTENTIONS (new) |
| Jump | RED LIGHT, GREEN LIGHT, STICK OUT |
| CAS | READBACK (new): target location and restrictions; IP INBOUND (new), IN, OFF, ATTACK COMPLETE (new, Type 3) |
| Fires | SHOT, SPLASH, ROUNDS COMPLETE (new) |

## Command definitions

Every command in the workflows, with what it tells the asset to do. Source says where the meaning comes from: a pub, the mod's own template, or this design.

**Any asset thread**

| Command | Meaning | Source |
| --- | --- | --- |
| STATUS | Report position, current task, time left on station, fuel, ammo and pax. | Design |
| HOLD | Stop where you are and wait for the next order. | Mod, meaning widened |
| ABORT | Stop what you are doing now. On a landing or lift-off: do not complete it. On a CAS run: abort the pass, do not release. The asset then asks for intentions. | FM 3-21.38 Table 3-3; JP 3-09.3 Fig V-13 |
| RTB | Return to base. Ends the asset's thread when it lands. | Mod |
| ROGER | Received and understood. Commits to nothing. | FM 3-21.38 Table 3-3 |

**Landing**

| Command | Meaning | Source |
| --- | --- | --- |
| CLEARED TO LAND | Land now. | FM 3-21.38 Table 3-2 |
| CONTINUE APPROACH | Keep coming. You are not cleared to land yet. | FM 3-21.38 Table 3-2 |
| GO AROUND | Do not land. Circle and begin another approach. | FM 3-21.38 Table 3-3 |

**Lift**

| Command | Meaning | Source |
| --- | --- | --- |
| ALL IN | Everyone is aboard. Lift off. | Mod |
| EXTRACT | Leave the station and come in to the HLZ now. | Mod |
| BOARD | The stick is boarding the jump aircraft. Take off when loaded. | Mod, title only |

**Drop and jump**

| Command | Meaning | Source |
| --- | --- | --- |
| EXECUTE | Drop personnel or equipment. | FM 3-21.38 Table 3-3 |
| NO DROP | Do not drop. Fly another pass or await orders. | FM 3-21.38 Table 3-3 |
| GO | Jump. Given at the red light to release the stick. | Mod |

**CAS**

| Command | Meaning | Source |
| --- | --- | --- |
| CLEARED HOT | Cleared to release ordnance on this pass. | JP 3-09.3 Fig V-13 |
| CLEARED TO ENGAGE | Type 3 control: attack within the limits given. The aircraft reports ATTACK COMPLETE. | JP 3-09.3 Fig V-13 |
| CONTINUE | Proceed with the attack run. No release yet. | JP 3-09.3 Fig V-13 |
| ALL ATTACK | Every aircraft in the flight attacks. | Mod, title only |

**Fires**

| Command | Meaning | Source |
| --- | --- | --- |
| REPEAT | Fire the same again. After CHECK FIRE, resume. | Mod |
| CHECK FIRE | Stop firing at once. | Mod |
| RECORD AS TARGET | Save this target so it can be called again. | Mod, title only |

**Answers** (offered only when the asset asks)

| Answer | To the question | Meaning |
| --- | --- | --- |
| COLD | LZ status? | No enemy fire at the LZ. |
| HOT | LZ status? | The LZ is under fire. |
| CORRECT | Mark colour, or a CAS readback | What you called is right. |
| WRONG | Mark colour, or a CAS readback | Not mine, or not what I sent. |
| NO SMOKE | Mark? | There is no mark. Land on the grid. |
| RECEIVED | Resupply delivered? | We have it. |
| NOT FOUND | Resupply delivered? | We cannot find it. |
| NO | Any yes / no question | No. |

"Title only" means the meaning is read from the template's title; the code behind it was not read.

## Changes from today's templates

| Change | Templates |
| --- | --- |
| New | FRAGO, MOVE, STATUS, STATUS REPLY, GO AROUND, CONTINUE APPROACH, CONTINUE, CLEARED TO ENGAGE, ATTACK COMPLETE, EXECUTE, NO DROP, READBACK, IP INBOUND, STATE INTENTIONS, ROUNDS COMPLETE |
| Retired | DESTINATION (into MOVE), CONFIRM (into EXECUTE) |
| Changed | BDA decision has three picks. CASEVAC goes to the 9-line: security N / P / E / X, URGENT-SURG, special equipment, no colour on the request. CAS REQUEST goes to true 9-line order and gains type of control, restrictions, TOT. PICKUP, INSERTION and EXTRACTION gain land heading. Marking colour comes off PICKUP, INSERTION, EXTRACTION, PARADROP and RESUPPLY; the crew calls the colour and you verify it. |
| Engine | A starter may be filed in an open thread. Each template carries a short-form field list. The composer gets the STD / SHORT switch and a default setting. |
| Unchanged | SALUTE, MIST, MESSAGE, QRF, JUMP REQUEST, the three CALL FOR FIRE templates (fields; they only gain a short view) |

## Decisions

Settled on 2026-11-09.

1. **CASEVAC.** The 9-line is the standard form and three lines are the short form. This replaces the 6-line from Nov 2.
2. **SALUTE and MIST.** One form each, unshortened.
3. **CAS REQUEST.** True 9-line order. The field keys are renamed, and the support core's key list changes with them.
4. **Reports as hosts.** A CAS, fires or CASEVAC request filed in a TIC, SALUTE or MIST thread stays in that thread.
5. **ALL ATTACK.** Kept as a game command. It is not in JP 3-09.3.
6. **Type of control.** A 1 / 2 / 3 pick on CAS REQUEST. Type 3 uses CLEARED TO ENGAGE, and the aircraft reports ATTACK COMPLETE.
7. **CHECK FIRE.** REPEAT resumes.
8. **Security.** GREEN / YELLOW / RED on the transport templates, N / P / E / X on CASEVAC.
9. **MOVE.** Route, altitude and time are standard-form lines.

**Not checked**

- Fires wording (ADJUST, REPEAT, CHECK FIRE, END OF MISSION) and the call-for-fire lines. ATP 3-09.23 is the battalion's side and does not carry them; the observer's pub is ATP 3-09.30.
- The PAC templates (OPORD, METT-TC) were not read.
- Which calls are asset-only is my read of the reply templates. IN, OFF and PAX OFF are the least certain.

**Sources**

- FM 3-21.38, Pathfinder Operations, 2006: ch. 3, Tables 3-2 and 3-3, paras 3-7, 3-26, 3-27, 3-60.
- JP 3-09.3, Close Air Support, 2003: ch. V, Figs V-10, V-11, V-13, V-14.
- ATP 4-02.2, Medical Evacuation, 2019: Table 2-1, Appendix C.
- ATP 3-09.23, Field Artillery Battalion Operations, 2026: paras 5-1, 5-52 to 5-53.
- Mod: `addons/messaging` and `addons/support` built-in templates, as read on 2026-11-09.
