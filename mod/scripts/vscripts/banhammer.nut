global function BanHammerInit
global function GetMatchProgress

int banhammerEnable = 1

enum eSkillState
{
    NOOB
    GOOD
    GREAT
    ASCENDED
    STOMPER
}

struct statSet {
    float kills
    float killsAsTitan
    float deaths
    float time
}

table <string, statSet> PlayerStats
array <string> HUDcreated
array <string> GreatPlayers
array <string> Ascended
array <string> Stompers
array <string> BannedAscended
array <string> BannedStompers
table <string, float> RepeatAscenders

int killLimit = 20
float kdLimit = 1.8
int stompKillLimit = 30
float stompKdLimit = 3.2
int stompMinimumKills = 8
float stompKdClose = 1.0
int scoreLimit = 650
float kdSpike = 12.5
int matchDuration = 900


void function BanHammerInit(){
    banhammerEnable = GetConVarInt( "bs_banhammer" )
    killLimit = GetConVarInt( "bs_kill_limit" )
    kdLimit = GetConVarFloat( "bs_kd_limit" )
    stompKillLimit = GetConVarInt( "bs_stompkill_limit" )
    stompKdLimit = GetConVarFloat( "bs_stompkd_limit" )
    kdSpike = GetConVarFloat( "bs_kd_maxspike" ) - stompKdLimit
    stompMinimumKills = GetConVarInt( "bs_minimumkills" )
    stompKdClose = stompKdLimit * 0.8
    scoreLimit = GameMode_GetScoreLimit( "aitdm" )
    if(banhammerEnable == 1){

        printl("[BANHAMMER] INITIALIZING")
        AddCallback_GameStateEnter( eGameState.Postmatch, Postmatch )
        AddCallback_GameStateEnter( eGameState.Playing, Playing )
        AddCallback_GameStateEnter( eGameState.Epilogue, Epilogue_OnEnter )

        AddCallback_OnClientConnecting( OnPlayerConnecting )
        AddCallback_OnClientConnected( OnPlayerConnected )

        AddCallback_OnClientConnected( CreatePlayerDetails )
        AddCallback_OnPlayerKilled( UpdatePlayerDetails )

        UpdateBans("bs_ban_ascended")
        UpdateBans("bs_ban_stompers")
        LoadRepeatAscenders()
        BannedAscended = GetSecondaryArrayFromConVar("bs_ban_ascended", 0)
        BannedStompers = GetSecondaryArrayFromConVar("bs_ban_stompers", 0)
    }
}

void function Playing(){
    printl("[BANHAMMER] ONLINE, PREPARE FOR ASCENSION")
    thread Thread()
    AddCallback_OnPlayerRespawned(OnPlayerSpawned)
    matchDuration = GameTime_TimeLeftSeconds()
}

void function UpdateBans(string convar){
    array <string> kicked = GetSecondaryArrayFromConVar(convar, 0)
    array <string> kickedfor = GetSecondaryArrayFromConVar(convar, 1)

    for(int i = kickedfor.len()-1; i > -1; i--){
        kickedfor.insert(i, (kickedfor[i].tointeger()-1).tostring())
        kickedfor.remove(i+1)
        if(kickedfor[i].tointeger() <= 0){
            kickedfor.remove(i)
            kicked.remove(i)
        }
    }

    array <string> newKickedArray
    for(int i = 0; i < kicked.len(); i++){
        newKickedArray.append( kicked[i] + "-" + kickedfor[i] )
    }

    SaveArrayToConVar(convar, newKickedArray)
}


void function LoadRepeatAscenders(){
    foreach( item in GetArrayFromConVar( "bs_repeat_ascenders" ) ){
        array <string> split = split(item, "-")
        if( split[1].tofloat() > 0.1 )
            RepeatAscenders[split[0]] <- split[1].tofloat() - 0.002
    }
}

void function SaveRepeatAscenders(){
    array <string> convarSave
    foreach( key, value in RepeatAscenders ){
        convarSave.append( key + "-" + value )
    }
    SaveArrayToConVar("bs_repeat_ascenders", convarSave)
}

