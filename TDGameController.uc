class TDGameController extends GamePlayerController placeable;


/************************ MOUSE AND CAMERA RELATED VARIABLES SECTION ********************************/
//Mouse event enum
enum EMouseEvent
{
  LeftMouseButton,
  RightMouseButton,
  MiddleMouseButton,
  ScrollWheelUp,
  ScrollWheelDown,
};

var Vector2D    PlayerMouse;                //Hold calculated mouse position (this is calculated in HUD)

var Vector      MouseHitWorldLocation;      //Hold where the ray casted from the mouse in 3d coordinate intersect with world geometry. We will
											//use this information for our movement target when not in pathfinding.

var Vector      MouseHitWorldNormal;        //Hold the normalized vector of world location to get direction to MouseHitWorldLocation (calculated in HUD, not used)
var Vector      MousePosWorldLocation;      //Hold deprojected mouse location in 3d world coordinates. (calculated in HUD, not used)
var Vector      MousePosWorldNormal;        //Hold deprojected mouse location normal. (calculated in HUD, used for camera ray from above)

var vector      StartTrace;                 //Hold calculated start of ray from camera
var Vector      EndTrace;                   //Hold calculated end of ray from camera to ground
var vector      RayDir;                     //Hold the direction for the ray query.
var Vector      PawnEyeLocation;            //Hold location of pawn eye for rays that query if an obstacle exist to destination to pathfind.
var Actor       TraceActor;                 //If an actor is found under mouse cursor when mouse moves, its going to end up here.

var() Color BoxColor;
var() Texture2D CursorTexture; 

var() float LowerZoomLimit, UpperZoomLimit;

var() ParticleSystem GoToParticle;

var bool bPawnNearDestination; //This indicates if pawn is within acceptable offset of destination to stop moving.
var float DistanceRemaining; //This is the calculated distance the pawn has left to get to MouseHitWorldLocation.

var bool bDragging,bWillBuild;
var array<actor> selectedActorsArray;
var bool multiSelectActive;
/****************************************************************************************************/
/****************************** INVENTORY RELATED VARIABLES SECTION *********************************/
enum WeaponTypes{
	Melee,
	Ranged,
	Magic,
};

struct weaponUpgradeData
{
  var class weaponClass;
  var() float damageMultiplier;
  var() float damageSplash;
  var() float weaponSpeed;
  var() float weaponAccel;
  var() float projLifeSpan;
  var() float projRange;
  var() vector drawscale;
  var() WeaponTypes type;

  structdefaultproperties{
	weaponClass = class 'TowerDefense.TDWeaponBase'
	damageMultiplier = 1
	drawscale = (x=1,y=1,z=1)
	projLifeSpan = 10 //seconds
	type = ""
  }
};
var() weaponUpgradeData weaponStats[3];
/****************************************************************************************************/
/******************************** TEAM RELATED VARIABLES SECTION ************************************/
var() int PlayerTeam;
/****************************************************************************************************/
var TDUnitBase PortraitCameraOn;
var class<TDUnitFighting> UnitsClass;
var class<TDUnitConstruction> BuildingsClass;
var TDUnitConstruction BeingBuilt;



/***********************************************************************************
 *					       DEFAULT FUNCTIONS SECTION                               *
 ***********************************************************************************/
