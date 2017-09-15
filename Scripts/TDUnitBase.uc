class TDUnitBase extends Pawn placeable;

var bool bSelected;
var() ParticleSystemComponent SelectionParticle;

var AnimNodeSlot FullBodyAnimSlot;
var AnimNodeSlot TopHalfAnimSlot;

var() string customName;
var() string customType;

var() float Range;
var() int PawnTeam;
var() WeaponTypes WeaponType;
var() int WeaponUpgradeLevel;
var() float walkingOffset;
var() float DefendRange;

var bool bBeingBuilt;

var() array<Slots> PrimaryPannel,SecondaryPannel;

struct CustomAttackAnim{
	var() name CustomAnimName;
	var() float CustomAnimRate;
	var() float CustomAttackCooldown;
};
var() array<CustomAttackAnim> CAttackAnim;

struct CustomBuildAnim{
	var() name CustomAnimName;
	var() float CustomAnimRate;
	var() float CustomBuildCooldown;
};
var() array<CustomBuildAnim> CBuildAnim;

var GameInventoryManager GameInv;
var SceneCapture2DComponent UICapComp;
var TextureRenderTarget2D PortraitTex;

simulated event PostBeginPlay(){	
	super.PostBeginPlay();
    SetPhysics(PHYS_Falling);

	TopHalfAnimSlot = AnimNodeSlot(mesh.FindAnimNode('TopHalfSlot'));
	FullBodyAnimSlot = AnimNodeSlot(mesh.FindAnimNode('FullBodySlot'));

	addDefaultInventory();
	SpawnDefaultController();
	//SetCollisionSize(Mesh.Bounds.SphereRadius/2,Mesh.Bounds.BoxExtent.Z/2);

	//SetTimer(0.2,false,NameOf(StartupTimer));
	//Range = TDGameInfo(WorldInfo.Game).Player.weaponStats[TDDummyController(Controller).WeaponUsed].projRange;
	//Range = TDGameInfo(WorldInfo.Game).Player.weaponStats[WeaponType].projRange;
	TDDummyController(Controller).walkingOffset = walkingOffset;
	TDDummyController(Controller).DefendRange = DefendRange;
	SetTeam(PawnTeam);
}

function SetPortrait(){
	if (PortraitTex == None){
		/**
		 *	Be sure the scene captures clear color and 
		 *	render textures background color are the same.
		 */
		PortraitTex = class'TextureRenderTarget2D'.static.Create(80, 80, , MakeLinearColor(0.0f, 0.0f, 0.0f, 1.0f));

		UICapComp.SetCaptureParameters(PortraitTex, 90);
	}
	if(TDDummyController(Controller).Team == TDGameInfo(WorldInfo.Game).Player.PlayerTeam){
		TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.SetPortraitTexture(PortraitTex);
		TDGameInfo(WorldInfo.Game).Player.PortraitCameraOn = self;
	}
}

function SetHUDButtons(){
	local int i;
	local Slots tempSlot;

	TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.ResetArrays();
	if(bBeingBuilt){
		tempSlot = SecondaryPannel[11];
		TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.InitHUD(0,i,tempSlot.ImageName,tempSlot.InitialState,tempSlot.customName,tempSlot.ResourceCost,tempSlot.Description);
	} else {
		for(i=0;i<PrimaryPannel.length;i++){
			tempSlot = PrimaryPannel[i];
			TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.InitHUD(0,i,tempSlot.ImageName,tempSlot.InitialState,tempSlot.customName,tempSlot.ResourceCost,tempSlot.Description);
		}
		for(i=0;i<SecondaryPannel.length;i++){
			tempSlot = SecondaryPannel[i];
			TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.InitHUD(1,i,tempSlot.ImageName,tempSlot.InitialState,tempSlot.customName,tempSlot.ResourceCost,tempSlot.Description);
		}
	}
	TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).PrimaryPannel = PrimaryPannel;
	TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).SecondaryPannel = SecondaryPannel;
	TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).HUDMovie.DrawFlashHUD(0);
}

