class TDHUD extends HUD;

var FontRenderInfo  TextRenderInfo;         //Font for outputed text to viewport

// The texture which represents the cursor on the screen
var Texture2D CursorTexture; 
// The color of the cursor
var Color CursorColor[3];
var int CursorColorChoice;

// Pending left mouse button pressed event
var bool PendingLeftPressed;
// Pending left mouse button released event
var bool PendingLeftReleased;
// Pending right mouse button pressed event
var bool PendingRightPressed;
// Pending right mouse button released event
var bool PendingRightReleased;
// Pending middle mouse button pressed event
var bool PendingMiddlePressed;
// Pending middle mouse button released event
var bool PendingMiddleReleased;
// Pending mouse wheel scroll up event
var bool PendingScrollUp;
// Pending mouse wheel scroll down event
var bool PendingScrollDown;
// Cached mouse world origin
var Vector CachedMouseWorldOrigin;
// Cached mouse world direction
var Vector CachedMouseWorldDirection;
// Last mouse interaction interface
var MouseInterfaceInteractionInterface LastMouseInteractionInterface;

var vector2D BoxStart,BoxEnd;
var Color BoxColor;
var vector StartBox3DWorld,StartBox3DNormal,EndBox3DWorld,EndBox3DNormal,aux;

var array<TDUnitBase> SelectedActor;
var array<vector> ActorLoc;

var int JustStarted;

var TDGfxHUD HUDMovie;
var GFxObject HudMovieSize;

var() array<Slots> PrimaryPannel,SecondaryPannel;


simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	`log("Custom HUD up");
	BoxColor = TDGameController(PlayerOwner).BoxColor;
	CursorTexture = TDGameController(PlayerOwner).CursorTexture;

	HudMovie = new class'TDGfxHUD'; 
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init();

	HudMovieSize = HudMovie.GetVariableObject("Stage.originalRect");
	InitHUDButtons();
}

function DrawHUD()
{
	local string StringMessage;
	local int i;
	local vector tempLoc,tempBoxStart,tempBoxEnd;

	//Display traced actor class under mouse cursor for fun :)
	if(TDGameController(PlayerOwner).TraceActor != none)
	{
		StringMessage = "Actor selected:"@TDGameController(PlayerOwner).TraceActor;
	}

	// now draw string with GoldColor color defined in defaultproperties. note you can
	// alternatively use MakeColor(R,G,B,A)
	Canvas.DrawColor = MakeColor(255,183,11,255);
	Canvas.SetPos( 250, 50 );
	Canvas.DrawText( StringMessage, false, , , TextRenderInfo );

	if(!TDGameController(PlayerOwner).bWillBuild){
		if(SelectedActor.Length!=0)
				for(i=0;i<SelectedActor.Length;i++)
					ActorLoc[i] = Canvas.Project(SelectedActor[i].Location);
	
		if(TDGameController(PlayerOwner).bDragging){		
			BoxEnd = GetMouseCoordinates();		
			Canvas.DeProject(BoxStart, StartBox3DWorld, StartBox3DNormal);
			Canvas.DeProject(BoxEnd, EndBox3DWorld, EndBox3DNormal);

			Canvas.SetPos(GetMouseCoordinates().X-CursorTexture.SizeY,GetMouseCoordinates().Y-CursorTexture.SizeX);
			Canvas.Draw2DLine (BoxStart.X,BoxStart.Y,BoxStart.X,BoxEnd.Y,BoxColor);
			Canvas.Draw2DLine (BoxStart.X,BoxStart.Y,BoxEnd.X,BoxStart.Y,BoxColor);
			Canvas.Draw2DLine (BoxEnd.X,BoxStart.Y,BoxEnd.X,BoxEnd.Y,BoxColor);
			Canvas.Draw2DLine (BoxStart.X,BoxEnd.Y,BoxEnd.X,BoxEnd.Y,BoxColor);

			if(SelectedActor.Length!=0)
				for(i=0;i<SelectedActor.Length;i++){
					tempLoc = Canvas.Project(SelectedActor[i].Location);
					tempBoxStart.X = BoxStart.X;
					tempBoxStart.Y = BoxStart.Y;
					tempBoxStart.Z = 0;
					tempBoxEnd.X = BoxEnd.X;
					tempBoxEnd.Y = BoxEnd.Y;
					tempBoxEnd.Z = 0;
					if(VSize(tempLoc)>VSize(tempBoxStart) && VSize(tempLoc)<VSize(tempBoxEnd))
						DrawBar("",SelectedActor[i].Health, SelectedActor[i].HealthMax,ActorLoc[i].X-20,ActorLoc[i].Y+10,200,80,80);
				}
		}
	}
}

event PostRender(){
	local TDGameCamera PlayerCam;
	local TDGameController TDGameCont;
	local MouseInterfacePlayerInput MouseInterfacePlayerInput;
	local MouseInterfaceInteractionInterface MouseInteractionInterface;
	local Vector HitLocation, HitNormal, tempBarLoc;
	
	super.PostRender();

	if (HudMovie != none){
		//As long as we have a HUD, we call the TickHUD function on every tick.
		HudMovie.TickHUD();
	}

	//Get a type casted reference to our custom player controller.
	TDGameCont = TDGameController(PlayerOwner);

	//Get the mouse coordinates from the GameUISceneClient
	TDGameCont.PlayerMouse = GetMouseCoordinates();
	//Deproject the 2d mouse coordinate into 3d world. Store the MousePosWorldLocation and normal (direction).
	Canvas.DeProject(TDGameCont.PlayerMouse, TDGameCont.MousePosWorldLocation, TDGameCont.MousePosWorldNormal);

	//Get a type casted reference to our custom camera.
	PlayerCam = TDGameCamera(TDGameCont.PlayerCamera);

	//Calculate a trace from Player camera + 100 up(z) in direction of deprojected MousePosWorldNormal (the direction of the mouse).
	//-----------------
	//Set the ray direction as the mouseWorldnormal
	TDGameCont.RayDir = TDGameCont.MousePosWorldNormal;
	//Start the trace at the player camera (isometric) + 100 unit z and a little offset in front of the camera (direction *10)
	TDGameCont.StartTrace = PlayerCam.ViewTarget.POV.Location + TDGameCont.RayDir * 10;
	//End this ray at start + the direction multiplied by given distance (5000 unit is far enough generally)
	TDGameCont.EndTrace = TDGameCont.StartTrace + TDGameCont.RayDir * 5000;

	//Trace MouseHitWorldLocation each frame to world location (here you can get from the trace the actors that are hit by the trace, for the sake of this
	//simple tutorial, we do noting with the result, but if you would filter clicks only on terrain, or if the player clicks on an npc, you would want to inspect
	//the object hit in the StartFire function
	TDGameCont.TraceActor = Trace(TDGameCont.MouseHitWorldLocation, TDGameCont.MouseHitWorldNormal, TDGameCont.EndTrace, TDGameCont.StartTrace, true);
	if(TDGameCont.TraceActor!=none && !TDGameCont.TraceActor.IsA('Terrain') && !TDGameCont.bWillBuild){
		tempBarLoc = Canvas.Project(TDGameCont.TraceActor.Location);
		DrawBar("",TDUnitBase(TDGameCont.TraceActor).Health, TDUnitBase(TDGameCont.TraceActor).HealthMax,tempBarLoc.X-20,tempBarLoc.Y+10,200,80,80);
	}
	

	// Ensure that we have a valid PlayerOwner and CursorTexture
	/*if (PlayerOwner != None && CursorTexture != None) 
	{
		// Cast to get the MouseInterfacePlayerInput
		MouseInterfacePlayerInput = MouseInterfacePlayerInput(PlayerOwner.PlayerInput); 

		if (MouseInterfacePlayerInput != None)
		{
		  // Set the canvas position to the mouse position
		  Canvas.SetPos(MouseInterfacePlayerInput.MousePosition.X, MouseInterfacePlayerInput.MousePosition.Y); 
		  // Set the cursor color
		  Canvas.DrawColor = CursorColor[CursorColorChoice];
		  // Draw the texture on the screen
		  Canvas.DrawTile(CursorTexture, CursorTexture.SizeX, CursorTexture.SizeY, 0.f, 0.f, CursorTexture.SizeX, CursorTexture.SizeY,, true);
		}
	}*/
	if (PlayerOwner != None){
	MouseInterfacePlayerInput = MouseInterfacePlayerInput(PlayerOwner.PlayerInput); 
		if(JustStarted>0){
			MouseInterfacePlayerInput.MousePosition.X = Canvas.SizeX/2;
			MouseInterfacePlayerInput.MousePosition.Y = Canvas.SizeY/2;
			/*Canvas.SetPos(Canvas.SizeX/2,Canvas.SizeY/2); 
			Canvas.DrawColor = CursorColor[CursorColorChoice];
			Canvas.DrawTile(CursorTexture, CursorTexture.SizeX, CursorTexture.SizeY, 0.f, 0.f, CursorTexture.SizeX, CursorTexture.SizeY,, true);*/
			JustStarted--;
		}
	}

	    // Ensure that we have a valid PlayerOwner
    if (PlayerOwner != None)
    {
      // Cast to get the MouseInterfacePlayerInput
      MouseInterfacePlayerInput = MouseInterfacePlayerInput(PlayerOwner.PlayerInput);
    }

	// Get the current mouse interaction interface
  MouseInteractionInterface = GetMouseActor(HitLocation, HitNormal);

  // Handle mouse over and mouse out
  // Did we previously had a mouse interaction interface?
  if (LastMouseInteractionInterface != None)
  {
    // If the last mouse interaction interface differs to the current mouse interaction
    if (LastMouseInteractionInterface != MouseInteractionInterface)
    {
      // Call the mouse out function
      LastMouseInteractionInterface.MouseOut(CachedMouseWorldOrigin, CachedMouseWorldDirection);
      // Assign the new mouse interaction interface
      LastMouseInteractionInterface = MouseInteractionInterface; 

      // If the last mouse interaction interface is not none
      if (LastMouseInteractionInterface != None)
      {
        // Call the mouse over function
        LastMouseInteractionInterface.MouseOver(CachedMouseWorldOrigin, CachedMouseWorldDirection); // Call mouse over
      }
	      }
  }
  else if (MouseInteractionInterface != None)
  {
    // Assign the new mouse interaction interface
    LastMouseInteractionInterface = MouseInteractionInterface; 
    // Call the mouse over function
    LastMouseInteractionInterface.MouseOver(CachedMouseWorldOrigin, CachedMouseWorldDirection); 
  }

  if (LastMouseInteractionInterface != None)
  {
    // Handle left mouse button
    if (PendingLeftPressed)
    {
      if (PendingLeftReleased)
      {
        // This is a left click, so discard
        PendingLeftPressed = false;
        PendingLeftReleased = false;
      }
      else
      {
        // Left is pressed
        PendingLeftPressed = false;
        LastMouseInteractionInterface.MouseLeftPressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
      }
    }
    else if (PendingLeftReleased)
    {
      // Left is released
      PendingLeftReleased = false;
      LastMouseInteractionInterface.MouseLeftReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
    }

    // Handle right mouse button
    if (PendingRightPressed)
    {
      if (PendingRightReleased)
      {
        // This is a right click, so discard
        PendingRightPressed = false;
        PendingRightReleased = false;
      }
      else
      {
        // Right is pressed
        PendingRightPressed = false;
        LastMouseInteractionInterface.MouseRightPressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
      }
    }
    else if (PendingRightReleased)
    {
      // Right is released
      PendingRightReleased = false;
      LastMouseInteractionInterface.MouseRightReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
    }

    // Handle middle mouse button
    if (PendingMiddlePressed)
    {
      if (PendingMiddleReleased)
      {
        // This is a middle click, so discard 
        PendingMiddlePressed = false;
        PendingMiddleReleased = false;
      }
      else
      {
        // Middle is pressed
        PendingMiddlePressed = false;
        LastMouseInteractionInterface.MouseMiddlePressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
      }
    }
    else if (PendingMiddleReleased)
    {
      PendingMiddleReleased = false;
      LastMouseInteractionInterface.MouseMiddleReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
    }

    // Handle middle mouse button scroll up
    if (PendingScrollUp)
    {
      PendingScrollUp = false;
      LastMouseInteractionInterface.MouseScrollUp(CachedMouseWorldOrigin, CachedMouseWorldDirection);
    }

    // Handle middle mouse button scroll down
    if (PendingScrollDown)
    {
      PendingScrollDown = false;
      LastMouseInteractionInterface.MouseScrollDown(CachedMouseWorldOrigin, CachedMouseWorldDirection);
    }
  }
}

function getDeProjection(vector2D MouseCoords, out vector DeprojectedCoord, out vector DeprojectedNormal){
	self.Canvas.DeProject(MouseCoords,DeprojectedCoord,DeprojectedNormal);
}

function Vector2d GetMouseCoordinates()
{
	local Vector2D MousePos;
	local MouseInterfacePlayerInput MouseInterfacePlayerInput;
	
	if (PlayerOwner != None) 
	{
		MouseInterfacePlayerInput = MouseInterfacePlayerInput(PlayerOwner.PlayerInput); 

		if (MouseInterfacePlayerInput != None)
		{
			MousePos.X = MouseInterfacePlayerInput.MousePosition.X;
			MousePos.Y = MouseInterfacePlayerInput.MousePosition.Y;
		}
	}
	return MousePos;
}

function MouseInterfaceInteractionInterface GetMouseActor(optional out Vector HitLocation, optional out Vector HitNormal)
{
  local MouseInterfaceInteractionInterface MouseInteractionInterface;
  local MouseInterfacePlayerInput MouseInterfacePlayerInput;
  local Vector2D MousePosition;
  local Actor HitActor;

  // Ensure that we have a valid canvas and player owner
  if (Canvas == None || PlayerOwner == None)
  {
    return None;
  }

  // Type cast to get the new player input
  MouseInterfacePlayerInput = MouseInterfacePlayerInput(PlayerOwner.PlayerInput);

  // Ensure that the player input is valid
  if (MouseInterfacePlayerInput == None)
  {
    return None;
  }

  // We stored the mouse position as an IntPoint, but it's needed as a Vector2D
  MousePosition.X = MouseInterfacePlayerInput.MousePosition.X;
  MousePosition.Y = MouseInterfacePlayerInput.MousePosition.Y;
  // Deproject the mouse position and store it in the cached vectors
  Canvas.DeProject(MousePosition, CachedMouseWorldOrigin, CachedMouseWorldDirection);

  // Perform a trace actor interator. An interator is used so that we get the top most mouse interaction
  // interface. This covers cases when other traceable objects (such as static meshes) are above mouse
  // interaction interfaces.
  ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CachedMouseWorldOrigin + CachedMouseWorldDirection * 65536.f, CachedMouseWorldOrigin,,, TRACEFLAG_Bullet)
  {
    // Type cast to see if the HitActor implements that mouse interaction interface
    MouseInteractionInterface = MouseInterfaceInteractionInterface(HitActor);
    if (MouseInteractionInterface != None)
    {
      return MouseInteractionInterface;
    }
  }

  return None;
}

function DrawBar(String Title, float Value, float MaxValue,int X, int Y, int R, int G, int B){
    local int PosX;
	local int BarSizeX; //Declare our variable representing the size of our bar

    PosX = X; // Where we should draw the next rectangle
	BarSizeX = 40 * FMin(Value / MaxValue, 1); // size of active rectangle

    /* Displays active rectangles */
        Canvas.SetPos(PosX,Y);
		Canvas.SetDrawColor(R, G, B, 200);
		Canvas.DrawRect(BarSizeX, 5);

    /* Displays desactived rectangles */
        Canvas.SetPos(BarSizeX+X,Y);
		Canvas.SetDrawColor(255, 255, 255, 80);
		Canvas.DrawRect(40 - BarSizeX, 5); //Change 300 to however big you want your bar to be

    /* Displays a title */
    Canvas.SetPos(PosX+300+5, Y); //Change 300 to however big your bar is
    Canvas.SetDrawColor(R,G,B,200);
    Canvas.Font = class'Engine'.static.GetSmallFont();
    Canvas.DrawText(Title);
} 

function CursorColorChange(int choice){
	CursorColorChoice = choice;
	HUDMovie.UpdateMouseColor(CursorColor[choice].R,CursorColor[choice].G,CursorColor[choice].B,CursorColor[choice].A);
}

function InitHUDButtons(){
	local int i;
	local Slots tempSlot;

	if(PrimaryPannel.length!=0){
		for(i=0;i<PrimaryPannel.length;i++){
			tempSlot = PrimaryPannel[i];
			HUDMovie.InitHUD(0,i,tempSlot.ImageName,tempSlot.InitialState,tempSlot.customName,tempSlot.ResourceCost,tempSlot.Description);
		}
	}
	if(SecondaryPannel.length!=0){
		for(i=0;i<SecondaryPannel.length;i++){
			tempSlot = SecondaryPannel[i];
			HUDMovie.InitHUD(1,i,tempSlot.ImageName,tempSlot.InitialState,tempSlot.customName,tempSlot.ResourceCost,tempSlot.Description);
		}
	}
	HUDMovie.DrawFlashHUD(0);
}

function ResetHUD(){
	HUDMovie.ResetHUD();
}

singular event Destroyed(){
	if (HUDMovie != none){
		HUDMovie.Close(true);
		HUDMovie=none;
	}
	Destroy();
}

DefaultProperties
{
	CursorColor[0]=(R=255,G=255,B=255,A=100)
	CursorColor[1]=(R=255,G=0,B=0,A=255)
	CursorColor[2]=(R=0,G=255,B=0,A=255)
	CursorColorChoice=0

	JustStarted = 10;
}
