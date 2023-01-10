global function BanHammerInit
global function GetMatchProgress

int banhammerEnable = 1

array<string> HUDcreated = []
array<string> GreatPlayers = []
array<string> Ascended = []
array<string> Stompers = []
array<string> BannedAscended = []
array<string> BannedStompers = []

int killLimit = 20
float kdLimit = 1.8
int stompKillLimit = 30
float stompKdLimit = 3.2
int stompMinimumKills = 8
float killsClose = 1.0
float kdClose = 1.0
float stompKdClose = 1.0
int scoreLimit = 650
float assistRatioLimit = 0.3
int stompTitanKillLimit = 1
int ascendTitanKillLimit = 1
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
    assistRatioLimit = GetConVarFloat( "bs_assistratio" )
    stompTitanKillLimit = GetConVarInt( "bs_stomptitankill_limit" )
    ascendTitanKillLimit = GetConVarInt( "bs_ascendtitankill_limit" )
    killsClose = killLimit * 0.75
    kdClose = kdLimit * 0.75
    stompKdClose = stompKdLimit * 0.8
    scoreLimit = GameMode_GetScoreLimit( "aitdm" )
    matchDuration = GameTime_TimeLeftSeconds()
    if(banhammerEnable == 1){

        printl("[BANHAMMER] INITIALIZING")
        AddCallback_GameStateEnter( eGameState.Postmatch, Postmatch )
        AddCallback_GameStateEnter( eGameState.Playing, Playing )
        AddCallback_GameStateEnter( eGameState.Epilogue, Epilogue_OnEnter )
    }

    UpdateBans("bs_ban_ascended")
    UpdateBans("bs_ban_stompers")
    BannedAscended = GetSecondaryArrayFromConVar("bs_ban_ascended", 0)
    BannedStompers = GetSecondaryArrayFromConVar("bs_ban_stompers", 0)
}

