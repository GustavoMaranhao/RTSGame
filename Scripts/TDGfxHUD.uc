class TDGfxHUD extends GFxMoviePlayer;

var IntPoint MousePosition, screenCenter;
var GFxObject RootMC, MouseContainer, MouseCursor;

var int JustStarted;
var bool bInPlayArea;

var TextureRenderTarget2D MinimapTexture;
var TextureRenderTarget2D ResetTex;

function Init(optional LocalPlayer LocPlay){
	super.Init (LocPlay);
	RootMC = GetVariableObject("_root");

	ResetTex = class'TextureRenderTarget2D'.static.Create(80, 100, , MakeLinearColor(0.0f, 0.0f, 0.0f, 1.0f));
	SetRenderTexture();

	TickHUD();
}

function TickHUD(){
	bInPlayArea = GetVariableBool("_root.bIsPlaying");
	if(!bInPlayArea) AddCaptureKey('LeftMouseButton');
	else ClearCaptureKeys();
}

event UpdateMousePosition(float X, float Y){
    local MouseInterfacePlayerInput MouseInterfacePlayerInput;

    MouseInterfacePlayerInput = MouseInterfacePlayerInput(GetPC().PlayerInput);

    if (MouseInterfacePlayerInput != None){
		MouseInterfacePlayerInput.SetMousePosition(X, Y);
    } 
}

function UpdateMouseColor(int R,int G,int B,int A){
	ActionScriptVoid("ChangeMouseColor");
}

function SetRenderTexture(){
	SetExternalTexture("miniMapImg",MinimapTexture);
}

function SetPortraitTexture(TextureRenderTarget2D tex){
	SetExternalTexture("portraitImg",tex);
}

function SetFlashVariable(string whichOne,string type,string value){
	switch(type){
		case "string": SetVariableString("_root."$whichOne,value); break;
		case "bool": 
			if(value=="true") SetVariableBool("_root."$whichOne,true);
			else SetVariableBool("_root."$whichOne,false); 
			break;
		case "int":
		case"float": SetVariableNumber("_root."$whichOne,float(value)); break;
	}
}

function ResetArrays(){
	SetVariableNumber("_root.buttons_PrimaryPannelArray.length",0);
	SetVariableNumber("_root.buttons_SecondaryPannelArray.length",0);
}

function InitHUD(int ArrayToUpdate,int SlotNumber,string ImageName,string InitialState,string RealName,string Cost,string Description){
	local GFxObject tempObj;

	ActionScriptVoid("_root.UpdateButtonsArray");
	
	tempObj = RootMC.GetObject("buttons_PrimaryPannelArray").GetElementObject(1);
	if(tempObj!=none) RootMC.SetObject("buttons_LastActiveState",tempObj);
}

function ResetHUD(){
	SetPortraitTexture(ResetTex);
	ActionScriptVoid("_root.ResetHUD");	
}

function DrawFlashHUD(int choice){
	ActionScriptVoid("_root.DrawButtons");
}

function BuildRequested(string Building){
	`log(Building@"Requested");
	TDGameController(getPC()).doBuildAction(Building);
}

function StopButtonClicked(){
	`log("Stop Button Clicked");
}

function HoldButtonClicked(){
	`log("Hold Button Clicked");
}

DefaultProperties
{
	MovieInfo=SwfMovie'HeavyMetal.TDHUD'
	bDisplayWithHudOff=false
	bIgnoreMouseInput=false
	bAutoPlay=true
	bCaptureInput=false;

	bInPlayArea = true

	MinimapTexture=TextureRenderTarget2D'Gustavo_Pacote1.Textures.MinimapTexture'

	JustStarted = 10;
}