void function OnPlayerConnecting(entity player) {
    if ( BannedAscended.contains(player.GetUID()) ) {
        NSDisconnectPlayer(player, "You ascended! You cannot play on the server for a while")
        return
    }
    if ( BannedStompers.contains(player.GetUID()) ) {
        NSDisconnectPlayer(player, "Your ban for stomping on the beginners has not expired")
        return
    }
}

void function OnPlayerConnected(entity player) {
    if (HUDcreated.find(player.GetPlayerName()) != -1){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer")
    }
}

void function OnPlayerSpawned(entity player){
    if (HUDcreated.find(player.GetPlayerName()) == -1){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer")
        HUDcreated.append(player.GetPlayerName())
        thread TipThread( player )
    }
}

void function TipThread(entity player){
    wait 1.5
    NSSendInfoMessageToPlayer( player, "This server is intended for new and rusty returning players, and automatically bans players going a bit too hard. Have fun!" )
}

void function CreatePlayerDetails( entity player ){
    if( player.GetUID() in PlayerStats )
        return
    else{
        statSet blank
        PlayerStats[player.GetUID()] <- clone blank
    }
}

void function UpdatePlayerDetails( entity victim, entity attacker, var damageInfo){
    try{
        if( attacker.IsPlayer() && victim.IsPlayer() && attacker != victim ){
            if( attacker.IsTitan() )
                PlayerStats[attacker.GetUID()].killsAsTitan += 1
            else
                PlayerStats[attacker.GetUID()].kills += 1
            PlayerStats[victim.GetUID()].deaths += 1
        }
    }
    catch(error){
    }
}

void function Postmatch(){
    FinalBanHammer()
}

void function Epilogue_OnEnter(){
    //CongratulationMessage()
}

int function GetSettingIntFromConVar(string convar){
 return split(GetConVarString(convar), ",")[0].tointeger()
}

array <string> function GetArrayFromConVar(string convar){
  array <string> convarArray = split(GetConVarString(convar), ",")
  convarArray.remove(0)
  return convarArray
}

void function SaveArrayToConVar(string convar, array <string> input){
  if(GetConVarString(convar) == "0")
    return

  string newContent = split(GetConVarString(convar), ",")[0]
  foreach(string item in input){
    newContent += "," + item
  }
  SetConVarString(convar, newContent)
}

array <string> function GetSecondaryArrayFromConVar(string convar, int whichArray){
  array <string> convarArray
  foreach(string item in GetArrayFromConVar(convar)){
    convarArray.append(split(item, "-")[whichArray])
  }
  return convarArray
}


float function GetMatchProgress(){
    float tempScoreProgress1 = 1.0 * GameRules_GetTeamScore2(TEAM_IMC) / scoreLimit
    float tempScoreProgress2 = 1.0 * GameRules_GetTeamScore2(TEAM_MILITIA) / scoreLimit
    float timeProgressLeft = 1.0 * GameTime_TimeLeftSeconds() / matchDuration
    if(tempScoreProgress1 == 0 && tempScoreProgress2 == 0){
        return 0.0001
    }
    if( tempScoreProgress1 < 1.0 - timeProgressLeft && tempScoreProgress1 < 1.0 - timeProgressLeft )
        return 1.0 - timeProgressLeft
    if(tempScoreProgress1 > tempScoreProgress2){
        return tempScoreProgress1
    }
    return tempScoreProgress2
}

