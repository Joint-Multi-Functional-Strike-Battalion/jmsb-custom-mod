# Boarding

`jmfsb_boarding`

A muster point that loads players into transport. Synchronise the OBJECT players press - a sign, a crate, a flagpole - and it carries an ACE action; pressing it moves every player within the module's range into cargo. Synchronise VEHICLES too to say which transport is theirs; with none synced it uses whatever has free cargo near the module. Players already in a vehicle are left alone, and anyone who does not fit is told so rather than being silently left behind.

**Who pressed (review R1).** The action asks the server by `remoteExec` to
`jmfsb_boarding_fnc_board`. The server checks the presser is the sender's own
unit, alive, and within 15 m of one of the point's buttons. It then uses its own
copy of the point's range, transport and options, kept in `localNamespace` when
the module started, not the logic's public variables, which any client can
overwrite.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `ace_interact_menu` _(external)_
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 4 functions.

## Eden modules

### JMSB - Boarding Point

`jmfsb_moduleBoarding`, category jmfsb_modules

A muster point that loads players into transport. Synchronise the OBJECT players press - a sign, a crate, a flagpole - and it carries an ACE action; pressing it moves every player within the module's range into cargo. Synchronise VEHICLES too to say which transport is theirs; with none synced it uses whatever has free cargo near the module. Players already in a vehicle are left alone, and anyone who does not fit is told so rather than being silently left behind.

<details><summary>4 attributes</summary>

- `includePresser`
- `range`
- `sideOnly`
- `title`

</details>

## Functions

<details><summary>4</summary>

- `jmfsb_boarding_fnc_board`
- `jmfsb_boarding_fnc_canBoard`
- `jmfsb_boarding_fnc_moduleController`
- `jmfsb_boarding_fnc_seatsFor`

</details>
