#pragma semicolon 1
#pragma newdecls required

//this thing is *kinda* an npc, but also not really


static const char g_DeathSounds[][] = {
	"vo/spy_paincrticialdeath01.mp3",
	"vo/spy_paincrticialdeath02.mp3",
	"vo/spy_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = {
	"vo/spy_painsharp01.mp3",
	"vo/spy_painsharp02.mp3",
	"vo/spy_painsharp03.mp3",
	"vo/spy_painsharp04.mp3",
};

static const char g_MeleeHitSounds[][] = {
	"weapons/dragons_fury_shoot.wav",
};

static int i_following_id[MAXENTITIES];

void Ruina_Storm_Weaver_Mid_MapStart()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_HurtSounds));		i++) { PrecacheSound(g_HurtSounds[i]);		}
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	i++) { PrecacheSound(g_MeleeHitSounds[i]);	}

	PrecacheModel(RUINA_STORM_WEAVER_MODEL);

}

methodmap Storm_Weaver_Mid < CClotBody
{
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
	
	public void PlayMeleeHitSound() {
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, RUINA_NPC_PITCH);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}
	
	public Storm_Weaver_Mid(int client, float vecPos[3], float vecAng[3], bool ally, float in_line_id)
	{
		Storm_Weaver_Mid npc = view_as<Storm_Weaver_Mid>(CClotBody(vecPos, vecAng, RUINA_STORM_WEAVER_MODEL, RUINA_STORM_WEAVER_MODEL_SIZE, "1250", ally));
		
		i_NpcInternalId[npc.index] = RUINA_STORM_WEAVER_MID;
		i_NpcWeight[npc.index] = 999;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");

		
		i_following_id[npc.index] = EntIndexToEntRef(RoundToFloor(in_line_id));


		if(!ally)
		{
			b_thisNpcIsABoss[npc.index] = true;
		}
		
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		Ruina_Set_Heirarchy(npc.index, 2);

		Ruina_Set_No_Retreat(npc.index);

		
		
		SDKHook(npc.index, SDKHook_Think, Storm_Weaver_Mid_ClotThink);
		
		npc.m_flGetClosestTargetTime = 0.0;

		NPC_StopPathing(npc.index);
		npc.m_bPathing = false;

		b_NoGravity[npc.index] = true;	//Found ya!

		b_DoNotUnStuck[npc.index] = true;

		b_NoKnockbackFromSources[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;

		return npc;
	}
	
}


//TODO 
//Rewrite
public void Storm_Weaver_Mid_ClotThink(int iNPC)
{
	Storm_Weaver_Mid npc = view_as<Storm_Weaver_Mid>(iNPC);
	
	float GameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > GameTime)
	{
		return;
	}

	npc.m_flNextDelayTime = GameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();
			
	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > GameTime)
	{
		return;
	}
	
	npc.m_flNextThinkTime = GameTime + 0.1;
	
	if(npc.m_flGetClosestTargetTime < GameTime)
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = GameTime + GetRandomRetargetTime();
	}

	int PrimaryThreatIndex = npc.m_iTarget;

	int follow_id = EntRefToEntIndex(i_following_id[npc.index]);

	if(IsValidEntity(follow_id))
	{
		float Follow_Loc[3];
		GetEntPropVector(follow_id, Prop_Send, "m_vecOrigin", Follow_Loc);

		int I_see=Can_I_See_Ally(npc.index, follow_id);
		if(I_see==follow_id)
		{
			Storm_Weaver_Middle_Movement(npc, Follow_Loc, false);	//we can see it, travel normally!
		}
		else
		{
			Storm_Weaver_Middle_Movement(npc, Follow_Loc, true);	//we can't see the thing we are following, noclip
		}
		
	}


	if(IsValidEnemy(npc.index, PrimaryThreatIndex))
	{
		int Enemy_I_See;
				
		Enemy_I_See = Can_I_See_Enemy(npc.index, PrimaryThreatIndex);
		//Target close enough to hit
		if(IsValidEnemy(npc.index, Enemy_I_See)) //Check if i can even see.
		{
			float vecTarget[3];
			vecTarget = WorldSpaceCenter(PrimaryThreatIndex);

			if(GameTime > npc.m_flNextRangedAttack)
			{
				npc.PlayMeleeHitSound();

				float DamageDone = 100.0*RaidModeScaling;
				npc.FireParticleRocket(vecTarget, DamageDone, 1250.0, 0.0, "spell_fireball_small_blue", false, true, false,_,_,_,10.0);
				npc.m_flNextRangedAttack = GameTime + 5.0;
			}
		}
	}
	else
	{
		
	}


}
public Action Storm_Weaver_Mid_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Storm_Weaver_Mid npc = view_as<Storm_Weaver_Mid>(victim);
		
	if(attacker <= 0)
		return Plugin_Continue;
		
	if(!b_storm_weaver_solo)
	{
		Storm_Weaver_Share_With_Anchor_Damage(attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition);
		fl_ruina_battery[npc.index] += damage;	//turn damage taken into energy

		SetEntProp(npc.index, Prop_Data, "m_iHealth", Storm_Weaver_Return_Health());
	}

	damage=0.0;	//storm weaver doesn't really take any damage, his "health bar" is just the combined health of all the towers
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	
	return Plugin_Changed;
}

public void Storm_Weaver_Mid_NPCDeath(int entity)
{
	Storm_Weaver_Mid npc = view_as<Storm_Weaver_Mid>(entity);
	if(!npc.m_bGib)
	{
		npc.PlayDeathSound();	
	}
	
	
	SDKUnhook(npc.index, SDKHook_Think, Storm_Weaver_Mid_ClotThink);

}