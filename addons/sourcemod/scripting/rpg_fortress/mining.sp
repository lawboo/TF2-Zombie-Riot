#pragma semicolon 1
#pragma newdecls required

static const char MiningLevels[][] =
{
	"Wooden (0)",
	"Stone (1)",
	"Bronze (2)",
	"Iron (3)",
	"Steel (4)",
	"Diamond (5)",
	"Emerald (6)",
	"Obsidian (7)"
};

static float f_clientFoundRareRockSpot[MAXTF2PLAYERS];
static float f_clientFoundRareRockSpotPos[MAXTF2PLAYERS][3];

static float f_ClientStartedTouch[MAXTF2PLAYERS];
static float f_ClientStartedTouchDelay[MAXTF2PLAYERS];
static float f_TouchedThisManyTimes[MAXTF2PLAYERS];

static float f_clientMinedThisSpot[MAXTF2PLAYERS];
static float f_clientMinedThisSpotPos[MAXTF2PLAYERS][3];

enum struct MineEnum
{
	char Zone[32];
	
	char Model[PLATFORM_MAX_PATH];
	float Pos[3];
	
	float Text_Pos[3];
	char Text_Name[PLATFORM_MAX_PATH];
	int Text_Size;

	float Ang[3];
	float Scale;
	bool OnTouch;
	int Color[4];
	
	char Item[48];
	int Health;
	int Tier;
	
	char Item1[48];
	float Chance1;
	int Tier1;
	
	char Item2[48];
	float Chance2;
	int Tier2;
	
	char Item3[48];
	float Chance3;
	int Tier3;

	int EntRef;
	
	void SetupEnum(KeyValues kv)
	{
		kv.GetSectionName(this.Model, PLATFORM_MAX_PATH);
		ExplodeStringFloat(this.Model, " ", this.Pos, sizeof(this.Pos));

		//kv.GetString("zone", this.Zone, 32);
		
		kv.GetString("model", this.Model, PLATFORM_MAX_PATH, "models/error.mdl");
		if(!this.Model[0])
			SetFailState("Missing model in mining.cfg");
			
		kv.GetString("text_name", this.Text_Name, PLATFORM_MAX_PATH, "Ore");
		
		this.Text_Size = kv.GetNum("text_font_size");
		PrecacheModel(this.Model);
		
		kv.GetVector("ang", this.Ang);

		kv.GetVector("text_pos", this.Text_Pos);

		kv.GetColor4("color", this.Color);
		this.Scale = kv.GetFloat("scale", 1.0);

		kv.GetString("item", this.Item, 48);
		this.Health = kv.GetNum("health");
		this.Tier = kv.GetNum("tier");
		
		this.OnTouch = view_as<bool>(kv.GetNum("ontouch"));

		kv.GetString("s1_item", this.Item1, 48);
		this.Chance1 = kv.GetFloat("s1_chance");
		this.Tier1 = kv.GetNum("s1_tier");

		kv.GetString("s2_item", this.Item2, 48);
		this.Chance2 = kv.GetFloat("s2_chance");
		this.Tier2 = kv.GetNum("s2_tier");

		kv.GetString("s3_item", this.Item3, 48);
		this.Chance3 = kv.GetFloat("s3_chance");
		this.Tier3 = kv.GetNum("s3_tier");
	}
	
	void Despawn()
	{
		if(this.EntRef != INVALID_ENT_REFERENCE)
		{
			int entity = EntRefToEntIndex(this.EntRef);
			if(entity != -1)
			{
				RemoveEntity(entity);

				int text = EntRefToEntIndex(i_TextEntity[entity][0]);
				if(text != -1)
					RemoveEntity(text);
			}
						
			this.EntRef = INVALID_ENT_REFERENCE;
		}
	}

	void DropChanceItem(int client, int hasTier, float pos[3], const char[] name, float chance, int tier)
	{
		if(name[0] && hasTier >= tier)
		{
			if(GetURandomFloat() < (float(300 + Stats_Luck(client)) / 300.0) * chance)
			{
				TextStore_DropNamedItem(client, name, pos, 1);
			}
		}
	}
	