simulated event PostBeginPlay(){
	super.PostBeginPlay();
	`log("Custom Controller up"@self);
}

function UpdateRotation(float DeltaRot){ }

/***********************END OF DEFAULT FUNCTIONS SECTION*****************************/

/***********************************************************************************
 *							    MOUSE INPUT SECTION                                *
 ***********************************************************************************/
// Handle mouse inputs
function HandleMouseInput(EMouseEvent MouseEvent, EInputEvent InputEvent)
{
  local TDHUD MouseInterfaceHUD;

  // Type cast to get our HUD
 MouseInterfaceHUD = TDHUD(myHUD);

  if (MouseInterfaceHUD != None)
  {
    // Detect what kind of input this is
    if (InputEvent == IE_Pressed)
    {
      // Handle pressed event
      switch (MouseEvent)
      {
		 case LeftMouseButton:
		 MouseInterfaceHUD.PendingLeftPressed = true;
		 break;

		 case RightMouseButton:
		 MouseInterfaceHUD.PendingRightPressed = true;
		 break;

		 case MiddleMouseButton:
		 MouseInterfaceHUD.PendingMiddlePressed = true;
		 break;

		 case ScrollWheelUp:
		 MouseInterfaceHUD.PendingScrollUp = true;
		 break;

		 case ScrollWheelDown:
		 MouseInterfaceHUD.PendingScrollDown = true;
		 break;

		 default:
		 break;
      }
    }
    else if (InputEvent == IE_Released)
    {
      // Handle released event
      switch (MouseEvent)
      {
		 case LeftMouseButton:
		 MouseInterfaceHUD.PendingLeftReleased = true;
		 break;

		 case RightMouseButton:
		 MouseInterfaceHUD.PendingRightReleased = true;
		 break;

		 case MiddleMouseButton:
		 MouseInterfaceHUD.PendingMiddleReleased = true;
		 break;

		 default:
		 break;
      }
    }
  }
}

exec function LeftMousePressed()
{
  HandleMouseInput(LeftMouseButton, IE_Pressed);

  bDragging=true;
  TDHUD(myHUD).BoxStart = TDHUD(myHUD).GetMouseCoordinates();

  if(!bWillBuild){
  	clearSelectedActors();
	TDHUD(myHUD).ResetHUD();
  }
  switch(TraceActor.class){
	case class'TDUnitBase':
	case class'TDUnitBuilder':
	case class'TDUnitFighting':
	case class'TDUnitConstruction':
		if(!TDUnitBase(TraceActor).bSelected && TDDummyController(Pawn(TraceActor).Controller).Team == PlayerTeam){			
			if(bWillBuild){
				doMoveAction(MouseHitWorldLocation);
			}
			else{
				SpawnSelectionPart(TraceActor);			
				addSelectedActor(TraceActor);	
				TDUnitBase(TraceActor).SetPortrait();
				TDHUD(myHUD).HUDMovie.SetFlashVariable("LowerHUD_MC.UnitNameVar","string",TDUnitBase(TraceActor).customName);
				TDHUD(myHUD).HUDMovie.SetFlashVariable("LowerHUD_MC.UnitTypeVar","string",TDUnitBase(TraceActor).customType);
				TDUnitBase(TraceActor).SetHUDButtons();
			}
		}
		break;
  }
}

exec function LeftMouseReleased()
{
  HandleMouseInput(LeftMouseButton, IE_Released);

  bDragging=false;
  TDHUD(myHUD).ActorLoc.length = 0;	
  TDHUD(myHUD).SelectedActor.length = 0;	
}

exec function RightMousePressed()
{
  HandleMouseInput(RightMouseButton, IE_Pressed);

  if((TraceActor.class == class'Terrain') && (selectedActorsArray.Length != 0))WorldInfo.MyEmitterPool.SpawnEmitter(GoToParticle,MouseHitWorldLocation,);
  switch(TraceActor.class){
	  case none:
	  case class 'Terrain':
		doMoveAction(MouseHitWorldLocation);
		break;
	  case class'TDUnitBase':
	  case class'TDUnitBuilder':
	  case class'TDUnitFighting':
		doAttackAction(TraceActor);
		break;
	  case class'TDUnitConstruction':
		if(!bWillBuild){
			if(TDDummyController(Pawn(TraceActor).Controller).Team==PlayerTeam) goToBuildAction(TraceActor);
			else doAttackAction(TraceActor);
		}
		else{
			BeingBuilt.destroy();
			bWillBuild = false;
		}
	  break;
  }
}

exec function RightMouseReleased()
{
  HandleMouseInput(RightMouseButton, IE_Released);
}

exec function MiddleMousePressed()
{
  HandleMouseInput(MiddleMouseButton, IE_Pressed);

  switch(TraceActor.class){
	  case none:
	  case class 'Terrain':
		TDGameInfo(WorldInfo.Game).TestSpawn();
		break;
	  case class'TDUnitBase':
	  case class'TDUnitBuilder':
	  case class'TDUnitFighting':
	  case class'TDUnitConstruction':
		TDWeaponBase(Pawn(TraceActor).weapon).SetParameters(weaponStats[TDDummyController(Pawn(TraceActor).Controller).WeaponUsed]);
		break;
  }
}

exec function MiddleMouseReleased()
{
  HandleMouseInput(MiddleMouseButton, IE_Released);
}

exec function MiddleMouseScrollUp()
{
  HandleMouseInput(ScrollWheelUp, IE_Pressed);

  if(TDGameCamera(PlayerCamera).Zoom>=LowerZoomLimit) TDGameCamera(PlayerCamera).Zoom -= 25;
}

exec function MiddleMouseScrollDown()
{
  HandleMouseInput(ScrollWheelDown, IE_Pressed);

  if(TDGameCamera(PlayerCamera).Zoom<=UpperZoomLimit) TDGameCamera(PlayerCamera).Zoom += 25;
}
/****************************END OF MOUSE INPUT SECTION*****************************/

/***********************************************************************************
 *			      SELECTION ARRAY MANAGEMENT FUNCTIONS SECTION                     *
 ***********************************************************************************/
function bool isSelectedInArray(Actor a){
	if (selectedActorsArray.find(a) != -1) return true;
	
	return false;
}

function addSelectedActor(Actor a){	
	//most recently clicked is in array already
	if (selectedActorsArray.find(a) != -1 ) return;	
	//add item
	selectedActorsArray.addItem(a);	
	//only 1 selected?
	if (selectedActorsArray.length <= 1) {
		multiSelectActive = false;
	}
	else {
		multiSelectActive = true;
	}
	//Spawn Particle
	SpawnSelectionPart(a);
	`log(a@"added");
}