int function GetSkillState( string puid ){ // determine and return the current skill bracket of a player
    float tempkills = ( PlayerStats[puid].kills * 1.25 ) + ( PlayerStats[puid].killsAsTitan * 0.5 )
    float tempdeaths = PlayerStats[puid].deaths
    float kdspikelimit = stompKdLimit
    float percentagepresent = PlayerStats[puid].time.tofloat() / matchDuration
    if ( percentagepresent < 0.5 )
        kdspikelimit = (kdSpike * (1.0 - pow(percentagepresent*2,1.5))) + stompKdLimit
    float tempkd = 1.0

    if( puid in RepeatAscenders ){
        tempkills += RepeatAscenders[puid]
    }

    if(tempdeaths > 0 && tempkills > 0){
        tempkd = tempkills / tempdeaths
    }
    else if( tempkills > 0 ){
        tempkd = tempkills / 0.8
    }
    else{
        tempkd = 0.5
    }
    //Stompers
    // if KD too high
    if( tempkills >= stompMinimumKills && tempkd > kdspikelimit ){
        return eSkillState.STOMPER
    }
    // if too many kills too early
    else if( tempkills >= stompMinimumKills && tempkills >= ((stompKillLimit-2)*pow(percentagepresent,0.5))+2 && tempkd >= 1.6 ){
        return eSkillState.STOMPER
    }
    // if too many kills
    else if( tempkills >= stompKillLimit && tempkd >= 1.6 ){
        return eSkillState.STOMPER
    }
    //Ascended players
    else if( tempkills >= killLimit && tempkd > kdLimit ){
        return eSkillState.ASCENDED
    }
    //check if a player is getting close to ascending
    else if( tempkills >= ((killLimit-2)*pow(percentagepresent,0.5) *0.8)+2 && tempkd > kdLimit *0.8 || tempkills > ((killLimit-2)*pow(percentagepresent,0.5))+2 || tempkd > kdspikelimit*0.8 ){
        return eSkillState.GREAT
    }
    else if( tempkills >= ((killLimit-2)*pow(percentagepresent,0.5) *0.7)+2 || tempkd > kdLimit *0.7 ){
        return eSkillState.GOOD
    }
    //mark the rest as noob
    return eSkillState.NOOB
}


string function ReturnSkillStats( string puid ){ // Return a players stats as a string
    float tempkills = PlayerStats[puid].kills
    float astitankills = PlayerStats[puid].killsAsTitan
    float weightedkills = ( PlayerStats[puid].kills * 1.25 ) + ( PlayerStats[puid].killsAsTitan * 0.5 )
    float tempdeaths = PlayerStats[puid].deaths
    float percentagepresent = PlayerStats[puid].time.tofloat() / matchDuration
    float killRateLimit = ((stompKillLimit-2)*pow(percentagepresent,0.5))+2
    float kdspikelimit = stompKdLimit
    if ( percentagepresent < 0.5 )
        kdspikelimit = (kdSpike * (1.0 - pow(percentagepresent*2,1.5))) + stompKdLimit
    float tempkd = 1.0
    float weightedkd = 0.0
    if(tempdeaths > 0 && tempkills > 0){
        tempkd = tempkills / tempdeaths
        weightedkd = weightedkills / tempdeaths
    }
    else if( tempkills > 0 ){
        tempkd = tempkills / 0.8
    }
    else{
        tempkd = 0.5
    }
    string killdeathkdtext = "K:"+ tempkills +"/TK:"+ astitankills +"/D:"+ tempdeaths +"/WKD:"+ weightedkd +"/KD:"+ tempkd +"/KDSL:"+ kdspikelimit +"/KL:"+ killRateLimit
    return killdeathkdtext
}

void function WatchStomper(string puid, int team){
    printl("[BANHAMMER] A POTENTIAL STOMPER IS BEING WATCHED")
    wait 50

    while( true ){
        bool present = false
        foreach( player in GetPlayerArray() )
            if( player.GetUID() == puid )
                present = true
        if(!present){
            BanStomper( puid )
            return
        }

        int own = GetPlayerArrayOfTeam(team).len()
        int other = GetPlayerArrayOfTeam(GetOtherTeam(team)).len()
        if( GetSkillState( puid ) == eSkillState.STOMPER && own >= other ){
            BanStomper( puid )
            return
        }else if( GetSkillState( puid ) != eSkillState.STOMPER ){
            return
        }

        wait 10
    }

    return
}

