# Beginner Server Tools

Tools for running and enforcing a server intended for beginners.

MADE FOR ATTRITION

In theory, could be tuned for any mode, but testing and presets have been entirely based around attrition.

The default mod.json is for Novice level, to use intermediate, rename the second .json file and delete/rename the first. If you want to use convars, or tweak the settings of the mod, convar names and explanations can be found inside the mod.json file.

Using [Fifty's Server Utilities](https://northstar.thunderstore.io/package/Fifty/Server_Utilities/) and my [BetterTeamBalance](https://northstar.thunderstore.io/package/MentalEdge/BetterTeamBalance/) mod is highly recommended. You WILL get high skill players joining without realising what the server will do to them, who will then contact you questioning their ban. It would be good to have the server inform players of the automatic-banning in multiple places (description, FSU welcom message, FSU broadcasts).

This mod now uses automatic temp "bans". The server will prevent any offending players from rejoining, by default, for four matches.

#### 1.0.3

- Small bug fixes, should crash less

#### 1.0.2

- Same as 1.0.1
- The mod now uses RUI to display evaluated player skill level in the top right
- Chat tips are now sent as RUI info messages on player respawn
- No longer uses bans, instead temporarily blocks players from joining the server for a configurable number of matches
- Stompers are now warned before a being kicked

## Banhammer

The main feature of this mod. The banhammer is a tool that kicks and prevents players from re-joining, if it evaluates them to be too skilled for the server. The banhammer can be extensively tuned, but I recommend using one of the included presets, and including which one you are running in the server name. This way people will find beginner servers interchangeable, and know what type of skill level to expect.

## Chat tips

A simple script that will make the server occasionally provide random titanfall tips in the chat, which let players know things that are good to know and can be used to improve at the game. You can add your own tips in the respective .nut file. Submitting expansions to the list would be greatly appreciated.

## Statscollector

A truly small brain solution. Barely a "tool". The statscollector, if enable, will post all player details in the server log every ten seconds. This allowed me to graph out and better identify how the detection should work. Techically, you too could use it to tune the banhammer to your liking.

## Team balancing

I highly recommend runnig the [BetterTeamBalance](https://northstar.thunderstore.io/package/MentalEdge/BetterTeamBalance/) mod, also by me.
