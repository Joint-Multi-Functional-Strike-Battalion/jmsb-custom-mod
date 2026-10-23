class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Checkbox;
        };
        class ModuleDescription;
    };

    // PLACING THIS MODULE IS THE ENABLE. No module, no jamming - there is no
    // separate on switch to forget, and no system quietly running because a
    // setting defaulted to on in a mission that never asked for one.
    //
    // IT PLACES NOTHING. Every attribute here is true of the whole map: what a
    // radius may roll between, whether a strong set burns through, whether GPS
    // is a domain at all. WHERE a jammer stands is a JMSB - Jammer Site module
    // put down on the spot - which is what the ALiVE version could not do,
    // because it read its positions off a commander's objective list and the
    // mission maker had no say in any of them.
    class jmfsb_moduleJamming: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Jamming";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_installation.paa";

        class Attributes: AttributesBase {
            // A SITE'S REACH IS ROLLED, NOT FIXED (user, 2026-08-31: "radius is
            // too small, they need to be 1000 to 3000 random number"). These are
            // the bounds, and every site takes its own number between them - so
            // two masts of the same kind are not the same problem, and nobody
            // learns one radius and applies it to the whole map.
            //
            // They were Hub Radius 900 and Terminal Radius 300, which is where
            // "too small" came from: a 300 m field is a building's worth of
            // ground and a player walked out of it without noticing.
            class largeRadius: Edit {
                property = QGVAR(largeRadius);
                displayName = "Site Radius Max (m)";
                tooltip = "Upper bound. Every jammer site rolls its own reach between the minimum and this.";
                typeName = "NUMBER";
                defaultValue = "3000";
                expression = QUOTE(_this setVariable [ARR_2('largeRadius',_value)]);
            };
            class smallRadius: Edit {
                property = QGVAR(smallRadius);
                displayName = "Site Radius Min (m)";
                tooltip = "Lower bound. Every jammer site rolls its own reach between this and the maximum.";
                typeName = "NUMBER";
                defaultValue = "1000";
                expression = QUOTE(_this setVariable [ARR_2('smallRadius',_value)]);
            };
            class objectiveShare: Edit {
                property = QGVAR(objectiveShare);
                displayName = "Objectives With Jammers (%)";
                tooltip = "Share of a commander's objectives that get an emitter. This shapes a small map; the cap below is what bounds a big one.";
                typeName = "NUMBER";
                defaultValue = "30";
                expression = QUOTE(_this setVariable [ARR_2('objectiveShare',_value)]);
            };
            class maxPerSide: Edit {
                property = QGVAR(maxPerSide);
                displayName = "Max Jammers Per Side";
                tooltip = "Hard ceiling per commander whatever the share works out to. A percentage has no ceiling - 30% of 173 objectives is 52 emitters, and three commanders put 156 props on the map in one frame.";
                typeName = "NUMBER";
                defaultValue = "8";
                expression = QUOTE(_this setVariable [ARR_2('maxPerSide',_value)]);
            };
            // GPS is the third domain and the odd one out: space-based, so the
            // radius here is the UPLINK's own small field, not the sphere's.
            // The sphere is rolled between 1 km and 2 km in the code, because a
            // mission tuning it to 300 m would just be a fourth mast.
            class gpsEnable: Checkbox {
                property = QGVAR(gpsEnable);
                displayName = "GPS Denial";
                tooltip = "One satellite uplink per commander, at its biggest objective, steering a 1-2 km sphere that wanders the map. Destroy or hack the uplink and GPS comes back for good.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('gpsEnable',_value)]);
            };
            // RADIO BURN-THROUGH, the lever that makes a big set worth carrying
            // and worth thinking about. It was a preInit variable with no way to
            // reach it - off, everywhere, with no attribute and no setting - so
            // the burnthrough branch in FUNC(jamFactor) had never run in a
            // mission. Reachable here, on by default, because jmfsb_reaction now
            // answers a burn-through with a QRF and the pair only makes sense on.
            class burnThrough: Checkbox {
                property = QGVAR(burnThrough);
                displayName = "Radio Burn-Through";
                tooltip = "A high-powered set cuts through a radio jamming field - and the transmission is answered with the full reaction and a QRF on the transmitter. Off: no set beats a jammer, and nobody is punished for trying.";
                defaultValue = 1;
                expression = QUOTE(_this setVariable [ARR_2('burnThrough',_value)]);
            };
            class burnRef: Edit {
                property = QGVAR(burnRef);
                displayName = "Burn-Through Reference (mW)";
                tooltip = "The set power a jamming field is calibrated against. A radio at this power is unaffected by the cut; anything stronger punches through in proportion.";
                typeName = "NUMBER";
                defaultValue = "500";
                expression = QUOTE(_this setVariable [ARR_2('burnRef',_value)]);
            };
            // EVERY SITE AN ALiVE OBJECTIVE - your original spec, off by
            // default because of what it did on 31 August. The uplink is always
            // registered; this is about the 248 masts. Registration itself is
            // cheap now (adapter_alive registerSite dedups through OPCOM's own
            // objectivesByID hashmap rather than walking the list), but each one
            // still ADDS an objective, and on a 31-commander mission that takes
            // OPCOM's world from 132 to ~380 per commander for the whole session.
            // Worth it if you want the masts garrisoned and retaken; not worth
            // it by default.
            class siteObjectives: Checkbox {
                property = QGVAR(siteObjectives);
                displayName = "Masts Are ALiVE Objectives";
                tooltip = "Register every radio and data mast with its commander, so ALiVE garrisons and retakes them. The GPS uplink always is. On a large order of battle this multiplies the objective count OPCOM iterates every tick - see the addon README.";
                defaultValue = 0;
                expression = QUOTE(_this setVariable [ARR_2('siteObjectives',_value)]);
            };
            class gpsUplinkRadius: Edit {
                property = QGVAR(gpsUplinkRadius);
                displayName = "Uplink Radius (m)";
                tooltip = "The uplink's own GPS field - the last leg of the assault on it, not a second sphere.";
                typeName = "NUMBER";
                defaultValue = "400";
                expression = QUOTE(_this setVariable [ARR_2('gpsUplinkRadius',_value)]);
            };
            // THE ZONES ARE RF NOISE (2026-10-19). A radio or data zone adds
            // this much noise at its full-strength core to every receiver on
            // its bands, falling with the zone's own shape; the RF link budget
            // does the rest, so voice and data degrade by SNR like any other
            // interference, and a set's spread gain buys some of it back.
            class rfNoise: Edit {
                property = QGVAR(rfNoise);
                displayName = "Zone Noise at the Core (dBm)";
                tooltip = "Interference a radio or data zone puts into a receiver standing in its full-strength core, before the receiver's spread gain. -40 drowns a handheld anywhere in the core and a vehicle set beyond a few hundred metres; every 10 dB lower roughly triples the distance a link survives.";
                typeName = "NUMBER";
                defaultValue = -40;
                expression = QUOTE(_this setVariable [ARR_2('rfNoise',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Placing this module turns on jamming. Without it, the system is off.",
                "It places no jammers - a JMSB - Jammer Site module does that, one per emitter.",
                "",
                "Site Radius Min / Max (m) - every site rolls its own reach between the two",
                "GPS Denial - one uplink per commander steering a wandering 1-2 km GPS sphere",
                "Uplink Radius (m) - the uplink's own GPS field",
                "Radio Burn-Through - a strong set beats a jammer, and is answered with a QRF",
                "Burn-Through Reference (mW) - the set power the field is calibrated against",
                "Zone Noise at the Core (dBm) - what a radio or data zone adds to the RF link budget",
            };
        };
    };

    // ONE MODULE, ONE EMITTER, WHERE YOU PUT IT. This is the placement the ALiVE
    // version could not offer: sites were spread over a commander's objective
    // list, so the mission maker chose how many and never chose where. Drop this
    // where the mast should stand - in Eden, or in Zeus mid-mission - and a site
    // is built on the spot when it arms.
    //
    // THE SPECTRUM IS THE POINT OF THE SITE. A mast that denies the voice net is
    // a different problem from one that denies the data link, and the terminal
    // model differs per domain so the site says which before you are close
    // enough to read anything. One domain per module: a site that denied
    // everything would make the other two pointless.
    //
    // AN EMITTER IS A TRANSMITTER, AND A TRANSMITTER CAN BE HEARD. Left running
    // where somebody hostile is standing, the site calls artillery - see the
    // reply attributes below and FUNC(artyReply). Off by default, because it
    // changes what a jammer IS: not scenery to be cleared at leisure, but a
    // thing that answers back.
    class jmfsb_moduleJammerSite: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Jammer Site";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleJammerSite));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_installation.paa";

        class Attributes: AttributesBase {
            class domain: Edit {
                property = QGVAR(domain);
                displayName = "Spectrum";
                tooltip = "What this site denies: radio (the voice net), data (TAC//MSG and shared markers), or gps. One only. The terminal model follows the domain, so the site reads as what it is from three hundred metres out.";
                typeName = "STRING";
                defaultValue = "radio";
                expression = QUOTE(_this setVariable [ARR_2('domain',_value)]);
            };
            class radius: Edit {
                property = QGVAR(radius);
                displayName = "Radius (m)";
                tooltip = "The field's outer reach. 0 rolls one between the Jamming module's minimum and maximum, which is what an unattended site should do - two masts of the same kind are not meant to be the same problem.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = QUOTE(_this setVariable [ARR_2('radius',_value)]);
            };

            // ---- the reply ---------------------------------------------------
            class artyReply: Checkbox {
                property = QGVAR(artyReply);
                displayName = "Artillery Reply";
                tooltip = "If a hostile unit stays inside the field for the delay below, the site calls artillery on it. Off: the site is inert and can be worked at leisure.";
                defaultValue = 0;
                expression = QUOTE(_this setVariable [ARR_2('artyReply',_value)]);
            };
            class artyDelay: Edit {
                property = QGVAR(artyDelay);
                displayName = "Reply Delay (s)";
                tooltip = "How long somebody has to stay inside the field before the mission fires. The clock resets the moment no hostile is inside, so a fast approach and a fast exit is the counter.";
                typeName = "NUMBER";
                defaultValue = "90";
                expression = QUOTE(_this setVariable [ARR_2('artyDelay',_value)]);
            };
            class artyRounds: Edit {
                property = QGVAR(artyRounds);
                displayName = "Reply Rounds";
                tooltip = "Shells per mission.";
                typeName = "NUMBER";
                defaultValue = "8";
                expression = QUOTE(_this setVariable [ARR_2('artyRounds',_value)]);
            };
            class artyScatter: Edit {
                property = QGVAR(artyScatter);
                displayName = "Reply Scatter (m)";
                tooltip = "How wide the fall of shot is around the LAST KNOWN position - where the detection was, not where the target is now. Moving is the counter; standing still is not.";
                typeName = "NUMBER";
                defaultValue = "120";
                expression = QUOTE(_this setVariable [ARR_2('artyScatter',_value)]);
            };
            class artyCooldown: Edit {
                property = QGVAR(artyCooldown);
                displayName = "Reply Cooldown (s)";
                tooltip = "Minimum gap between two missions from this site, so a field somebody has to cross is not a continuous barrage.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = QUOTE(_this setVariable [ARR_2('artyCooldown',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "One jammer site, where you place it. Needs the JMSB - Jamming module on the map to arm.",
                "",
                "Spectrum - radio, data or gps. One per site",
                "Radius (m) - 0 rolls one from the Jamming module's bounds",
                "Owner - whoever is hostile to the players, worked out from the mission's side relations",
                "",
                "Artillery Reply - the site shells whoever loiters in its field",
                "Reply Delay (s) - how long a hostile must stay inside before it fires",
                "Reply Rounds / Scatter (m) - the size of the mission and how wide it falls",
                "Reply Cooldown (s) - minimum gap between two missions from this site",
            };
        };
    };
};
