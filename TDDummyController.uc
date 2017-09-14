class TDDummyController extends GameAIController;

var bool bPawnNearDestination; //This indicates if pawn is within acceptable offset of destination to stop moving.
var float DistanceRemaining; //This is the calculated distance the pawn has left to get to MouseHitWorldLocation.
var bool bisMoving,bWasChasing;

/** Temp Destination for navmesh destination */
var() Vector TempDest;
var bool GotToDest;
var Vector NavigationDestination;
var Vector2D DistanceCheck;
/*****************************************************************/
var Actor TargetPawn;
var bool CurrentTargetIsReachable;

var vector PawnScreenPos,DefendLoc;
var int Team;
var int WeaponUsed;

var float walkingOffset;
var float DefendRange;

var bool bBuild;


/***********************************************************************************
 *					        MOVEMENT FUNCTIONS SECTION                             *
 ***********************************************************************************/
event Tick( float DeltaTime )
{
	local Vector PawnXYLocation,aux,newLoc;
	local Vector DestinationXYLocation;
	local Vector    Destination;
	local Vector2D  DistanceCheck;

	super.Tick(DeltaTime);

	//`log(GetStateName());

	if(bisMoving && Pawn.Class!=class 'TDUnitConstruction'){
		if(TDUnitFighting(Pawn).bTooClose){
			while(VSize2D(aux)<TDUnitBase(Pawn).Range){
				NavigationDestination.X += RandRange(-walkingOffset,walkingOffset);
				NavigationDestination.Y += RandRange(-walkingOffset,walkingOffset);
				aux = Pawn.Location - NavigationDestination;
				newLoc = NavigationDestination + aux*TDUnitBase(Pawn).Range/VSize2D(aux);
			}
			SetDestinationPosition(newLoc);
			if(TargetPawn!=none) Pawn.SetRotation(Rotator(newLoc - Pawn.Location));
			TDUnitFighting(Pawn).bTooClose = false;
		}
		//Get player destination for a check on distance left. (calculate distance)
		if(bWasChasing && !bPawnNearDestination){
			aux = Pawn.Location - TargetPawn.Location;
			newLoc = TargetPawn.Location + aux*TDUnitBase(Pawn).Range/VSize2D(aux);
			NavigationDestination = newLoc;
			SetDestinationPosition(newLoc);
		}
		Destination = GetDestinationPosition();
		DistanceCheck.X = Destination.X - Pawn.Location.X;
		DistanceCheck.Y = Destination.Y - Pawn.Location.Y;
		DistanceRemaining = Sqrt((DistanceCheck.X*DistanceCheck.X) + (DistanceCheck.Y*DistanceCheck.Y));
		
		bPawnNearDestination = DistanceRemaining < TDUnitBase(Pawn).Range;

		PawnXYLocation.X = Pawn.Location.X;
		PawnXYLocation.Y = Pawn.Location.Y;

		DestinationXYLocation.X = GetDestinationPosition().X;
		DestinationXYLocation.Y = GetDestinationPosition().Y;

		if(TargetPawn!=none || !IsInState('NavMeshSeeking') || !IsInState('MoveMouseClick')) Pawn.SetRotation(Rotator(DestinationXYLocation - PawnXYLocation));
	}

	if(TargetPawn!=none && IsInState('Attack'))	Pawn.SetRotation(Rotator(TargetPawn.Location - Pawn.Location));
	if(!IsInState('Build') && TDGameInfo(WorldInfo.Game).Player.BeingBuilt!=none && bBuild){
		if(VSize(Pawn.Location - TDGameInfo(WorldInfo.Game).Player.BeingBuilt.Location) < 95){
			if(TDGameInfo(WorldInfo.Game).Player.BeingBuilt.IsInState('BuildUnfinished')) TDGameInfo(WorldInfo.Game).Player.BeingBuilt.PopState();
			TDGameInfo(WorldInfo.Game).Player.BeingBuilt.ResetMeshToNormal();
			PushState('Build');                           		
		}
	}
	if(Pawn == none) self.Destroy();
}

function ExecutePathFindMove(vector Dest)
{
	//Lets find path with navmesh
	`Log("Launching PathFind with navmesh");
	NavigationDestination = Dest;
	SetDestinationPosition(Dest);
	PushState('NavMeshSeeking');
}
function MovePawnToDestination(vector Dest)
{
	//`log("Moving to location without pathfinding!");
	`log("MovePawn"@Pawn);
    SetDestinationPosition(Dest);
    PushState('MoveMouseClick');
}

function StopLingering(){
	PopState(true);
}
/***********************END OF MOVEMENT FUNCTIONS SECTION***************************/

/***********************************************************************************
 *					                EVENTS SECTION                                 *
 ***********************************************************************************/
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	//TDUnitBase(inPawn).bSelected = true;
	`log(inPawn@"Possessed, bSelected"@TDUnitBase(inPawn).bSelected);
    super.Possess(inPawn, bVehicleTransition);	
}

