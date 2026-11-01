# Tasks

`jmfsb_tasks`

Task helpers shared by the mission systems.

**Condition events (review R1).** A task's `conditionEvents*` names are no
longer CBA events: a CBA event carries no sender, so any client could raise one
and complete or show any task. Raise them with `jmfsb_tasks_fnc_raise` on the
server. A client's call goes to the server by `remoteExec`, and only an admin
passes. A mission that raises a condition from a player's machine sends the
request to its own server function, which checks the player, then calls
`raise`. `onShowEvents` / `on<Type>Events` still go out as local CBA events
on the server, for mission scripts that listen there.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`

## Ships

13 functions.

## Functions

<details><summary>13</summary>

- `jmfsb_tasks_fnc_cancelUnfinishedTasks`
- `jmfsb_tasks_fnc_createTask`
- `jmfsb_tasks_fnc_finishTask`
- `jmfsb_tasks_fnc_handleFinish`
- `jmfsb_tasks_fnc_handleOnFinished`
- `jmfsb_tasks_fnc_handleOnShow`
- `jmfsb_tasks_fnc_handleShow`
- `jmfsb_tasks_fnc_onEvent`
- `jmfsb_tasks_fnc_raise`
- `jmfsb_tasks_fnc_readDestination`
- `jmfsb_tasks_fnc_readOwners`
- `jmfsb_tasks_fnc_readTitleAndDescription`
- `jmfsb_tasks_fnc_showTask`

</details>
