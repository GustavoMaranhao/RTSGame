class TDProjectileBase extends UTProjectile
	dependson(TDGameController);

var int Type;
var bool bDamageDone;

function projInit(vector Direction, weaponUpgradeData weaponData){
	Speed = weaponData.weaponSpeed;
	AccelRate = weaponData.weaponAccel;
	Damage *= weaponData.damageMultiplier;
	LifeSpan = weaponData.projLifeSpan;
	SetDrawScale3D(weaponData.drawscale);
	Type = weaponData.type;
	DamageRadius = weaponData.damageSplash;
	//`log("Proj Initiated");

	switch(Type){
	case 0: //Melee
		if(TDGameInfo(WorldInfo.Game).Player.weaponStats[0].projRange!=GetRange()){
			//TDGameInfo(WorldInfo.Game).Player.weaponStats[0].projRange = GetRange();
			TDUnitBase(Instigator).Range = 75.f;
		}
		break;
	case 1: //Ranged
		if(TDGameInfo(WorldInfo.Game).Player.weaponStats[1].projRange!=GetRange()){
			//TDGameInfo(WorldInfo.Game).Player.weaponStats[1].projRange = GetRange();
			TDUnitBase(Instigator).Range = GetTDRange();
		}
		break;
	case 2: //Magic
		if(TDGameInfo(WorldInfo.Game).Player.weaponStats[2].projRange!=GetRange()){
			//TDGameInfo(WorldInfo.Game).Player.weaponStats[2].projRange = GetRange();
			TDUnitBase(Instigator).Range = GetTDRange();
		}
		break;
	}
	Init(Direction);
}

simulated function float GetTDRange(){
	if (LifeSpan==0.0) return 15000.0;
	else return (MaxSpeed*LifeSpan);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal){
	if (bDamageDone || TDDummyController(Instigator.Controller).Team==TDDummyController(Pawn(Other).Controller).Team) return;
	if (Other != Instigator){
		Other.TakeDamage( Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity)/2, MyDamageType,, self);
		WorldInfo.Game.Broadcast(self,"Damage Dealt to"@Other@"With a"@Type@"Weapon by"@Instigator);
		bDamageDone = true;
	}
}

simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp){
	//WorldInfo.Game.Broadcast(self,"Hit Wall");
}

DefaultProperties
{
	Damage = 5;
	bDamageDone = false;
}