void function BanStomper( string puid ){
    foreach( p in GetPlayerArray() ){
        if( p.GetUID() == puid ){
            entity player = p
            array <string> saveToConvar = GetArrayFromConVar("bs_ban_stompers")
            BannedStompers.append(puid)
            printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(puid) + ") A STOMPER HAS BEEN BANNED")
            Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!! Send them off with a salute, o7")

            if( puid in RepeatAscenders ){
                printl("[BANHAMMER] " + player.GetPlayerName() + " HAS BEEN SEEN STOMPING BEFORE, BAN DURATON EXTENDED")
                saveToConvar.append( puid + "-" + ( GetSettingIntFromConVar("bs_ban_stompers") + RepeatAscenders[player.GetUID()] + 1 ) )
                SaveArrayToConVar("bs_ban_stompers", saveToConvar)
                RepeatAscenders[puid] *= GetConVarFloat("bs_repeat_ascenders")
                RepeatAscenders[puid] += 0.5
                NSDisconnectPlayer(player, "You have been temporarily banned for stomping on this beginner server. As this is not your first time, the ban duration has been increased")
            }else{
                saveToConvar.append( puid + "-" + GetSettingIntFromConVar("bs_ban_stompers") )
                SaveArrayToConVar("bs_ban_stompers", saveToConvar)
                RepeatAscenders[puid] <- 0.5
                NSDisconnectPlayer(player, "You have been temporarily banned for stomping on this beginner server")
            }
            return
        }
    }
    // Ban the offender even if they left trying to escape the ban
    array <string> saveToConvar = GetArrayFromConVar("bs_ban_stompers")
    BannedStompers.append(puid)
    printl("[BANHAMMER] " + puid + " (" + ReturnSkillStats(puid) + ") A STOMPER HAS BEEN BANNED")
    if( puid in RepeatAscenders ){
        printl("[BANHAMMER] " + puid + " HAS BEEN SEEN STOMPING BEFORE, BAN DURATON EXTENDED")
        saveToConvar.append( puid + "-" + ( GetSettingIntFromConVar("bs_ban_stompers") + RepeatAscenders[puid] + 1 ) )
        SaveArrayToConVar("bs_ban_stompers", saveToConvar)
        RepeatAscenders[puid] *= GetConVarFloat("bs_repeat_ascenders")
        RepeatAscenders[puid] += 0.5
    }else{
        saveToConvar.append( puid + "-" + GetSettingIntFromConVar("bs_ban_stompers") )
        SaveArrayToConVar("bs_ban_stompers", saveToConvar)
        RepeatAscenders[puid] <- 0.5
    }
}

void function BanAscended( entity player ){
    array <string> saveToConvar = GetArrayFromConVar("bs_ban_ascended")
    BannedAscended.append(player.GetUID())
    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player.GetUID()) + ") A PLAYER HAS ASCENDED")

    if( player.GetUID() in RepeatAscenders ){
        printl("[BANHAMMER] " + player.GetPlayerName() + " HAS ASCENDED BEFORE, BAN DURATON EXTENDED")
        saveToConvar.append( player.GetUID() + "-" + ( GetSettingIntFromConVar("bs_ban_ascended") + RepeatAscenders[player.GetUID()] + 1 ) )
        SaveArrayToConVar("bs_ban_ascended", saveToConvar)

        RepeatAscenders[player.GetUID()] += GetConVarFloat("bs_repeat_ascenders") / 2
        NSDisconnectPlayer(player, "You have become ascended! You are now temporarily banned from playing on the beginner server. As this is not your first time, the ban duration has been increased")
    }else{
        saveToConvar.append( player.GetUID() + "-" + GetSettingIntFromConVar("bs_ban_ascended") )
        SaveArrayToConVar("bs_ban_ascended", saveToConvar)

        RepeatAscenders[player.GetUID()] <- 0.5
        NSDisconnectPlayer(player, "You have become ascended! You are now temporarily banned from playing on the beginner server")
    }
}