	void Spawn()
	{
		if(EntRefToEntIndex(this.EntRef) == INVALID_ENT_REFERENCE)
		{
			int entity = CreateEntityByName("prop_dynamic_override");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "targetname", "rpg_fortress");
				DispatchKeyValue(entity, "model", this.Model);
				DispatchKeyValueFloat(entity, "modelscale", this.Scale);
				DispatchKeyValue(entity, "solid", "6");
				SetEntPropFloat(entity, Prop_Send, "m_fadeMinDist", MIN_FADE_DISTANCE);
				SetEntPropFloat(entity, Prop_Send, "m_fadeMaxDist", MAX_FADE_DISTANCE);				
				DispatchSpawn(entity);
				TeleportEntity(entity, this.Pos, this.Ang, NULL_VECTOR, true);

				if(this.OnTouch)
				{
					SDKHook(entity, SDKHook_Touch, AntiTouchStuckMine);
				}

				if(this.Text_Name[0])
				{
					int text = SpawnFormattedWorldText(this.Text_Name, this.Text_Pos, this.Text_Size, this.Color, _,_, false);
					i_TextEntity[entity][0] = EntIndexToEntRef(text);
				}
				
				SetEntityRenderColor(entity, this.Color[0], this.Color[1], this.Color[2], this.Color[3]);
				
				this.EntRef = EntIndexToEntRef(entity);
			}
		}
	}
}

public void AntiTouchStuckMine(int entity, int other)
{
	if(other <= MaxClients)
	{
		if(f_ClientStartedTouchDelay[other] < GetGameTime())
		{
			f_ClientStartedTouchDelay[other] = GetGameTime() + 0.5;
			if(f_ClientStartedTouch[other] > GetGameTime())
			{
				f_ClientStartedTouch[other] = GetGameTime() + 5.0;
				f_TouchedThisManyTimes[other] *= 2.0;
				SDKHooks_TakeDamage(other, entity, entity, f_TouchedThisManyTimes[other], DMG_DROWN, -1);

				//Already touched before!
			}
			else
			{
				//new touch!
				f_ClientStartedTouch[other] = GetGameTime() + 5.0;
				f_TouchedThisManyTimes[other] = 1.0;
				SDKHooks_TakeDamage(other, entity, entity, f_TouchedThisManyTimes[other], DMG_DROWN, -1);
			}
		}
	}
}

static ArrayList MineList;
static int MineDamage[MAXTF2PLAYERS];

void Mining_ConfigSetup(KeyValues map)
{
	KeyValues kv = map;
	if(kv)
	{
		kv.Rewind();
		if(!kv.JumpToKey("Mining"))
			kv = null;
	}
	
	char buffer[PLATFORM_MAX_PATH];
	if(!kv)
	{
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "mining");
		kv = new KeyValues("Mining");
		kv.ImportFromFile(buffer);
	}
	
	delete MineList;
	MineList = new ArrayList(sizeof(MineEnum));

	MineEnum mine;
	mine.EntRef = INVALID_ENT_REFERENCE;

	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(mine.Zone, sizeof(mine.Zone));

		if(kv.GotoFirstSubKey())
		{
			do
			{
				mine.SetupEnum(kv);
				MineList.PushArray(mine);
			}
			while(kv.GotoNextKey());
			kv.GoBack();
		}
	}
	while(kv.GotoNextKey());

	if(kv != map)
		delete kv;
}

void Mining_EnableZone(const char[] name)
{
	int length = MineList.Length;
	for(int i; i < length; i++)
	{
		static MineEnum mine;
		MineList.GetArray(i, mine);
		if(StrEqual(mine.Zone, name))
		{
			mine.Spawn();
			MineList.SetArray(i, mine);
		}
	}
}

void Mining_DisableZone(const char[] name)
{
	int length = MineList.Length;
	for(int i; i < length; i++)
	{
		static MineEnum mine;
		MineList.GetArray(i, mine);
		if(StrEqual(mine.Zone, name))
		{
			mine.Despawn();
			MineList.SetArray(i, mine);
		}
	}
}

bool Mining_IsPickaxeFunc(const char[] buffer)
{
	return StrEqual(buffer, "Mining_PickaxeM1");
}

void Mining_DescItem(KeyValues kv, char[] desc, int[] attrib, float[] value, int attribs)
{
	static char buffer[64];
	kv.GetString("func_attack", buffer, sizeof(buffer));
	if(Mining_IsPickaxeFunc(buffer))
	{
		for(int i; i < attribs; i++)
		{
			switch(attrib[i])
			{
				case 2016:
				{
					Format(desc, 512, "%s\nMining Efficiency: %.0f%%", desc, value[i]);
				}
				case 2017:
				{
					int pos = RoundFloat(value[i]);
					if(pos < sizeof(MiningLevels))
						Format(desc, 512, "%s\nMining Level: %s", desc, MiningLevels[pos]);
				}
			}
		}
	}
}

