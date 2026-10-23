# ACM

`jmfsb_acm`

ACM's and ACE's skill dropdowns: who may perform a treatment. ACE's medic class is what the PAC skills set - CLS gives 1, Medic gives 2.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_medbags`
- `cba_settings` _(external)_
- `ace_medical_treatment` _(external)_
- `ACM_main` _(external)_
- `ACM_core` _(external)_
- `ACM_airway` _(external)_
- `ACM_breathing` _(external)_
- `ACM_cbrn` _(external)_
- `ACM_circulation` _(external)_
- `ACM_damage` _(external)_
- `ACM_disability` _(external)_
- `ACM_evacuation` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 2 functions.

## Eden modules

### JMSB - ACM Evacuation Zone

`jmfsb_acm_moduleEvacZone`, category jmfsb_modules

Any AI that enters the area is evacuated with ACM's evacuation: removed from the mission, out of a vehicle if it is in one, and a converted casualty returns its casualty ticket. Players are never touched. The zone is marked on everyone's map (EVAC).

<details><summary>2 attributes</summary>

- `interval`
- `who`

</details>

## Functions

<details><summary>2</summary>

- `jmfsb_acm_fnc_moduleEvacZone`
- `jmfsb_acm_fnc_setDefault`

</details>
