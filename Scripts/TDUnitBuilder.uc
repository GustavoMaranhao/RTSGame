class TDUnitBuilder extends TDUnitFighting;

DefaultProperties
{
	Begin Object Name=InitialSkeletalMesh
		SkeletalMesh=SkeletalMesh'pacote_personagem.humana.humana_saia2'
		Translation=(X=0,Y=0,Z=-40)
		Rotation=(Yaw=0,Roll=0,Pitch=0)
		Scale=2.9

		Materials(0)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(1)=none
		Materials(2)=none
		Materials(3)=none
		Materials(4)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(5)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(6)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(7)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(8)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(9)=Material'pacote_personagem.Materials.natal1_mat' 
		Materials(12)=Material'pacote_personagem.Materials.natal1_mat'
		Materials(11)=none
		Materials(13)=Material'pacote_personagem.Materials.natal2_mat'
	End Object
	Mesh=InitialSkeletalMesh;
	Components.Add(InitialSkeletalMesh);

	customType = "Builder"
	PrimaryPannel[5]=(ImageName="RepairButton",InitialState="Inactive",customName="Repair",ResourceCost="",Description="Unit will repair targeted building.");
	PrimaryPannel[7]=(ImageName="GatherResourceButton",InitialState="Inactive",customName="Gather resources",ResourceCost="",Description="Unit will start gathering resources at the targeted position.");
	PrimaryPannel[8]=(ImageName="BuildButton",InitialState="Inactive",customName="Build",ResourceCost="",Description="Select a structure to be built.");
	PrimaryPannel[9]=(ImageName="UnBuildButton",InitialState="Inactive",customName="Unbuild",ResourceCost="",Description="Destroys targeted building and recovers part of the resources used to build it.");

	SecondaryPannel[0]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[1]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[2]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[3]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[4]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[5]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[6]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[7]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
	SecondaryPannel[8]=(ImageName="NecropolisStruct",InitialState="Unavaiable",customName="Necropolis",ResourceCost="200 gold",Description="The necropolis serves as the central command structure of the undead army. Lumber harvested by ghouls is processed, and loyal acolytes train for tasks from their undead masters. Even when unattended, the vengeful spirits of the dead protect the necropolis from enemy attackers. In time, this structure can be further modified to become the Halls of the Dead. After that, it also may turn into a black citadel.");
	SecondaryPannel[9]=(ImageName="NecropolisStruct",InitialState="",customName="Necropolis",ResourceCost="200 gold",Description="The necropolis serves as the central command structure of the undead army. Lumber harvested by ghouls is processed, and loyal acolytes train for tasks from their undead masters. Even when unattended, the vengeful spirits of the dead protect the necropolis from enemy attackers. In time, this structure can be further modified to become the Halls of the Dead. After that, it also may turn into a black citadel.");
	SecondaryPannel[10]=(ImageName="",InitialState="",customName="",ResourceCost="",Description="");
}