function SetTeam(int NewTeam){
	PawnTeam = NewTeam;
	TDDummyController(Controller).Team = PawnTeam;
	ColorChange(TDGameInfo(WorldInfo.Game).TeamColors[PawnTeam]);
}

function ColorChange(LinearColor ColorVect){
	local MaterialInstanceConstant MatInst;
	local int i;

	MatInst = new Class'MaterialInstanceConstant';
	for(i=0;i<Mesh.Materials.Length;i++){
		if(Mesh.Materials[i]==none) continue;
		MatInst.SetParent(Mesh.GetMaterial(i));
		MatInst.SetVectorParameterValue('Color',ColorVect);
		Mesh.SetMaterial(i, MatInst);
	}
}

function AddDefaultInventory(){
	self.InvManager.CreateInventory(class'TowerDefense.TDWeaponBase');
}

simulated function StartFire(byte FireModeNum){
	super.StartFire(FireModeNum);
	Weapon.ProjectileFire();
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser){
	Health -= DamageAmount;
	if(TDDummyController(Controller).TargetPawn==none){
		TDDummyController(Controller).TargetPawn=TDDummyController(EventInstigator).Pawn;
		SetRotation(Rotator(TDDummyController(Controller).TargetPawn.Location - Location));
	}
	if (Health <= 0){
		Health = 0;
		Died(EventInstigator, DamageType, HitLocation);
		TDDummyController(EventInstigator).TargetPawn=none;
		TDDummyController(Controller).TargetPawn=none;
		TDDummyController(EventInstigator).SetDestinationPosition(EventInstigator.Pawn.Location);
		TDDummyController(EventInstigator).bisMoving = false;
	}
	else 
		super.TakeDamage(DamageAmount,EventInstigator, HitLocation,Momentum,DamageType,HitInfo,DamageCauser);
}

State Dying{
ignores Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, FellOutOfWorld;

	simulated function PlayWeaponSwitch(Weapon OldWeapon, Weapon NewWeapon) {}
	simulated function PlayNextAnimation() {}
	singular event BaseChange() {}
	event Landed(vector HitNormal, Actor FloorActor) {}

	function bool Died(Controller Killer, class<DamageType> damageType, vector HitLocation);

	  simulated singular event OutsideWorldBounds(){
		  SetPhysics(PHYS_None);
		  SetHidden(True);
		  LifeSpan = FMin(LifeSpan, 1.0);
	  }

	event Timer(){
		if (!PlayerCanSeeMe()){
			Destroy();
		}
		else{
			SetTimer(2.0, false);
		}
	}

	event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser){
		SetPhysics(PHYS_Falling);

		if ((Physics == PHYS_None) && (Momentum.Z < 0))
			Momentum.Z *= -1;

		Velocity += 3 * momentum/(Mass + 200);

		if (damagetype == None){
			//`warn("No damagetype for damage by "$instigatedby.pawn$" with weapon "$InstigatedBy.Pawn.Weapon);
			DamageType = class'DamageType';
		}

		Health -= Damage;
	}

	event BeginState(Name PreviousStateName){
		local Actor A;
		local array<SequenceEvent> TouchEvents;
		local int i;

		if (bTearOff && (WorldInfo.NetMode == NM_DedicatedServer)){LifeSpan = 2.0;}
		else{
			SetTimer(5.0, false);
			// add a failsafe termination
			LifeSpan = 25.f;
		}

		SetDyingPhysics();

		Mesh.MinDistFactorForKinematicUpdate = 0.0;
		Mesh.ForceSkelUpdate();
		Mesh.SetTickGroup(TG_PostAsyncWork);
		CollisionComponent = Mesh;
		CylinderComponent.SetActorCollision(false, false);
		Mesh.SetActorCollision(true, false);
		Mesh.SetTraceBlocking(true, true);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,TRUE);

		SetPhysics(PHYS_RigidBody);

		Mesh.PhysicsWeight = 1.f;

		if (Mesh.bNotUpdatingKinematicDueToDistance){
			Mesh.UpdateRBBonesFromSpaceBases(true, true);
		}

		Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
		Mesh.bUpdateKinematicBonesFromAnimation = false;
		Mesh.WakeRigidBody();

		SetCollision(true, false);

		if (Controller != None){
			if (Controller.bIsPlayer){DetachFromController();}
			else{Controller.Destroy();}
		}

		foreach TouchingActors(class'Actor', A){
			if (A.FindEventsOfClass(class'SeqEvent_Touch', TouchEvents)){
				for (i = 0; i < TouchEvents.length; i++){
					SeqEvent_Touch(TouchEvents[i]).NotifyTouchingPawnDied(self);
				}
				// clear array for next iteration
				TouchEvents.length = 0;
			}
		}
		foreach BasedActors(class'Actor', A){
			A.PawnBaseDied();
		}
	}