function removeSelectedActor(Actor a){	
	//remove item
	selectedActorsArray.removeItem(a);	
	//only 1 selected?
	if (selectedActorsArray.length <= 1) {
		multiSelectActive = false;
	}
	else {
		multiSelectActive = true;
	}
	//Remove the Particle
	TDUnitBase(a).bSelected = false;
	DestroyParticle(a);
	`log(a@"removed");
}

function clearSelectedActors(){
	local int i;
	for(i=0;i<selectedActorsArray.length;i++){
		DestroyParticle(selectedActorsArray[i]);
		TDUnitBase(selectedActorsArray[i]).bSelected = false;
	}
	multiSelectActive = false;
	selectedActorsArray.length = 0;	
	`log("all removed");
}

/******************END OF ARRAY MANAGEMENT FUNCTIONS SECTION************************/

/***********************************************************************************
 *			                  SPAWN FUNCTIONS SECTION                              *
 ***********************************************************************************/
function SpawnSelectionPart(Actor actor){
	local vector attachLoc;
	`log("Should Spawn");
	`log("Now at"@actor);
	TDUnitBase(actor).bSelected = true;
	TDUnitBase(actor).SelectionParticle.ActivateSystem();
	attachLoc.X = 0;
	attachLoc.Y = 0;
	attachLoc.Z = TDUnitBase(actor).CylinderComponent.CollisionHeight-1;
	TDUnitBase(actor).SelectionParticle.SetTranslation(-attachLoc);
	actor.AttachComponent(TDUnitBase(actor).SelectionParticle);
}

function DestroyParticle(Actor actor){
	`log("Should Deactivate");
	`log("Now at"@actor);
	TDUnitBase(actor).bSelected = false;
	TDUnitBase(actor).SelectionParticle.DeactivateSystem();
}

/*************************END OF SPAWN FUNCTIONS SECTION****************************/

/***********************************************************************************
 *			              CALCULATION FUNCTIONS SECTION                            *
 ***********************************************************************************/

function bool isWithin(vector2D BoxStart, vector2D BoxEnd, vector subject){
	//`log("Start"@BoxStart@"End"@BoxEnd@"Subject"@subject);
	if(subject.X > BoxStart.X && subject.X < BoxEnd.X){
		if(subject.Y > BoxStart.Y && subject.Y < BoxEnd.Y)
			return true;
		else return false;
	}else return false;
}

/********************END OF CALCULATION FUNCTIONS SECTION***************************/

/***********************************************************************************
 *  		                CONTROLLER ACTIONS SECTION                             *
 ***********************************************************************************/
