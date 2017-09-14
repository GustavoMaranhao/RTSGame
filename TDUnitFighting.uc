class TDUnitFighting extends TDUnitBase;

var bool bTooClose;

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	super.bump(Other, OtherComp, HitNormal);
	if(!Controller.IsInState('Attacking')) bTooClose = true;
}

event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	super.HitWall(HitNormal,Wall, WallComp);
	if(!Controller.IsInState('Attacking')) bTooClose = true;
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	if(!Controller.IsInState('Attacking')) bTooClose = true;	
}

DefaultProperties
{
	bTooClose = false;

	customType = "Fighter"
}
