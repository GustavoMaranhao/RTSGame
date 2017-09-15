class TDUnitConstruction extends TDUnitBase;

var() StaticMesh BuildTemplate;
var() float BuildTime;
var StaticMeshComponent BuildObject;
var BoxSphereBounds OriginalSize;
var int builderNum;

simulated event PostBeginPlay(){
	super.PostBeginPlay();
}

function UseBuildTemplate(){
	DetachComponent(Mesh);
	BuildObject.SetStaticMesh(BuildTemplate);
	AttachComponent(BuildObject);
}

function ResetMeshToNormal(){
	DetachComponent(BuildObject);
	Mesh.SetSkeletalMesh(Mesh.default.SkeletalMesh);
	AttachComponent(Mesh);
	OriginalSize = Mesh.Bounds;
	PushState('Building');
}

state Building{
	/*Upgrades: Vetor de Itens construídos, checar se o item existe no vetor sempre que este state for popped, remover (adicionar campo de pre-requisites no archetype) no state Dying (super state?),
	 *          update foreach builders (existentes), ao spawn de builder checar seu secondarypannel com os itens do vetor (InitialState), updateHUD ao acabar Building ou Dying */         
	local float x;
	local vector tempVector;
	event PoppedState(){
		TDGameInfo(WorldInfo.Game).Player.BeingBuilt = none;
		`log("Done");
	}
    event PushedState(){
		//SetTeam(2);
		Health = 0;
		bBeingBuilt = true;
    }

Begin:
	x = -OriginalSize.BoxExtent.Z;
	tempVector.X = 0;
	tempVector.Y = 0;
Tick:
	`log(builderNum);
	tempVector.Z = x;
	Mesh.SetTranslation(tempVector);
	if(x>=0) {bBeingBuilt = false; if(bSelected) SetHUDButtons(); PopState();}
	else{
		Sleep(0.5);
		x += builderNum*OriginalSize.BoxExtent.Z/(2*BuildTime);
		Health += builderNum*HealthMax/(2*BuildTime);
		GoTo('Tick');
	}
}

state BuildUnfinished{ }

DefaultProperties
{
	customType = "Building"
	GroundSpeed = 0;

	BuildTime = 50;
	Health = 1;
	HealthMax = 500;
	builderNum = 0;

	Begin Object Name=InitialSkeletalMesh
		Scale=1
	End Object
	Mesh=InitialSkeletalMesh;

	Begin Object Class=StaticMeshComponent Name=BuildTemplateObject
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
		LightEnvironment=MyLightEnvironment;
        BlockRigidBody=true;
        CollideActors=true;
        BlockZeroExtent=true;
		BlockNonZeroExtent=TRUE
		bHasPhysicsAssetInstance=true	
		Scale=2
	End Object
	BuildObject = BuildTemplateObject;
}