event UnPossess()
{
	TDUnitBase(Pawn).bSelected = false;
	`log(Pawn@"Unpossessed, bSelected"@TDUnitBase(Pawn).bSelected);
	super.Unpossess();
}

/******************************END OF EVENTS SECTION*********************************/

/***********************************************************************************
 *					                STATES SECTION                                 *
 ***********************************************************************************/
state Defend{
local TDUnitBase P,Nearest;
local float Distance,NearestDist;
local vector aux,newLoc,ChaseLoc;

function TDUnitBase GetClosestPawn(Vector LocationFrom, optional float MaxTestDistance = DefendRange){
   local TDUnitBase TempPawn, CurrentPawn;
   
   foreach WorldInfo.AllPawns(class'TowerDefense.TDUnitBase', TempPawn, LocationFrom, MaxTestDistance){
	  if (TempPawn.IsInState('Dying') || TempPawn==Pawn /*|| !CanSee(TempPawn)*/) continue;
	  if (TempPawn != None && TDDummyController(TempPawn.Controller).Team!=Team){
		  if(CurrentPawn == none || (VSize(TempPawn.Location - LocationFrom) < VSize(CurrentPawn.Location - LocationFrom)))
			 CurrentPawn = TempPawn;
	  }
   }
   if(CurrentPawn==none) GoToState('Idle');
   else return CurrentPawn;
}
event PushedState(){Pawn.SetMovementPhysics();}

Begin:
	if(Pawn.IsInState('Building')) {PopState(); `log("Was Building");}

	Nearest = GetClosestPawn(Pawn.Location);
	TargetPawn = Nearest;

Defending:
	if (Nearest!= none){
		Distance = VSize2D(Pawn.Location - Nearest.Location);
		if (Distance <= DefendRange){
			if (TargetPawn!=none){
				if(WeaponUsed==0) TDUnitBase(Pawn).Range = 75.f;
				else TDUnitBase(Pawn).Range = TDGameInfo(WorldInfo.Game).Player.weaponStats[WeaponUsed].projRange;
				aux = Pawn.Location - TargetPawn.Location;
				if(VSize2D(aux)>TDGameInfo(WorldInfo.Game).Player.weaponStats[WeaponUsed].projRange){
					bWasChasing = true;
					newLoc = TargetPawn.Location + aux*TDUnitBase(Pawn).Range/VSize2D(aux);
					ExecutePathFindMove(newLoc);
				}
				else{
					bWasChasing = false;
					PushState('Attack');
				}
			}
			else GoTo('Defending');
		}
	}
	GoTo('Begin');
}

auto state Idle{
   local TDUnitBase TempPawn, EnemyPawn, AllyPawn; 
   event PushedState(){Pawn.SetMovementPhysics();}
   event PoppedState(){Pawn.SetMovementPhysics();}

Begin:
   foreach WorldInfo.AllPawns(class'TowerDefense.TDUnitBase', TempPawn, Pawn.Location, DefendRange){
	  if (TempPawn.IsInState('Dying') /*|| TempPawn==Pawn || !CanSee(TempPawn)*/) continue;
	  if (TempPawn != None && TDDummyController(TempPawn.Controller).Team!=Team){
		  if(EnemyPawn == none || (VSize(TempPawn.Location - Pawn.Location) < VSize(EnemyPawn.Location - Pawn.Location)))
			 EnemyPawn = TempPawn;
	  }
	  else if(TempPawn != None)
		if(AllyPawn == none || (VSize(TempPawn.Location - Pawn.Location) < VSize(AllyPawn.Location - Pawn.Location)))
			 AllyPawn = TempPawn;
   }
   if(EnemyPawn==none){
	TargetPawn = AllyPawn;
	sleep(0.2);
	GoTo('Begin');
   }
   else{
	TargetPawn = EnemyPawn;
	GoToState('Defend');
   }
}

