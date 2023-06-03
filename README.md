# Beginner Server Tools

Tools for running and enforcing a server intended for beginners. Includes two presets intended for running with Attrition. In theory, could be tuned for any mode, but testing and presets have been entirely based around attrition.

The default mod.json is for Novice level, to use intermediate, rename the second .json file and delete/rename the first. If you want to use convars, or tweak the settings of the mod, convar names and explanations can be found inside the mod.json file.

Using [Fifty's Server Utilities](https://northstar.thunderstore.io/package/Fifty/Server_Utilities/) and my [BetterTeamBalance](https://northstar.thunderstore.io/package/MentalEdge/BetterTeamBalance/) mod is highly recommended.

## Notes on running a server for beginners

As of 2.0 the mod assigns different "weights" to kills while playing as a pilot vs when playing as a titan. Due to this, there is no longer a specific "killcap" that would get you banned. The mod now also takes into account killrate, meaning how fast someone gets kills has an impact.

Bans are managed by the mod and expire within 6 matches by default. Repeat offenders are tracked, and are given exponentially longer bans. (some other stuff also happens if they keep stomping on the server)

While ideally you'd want the server to have only beginners on it, this is often not the case. This is fine, there are not always enough beginners on NS to fill a server, anyway. What this mod will still do in that case is prevent vets from sweating too hard on the server. Or at least not do so for very much time.

Personally I take the approach of never shaming anyone for playing on the servers I run. Anyone and everyone is welcome, and a ban is never more than a slap on the wrist for ruining the fun of the newbies. The goal of the mod is not to prevent players of a any skill level from participating, but to encourage everyone in a lobby to play at a similar level. Thereby providing an opportunity for the least skilled participants to have a share of the fun, and even improve.

For obvious reasons beginner servers should not be connected to the Tone API. This would make them attractive to players wishing to inflate their stats, and unattractive to people who worry about ruining their stats. Either way, beginner servers can muddle the numbers of any given user.

The mod has no simple way to unban a player, aside from a complete server restart, resetting the mod entirely. This is by design and I do not intend to make it possible to give anyone, not even the host, immunity.

#### 2.0.1-2

- Bug fixes

#### 2.0.0

- New and improved!
- Tracks player stats in paralell with in-game stats
- Skill evaluator will remember a players stats, even if they leave and re-join in an attempt to reset them
- A stomper can no longer escape a ban by leaving, if a stomper leaves while above the ban treshold, a ban will still be triggered
- Tighter stat spike buffers, thanks to kills as a titan or pilot counting differently (high skill players should be detected sooner)
- Players are now informed of the reason for their ban on disconnect
- Repeated bans will lead to longer and longer ban durations (and eventually some other subtle punishment)
- Improved skill indicator, earlier heads-up when approaching the ban treshold

### Banhammer

The main feature of this mod. The banhammer is a tool that kicks and prevents players from re-joining, if it evaluates them to be too skilled for the server. The banhammer can be extensively tuned, but I recommend using one of the included presets, and including which one you are running in the server name. This way people will find beginner servers interchangeable, and know what type of skill level to expect.

### Chat tips

- Occasionally provides random tips about how to play titanfall 2 on spawn
- Originally sent chat messages, but as of RUI being implemented, uses the info pop-ups

### Statscollector

A truly small brain solution. Barely a "tool". The statscollector, if enable, will post all player details in the server log every ten seconds. This allowed me to graph out and better identify how the detection should work. Techically, you too could use it to tune the banhammer to your liking.

### Team balancing

I highly recommend runnig the [BetterTeamBalance](https://northstar.thunderstore.io/package/MentalEdge/BetterTeamBalance/) mod, also by me.
