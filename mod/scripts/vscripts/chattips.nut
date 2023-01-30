global function TipsInit

int chatTipsEnabled = 1
int tempTipNumber = 0
//array<int> alreadyUsedTips = [-1]
table <entity, array<int> > alreadyUsedForPlayer = {}

void function TipsInit(){
    chatTipsEnabled = GetConVarInt( "bs_chat_tips" )
    if(chatTipsEnabled == 1){
        AddCallback_GameStateEnter( eGameState.Playing, Playing)
        AddCallback_OnPlayerRespawned( SendTip )
    }
}

void function Playing(){
    printl("[CHATTIPS] PREPARE FOR INTERESTING TITANFALL FACTS")
    printl("[CHATTIPS] tips available: " + tipList.len())
    //thread TipsThread()
}


array<string> tipList = [

"Set off a satchel while not holding the detonator, by double tapping reload.",
"To turn while slide hopping, let go of W. Hold A or D and turn in the same direction during airtime.",
"A Firestar or Arc Grenade can be used to blind a titan.",
"You can hack the specters in multiplayer! Get behind them and use your data knife.",
"Holding a battery will make you easy to spot, even while cloaked.",
"Give your titan toting team-mates batteries! You get a huge titanfall progress bonus for it!",
"Enemy team got a lot of titans? Chip away at them using your anti-titan weapon, it will also massively boost you towards your own titan.",
"Anti-titan weapons also work great on reapers!",
"The mag-launcher works on all metal enemies, that includes Spectres, Stalkers and Reapers!",
"Wallrunning is faster than sprinting!",
"Your jump pack is very loud, and the jets will reveal you even if cloaked.",
"If you are holding the button for an ordnance or pulse blade throw, you can cancel by switching weapons.",
"Melee a doomed titan to execute it.",
"Hold melee behind an enemy pilot, to execute them.",
"All guns can do damage to titans, if you hit their weak spots. They glow red when aiming down sights.",
"The pulse blade can instakill. It can also be destroyed.",
"A very short grapple does not use up a charge.",
"Firestars can ignite Scorchs incendiary trap.",
"Satchel charges can be stuck to titans, and do massive damage.",
"Eject before your titan becomes doomed, by pressing X, then triple tap E as normal.",
"Grapple the ground when ejecting, to avoid flying high and becoming an easy target.",
"You can change aim and crouch to hold, instead of toggle in keybindings.",
"Charging Ions laser shot does no extra damage.",
"Turrets can be instantly destroyed by melee.",
"Ions shield can return damage, don't feed her! It can also block the arc wave and flame wall.",
"The heat shield does more damage than melee.",
"Scorch can throw his traps over Tones particle wall.",
"Tones particle wall is directional. Anyone, even the enemy team, can use it if behind it.",
"Tones missiles can be fired around corners.",
"Legions predator cannon consumes twice the ammo in long range mode.",
"Watch out for the lock-on indicator! Turn to deal with the threat if it appears.",
"Smoke can be used to put out fires.",
"The R-45 is surprisingly precise when aiming down sights.",
"Using stim while wallrunning gives you a much bigger speed boost.",
"The smart pistol ignores holo-pilot holograms.",
"Firing the Thunderbolt at the general direction of a titan may be enough. Its lightning strikes out and does damage in an area.",
"The paths of projectiles can be bent by the gravity star.",
"This server bans players above a certain skill threshold."
"If you want to avoid ascending, but are close, try learning a new loadout, your skills will diversify."

]

void function SendTip(entity player){
    if (RandomIntRange( 0, 2 ) > 0 || GetMatchProgress() < 0.5) {
        return
    }

    if ( !(player in alreadyUsedForPlayer) ){
        alreadyUsedForPlayer[player] <- [-1]
    }

    array <int> alreadyUsedTips = alreadyUsedForPlayer[player]

    tempTipNumber = RandomIntRange( 0, tipList.len() - 1 )
    if( tipList.len() > alreadyUsedTips.len() ){
        while( alreadyUsedTips.find(tempTipNumber) > 0 ){
            tempTipNumber = tempTipNumber + 1
            if(tempTipNumber == tipList.len() ){
                tempTipNumber = 0
            }
        }
    }
    else {
        alreadyUsedTips = [-1]
        printl("[CHATTIPS] " + player.GetPlayerName() + " has seen all tips, repeating at random.")
    }
    alreadyUsedTips.append(tempTipNumber)

    alreadyUsedForPlayer[player] <- alreadyUsedTips

    NSSendInfoMessageToPlayer(player, "Random tip: " + tipList[tempTipNumber])
    printl("[CHATTIPS] Sent tip to " + player.GetPlayerName() + ": " + tipList[tempTipNumber])
}

// void function TipsThread(){
//     while(true){
//         wait 22
//         if(GetMatchProgress() < 0.4){
//             tempTipNumber = RandomIntRange( 0, tipList.len() - 1 )
//             if( tipList.len() > alreadyUsedTips.len() ){
//                 while( alreadyUsedTips.find(tempTipNumber) > 0 ){
//                     tempTipNumber = tempTipNumber + 1
//                     if(tempTipNumber == tipList.len() ){
//                         tempTipNumber = 0
//                     }
//                 }
//             }
//             else{
//                 printl("[CHATTIPS] All tips posted at least once, now repeating randomly")
//             }
//
//             alreadyUsedTips.append(tempTipNumber)
//             foreach (entity player in GetPlayerArray()){
//                 NSSendInfoMessageToPlayer(player, "Random tip: " + tipList[tempTipNumber])
//             }
//             printl("[CHATTIPS] Posted a tip: " + tipList[tempTipNumber])
//         }
//         else{
//             return null
//         }
//         wait 81
//     }
// }