state MoveMouseClick{
	    event PoppedState()
        {
                `log("MoveMouseClick state popped, disabling StopLingering timer.");
                //Disable all active timers to stop lingering if they are active.
                if(IsTimerActive(nameof(StopLingering)))
                {
                        ClearTimer(nameof(StopLingering));
						Pawn.ZeroMovementVariables();
                }
				bisMoving = false;
        }
		event PausedState(){
				bisMoving = false;
        }
		event ContinuedState(){
				bisMoving = true;
        }
        event PushedState()
        {
                //Set a function timer. If the pawn is stuck it will stop moving
                //by itself.
                SetTimer(3, false, nameof(StopLingering));
                if (Pawn != None)
                {
                        // make sure the pawn physics are initialized
                        Pawn.SetMovementPhysics();
						bisMoving = true;
                }
        }
	Begin:
		if(Pawn.IsInState('Building')) {PopState(); `log("Was Building");}

        while(!bPawnNearDestination)
        {
                `log("Simple Move in progress");
				MoveTo(GetDestinationPosition());
        }
        `log("MoveMouseClick: Pawn is near destination, go out of this state");
        PopState();
}

state NavMeshSeeking{
	local int failSafe;
	event PausedState(){
				bisMoving = false;
        }
		event ContinuedState(){
				bisMoving = true;
        }
		event PushedState(){
                `log("BEGIN STATE SCRIPTEDMOVE");
                // while we have a valid pawn and move target, and
                // we haven't reached the target yet
				//SetTimer(0.2, false, nameof(StopLingering));
				bisMoving = true;
				failSafe = 10;
        }
		event PoppedState(){
				/*if(IsTimerActive(nameof(StopLingering)))
                {
                        ClearTimer(nameof(StopLingering));
						Pawn.ZeroMovementVariables();
                }*/
				bisMoving = false;
        }
        function bool FindNavMeshPath(){
                // Clear cache and constraints (ignore recycling for the moment)
                NavigationHandle.PathConstraintList = none;
                NavigationHandle.PathGoalList = none;

                // Create constraints
                class'NavMeshPath_Toward'.static.TowardPoint( NavigationHandle, NavigationDestination );
                class'NavMeshGoal_At'.static.AtLocation( NavigationHandle, NavigationDestination, 50, );

                // Find path
                return NavigationHandle.FindPath();
        }

        Begin:	
		if(Pawn.IsInState('Building')) {PopState(); `log("Was Building");}

				//if(bWasChasing) SetDestinationPosition(TargetPawn.Location);
				NavigationDestination = GetDestinationPosition();
                if(FindNavMeshPath()){
                        NavigationHandle.SetFinalDestination(NavigationDestination);
                        `log("FindNavMeshPath returned TRUE");
                        FlushPersistentDebugLines();
                        //NavigationHandle.DrawPathCache(,TRUE);

                        //!Pawn.ReachedPoint here, i do not know how to handle second param, this makes the pawn
                        //stop at the first navmesh patch
                        `Log("GetDestinationPosition before navigation (destination)"@NavigationDestination);
                        while(Pawn != None && !Pawn.ReachedPoint(NavigationDestination, None) && failSafe > 0){
                                if(NavigationHandle.PointReachable( NavigationDestination )){
                                        // then move directly to the actor
                                        MoveTo(NavigationDestination, None, , true );
                                        `Log("Point is reachable");
                                }
                                else{
                                        `Log("Point is not reachable");
                                        // move to the first node on the path
                                        if(NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius())){
                                                `Log("Got next move location in TempDest " @ TempDest);
                                                // suggest move preparation will return TRUE when the edge's
                                                // logic is getting the bot to the edge point
                                                // FALSE if we should run there ourselves
                                                if (!NavigationHandle.SuggestMovePreparation(TempDest,self)){
                                                        `Log("SuggestMovePreparation in TempDest " @ TempDest);
                                                        MoveTo(TempDest, None, , true );
                                                }
                                        }
                                }
                                DistanceCheck.X = NavigationDestination.X - Pawn.Location.X;
                                DistanceCheck.Y = NavigationDestination.Y - Pawn.Location.Y;
                                DistanceRemaining = Sqrt((DistanceCheck.X*DistanceCheck.X) + (DistanceCheck.Y*DistanceCheck.Y));
                                `Log("distance from pawn"@Pawn.Location@" to location "@ NavigationDestination@" is "@DistanceRemaining );
                                `Log("Is pawn valid ?" @Pawn);
                                GotToDest = Pawn.ReachedPoint(NavigationDestination, None);
                                `Log("Has pawn reached point ?"@GotToDest);
								               
								if(TargetPawn!= none && DistanceRemaining < TDUnitBase(Pawn).Range){
									if(!bBuild){
										bWasChasing = false;
                                		PushState('Attack');                           		
										`log("POPPING STATE!");
										Pawn.ZeroMovementVariables();
										// return to the previous state
										PopState();
									}
									/*else{
										if(VSize(Pawn.Location - TDGameInfo(WorldInfo.Game).Player.BeingBuilt.Location) < 70){
											TDGameInfo(WorldInfo.Game).Player.BeingBuilt.ResetMeshToNormal();
											PushState('Build');                           		
											`log("POPPING STATE!");
											Pawn.ZeroMovementVariables();
											// return to the previous state
											PopState();
										}
									}*/
								}
								failSafe--;
								if(failSafe<0){
									Pawn.ZeroMovementVariables();
									// return to the previous state
									PopState();
								}
                        }
                }
                else{
                        //give up because the nav mesh failed to find a path
                        `warn("FindNavMeshPath failed to find a path to"@ScriptedMoveTarget);
                        ScriptedMoveTarget = None;
                } 
}

state Attack{
	local bool bAttackCooldown;
	local int attackCount;
	local vector aux;
	local float Distance;

	function AttackAnim(actor target){
		if (target == Pawn || target == none) PopState(true);
		if (!bAttackCooldown){
			Pawn.SetRotation(Rotator(TargetPawn.Location - Pawn.Location));
			bAttackCooldown = true;
			Pawn.StartFire(0);
			TDUnitBase(Pawn).TopHalfAnimSlot.PlayCustomAnim(TDUnitBase(Pawn).CAttackAnim[attackCount].CustomAnimName, TDUnitBase(Pawn).CAttackAnim[attackCount].CustomAnimRate, , , false); 
			SetTimer(TDUnitBase(Pawn).CAttackAnim[attackCount].CustomAttackCooldown,false,'AttackCooldown');
		}
	}
	function AttackCooldown(){
		attackCount = Rand(TDUnitBase(Pawn).CAttackAnim.Length);
		bAttackCooldown = false;
		Pawn.StopFire(0);
		GoToState('Attack', 'Begin');
	}
	/*event PushedState(){

	}*/
	event PoppedState(){
		`log("Attack Popped");
		if(IsTimerActive(nameof(AttackCooldown))){
			ClearTimer(nameof(AttackCooldown));
        }
		Pawn.ZeroMovementVariables();
	}