function doMoveAction(vector toWhere){
	local int i;
	if(selectedActorsArray.Length != 0){
  		for(i=0;i<selectedActorsArray.Length;i++){
			if(Pawn(selectedActorsArray[i]).IsA('TDUnitConstruction')) continue;
			if(!Pawn(selectedActorsArray[i]).Controller.IsInState('Idle')){
				TDDummyController(Pawn(selectedActorsArray[i]).Controller).bBuild = false;
				if(BeingBuilt!=none && BeingBuilt.IsInState('Building')) 
					BeingBuilt.PushState('BuildUnfinished');
				Pawn(selectedActorsArray[i]).Controller.PopState(true);
			}
			//Our pawn has been ordered to a single location on mouse release.
			//Simulate a firing bullet. If it would be ok (clear sight) then we can move to and simply ignore pathfinding.
			if(FastTrace(MouseHitWorldLocation, PawnEyeLocation,, true))
			{
				//Simply move to destination.
				TDDummyController(Pawn(selectedActorsArray[i]).Controller).MovePawnToDestination(toWhere);
			}
			else
			{
				//fire up pathfinding
				TDDummyController(Pawn(selectedActorsArray[i]).Controller).ExecutePathFindMove(toWhere);
			}
			if(bWillBuild) TDDummyController(Pawn(selectedActorsArray[i]).Controller).bBuild = true;
  		}
	  }
	  bWillBuild = false;
}

function doAttackAction(actor attackWhom){
	local int i;
	local vector newLoc,aux;
	if(selectedActorsArray.Length != 0){
  		for(i=0;i<selectedActorsArray.Length;i++){
			aux = selectedActorsArray[i].Location - attackWhom.Location;
			if(VSize2d(aux)>TDUnitBase(selectedActorsArray[i]).Range){
				newLoc = attackWhom.Location + aux*TDUnitBase(selectedActorsArray[i]).Range/VSize2D(aux);
				if(!Pawn(selectedActorsArray[i]).Controller.IsInState('Attack')) doMoveAction(newLoc);
			}
			else Pawn(selectedActorsArray[i]).Controller.PushState('Attack');
			if(TDDummyController(Pawn(selectedActorsArray[i]).Controller).Team != TDDummyController(Pawn(attackWhom).Controller).Team) TDDummyController(Pawn(selectedActorsArray[i]).Controller).TargetPawn = attackWhom;
  		}
	}
}

function doBuildAction(string buildWhat){
	local TDUnitConstruction BuildArche;

	bWillBuild = true;
	switch(buildWhat){
		case"Necropolis": BuildArche = TDGameInfo(WorldInfo.Game).ArchetypeManager.Buildings[0]; break;
	}
	BeingBuilt = Spawn(BuildingsClass,,'BeingBuilt',MouseHitWorldLocation,,BuildArche);
	BeingBuilt.UseBuildTemplate();
	BeingBuilt.SetTeam(PlayerTeam);                 //Change to Pawn's Team
}

function goToBuildAction(actor buildWhat){
	local int i;
	local vector newLoc,aux;
	if(selectedActorsArray.Length != 0){
  		for(i=0;i<selectedActorsArray.Length;i++){
			aux = selectedActorsArray[i].Location - buildWhat.Location;
			if(VSize2d(aux)>TDUnitBase(selectedActorsArray[i]).Range){
				newLoc = buildWhat.Location + aux*TDUnitBase(selectedActorsArray[i]).Range/VSize2D(aux);
				if(!Pawn(selectedActorsArray[i]).Controller.IsInState('Build')) doMoveAction(newLoc);
			}
			else Pawn(selectedActorsArray[i]).Controller.PushState('Build');
			TDDummyController(Pawn(selectedActorsArray[i]).Controller).bBuild = true;
  		}
	}
}
/*************************END OF CONTROLLER ACTIONS SECTION*************************/

/***********************************************************************************
 *					                EVENTS SECTION                                 *
 ***********************************************************************************/
