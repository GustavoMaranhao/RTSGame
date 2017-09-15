class TDGameInfo extends GameInfo;

var actor test1,test2,test3;
var TDGameController Player;
var TDGameController TDPlayerTemplate;
var TDArchetypeManager ArchetypeManager;

var() LinearColor TeamColors[5];

var int Slot,DisplayCost1,DisplayCost2,DisplayCost3;
var string ImageFlashName,InitialState,DisplayName,DisplayDescription,Hotkey;

var TDUnitBuilder testTemplate1;
var TDUnitFighting testTemplate2;

event InitGame(string Options, out string ErrorMessage){
	Super.InitGame(Options,ErrorMessage);

	SetTimer(1,false,NameOf(StartupTimer));
}

function StartupTimer(){
	local TDGameController PlayerController;

	ForEach WorldInfo.AllControllers(class'TowerDefense.TDGameController', PlayerController){
		Player = PlayerController;
	}
	ArchetypeManager = new() class'TowerDefense.TDArchetypeManager';
}

function PlayerController SpawnPlayerController(vector SpawnLocation, rotator SpawnRotation){
	return Spawn(PlayerControllerClass,,, SpawnLocation, SpawnRotation,TDPlayerTemplate);
}

function TestSpawn(){
	test1 = Spawn(class'TowerDefense.TDUnitBuilder',,'Builder',vect(100,100,15),,testTemplate1);
	TDUnitBase(test1).SetTeam(0);
	TDDummyController(Pawn(test1).Controller).WeaponUsed = 0;
	TDWeaponBase(TDUnitBase(test1).weapon).SetParameters(Player.weaponStats[TDDummyController(Pawn(test1).Controller).WeaponUsed]);

	test3 = Spawn(class'TowerDefense.TDUnitFighting',,'Fighter',vect(300,300,15),,testTemplate2);
	TDUnitBase(test3).SetTeam(2);
	TDDummyController(Pawn(test3).Controller).WeaponUsed = 0;
	TDWeaponBase(TDUnitBase(test3).weapon).SetParameters(Player.weaponStats[TDDummyController(Pawn(test3).Controller).WeaponUsed]);

	test2 = Spawn(class'TowerDefense.TDUnitFighting',,'Fighter',vect(500,500,15),,testTemplate2);
	TDUnitBase(test2).SetTeam(0);
	TDDummyController(Pawn(test2).Controller).WeaponUsed = 0;
	TDWeaponBase(TDUnitBase(test2).weapon).SetParameters(Player.weaponStats[TDDummyController(Pawn(test2).Controller).WeaponUsed]);
}

exec function ChangeTDTeam(int number){
	Player.PlayerTeam = number;
	Broadcast(self,"Player"@Player@"Changed To Team"@Player.PlayerTeam);
}

DefaultProperties
{
	bUseClassicHUD=true
	bDelayedStart=false
	bWaitingToStartMatch=true
	PlayerControllerClass=class'TowerDefense.TDGameController'
	TDPlayerTemplate = TDGameController'Gustavo_Pacote1.Archetypes.PlayerControllerArchetype'
	//DefaultPawnClass=class'TowerDefense.TDPawn'
	DefaultPawnClass=none
    HUDType=class'TowerDefense.TDHUD'

	TeamColors[0] = (R=1.f,G=0.f,B=0.f,A=0.7f)     //Red
	TeamColors[1] = (R=0.f,G=1.f,B=0.f,A=0.7f)     //Green
	TeamColors[2] = (R=0.f,G=0.f,B=1.f,A=0.7f)     //Blue
	TeamColors[3] = (R=1.f,G=1.f,B=1.f,A=0.7f)     //White
	TeamColors[4] = (R=0.f,G=0.f,B=0.f,A=0.7f)     //Black

	testTemplate1 = TDUnitBuilder'Gustavo_Pacote1.Archetypes.UnitBuilder'
	testTemplate2 = TDUnitFighting'Gustavo_Pacote1.Archetypes.UnitFighting'
}