void function Thread(){
    wait 2
    foreach (entity player in GetPlayerArray()){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer")
        HUDcreated.append(player.GetPlayerName())
        NSSendInfoMessageToPlayer( player, "This server is intended for new and rusty returning players, and automatically bans players going a bit too hard. Have fun!" )
    }
    wait 10
    while( GetMatchProgress() < 0.99 && GameTime_TimeLeftSeconds() > 10 ){
        printl("[BANHAMMER] DISPLAYING SKILL STATUS TO PLAYERS")
        foreach (entity player in GetPlayerArray()){
            if(!IsValid(player))
                break
            PlayerStats[player.GetUID()].time += 10
            int skillstate = GetSkillState(player.GetUID())
            switch (skillstate){

                case eSkillState.STOMPER:
                    NSEditStatusMessageOnPlayer( player, "SKILL", "STOMPER (BAN)", "banhammer" )
                    if (Stompers.find(player.GetPlayerName()) == -1){
                        Stompers.append(player.GetPlayerName())
                        NSSendInfoMessageToPlayer( player, "Uh oh... You seem to be stomping on the server. Please chill out, or the server may ban you." );
                        WatchStomper( player.GetUID(), player.GetTeam() )
                    }
                    break

                case eSkillState.ASCENDED:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player.GetUID()) + ") A PILOT IS PROBABLY GOING TO BECOME ASCENDED")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "ASCENDED (BAN)", "banhammer" )
                    if (Ascended.find(player.GetPlayerName()) == -1){
                        Ascended.append(player.GetPlayerName())
                        NSSendInfoMessageToPlayer( player, "Heads up!! You are above the ascension(ban) treshold! Keep it up!!" );
                    }
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break

                case eSkillState.GREAT:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player.GetUID()) + ") A PILOT IS CLOSE TO BECOMING ASCENDED")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "GREAT", "banhammer" )
                    if (GreatPlayers.find(player.GetPlayerName()) == -1){
                        GreatPlayers.append(player.GetPlayerName())
                        NSSendInfoMessageToPlayer( player, "Good going! You are approaching ascension. Keep an eye on top right to see how close you are." );
                    }
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break

                case eSkillState.GOOD:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player.GetUID()) + ") A PILOT IS DOING WELL")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "GOOD", "banhammer" )
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break

                case eSkillState.NOOB:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player.GetUID()) + ")")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "SAFE", "banhammer" )
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break
            }
        }
        wait 10
    }
    CongratulationMessage()
}

void function CongratulationMessage(){ // send congratulatory message to any ascended or nearly ascended pilots
    //printl("[BANHAMMER] DISPLAYING FINAL SKILL STATUS TO PLAYERS")
    foreach (entity player in GetPlayerArray()){
        if(!IsValid(player))
            break
        int skillstate = GetSkillState(player.GetUID())
        switch (skillstate){

            case eSkillState.STOMPER:
                break

            case eSkillState.ASCENDED:
                NSSendAnnouncementMessageToPlayer( player, "You've ascended!!!!", "This is goodbye, Pilot.", <1,0,0>, 0, 1 )
                Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!!  Send them off with a salute, o7")
                break

            case eSkillState.GREAT:
                NSSendAnnouncementMessageToPlayer( player, "So close!!", "You got close to ascending, but didn't quite make it!", <1,0,0>, 0, 1 )
                break

            case eSkillState.GOOD:
                NSSendAnnouncementMessageToPlayer( player, "Well Played!! GG", "You did well, but no need to worry about ascending, yet.", <1,0,0>, 0, 1 )
                break

            case eSkillState.NOOB:
                NSSendAnnouncementMessageToPlayer( player, "Thank you for playing!", "GG!! Hope you had fun!", <1,0,0>, 0, 1 )
                break
        }
    }
}


void function FinalBanHammer(){
    printl("[BANHAMMER] RUNNING FINAL CHECKS AND ENACTING BANS")
    foreach (entity player in GetPlayerArray()){
        if(!IsValid(player))
            break
        int skillstate = GetSkillState(player.GetUID())
        switch (skillstate){
            case eSkillState.STOMPER:
                BanStomper( player.GetUID() )

                break

            case eSkillState.ASCENDED:  //ban ascended
                BanAscended( player )

                break

            case eSkillState.GREAT:
                break

            case eSkillState.GOOD:
                break

            case eSkillState.NOOB:
                break
        }
    }
    printl("[BANHAMMER] ALL DONE")
    SaveRepeatAscenders()
}