void function UpdateBans(string convar){
    array <string> kicked = GetSecondaryArrayFromConVar(convar, 0)
    array <string> kickedfor = GetSecondaryArrayFromConVar(convar, 1)
    int kickDuration = GetSettingIntFromConVar(convar)

    for(int i = kickedfor.len()-1; i > -1; i--){
        kickedfor.insert(i, (kickedfor[i].tointeger()+1).tostring())
        kickedfor.remove(i+1)
        if(kickedfor[i].tointeger() > kickDuration){
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

void function Playing(){
    printl("[BANHAMMER] ONLINE, PREPARE FOR ASCENSION")
    thread Thread()
    AddCallback_OnPlayerRespawned(OnPlayerSpawned)
    AddCallback_OnClientConnected(OnPlayerConnected)
}

void function OnPlayerConnected(entity player) {
    if (BannedAscended.contains(player.GetUID()) || BannedStompers.contains(player.GetUID())) {
        ServerCommand("kickid " + player.GetUID())
    }
    else if (HUDcreated.find(player.GetPlayerName()) != -1){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer")
    }
}

void function OnPlayerSpawned(entity player){
    if (HUDcreated.find(player.GetPlayerName()) == -1){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer")
        HUDcreated.append(player.GetPlayerName())
        NSSendInfoMessageToPlayer( player, "This server is intended for new and rusty returning players, and automatically bans players going a bit too hard. Have fun!" );
    }
}

void function Postmatch(){
    FinalBanHammer()
}

void function Epilogue_OnEnter(){
    //CongratulationMessage()
}

enum eSkillState
{
    NOOB
    GOOD
    GREAT
    ASCENDED
    STOMPER
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

float function GetPlayerKDLimit( entity player ){  // Get a players unique KD spike cap, based on their number of player interactions
    int kills = player.GetPlayerGameStat(PGS_KILLS)
    int deaths = player.GetPlayerGameStat(PGS_DEATHS)
    int assists = player.GetPlayerGameStat(PGS_ASSISTS)
    int aggregatedKda = kills + deaths + assists
    if(aggregatedKda < 30){
        float playerProgress = 1.0 * aggregatedKda / 30
        float invertProgress = 1.0 - pow(playerProgress,1.5)
        return kdSpike * invertProgress + stompKdLimit
    }
    return stompKdLimit
}


int function GetSkillState( entity player ){  // determine and return the current skill bracket of a player
    float tempkills = 1.0 * player.GetPlayerGameStat(PGS_KILLS)
    float tempdeaths = 1.0 * player.GetPlayerGameStat(PGS_DEATHS)
    float tempassistratio = player.GetPlayerGameStat(PGS_ASSISTS) / tempkills
    int temptitankills = player.GetPlayerGameStat(PGS_TITAN_KILLS)
    float tempkd = 1.0
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
    if( tempkills >= stompMinimumKills && tempkd > GetPlayerKDLimit(player) && temptitankills >= stompTitanKillLimit && tempassistratio < assistRatioLimit ){
        return eSkillState.STOMPER
    }
    else if( tempkills >= stompMinimumKills && tempkills >= stompKillLimit * pow(GetMatchProgress(),0.4) && temptitankills >= stompTitanKillLimit && tempassistratio < assistRatioLimit  ){
        return eSkillState.STOMPER
    }
    else if( tempkills >= stompKillLimit && tempkd >= 1.4 ){
        return eSkillState.STOMPER
    }
    //Ascended players
    else if( tempkills >= killLimit && tempkd > kdLimit && temptitankills >= ascendTitanKillLimit && tempassistratio < assistRatioLimit ){
        return eSkillState.ASCENDED
    }
    //check if a player is getting close to ascending
    else if( tempkills >= killsClose && tempkd > kdClose && tempassistratio < assistRatioLimit ){
        return eSkillState.GREAT
    }
    else if( tempkd > stompKdClose ){
        return eSkillState.GOOD
    }
    //mark the rest as noob
    return eSkillState.NOOB
}


string function ReturnSkillStats( entity player ){ // Return a players stats as a string
    float tempkills = 1.0 * player.GetPlayerGameStat(PGS_KILLS)
    float tempdeaths = 1.0 * player.GetPlayerGameStat(PGS_DEATHS)
    float tempkd = 1.0
    int tempassists = player.GetPlayerGameStat(PGS_ASSISTS)
    int temptitankills = player.GetPlayerGameStat(PGS_TITAN_KILLS)
    if(tempdeaths > 0 && tempkills > 0){
        tempkd = tempkills / tempdeaths
    }
    else if( tempkills > 0 ){
        tempkd = tempkills / 0.8
    }
    else{
        tempkd = 0.5
    }
    string killdeathkdtext = "K:"+ tempkills +"/D:"+ tempdeaths +"/A:"+ tempassists +"/T:"+ temptitankills +"/KD:"+ tempkd
    return killdeathkdtext
}


void function WatchStomper(entity player){
    wait 50

    if( IsValid(player) ){
        if( GetSkillState(player) == eSkillState.STOMPER ){
            BannedStompers.append(player.GetUID())
            array <string> saveToConvar = GetArrayFromConVar("bs_ban_stompers")
            saveToConvar.append(player.GetUID() + "-0")
            SaveArrayToConVar("bs_ban_stompers", saveToConvar)
            ServerCommand("kickid " + player.GetUID())
            printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN DETECTED AND BANNED")
            Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!! Send them off with a salute, o7")
        }
    }

    return
}

void function Thread(){
    wait 2
    foreach (entity player in GetPlayerArray()){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer");
        HUDcreated.append(player.GetPlayerName())
        NSSendInfoMessageToPlayer( player, "This server is intended for new and rusty returning players, and automatically bans players going a bit too hard. Have fun!" );
    }
    wait 10
    while( GetMatchProgress() < 0.97 && GameTime_TimeLeftSeconds() > 15 ){
        printl("[BANHAMMER] DISPLAYING SKILL STATUS TO PLAYERS")
        foreach (entity player in GetPlayerArray()){
            int skillstate = GetSkillState(player)
            switch (skillstate){

                case eSkillState.STOMPER:
                    NSEditStatusMessageOnPlayer( player, "SKILL", "STOMPER (BAN)", "banhammer" )
                    if (Stompers.find(player.GetPlayerName()) == -1){
                        Stompers.append(player.GetPlayerName())
                        NSSendInfoMessageToPlayer( player, "Uh oh... You seem to be stomping on the server. Please chill out, or the server may ban you." );
                        WatchStomper(player)
                    }
                    break

                case eSkillState.ASCENDED:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS PROBABLY GOING TO BECOME ASCENDED")
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
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS CLOSE TO BECOMING ASCENDED")
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
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS DOING WELL")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "GOOD", "banhammer" )
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break

                case eSkillState.NOOB:
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ")")
                    NSEditStatusMessageOnPlayer( player, "SKILL", "SAFE", "banhammer" )
                    if(Stompers.find(player.GetPlayerName()) > -1){
                        Stompers.remove(Stompers.find(player.GetPlayerName()))
                    }
                    break
            }
        }
        wait 10
    }
    wait GameTime_TimeLeftSeconds() - 5
    CongratulationMessage()
}

void function CongratulationMessage(){ // send congratulatory message to any ascended or nearly ascended pilots
    printl("[BANHAMMER] DISPLAYING FINAL SKILL STATUS TO PLAYERS")
    foreach (entity player in GetPlayerArray()){
        int skillstate = GetSkillState(player)
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
        int skillstate = GetSkillState(player)
        switch (skillstate){
            case eSkillState.STOMPER:
                BannedStompers.append(player.GetUID())
                array <string> saveToConvar = GetArrayFromConVar("bs_ban_stompers")
                saveToConvar.append(player.GetUID() + "-0")
                SaveArrayToConVar("bs_ban_stompers", saveToConvar)
                ServerCommand("kickid " + player.GetUID())
                printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN BANNED")

                break

            case eSkillState.ASCENDED:  //ban ascended
                BannedAscended.append(player.GetUID())
                array <string> saveToConvar = GetArrayFromConVar("bs_ban_ascended")
                saveToConvar.append(player.GetUID() + "-0")
                SaveArrayToConVar("bs_ban_ascended", saveToConvar)
                ServerCommand("kickid " + player.GetUID())
                printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PLAYER HAS ASCENDED")

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
}
