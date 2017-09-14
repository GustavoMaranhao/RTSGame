class TDWeaponBase extends UTWeapon
	dependson(TDGameController);

var weaponUpgradeData weaponData;
const HeightShotOffset = -10.f;

function SetParameters(weaponUpgradeData toSet){
	weaponData = toSet;
}

simulated state Active{
	/** Initialize the weapon as being active and ready to go. */
	simulated event BeginState(Name PreviousStateName){
	  local int i;
	  local weaponUpgradeData oneSetofStats;

	  //set the global weaponData var when a player picks up this weapon
	  /*if(TDGameController(Instigator.Controller) != none){
	      for(i=0;i < ArrayCount(TDDummyController(Instigator.Controller).weaponStats);i++){
	            oneSetofStats = TDDummyController(Instigator.Controller).weaponStats[i];
                    if(oneSetofStats.weaponClass == Self.class){
    		           weaponData = oneSetofStats;
                       break;
                    }
	       }
	  }*/
		
	  //Cache a reference to the AI controller
	  if (Role == ROLE_Authority)
		CacheAIController();

	  //Check to see if we need to go down
	  if(bWeaponPutDown){
	     `LogInv("Weapon put down requested during transition, put it down now");
		  PutDownWeapon();
	  }
	  else if(!HasAnyAmmo()){
	     WeaponEmpty();
	  }
	  else{
		//if either of the fire modes are pending, perform them
		for(i=0;i<GetPendingFireLength();i++){
			if(PendingFire(i)){
				BeginFire(i);
	            break;
	        }
	    }
      }
	}

	/** Override BeginFire so that it will enter the firing state right away. */
	simulated function BeginFire(byte FireModeNum){
		if(!bDeleteMe && Instigator != None){
	    Global.BeginFire(FireModeNum);

        //in the active state, fire right away if we have the ammunition
	    if(PendingFire(FireModeNum) && HasAmmo(FireModeNum)){
			SendToFiringState(FireModeNum);
	    }
	  }
	}

    /** ReadyToFire() called by NPC firing weapon.
      * bFinished should only be true if called from the Finished() function */	 
	simulated function bool ReadyToFire(bool bFinished){
		return true;
	}

	/** Activate() ignored since already active */
	simulated function Activate(){ }

	/** Put the weapon down */
	simulated function bool TryPutDown(){
		PutDownWeapon();
		return TRUE;
	}
}

simulated function Projectile ProjectileFire(){
	local vector		RealStartLoc;
	local Projectile	SpawnedProjectile;
	local string         ProjClass;

	//tell remote clients that we fired, to trigger effects
	IncrementFlashCount();

	if(Role == ROLE_Authority){
		//this is the location where the projectile is spawned.
		RealStartLoc = GetPhysicalFireStartLoc();
		RealStartLoc.Z += HeightShotOffset;

		// Spawn projectile using weapon upgrade data projectile class
		if(Instigator.Controller.isa('TDDummyController')){
			ProjClass = String(GetEnum(Enum'WeaponTypes', TDDummyController(Instigator.Controller).WeaponUsed));
			switch(ProjClass){
				case "Melee": SpawnedProjectile = Spawn(class 'TDProjMelee',,, RealStartLoc); break;
				case "Ranged": SpawnedProjectile = Spawn(class 'TDProjRanged',,, RealStartLoc); break;
				case "Magic": SpawnedProjectile = Spawn(class 'TDProjMagic',,, RealStartLoc); break;
			}
		}
		else{
			GetProjectileClass();
		}

		//if the user of weapon has weaponUpgradeData
		if(Instigator.Controller.isa('TDDummyController')){
			if(SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe){
				//use upgrade data via custom initialization function
				TDProjectileBase(SpawnedProjectile).projInit(Vector(GetAdjustedAim(RealStartLoc)), weaponData);
			}
		}
        //standard code
		else{
			if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe ){
				SpawnedProjectile.Init(Vector(GetAdjustedAim(RealStartLoc)));
			}
		}
		// Return it up the line
		return SpawnedProjectile;
	}

	return None;
}

DefaultProperties
{
}
