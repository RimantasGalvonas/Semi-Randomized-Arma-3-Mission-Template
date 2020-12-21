setGroupIconsVisible [true, false];

[] execVM "G_Revive_init.sqf";

Rimsiakas_missionValidationResult = ([] call Rimsiakas_fnc_validator);

if ((count Rimsiakas_missionValidationResult) > 0) exitWith {
        [] spawn {
            sleep 0.1; // Small delay required to make sure hintC happens after the mission is initialized. Couldn't find any proper event handler for that.
            waitUntil {!isNull player};
            {
                waitUntil {isNull findDisplay 72 && isNull findDisplay 57};
                (_x select 0) hintC (_x select 1);
            } forEach Rimsiakas_missionValidationResult;
        };
};



// Temporarily disabled to avoid firefights breaking out while mission is initializing
{_x disableAI "all"} forEach allUnits;



titleCut ["Initializing...", "BLACK FADED", 999, false];



// Small delay required to make sure the mission is initialized, otherwise isPlayerHighCommander is always false. Couldn't find any proper event handler for that.
sleep 0.1;
isPlayerHighCommander = (count (hcAllGroups player) > 0);



// Spawn/place units
_placersToProcessLast = [];

{
    if (_x getVariable "logicType" == "placer") then {
        if (count(_x getVariable ["camps", []]) == 0) then {
            [_x] call Rimsiakas_fnc_placer;
        } else {
            _placersToProcessLast append [_x]; // placers with camps need to be processed last so it can select the camp garrison from one of the already active factions
        };
    };
} forEach synchronizedObjects patrolCenter;

{
    [_x] call Rimsiakas_fnc_placer;
} forEach _placersToProcessLast;



// Enable team switch
{
    addSwitchableUnit _x;
} forEach units group player;



// Set visible group icons (otherwise allied faction icons are not shown)
_friendlyGroups = [];
{
    if ([side player, side _x] call BIS_fnc_sideIsFriendly) then {
        _friendlyGroups append [_x];
    };
} forEach allGroups;

player setVariable ["MARTA_reveal", _friendlyGroups];

// Without this the military symbols would disappear after teamswitching.
onTeamSwitch {setGroupIconsVisible [true, false]; _to setVariable ["MARTA_reveal", (_from getVariable "MARTA_reveal")];};



// Create intel grid
[] execVM "createGrid.sqf";



{_x enableAI "all"} forEach allUnits;



titleCut ["", "BLACK IN", 1];



// Start groups intel sharing
{
    [_x] spawn { // This makes it run parallel for all groups
        params["_group"];
        _group call Rimsiakas_fnc_shareIntel;
    };
} forEach allGroups;