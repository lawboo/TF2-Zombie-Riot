#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = {
	"vo/scout_paincrticialdeath01.mp3",
	"vo/scout_paincrticialdeath02.mp3",
	"vo/scout_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = {
	"vo/scout_painsharp01.mp3",
	"vo/scout_painsharp02.mp3",
	"vo/scout_painsharp03.mp3",
	"vo/scout_painsharp04.mp3",
	"vo/scout_painsharp05.mp3",
	"vo/scout_painsharp06.mp3",
	"vo/scout_painsharp07.mp3",
	"vo/scout_painsharp08.mp3",
};

static const char g_IdleSounds[][] = {
	"vo/scout_standonthepoint01.mp3",
	"vo/scout_standonthepoint02.mp3",
	"vo/scout_standonthepoint03.mp3",
	"vo/scout_standonthepoint04.mp3",
	"vo/scout_standonthepoint05.mp3",
};

static const char g_IdleAlertedSounds[][] = {
	"vo/scout_battlecry01.mp3",
	"vo/scout_battlecry02.mp3",
	"vo/scout_battlecry03.mp3",
	"vo/scout_battlecry04.mp3",
	"vo/scout_battlecry05.mp3",
};

static const char g_MeleeHitSounds[][] = {
	"weapons/halloween_boss/knight_axe_hit.wav",
};
static const char g_MeleeAttackSounds[][] = {
	"weapons/demo_sword_swing1.wav",
	"weapons/demo_sword_swing2.wav",
	"weapons/demo_sword_swing3.wav",
};

static const char g_MeleeMissSounds[][] = {
	"weapons/bat_draw_swoosh1.wav",
	"weapons/bat_draw_swoosh2.wav",
};
static char g_TeleportSounds[][] = {
	"misc/halloween/spell_stealth.wav",
};

void Lanius_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_HurtSounds));		i++) { PrecacheSound(g_HurtSounds[i]);		}
	for (int i = 0; i < (sizeof(g_IdleSounds));		i++) { PrecacheSound(g_IdleSounds[i]);		}
	for (int i = 0; i < (sizeof(g_IdleAlertedSounds)); i++) { PrecacheSound(g_IdleAlertedSounds[i]); }
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	i++) { PrecacheSound(g_MeleeHitSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeAttackSounds));	i++) { PrecacheSound(g_MeleeAttackSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeMissSounds));   i++) { PrecacheSound(g_MeleeMissSounds[i]);   }
	for (int i = 0; i < (sizeof(g_TeleportSounds));   i++) { PrecacheSound(g_TeleportSounds[i]);  			}
	PrecacheModel("models/player/scout.mdl");
}