event PlayerTick( float DeltaTime ){
	local TDUnitBase tempActor;
	local vector CaptureLoc;
	local rotator CaptureRot;
	local vector tempBuildLoc;

	super.PlayerTick(DeltaTime);

	if(PortraitCameraOn!=none){
		CaptureLoc = PortraitCameraOn.Location + vect(35,0,45);
		/*CaptureLoc = PortraitCameraOn.Location;
		CaptureLoc.X += PortraitCameraOn.Mesh.Bounds.BoxExtent.X;
		CaptureLoc.Z += PortraitCameraOn.Mesh.Bounds.BoxExtent.Z*3/4;*/
		CaptureRot = Rotator(Normal(PortraitCameraOn.Location - CaptureLoc));
		CaptureRot.Pitch = 0;
		PortraitCameraOn.UICapComp.SetView(CaptureLoc, CaptureRot);
	}

	if(bWillBuild){
		if(BeingBuilt!=none){
			tempBuildLoc = MouseHitWorldLocation;
			tempBuildLoc.Z = 30;
			BeingBuilt.setLocation(tempBuildLoc);
		}
	}

	if(TraceActor!=none){
		if(TraceActor.class!=none){
			switch(TraceActor.class){
			  case class'TDUnitBase':
			  case class'TDUnitBuilder':
			  case class'TDUnitFighting':
				if(TDDummyController(Pawn(TraceActor).Controller).Team == PlayerTeam) TDHUD(myHUD).CursorColorChange(2);
				else TDHUD(myHUD).CursorColorChange(1);
				break;
			  case class'TDUnitConstruction':
				if(!bWillBuild){
					if(TDDummyController(Pawn(TraceActor).Controller).Team == PlayerTeam) TDHUD(myHUD).CursorColorChange(2);
					else TDHUD(myHUD).CursorColorChange(1);
				}
				break;
			  case class 'Terrain':
			  default:
				TDHUD(myHUD).CursorColorChange(0);
				break;
			}
		}
	}

	if(bDragging && !bWillBuild){	
		foreach VisibleActors(class'TDUnitBase', tempActor)
		{
			if (TDHUD(myHUD).SelectedActor.find(tempActor)==-1)TDHUD(myHUD).SelectedActor.addItem(tempActor);

			if(TDHUD(myHUD).ActorLoc.length!=0){
				if(isWithin(TDHUD(myHUD).BoxStart,TDHUD(myHUD).BoxEnd, TDHUD(myHUD).ActorLoc[TDHUD(myHUD).SelectedActor.find(tempActor)])){	
					if(!tempActor.bSelected && TDHUD(myHUD).SelectedActor.Length!=0 && TDDummyController(tempActor.Controller).Team == PlayerTeam){		
						TDHUD(myHUD).ResetHUD();
						SpawnSelectionPart(tempActor);
						addSelectedActor(tempActor);
						tempActor.SetPortrait();
						TDHUD(myHUD).HUDMovie.SetFlashVariable("LowerHUD_MC.UnitNameVar","string",tempActor.customName);
						TDHUD(myHUD).HUDMovie.SetFlashVariable("LowerHUD_MC.UnitTypeVar","string",tempActor.customType);
						tempActor.SetHUDButtons();
					}
				}
			}
		}
	}
}
/******************************END OF EVENTS SECTION*********************************/

/***********************************************************************************
 *					                STATES SECTION                                 *
 ***********************************************************************************/

/*****************************END OF STATES SECTION******************************/

DefaultProperties
{
	CameraClass=class'TowerDefense.TDGameCamera';
	InputClass=class'TowerDefense.MouseInterfacePlayerInput';

	GoToParticle = ParticleSystem'Gustavo_Pacote1.Effects.ParticleMouse2';                      //Short Term Particle

	UpperZoomLimit = 400;
	LowerZoomLimit = -200;

	bPawnNearDestination = false;
	bDragging=false;
	bWillBuild = false;

	UnitsClass = class'TowerDefense.TDUnitFighter';
	BuildingsClass = class'TowerDefense.TDUnitConstruction';

	PlayerTeam = 0;
	BoxColor = (R=11,G=183,B=255,A=255)
	CursorTexture=Texture2D'EngineResources.Cursors.Arrow'

	//Melee Starting Upgrades
	weaponStats[0] ={(damageMultiplier=3,
					  damageSplash = 0,
					  weaponSpeed = 30,
	                  weaponAccel = 300,
	                  projLifeSpan = 0.7,
	                  projRange = 95.f,
	                  type = 0)};

	//Ranged Weapon Upgrades
	weaponStats[1] ={(damageMultiplier=2,
					  damageSplash = 0,
					  weaponSpeed = 1000,
	                  weaponAccel = 300,
	                  projLifeSpan = 3,
	                  projRange = 1000.f,
	                  type = 1)};

	//Magic Weapon Upgrades
	weaponStats[2] ={(damageMultiplier=1,
					  damageSplash = 50,
					  weaponSpeed = 2000,
	                  weaponAccel = 30,
	                  projLifeSpan = 5,
	                  projRange = 2000.f,
	                  type = 2)};
}