Begin:
	if(Pawn.IsInState('Building')) {PopState(); `log("Was Building");}

	aux = Pawn.Location - TargetPawn.Location;
	Distance = VSize2D(aux);
	if ((TDUnitBase(TargetPawn).Health <= 0) || (TargetPawn == Pawn) || (TargetPawn == none) || (Distance > TDGameInfo(WorldInfo.Game).Player.weaponStats[WeaponUsed].projRange)){
		`log("Target Pawn Dead, Null or Too Far");
		/*if(bBuild){
			TDGameInfo(WorldInfo.Game).Player.BeingBuilt.ResetMeshToNormal();
			PushState('Build');
		}*/
		PopState();
	}
	else{
		//`log("Attacking");
		AttackAnim(TargetPawn);
	}
}

state Build{
	local bool bBuildCooldown;
	local int buildCount;
	local vector aux;
	local float Distance;

	function BuildAnim(actor target){
		if (target == none) PopState(true);
		if (!bBuildCooldown){
			Pawn.SetRotation(Rotator(target.Location - Pawn.Location));
			bBuildCooldown = true;
			TDUnitBase(Pawn).TopHalfAnimSlot.PlayCustomAnim(TDUnitBase(Pawn).CBuildAnim[buildCount].CustomAnimName, TDUnitBase(Pawn).CBuildAnim[buildCount].CustomAnimRate, , , false); 
			SetTimer(TDUnitBase(Pawn).CBuildAnim[buildCount].CustomBuildCooldown,false,'BuildCooldown');
		}
	}
	function BuildCooldown(){
		buildCount = Rand(TDUnitBase(Pawn).CAttackAnim.Length);
		bBuildCooldown = false;
		GoToState('Build', 'Begin');
	}
	event PushedState(){
		Pawn.ZeroMovementVariables();
		TDGameInfo(WorldInfo.Game).Player.BeingBuilt.builderNum++;
	}

	event PoppedState(){
		if(TDGameInfo(WorldInfo.Game).Player.BeingBuilt.builderNum>0) TDGameInfo(WorldInfo.Game).Player.BeingBuilt.builderNum--;
	}

Begin:
	if(Pawn.IsInState('Building')) {PopState(); `log("Was Building");}

	aux = Pawn.Location - TDGameInfo(WorldInfo.Game).Player.BeingBuilt.Location;
	Distance = VSize2D(aux);
	if(Distance < 95){
		`log(TDGameInfo(WorldInfo.Game).Player.BeingBuilt.GetStateName());
		if(!TDGameInfo(WorldInfo.Game).Player.BeingBuilt.IsInState('Building')) 
			PopState();
		BuildAnim(TDGameInfo(WorldInfo.Game).Player.BeingBuilt);
	}
	else{
		TDGameInfo(WorldInfo.Game).Player.BeingBuilt.PushState('BuildUnfinished');
		bBuild = false;
	}
}
/*****************************END OF STATES SECTION******************************/

DefaultProperties
{
	bPawnNearDestination = false;
	bisMoving = false;
	bBuild = false;

	Team = 0;
	WeaponUsed = 0;
}