methodmap Lanius < CClotBody
{
	
	public void PlayIdleSound() {
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(24.0, 48.0);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayIdleSound()");
		#endif
	}
	
	public void PlayTeleportSound() {
		EmitSoundToAll(g_TeleportSounds[GetRandomInt(0, sizeof(g_TeleportSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayTeleportSound()");
		#endif
	}
	
	public void PlayIdleAlertSound() {
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayIdleAlertSound()");
		#endif
	}
	
	public void PlayHurtSound() {
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;
			
		this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayHurtSound()");
		#endif
	}
	
	public void PlayDeathSound() {
	
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayDeathSound()");
		#endif
	}
	
	public void PlayMeleeSound() {
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}
	public void PlayMeleeHitSound() {
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}

	public void PlayMeleeMissSound() {
		EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		#if defined DEBUG_SOUND
		PrintToServer("CGoreFast::PlayMeleeMissSound()");
		#endif
	}
	
	
	public Lanius(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		Lanius npc = view_as<Lanius>(CClotBody(vecPos, vecAng, "models/player/scout.mdl", "1.0", "1250", ally));
		
		i_NpcInternalId[npc.index] = RUINA_LANIUS;
		i_NpcWeight[npc.index] = 1;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE_ALLCLASS");
		if(iActivity > 0) npc.StartActivity(iActivity);
		
		
		/*
			Bunsen Brave		Robo_Heavy_Chief
			Claid					"models/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");	//claidemor
			Dark Helm - Lanius		Hw2013_The_Dark_Helm_(Class)
			Diplomat 			"models/workshop/player/items/soldier/dec15_diplomat/dec15_diplomat.mdl");
			Herzenvrecher		"models/workshop/player/items/medic/sf14_medic_herzensbrecher/sf14_medic_herzensbrecher.mdl");
		
		*/
		
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		
		
		SDKHook(npc.index, SDKHook_Think, Lanius_ClotThink);
		
		npc.m_flSpeed = 300.0;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.StartPathing();
		
		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");	//claidemor
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
		
		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/soldier/dec15_diplomat/dec15_diplomat.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");
		
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/medic/sf14_medic_herzensbrecher/sf14_medic_herzensbrecher.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable3, "SetModelScale");
		
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/heavy/robo_heavy_chief/robo_heavy_chief.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable4, "SetModelScale");
		
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/all_class/hw2013_the_dark_helm/hw2013_the_dark_helm_scout.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable5, "SetModelScale");
		
		int skin = 1;	//1=blue, 0=red
		SetVariantInt(1);	
		SetEntProp(npc.index, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable1, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", skin);
				
		npc.m_flNextTeleport = GetGameTime(npc.index) + 1.0;
				
		fl_ruina_battery[npc.index] = 0.0;
		b_ruina_battery_ability_active[npc.index] = false;
		fl_ruina_battery_timer[npc.index] = 0.0;
		
		Ruina_Set_Heirarchy(npc.index, 1);	//is a melee npc
		
		return npc;
	}
	
	
}

//TODO 
//Rewrite
public void Lanius_ClotThink(int iNPC)
{
	Lanius npc = view_as<Lanius>(iNPC);
	
	float GameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > GameTime)
	{
		return;
	}
	
	Ruina_Add_Battery(npc.index, 0.75);
	
	npc.m_flNextDelayTime = GameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();
			
	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > GameTime)
	{
		return;
	}
	
	npc.m_flNextThinkTime = GameTime + 0.1;

	
	int PrimaryThreatIndex = npc.m_iTarget;	//when the npc first spawns this will obv be invalid, the core handles this.

	Ruina_Ai_Override_Core(npc.index, PrimaryThreatIndex, GameTime);	//handles movement, also handles targeting
	
	if(fl_ruina_battery[npc.index]>500.0)
	{
		fl_ruina_battery[npc.index] = 0.0;
		fl_ruina_battery_timer[npc.index] = GameTime + 2.5;
		
	}
	if(fl_ruina_battery_timer[npc.index]>GameTime)	//apply buffs
	{
		Master_Apply_Speed_Buff(npc.index, 125.0, 1.0, 1.12);
	}
	if(IsValidEnemy(npc.index, PrimaryThreatIndex))	//a final final failsafe
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(PrimaryThreatIndex);
		
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
			
		if(npc.m_flNextTeleport < GameTime && flDistanceToTarget > (125.0* 125.0) && flDistanceToTarget < (500.0 * 500.0))
		{
			float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, PrimaryThreatIndex);
			static float flVel[3];
			GetEntPropVector(PrimaryThreatIndex, Prop_Data, "m_vecVelocity", flVel);
		
			if (flVel[0] >= 190.0)
			{
				npc.FaceTowards(vPredictedPos);
				npc.FaceTowards(vPredictedPos);
				npc.m_flNextTeleport = GameTime + 30.0;
				float Tele_Check = GetVectorDistance(WorldSpaceCenter(npc.index), vPredictedPos);
					
					
				float start_offset[3], end_offset[3];
				start_offset = WorldSpaceCenter(npc.index);
					
				if(Tele_Check > 200.0)
				{
					bool Succeed = NPC_Teleport(npc.index, vPredictedPos);
					if(Succeed)
					{
						npc.PlayTeleportSound();
							
						float effect_duration = 0.25;
	
						end_offset = WorldSpaceCenter(npc.index);
							
						start_offset[2]-= 25.0;
						end_offset[2] -= 25.0;
							
						for(int help=1 ; help<=8 ; help++)
						{	
							Lanius_Teleport_Effect(RUINA_BALL_PARTICLE_BLUE, effect_duration, start_offset, end_offset);
							
							start_offset[2] += 12.5;
							end_offset[2] += 12.5;
						}
					}
					else
					{
						npc.m_flNextTeleport = GameTime + 1.0;
					}
				}
			}
		}		
		int status=0;
		Ruina_Generic_Melee_Self_Defense(npc.index, PrimaryThreatIndex, flDistanceToTarget, 10000.0, 25.0, 125.0, "ACT_MP_ATTACK_STAND_MELEE_ALLCLASS", 0.54, 0.4, 20000.0, GameTime, status);
		switch(status)
		{
			case 1:	//we swung
				npc.PlayMeleeSound();
			case 2:	//we hit something
				npc.PlayMeleeHitSound();
			case 3:	//we missed
				npc.PlayMeleeMissSound();
			//0 means nothing.
		}
	}
	else
	{
		NPC_StopPathing(npc.index);
		npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	npc.PlayIdleAlertSound();
}

static void Lanius_Teleport_Effect(char type[255], float duration = 0.0, float start_point[3], float end_point[3])
{
	int part1 = CreateEntityByName("info_particle_system");
	if(IsValidEdict(part1))
	{
		TeleportEntity(part1, start_point, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(part1, "effect_name", type);
		SetVariantString("!activator");
		DispatchSpawn(part1);
		ActivateEntity(part1);
		AcceptEntityInput(part1, "Start");
		
		DataPack pack;
		CreateDataTimer(0.1, Timer_Move_Particle, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(EntIndexToEntRef(part1));
		pack.WriteCell(end_point[0]);
		pack.WriteCell(end_point[1]);
		pack.WriteCell(end_point[2]);
		pack.WriteCell(duration);
	}
}

public Action Lanius_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Lanius npc = view_as<Lanius>(victim);
		
	if(attacker <= 0)
		return Plugin_Continue;
		
	fl_ruina_battery[npc.index] += damage;	//turn damage taken into energy
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	
	return Plugin_Changed;
}

public void Lanius_NPCDeath(int entity)
{
	Lanius npc = view_as<Lanius>(entity);
	if(!npc.m_bGib)
	{
		npc.PlayDeathSound();	
	}
	
	
	SDKUnhook(npc.index, SDKHook_Think, Lanius_ClotThink);
		
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
	
}