class TDGameCamera extends Camera;

var vector Loc;
var float Zoom;
var int SidesMoveFactor;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	`log("Custom Camera up");
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local vector		Pos, HitLocation, HitNormal;
	local rotator		Rot;
	local Actor			HitActor;
	local CameraActor	CamActor;
	local bool			bDoNotApplyModifiers;
	local TPOV			OrigPOV;

	// store previous POV, in case we need it later
	OrigPOV = OutVT.POV;

	// Default FOV on viewtarget
	OutVT.POV.FOV = DefaultFOV;

	// Viewing through a camera actor.
	CamActor = CameraActor(OutVT.Target);
	if( CamActor != None )
	{
		CamActor.GetCameraView(DeltaTime, OutVT.POV);

		// Grab aspect ratio from the CameraActor.
		bConstrainAspectRatio	= bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
		OutVT.AspectRatio		= CamActor.AspectRatio;

		// See if the CameraActor wants to override the PostProcess settings used.
		CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
		CamPostProcessSettings = CamActor.CamOverridePostProcess;
	}
	else
	{
		// Give Pawn Viewtarget a chance to dictate the camera position.
		// If Pawn doesn't override the camera view, then we proceed with our own defaults
		if( Pawn(OutVT.Target) == None ||
			!Pawn(OutVT.Target).CalcCamera(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV) )
		{
			// don't apply modifiers when using these debug camera modes.
			bDoNotApplyModifiers = TRUE;
			CameraStyle = 'Fixed';

			switch( CameraStyle )
			{
				case 'Fixed'		:	// do not update, keep previous camera position by restoring
										// saved POV, in case CalcCamera changes it but still returns false									
										//OutVT.POV = OrigPOV;
										Loc.X+=MouseInterfacePlayerInput(PCOwner.PlayerInput).Forward/100;
										Loc.Y+=MouseInterfacePlayerInput(PCOwner.PlayerInput).Strafe/100;
										Loc.Z=500.0;

										if(!TDGameController(PCOwner).bDragging){
											if(MouseInterfacePlayerInput(PCOwner.PlayerInput).bLeftEdge)Loc.Y-=SidesMoveFactor/1.2;
											else if(MouseInterfacePlayerInput(PCOwner.PlayerInput).bRightEdge)Loc.Y+=SidesMoveFactor/1.2;
											if(MouseInterfacePlayerInput(PCOwner.PlayerInput).bTopEdge)Loc.X+=SidesMoveFactor;
											else if(MouseInterfacePlayerInput(PCOwner.PlayerInput).bBottomEdge)Loc.X-=SidesMoveFactor;
										}

										Rot.Pitch = (-60*DegToRad)*RadToUnrRot;
									 	Rot.Roll = 0;
										Rot.Yaw = 0;

										//Set zooming.
										Pos = Loc - Vector(Rot) * FreeCamDistance;
										Pos.Z += Zoom;

										HitActor = Trace(HitLocation, HitNormal, Pos, Loc, FALSE, vect(12,12,12));
										OutVT.POV.Location = (HitActor == None) ? Pos : HitLocation;
										OutVT.POV.Rotation = Rot;
										break;

				case 'ThirdPerson'	: // Simple third person view implementation
				case 'FreeCam'		:
				case 'FreeCam_Default':
										Loc = OutVT.Target.Location;
										Rot = OutVT.Target.Rotation;

										OutVT.Target.GetActorEyesViewPoint(Loc, Rot);
										if( CameraStyle == 'FreeCam' || CameraStyle == 'FreeCam_Default' )
										{
											Rot = PCOwner.Rotation;
										}

										Loc += FreeCamOffset >> Rot;

										// @fixme, respect BlockingVolume.bBlockCamera=false
										HitActor = Trace(HitLocation, HitNormal, Pos, Loc, FALSE, vect(12,12,12));
										OutVT.POV.Location = (HitActor == None) ? Pos : HitLocation;
										OutVT.POV.Rotation = Rot;
										break;

				case 'Isometric':
									
										// fix Camera rotation
										 										
										 Rot = OutVT.Target.Rotation;
										 OutVT.Target.GetActorEyesViewPoint(Loc, Rot);
										 Rot = PCOwner.Rotation;

										 Rot.Pitch = (PCOwner.PlayerInput.aLookUp);//    *DegToRad) * RadToUnrRot;
									 	 Rot.Roll =  (0*DegToRad) * RadToUnrRot;
										 Rot.Yaw =   (PCOwner.PlayerInput.aTurn    *DegToRad) * RadToUnrRot;
										

										// fix Camera position offset from avatar.
										Loc.X = PCOwner.Pawn.Location.X;// - 64;
										Loc.Y = PCOwner.Pawn.Location.Y;// - 64;
										Loc.Z = PCOwner.Pawn.Location.Z + 16;// + 156; 

										//Set zooming.
										Pos = Loc - Vector(Rot) * FreeCamDistance;

										Loc += FreeCamOffset >> Rot;

										// @fixme, respect BlockingVolume.bBlockCamera=false
										HitActor = Trace(HitLocation, HitNormal, Pos, Loc, FALSE, vect(12,12,12));
										OutVT.POV.Location = (HitActor == None) ? Pos : HitLocation;
										OutVT.POV.Rotation = Rot;

										/*OutVT.POV.Location = Pos;
										OutVT.POV.Rotation = Rot;*/
										break;

				case 'FirstPerson'	: // Simple first person, view through viewtarget's 'eyes'
				default				:	OutVT.Target.GetActorEyesViewPoint(OutVT.POV.Location, OutVT.POV.Rotation);
										break;

			}
		}
	}

	SetRotation(OutVT.POV.Rotation);

	if( !bDoNotApplyModifiers )
	{
		// Apply camera modifiers at the end (view shakes for example)
		ApplyCameraModifiers(DeltaTime, OutVT.POV);
	}
	////`log( WorldInfo.TimeSeconds  @ GetFuncName() @ OutVT.Target @ OutVT.POV.Location @ OutVT.POV.Rotation @ OutVT.POV.FOV );
	}

DefaultProperties
{
	FreeCamDistance = 192.f;
	Zoom = 0;
	SidesMoveFactor = 12;
}
