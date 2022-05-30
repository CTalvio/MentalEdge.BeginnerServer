global function StatsInit

int statsCollectorEnable = 1

void function StatsInit(){

    statsCollectorEnable = GetConVarInt( "bs_statscollector" )

    if(statsCollectorEnable == 1){
        AddCallback_GameStateEnter( eGameState.Playing, Playing )
        AddCallback_GameStateEnter( eGameState.Postmatch, Postmatch)
    }
}

void function Playing(){
    printl("[STATCOLLECTOR] HELLO")
    thread StatCollectorThread()
}


void function StatCollectorThread(){
    printl("[STATCOLLECTOR] NEW MATCH")
    while(true){
        wait 15
        foreach (entity player in GetPlayerArray()){
            printl("[STATCOLLECTOR]PROG:IMC:MIL:NAME:K:D:A:T," + GameTime_TimeLeftSeconds() + "," + GameRules_GetTeamScore2(TEAM_IMC) + "," + GameRules_GetTeamScore2(TEAM_MILITIA) + "," + player.GetPlayerName() + "," + player.GetPlayerGameStat(PGS_KILLS) + "," + player.GetPlayerGameStat(PGS_DEATHS) + "," + player.GetPlayerGameStat(PGS_ASSISTS) + "," + player.GetPlayerGameStat(PGS_TITAN_KILLS))
        }
    }
}

void function Postmatch(){
    printl("[STATCOLLECTOR] MATCH END")
}