Begin:
	TDDummyController(Controller).TargetPawn=none;
	Sleep(0.2);
	PlayDyingSound();
	sleep(3);
	if(bSelected) TDHUD(TDGameInfo(WorldInfo.Game).Player.myHUD).ResetHUD();
	Mesh.SetHidden(true);
	self.Destroy();
}

DefaultProperties
{
	Components.Remove(Sprite)

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		ModShadowFadeoutTime=0.25
		MinTimeBetweenFullUpdates=0.2
		AmbientGlow=(R=.01,G=.01,B=.01,A=1)
		AmbientShadowColor=(R=0.15,G=0.15,B=0.15)
		LightShadowMode=LightShadow_ModulateBetter
		ShadowFilterQuality=SFQ_High
		bSynthesizeSHLight=TRUE
	End Object
	Components.Add(MyLightEnvironment)

    Begin Object Class=SkeletalMeshComponent Name=InitialSkeletalMesh
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
		LightEnvironment=MyLightEnvironment;
        BlockRigidBody=true;
        CollideActors=true;
        BlockZeroExtent=true;
		BlockNonZeroExtent=TRUE
		bHasPhysicsAssetInstance=true		
		PhysicsAsset=PhysicsAsset'pacote_personagem.humana.humana2_Physics'
		AnimSets(0)=AnimSet'pacote_personagem.humana.humana_correndo'
        AnimSets(1)=AnimSet'pacote_personagem.humana.humana_idle'
        AnimSets(2)=AnimSet'pacote_personagem.humana.humana_pulo'
        AnimSets(3)=AnimSet'pacote_personagem.humana.humana_pulo2'
        AnimSets(4)=AnimSet'pacote_personagem.humana.humana_pulo3' 
		AnimSets(5)=AnimSet'pacote_personagem.humana.humana_pulo4' 
		AnimSets(6)=AnimSet'pacote_personagem.humana.humana_pulo5' 
		AnimSets(7)=AnimSet'pacote_personagem.humana.humana_pulo6' 
		AnimSets(8)=AnimSet'pacote_personagem.humana.humana_pulo7' 
		AnimSets(9)=AnimSet'pacote_personagem.humana.humana_ataque01' 
		AnimSets(10)=AnimSet'pacote_personagem.humana.humana_ataque02' 
		AnimSets(11)=AnimSet'pacote_personagem.humana.humana_ataque03' 
		AnimTreeTemplate=AnimTree'pacote_personagem.humana.humana_mulher_animtree'
		SkeletalMesh=SkeletalMesh'pacote_personagem.humana.humana2'//SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
		Translation=(X=0,Y=0,Z=-140)
		Rotation=(Yaw=-16384,Roll=0,Pitch=0)
		Scale=2.9

		Materials(0)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(1)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(2)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(3)=Material'pacote_personagem.Materials.natal2_mat'
		Materials(5)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(11)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(12)=Material'pacote_personagem.Materials.natal1_mat'
	End Object

	Mesh=InitialSkeletalMesh;
	Components.Add(InitialSkeletalMesh);

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0                    //Particle used for an Undefined Amount of Time
        Template=ParticleSystem'KismetGame_Assets.Effects.P_EarBuzz_01'
        bAutoActivate=false
		Scale=0.25
	End Object
	SelectionParticle=ParticleSystemComponent0
	Components.Add(ParticleSystemComponent0)

	Begin Object Class=SceneCapture2DComponent Name=RTTComponent
		ViewMode=SceneCapView_Lit
		NearPlane=10
		/**
		 *	Far plane clip distance: <= 0 means no far plane.
		 *	Set this far enough to encompass what we want to render.
		 *	Beyond that, noting will be captured and sent to the rendered
		 *	texture, thereby eliminating the need to mask out colours etc.
		 */
		FarPlane=50
		/**
		 *	Be sure the scene captures clear color and 
		 *	render textures background color are the same.
		 */
		ClearColor=(R=0,G=0,B=0,A=255)
		bEnablePostProcess=False
		bEnableFog=False
		FrameRate=1000
		bUpdateMatrices=False
	End Object
	UICapComp=RTTComponent
	Components.Add(RTTComponent);

	CollisionType=COLLIDE_BlockAll
	Begin Object Name=CollisionCylinder
	CollisionRadius=+0012.000000
	CollisionHeight=+0034.000000
	End Object
	CylinderComponent=CollisionCylinder

	bSelected = false;
	ControllerClass= class 'TowerDefense.TDDummyController';

	Health = 100;
	HealthMax = 100;

	Range = 75.f;
	PawnTeam = 0;
	walkingOffset = 10;
	DefendRange = 600;

	WeaponUpgradeLevel = 0;

	bBeingBuilt = false;

	InventoryManagerClass=class'TowerDefense.GameInventoryManager'

	CAttackAnim[0]=(CustomAnimName="humana_ataque01",CustomAnimRate=1.0,CustomAttackCooldown=1.1);
	CAttackAnim[1]=(CustomAnimName="humana_ataque02",CustomAnimRate=1.0,CustomAttackCooldown=1.1);
	CAttackAnim[2]=(CustomAnimName="humana_ataque03",CustomAnimRate=1.0,CustomAttackCooldown=1.1);

	CBuildAnim[0]=(CustomAnimName="humana_ataque01",CustomAnimRate=1.0,CustomBuildCooldown=1.1);
	CBuildAnim[1]=(CustomAnimName="humana_ataque02",CustomAnimRate=1.0,CustomBuildCooldown=1.1);
	CBuildAnim[2]=(CustomAnimName="humana_ataque03",CustomAnimRate=1.0,CustomBuildCooldown=1.1);

	PrimaryPannel[0]=(ImageName="MoveToButton",InitialState="Inactive",customName="Move to destination",ResourceCost="",Description="Move selected unit to targeted destination.");
	PrimaryPannel[1]=(ImageName="StopButton",InitialState="Active",customName="Stop",ResourceCost="",Description="Unit stops what it was doing and go back to defending its imediate location.");
	PrimaryPannel[2]=(ImageName="HoldButton",InitialState="Inactive",customName="Hold position",ResourceCost="",Description="Unit will await new orders or react only if attacked.");
	PrimaryPannel[3]=(ImageName="AttackButton",InitialState="Inactive",customName="Attack",ResourceCost="",Description="Commands unit to attack the desired target.");
	PrimaryPannel[4]=(ImageName="PatrolButton",InitialState="Inactive",customName="Patrol area",ResourceCost="",Description="Unit will patrol the selected area.");
	PrimaryPannel[5]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	PrimaryPannel[6]=(ImageName="",InitialState="Inactive",customName="",ResourceCost="",Description="");
	PrimaryPannel[7]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	PrimaryPannel[8]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	PrimaryPannel[9]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	PrimaryPannel[10]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	PrimaryPannel[11]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");

	SecondaryPannel[0]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[1]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[2]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[3]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[4]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[5]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[6]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[7]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[8]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[9]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[10]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[11]=(ImageName="CancelButton",InitialState="",customName="Cancel",ResourceCost="",Description="Returns to the previous screen.");
}