public void Mining_PickaxeM1(int client, int weapon, const char[] classname, bool &result)
{
	float ApplyCooldown =  0.8 * Attributes_FindOnWeapon(client, weapon, 6, true, 1.0);
	Ability_Apply_Cooldown(client, 1,ApplyCooldown);

	DataPack pack;
	CreateDataTimer(0.2, Mining_PickaxeM1Delay, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(client));
	pack.WriteCell(EntIndexToEntRef(weapon));
}

public Action Mining_PickaxeM1Delay(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(client) && IsValidEntity(weapon))
	{
		Handle tr;
		float forwar[3];
		DoSwingTrace_Custom(tr, client, forwar);

		int target = TR_GetEntityIndex(tr);
		if(target != -1)
		{
			int index = MineList.FindValue(EntIndexToEntRef(target), MineEnum::EntRef);
			if(index != -1)
			{
				int Item_Index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				PlayCustomWeaponSoundFromPlayerCorrectly(client, target, Item_Index, weapon);	
				static MineEnum mine;
				MineList.GetArray(index, mine);

				int tier = RoundToNearest(Attributes_FindOnWeapon(client, weapon, 2017));
				float attackspeed = Attributes_FindOnWeapon(client, weapon, 6 , true, 1.0);
				if(tier < mine.Tier)
				{
					ShowGameText(client, "ico_metal", 0, "You need atleast %s tier to mine this!", MiningLevels[mine.Tier]);
				}
				else
				{
					float f_positionhit[3];	
					TR_GetEndPosition(f_positionhit, tr);
						
			//		static float f_clientMinedThisSpot[MAXTF2PLAYERS];
			//		static float f_clientMinedThisSpotPos[MAXTF2PLAYERS][3];
					if(f_clientMinedThisSpotPos[client][1] == f_positionhit[1] && f_clientMinedThisSpotPos[client][0] == f_positionhit[0]) //It should theoretically be absolutely impossible to hit the same spot when moving around.
					{
						//We do not care about height. Because the numbers will be very off in this case.
						if(f_clientMinedThisSpot[client] < GetGameTime())
						{
							static float m_vecMaxs[3];
							static float m_vecMins[3];
							m_vecMaxs = view_as<float>( { 5.0, 5.0, 5.0 } );
							m_vecMins = view_as<float>( { -5.0, -5.0, -5.0 } );	
							TE_DrawBox(client, f_positionhit, m_vecMins, m_vecMaxs, 0.2, view_as<int>({255, 0, 0, 255}));
							ShowGameText(client, "ico_metal", 0, "This part of the rock is exhausted, mine another spot!");
							delete tr;
							return Plugin_Handled;
						}
					}
					else
					{
						f_clientMinedThisSpot[client] = GetGameTime() + 5.0; //You cannot mine the exact same spot after 5 seconds.
						f_clientMinedThisSpotPos[client] = f_positionhit;
					}
					
					DoClientHitmarker(client);

					bool Rare_hit = false;
					if(f_clientFoundRareRockSpot[client] > GetGameTime())
					{
						float distance = GetVectorDistance( f_clientFoundRareRockSpotPos[client], f_positionhit, true ); 
						if(distance < (27.0 * 27.0))
						{
							Rare_hit = true;
							DisplayCritAboveNpc(_, client, true,f_positionhit); //Display crit above head
							f_clientFoundRareRockSpot[client] = 0.0;
							f_clientFoundRareRockSpotPos[client][0] = 0.0;
							f_clientFoundRareRockSpotPos[client][1] = 0.0;
							f_clientFoundRareRockSpotPos[client][2] = 0.0;
						}
					}
					if(!Rare_hit && f_clientFoundRareRockSpot[client] < GetGameTime())
					{
						float f_ang[3];
						float f_pos[3];

						GetClientEyeAngles(client,f_ang);
						GetClientEyePosition(client,f_pos);

						float tmp[3];
						float actualBeamOffset[3];
						float BEAM_BeamOffset[3];
						BEAM_BeamOffset[0] = -35.0; //Go back 35 units.
						BEAM_BeamOffset[1] = 0.0;
						BEAM_BeamOffset[2] = 0.0;

						tmp[0] = BEAM_BeamOffset[0];
						tmp[1] = BEAM_BeamOffset[1];
						tmp[2] = 0.0;
						VectorRotate(tmp, f_ang, actualBeamOffset);
						actualBeamOffset[2] = BEAM_BeamOffset[2];
						f_pos[0] += actualBeamOffset[0];
						f_pos[1] += actualBeamOffset[1];
						f_pos[2] += actualBeamOffset[2];

						float f_resulthit[3];

						f_ang[0] += GetRandomFloat(-20.0,20.0);
						f_ang[1] += GetRandomFloat(-20.0,20.0);
					//	f_ang[2] += GetRandomFloat(-20.0,20.0);

						Handle trace; 
						trace = TR_TraceRayFilterEx(f_pos, f_ang, ( MASK_SHOT | MASK_SHOT_HULL ), RayType_Infinite, BulletAndMeleeTrace, client);
						

						TR_GetEndPosition(f_resulthit, trace);
						int i_entity_hit = TR_GetEntityIndex(trace);
						delete trace;

					//	int g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
					//	TE_SetupBeamPoints(f_pos, f_resulthit, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 1.0, 1.0, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
					//	TE_SendToAll();

						if(i_entity_hit == target)
						{
							if(f_clientFoundRareRockSpot[client] < GetGameTime())
							{
								f_clientFoundRareRockSpot[client] = GetGameTime() + 10.0;
								DataPack pack_repack;
								CreateDataTimer((5.0 * attackspeed), ApplyRareMiningChance, pack_repack, TIMER_FLAG_NO_MAPCHANGE);
								pack_repack.WriteCell(EntIndexToEntRef(client));
								pack_repack.WriteCell(EntIndexToEntRef(i_entity_hit));
								pack_repack.WriteFloat(f_resulthit[0]);
								pack_repack.WriteFloat(f_resulthit[1]);
								pack_repack.WriteFloat(f_resulthit[2]);
							}
						}
					}
					int damage = RoundToNearest(Attributes_FindOnWeapon(client, weapon, 2016, true));

					if(Rare_hit)
					{
						damage *= 6;
						Tinker_GainXP(client, weapon);
					}

					Event event = CreateEvent("npc_hurt", true);
					event.SetInt("entindex", target);
					event.SetInt("attacker_player", GetClientUserId(client));
					event.SetInt("weaponid", weapon);
					event.SetInt("damageamount", damage);
					event.SetInt("health", 999999);
					event.SetBool("crit", Rare_hit);
					event.FireToClient(client);
					event.Cancel();
					
					MineDamage[client] += damage;
					while(MineDamage[client] >= mine.Health)
					{
						GetClientEyePosition(client, forwar);
						TextStore_DropNamedItem(client, mine.Item, forwar, 1);
						MineDamage[client] -= mine.Health;

						mine.DropChanceItem(client, tier, forwar, mine.Item1, mine.Chance1, mine.Tier1);
						mine.DropChanceItem(client, tier, forwar, mine.Item2, mine.Chance2, mine.Tier2);
						mine.DropChanceItem(client, tier, forwar, mine.Item3, mine.Chance3, mine.Tier3);
					}
				}
			}
		}

		delete tr;
	}
	return Plugin_Handled;
}
public Action ApplyRareMiningChance(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int mined_rock = EntRefToEntIndex(pack.ReadCell());
	float f_pos[3];
	f_pos[0] = pack.ReadFloat();
	f_pos[1] = pack.ReadFloat();
	f_pos[2] = pack.ReadFloat();
	if(IsValidEntity(client) && IsValidEntity(mined_rock))
	{
		DataPack pack_repack;
		CreateDataTimer(0.1, ApplyRareMiningChanceRepeat, pack_repack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		pack_repack.WriteCell(EntIndexToEntRef(client));
		pack_repack.WriteCell(EntIndexToEntRef(mined_rock));
		pack_repack.WriteFloat(f_pos[0]);
		pack_repack.WriteFloat(f_pos[1]);
		pack_repack.WriteFloat(f_pos[2]);
		f_clientFoundRareRockSpotPos[client] = f_pos;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Stop;
	}
	
}

public Action ApplyRareMiningChanceRepeat(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int mined_rock = EntRefToEntIndex(pack.ReadCell());
	float f_pos[3];
	f_pos[0] = pack.ReadFloat();
	f_pos[1] = pack.ReadFloat();
	f_pos[2] = pack.ReadFloat();
	if(IsValidEntity(client) && IsValidEntity(mined_rock))
	{
		if((f_clientFoundRareRockSpot[client] - 0.3) > GetGameTime())
		{
			static float m_vecMaxs[3];
			static float m_vecMins[3];
			m_vecMaxs = view_as<float>( { 10.0, 10.0, 10.0 } );
			m_vecMins = view_as<float>( { -10.0, -10.0, -10.0 } );	
			TE_DrawBox(client, f_pos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({0, 255, 0, 255}));
			return Plugin_Continue;
		}
		else
		{
			f_clientFoundRareRockSpot[client] = 0.0;
			f_clientFoundRareRockSpotPos[client][0] = 0.0;
			f_clientFoundRareRockSpotPos[client][1] = 0.0;
			f_clientFoundRareRockSpotPos[client][2] = 0.0;
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
}