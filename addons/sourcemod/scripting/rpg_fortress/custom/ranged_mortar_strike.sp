#define MORTAR_SHOT	"weapons/mortar/mortar_fire1.wav"
#define MORTAR_BOOM	"beams/beamstart5.wav"
#define MORTAR_SHOT_INCOMMING	"weapons/mortar/mortar_shell_incomming1.wav"

static int WeaponToFire[MAXENTITIES];

void Mortar_MapStart()
{
	PrecacheSound(MORTAR_SHOT);
	PrecacheSound(MORTAR_BOOM); 
	PrecacheSound(MORTAR_SHOT_INCOMMING); 
	PrecacheSound("weapons/drg_wrench_teleport.wav");
}

public float AbilityMortarRanged(int client, int index, char name[48])
{
	KeyValues kv = TextStore_GetItemKv(index);
	if(kv)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(weapon))
		{
			static char classname[36];
			GetEntityClassname(weapon, classname, sizeof(classname));
			if (TF2_GetClassnameSlot(classname) != TFWeaponSlot_Melee && !i_IsWandWeapon[weapon] && !i_IsWrench[weapon])
			{
				Ability_MortarRanged(client, 1, weapon);
				return (GetGameTime() + 40.0);
			}
			else
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				ShowGameText(client,"leaderboard_streak", 0, "Not usable Without a Ranged Weapon.");
				return 0.0;
			}
		}

	//	if(kv.GetNum("consume", 1))

	}
	return 0.0;
}
static float f_MarkerPosition[MAXTF2PLAYERS][3];
static float f_Damage[MAXTF2PLAYERS];



public void Ability_MortarRanged(int client, int level, int weapon)
{
	float damage = Config_GetDPSOfEntity(weapon);
	
	if(damage < 1.0)
	{
		f_Damage[client] = 1.0;
	}
	else
	{
		f_Damage[client] = (damage * 6);
	}	
	WeaponToFire[client] = EntIndexToEntRef(weapon);
	BuildingMortarAction(client);
}
	

public void BuildingMortarAction(int client)
{
	float spawnLoc[3];
	float eyePos[3];
	float eyeAng[3];
			   
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	b_LagCompNPC_No_Layers = true;
	StartLagCompensation_Base_Boss(client);
	
	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	FinishLagCompensation_Base_boss();
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(spawnLoc, trace);
	} 
	int color[4];
	color[0] = 255;
	color[1] = 255;
	color[2] = 0;
	color[3] = 255;
									
	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		color[2] = 255;
		color[0] = 0;
	}
	GetAttachment(client, "effect_hand_R", eyePos, eyeAng);
	int SPRITE_INT = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	float amp = 0.2;
	float life = 0.1;
	TE_SetupBeamPoints(eyePos, spawnLoc, SPRITE_INT, 0, 0, 0, life, 2.0, 2.2, 1, amp, color, 0);
	TE_SendToAll();
								
	delete trace;
	
	EmitSoundToAll("weapons/drg_wrench_teleport.wav", client, SNDCHAN_AUTO, 70);
	static float pos[3];
	CreateTimer(1.0, MortarFire_Anims, client, TIMER_FLAG_NO_MAPCHANGE);
	f_MarkerPosition[client] = spawnLoc;
	float position[3];
	position[0] = spawnLoc[0];
	position[1] = spawnLoc[1];
	position[2] = spawnLoc[2];
				
	position[2] += 3000.0;

	int particle = ParticleEffectAt(position, "kartimpacttrail", 2.0);
	SetEdictFlags(particle, (GetEdictFlags(particle) | FL_EDICT_ALWAYS));	
	CreateTimer(1.7, MortarFire_Falling_Shot, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	ParticleEffectAt(pos, "utaunt_portalswirl_purple_warp2", 2.0);
}

public Action MortarFire_Falling_Shot(Handle timer, int ref)
{
	int particle = EntRefToEntIndex(ref);
	if(particle>MaxClients && IsValidEntity(particle))
	{
		float position[3];
		GetEntPropVector(particle, Prop_Send, "m_vecOrigin", position);
		position[2] -= 3700;
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}
public Action MortarFire_Anims(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		EmitSoundToAll(MORTAR_SHOT_INCOMMING, 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, f_MarkerPosition[client]);
		EmitSoundToAll(MORTAR_SHOT_INCOMMING, 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, f_MarkerPosition[client]);
		//	SetColorRGBA(glowColor, r, g, b, alpha);
		ParticleEffectAt(f_MarkerPosition[client], "taunt_flip_land_ring", 1.0);
		CreateTimer(0.8, MortarFire, client, TIMER_FLAG_NO_MAPCHANGE);
	}	
	return Plugin_Handled;
}

public Action MortarFire(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		int weapon = EntRefToEntIndex(WeaponToFire[client]);
		if(IsValidEntity(weapon))
		{
			Explode_Logic_Custom(f_Damage[client], client, client, weapon, f_MarkerPosition[client], 350.0, 1.45, _, false);
		}
			
		CreateEarthquake(f_MarkerPosition[client], 0.5, 350.0, 16.0, 255.0);
		EmitSoundToAll(MORTAR_BOOM, 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, f_MarkerPosition[client]);
		EmitSoundToAll(MORTAR_BOOM, 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, f_MarkerPosition[client]);
		ParticleEffectAt(f_MarkerPosition[client], "rd_robot_explosion", 1.0);
	}
	return Plugin_Handled;
}