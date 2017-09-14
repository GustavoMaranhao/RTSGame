class MouseInterfacePlayerInput extends PlayerInput;

// Stored mouse position. Set to private write as we don't want other classes to modify it, but still allow other classes to access it.
var IntPoint MousePosition; 
var TDHUD SFHudWrapper;
var float HudX, HudY;

var float Forward, Strafe;

var bool bLeftEdge, bRightEdge, bTopEdge, bBottomEdge;

// This function gets the original width and height of the HUD SWF and stores those values in HudX and HudY.
function GetHudSize(){
    // First store a reference to our HUD Wrapper and get the resolution of the HUD
    SFHudWrapper = TDHUD(myHUD);
    HudX = SFHudWrapper.HudMovieSize.GetFloat("width");
    HudY = SFHudWrapper.HudMovieSize.GetFloat("height");
}

function SetMousePosition(int X, int Y){
    GetHudSize();
	
    if (MyHUD != None){
		MousePosition.X = Clamp(X, 0, HudX);
		MousePosition.Y = Clamp(Y, 0, HudY);

		if(MousePosition.X==0)bLeftEdge=true; else bLeftEdge=false;
		if(MousePosition.X==MyHUD.SizeX-1)bRightEdge=true; else bRightEdge=false;
		if(MousePosition.Y==0)bTopEdge=true; else bTopEdge=false;
		if(MousePosition.Y==MyHUD.SizeY-1)bBottomEdge=true; else bBottomEdge=false;
    }
}

defaultproperties
{
}