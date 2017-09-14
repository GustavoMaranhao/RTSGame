class TDArchetypeManager extends Object placeable;

struct Slots{
	var() string customName;
	var() string ImageName;
	var() string InitialState;
	var() string ResourceCost;
	var() string Description;
};

var() array<TDUnitConstruction> Buildings;
var() array<TDUnitBase>	Units;

DefaultProperties
{
	Buildings[0] = TDUnitConstruction'Gustavo_Pacote1.Archetypes.UnitConstruction1';
	Units[0] = TDUnitBuilder'Gustavo_Pacote1.Archetypes.UnitBuilder';
	Units[1] = TDUnitFighting'Gustavo_Pacote1.Archetypes.UnitFighting';
}
