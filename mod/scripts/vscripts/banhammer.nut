global function BanHammerInit
global function GetMatchProgress

int banhammerEnable = 1

array<string> HUDcreated = []

int killLimit = 20
float kdLimit = 1.8
int stompKillLimit = 30
float stompKdLimit = 3.2
int stompMinimumKills = 8
int banStompers = 1
int banAscended = 0
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
    banStompers = GetConVarInt( "bs_ban_stompers" )
    banAscended = GetConVarInt( "bs_ban_ascended" )
    killsClose = killLimit * 0.75
    kdClose = kdLimit * 0.75
    stompKdClose = stompKdLimit * 0.8
    scoreLimit = GameMode_GetScoreLimit( "aitdm" )
    matchDuration = GameTime_TimeLeftSeconds()
    if(banhammerEnable == 1){

        printl("[BANHAMMER] INITIALIZING")
        AddCallback_GameStateEnter( eGameState.Postmatch, Postmatch)
        AddCallback_GameStateEnter( eGameState.Playing, Playing)
        AddCallback_GameStateEnter( eGameState.Epilogue, Epilogue_OnEnter )
    }
}

void function Playing(){
    printl("[BANHAMMER] ONLINE, PREPARE FOR ASCENSION")
    thread StompCheckerThread()
    thread MessageThread()
    foreach (entity player in GetPlayerArray()){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer");
        HUDcreated.append(player.GetPlayerName())
        NSSendInfoMessageToPlayer( player, "This server is intended for new and returning players, and automatically bans players who are too high skilled. Have fun!" );
    }
    AddCallback_OnPlayerRespawned(OnPlayerSpawned)
}

void function OnPlayerSpawned(entity player){
    if (HUDcreated.find(player.GetPlayerName()) == -1){
        NSCreateStatusMessageOnPlayer( player, "SKILL", "N/A", "banhammer");
        HUDcreated.append(player.GetPlayerName())
        NSSendInfoMessageToPlayer( player, "This server is intended for new and returning players, and automatically bans players who are too high skilled. Have fun!" );
    }
}

void function Postmatch(){
    FinalBanHammer()
}

void function Epilogue_OnEnter(){
    CongratulationMessage()
}

enum eSkillState
{
    NOOB
    GOOD
    GREAT
    ASCENDED
    STOMPER
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
    //Sscended players
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


void function StompCheckerThread(){  //check for stompers
    while(true){
        wait 20
        if ( GetMatchProgress() < 0.93 ){
            printl("[BANHAMMER] CHECKING FOR STOMPS")
            foreach (entity player in GetPlayerArray()){

                int skillstate = GetSkillState(player)
                switch (skillstate){

                    case eSkillState.STOMPER:
                        if (banStompers == 1){
                            ServerCommand("ban " + player.GetUID())
                            printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN BANNED")
                        }
                        else{
                            ServerCommand("kickid " + player.GetUID())
                            printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN KICKED")
                        }
                        Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!!")

                        break

                    case eSkillState.ASCENDED:
                        break

                    case eSkillState.GREAT:
                        break

                    case eSkillState.GOOD:
                        break

                    case eSkillState.NOOB:
                        break
                }
            }
        }
        else{
            return null
        }
    }
}

void function MessageThread(){ // send messages to player that are close to ascending
    while(true){
        wait 20
        if( GetMatchProgress() < 0.78 ){
            wait 30
        }
        if( GetMatchProgress() < 0.93 ){
            printl("[BANHAMMER] DISPLAYING SKILL STATUS TO PLAYERS")
            foreach (entity player in GetPlayerArray()){
                int skillstate = GetSkillState(player)
                switch (skillstate){

                    case eSkillState.STOMPER:
                        NSEditStatusMessageOnPlayer( player, "SKILL", "STOMPER", "banhammer" )
                        break

                    case eSkillState.ASCENDED:  // send a pilot that has achieved potential ascension a message
                        printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS PROBABLY GOING TO BECOME ASCENDED")
                        NSEditStatusMessageOnPlayer( player, "SKILL", "ASCENDED", "banhammer" )
                        SendHudMessage( player, "You're now very close to ascending! Keep it up, Pilot!!!", -1, 0.31, 255, 255, 255, 255, 0.15, 5, 1 )
                        break

                    case eSkillState.GREAT: // send a pilot that's doing well an encouraging message
                        printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS CLOSE TO BECOMING ASCENDED")
                        NSEditStatusMessageOnPlayer( player, "SKILL", "GREAT", "banhammer" )
                        break

                    case eSkillState.GOOD:
                        printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A PILOT IS DOING WELL")
                        NSEditStatusMessageOnPlayer( player, "SKILL", "GOOD", "banhammer" )
                        break

                    case eSkillState.NOOB:
                        printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ")")
                        NSEditStatusMessageOnPlayer( player, "SKILL", "NOOB", "banhammer" )
                        break
                }
            }
        }
        else{
            return null
        }
    }
}

void function CongratulationMessage(){ // send congratulatory message to any ascended or nearly ascended pilots
    printl("[BANHAMMER] DISPLAYING FINAL SKILL STATUS TO PLAYERS")
    foreach (entity player in GetPlayerArray()){
        int skillstate = GetSkillState(player)
        switch (skillstate){

            case eSkillState.STOMPER:
                break

            case eSkillState.ASCENDED:
                SendHudMessage( player, "You've ascended!!!! This is goodbye, Pilot.", -1, 0.35, 255, 255, 255, 255, 0.15, 15, 1 )
                Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!!")
                break

            case eSkillState.GREAT:
                SendHudMessage( player, "You got close to ascending, but didn't quite make it!", -1, 0.35, 255, 255, 255, 255, 0.15, 12, 1 )
                break

            case eSkillState.GOOD:
                SendHudMessage( player, "Well Played! GG!!", -1, 0.35, 255, 255, 255, 255, 0.15, 12, 1 )
                break

            case eSkillState.NOOB:
                SendHudMessage( player, "GG!!! Thank you for playing!", -1, 0.35, 255, 255, 255, 255, 0.15, 12, 1 )
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
                if (banStompers == 1){
                    ServerCommand("ban " + player.GetUID())
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN BANNED")
                }
                else{
                    ServerCommand("kickid " + player.GetUID())
                    printl("[BANHAMMER] " + player.GetPlayerName() + " (" + ReturnSkillStats(player) + ") A STOMPER HAS BEEN KICKED")
                }
                Chat_ServerBroadcast(player.GetPlayerName() + " became ascended!!")
                break

            case eSkillState.ASCENDED:  //ban ascended
                if (banAscended == 1){
                    ServerCommand("ban " + player.GetUID())
                    printl("[BANHAMMER] ASCENDED PILOT(" + player.GetPlayerName() + " " + player.GetPlayerGameStat(PGS_KILLS) + "/" + player.GetPlayerGameStat(PGS_DEATHS) + ") HAS BEEN BANNED")
                }
                else{
                    ServerCommand("kickid " + player.GetUID())
                    printl("[BANHAMMER] ASCENDED PILOT(" + player.GetPlayerName() + " " + player.GetPlayerGameStat(PGS_KILLS) + "/" + player.GetPlayerGameStat(PGS_DEATHS) + ") HAS BEEN KICKED")
                }
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
