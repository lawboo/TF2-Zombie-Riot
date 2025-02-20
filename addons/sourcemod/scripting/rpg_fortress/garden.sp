#pragma semicolon 1
#pragma newdecls required

enum struct GardenEnum
{
	char Zone[32];
	float Pos[3];
	
	int Store[MAXTF2PLAYERS];
	float StartAt[MAXTF2PLAYERS];
	float ReadyIn[MAXTF2PLAYERS];
}

static ArrayList GardenList;
static char InGarden[MAXTF2PLAYERS][32];
static float UpdateTrace[MAXTF2PLAYERS];
static int InMenu[MAXTF2PLAYERS] = {-1, ...};

void Garden_ResetAll()
{
	if(GardenList)
	{
		GardenEnum garden;
		int length = GardenList.Length;
		for(int i; i < length; i++)
		{
			GardenList.GetArray(i, garden);
			Zero(garden.ReadyIn);
			GardenList.SetArray(i, garden);
		}
	}
}

void Garden_ConfigSetup(KeyValues map)
{
	KeyValues kv = map;
	if(kv)
	{
		kv.Rewind();
		if(!kv.JumpToKey("Garden"))
			kv = null;
	}
	
	char buffer[PLATFORM_MAX_PATH];
	if(!kv)
	{
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "garden");
		kv = new KeyValues("Garden");
		kv.ImportFromFile(buffer);
	}
	
	delete GardenList;
	GardenList = new ArrayList(sizeof(GardenEnum));

	GardenEnum garden;

	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(garden.Zone, sizeof(garden.Zone));
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					ExplodeStringFloat(buffer, " ", garden.Pos, sizeof(garden.Pos));
					GardenList.PushArray(garden);
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}
		}
		while(kv.GotoNextKey());
	}

	if(kv != map)
		delete kv;
}

static int GetNearestGarden(const char[] zone, const float pos[3])
{
	int found = -1;
	float distance = 10000.0;
	
	int length = GardenList.Length;
	for(int i; i < length; i++)
	{
		static GardenEnum garden;
		GardenList.GetArray(i, garden);
		if(StrEqual(garden.Zone, zone, false))
		{
			float dist = GetVectorDistance(pos, garden.Pos, true);
			if(dist < distance)
			{
				found = i;
				distance = dist;
			}
		}
	}
	
	return found;
}

void Garden_ClientEnter(int client, const char[] zone)
{
	if(GardenList)
	{
		static GardenEnum garden;
		int length = GardenList.Length;
		for(int i; i < length; i++)
		{
			GardenList.GetArray(i, garden);
			if(StrEqual(garden.Zone, zone))
			{
				strcopy(InGarden[client], sizeof(InGarden[]), zone);
				UpdateTrace[client] = 0.0;
				break;
			}
		}
	}
}

void Garden_ClientLeave(int client, const char[] zone)
{
	if(StrEqual(InGarden[client], zone))
	{
		InGarden[client][0] = 0;
		if(InMenu[client] != -1)
			CancelClientMenu(client);
	}
}

void Garden_Interact(int client, const float pos[3])
{
	if(InGarden[client][0])
	{
		int index = GetNearestGarden(InGarden[client], pos);
		if(index != -1)
		{
			InMenu[client] = index;
			ShowMenu(client, true);
		}
	}
}

void Garden_PlayerRunCmd(int client)
{
	if(InGarden[client][0])
	{
		float gameTime = GetGameTime();
		if(UpdateTrace[client] < gameTime)
		{
			UpdateTrace[client] = gameTime + 3.0;
			
			int length = GardenList.Length;
			for(int i; i < length; i++)
			{
				static GardenEnum garden;
				GardenList.GetArray(i, garden);
				if(StrEqual(garden.Zone, InGarden[client], false))
				{
					if(garden.ReadyIn[client])
					{
						float time = garden.ReadyIn[client] - garden.StartAt[client];
						float left = garden.ReadyIn[client] - GetGameTime();
						int stage = 4 - RoundToCeil(left * 4.0 / time);
						if(stage > 4)
							stage = 4;
						
						PlantHasBeenPlanted(client, garden.Pos, stage);
					}
					else
					{
						NoPlantPlanted(client, garden.Pos);
						// No Plant
					}
				}
			}
			
			if(InMenu[client] != -1)
				ShowMenu(client, false);
		}
	}
}

stock void NoPlantPlanted(int client, float pos[3])
{
	static float m_vecMaxs[3];
	static float m_vecMins[3];
	m_vecMaxs = view_as<float>( { 10.0, 10.0, -5.0 } );
	m_vecMins = view_as<float>( { -10.0, -10.0, 5.0 } );	
	TE_DrawBox(client, pos, m_vecMins, m_vecMaxs, 3.5, view_as<int>({255, 0, 0, 255}));
}

stock void PlantHasBeenPlanted(int client, float pos[3], int stage)
{
	float temp[3];
	static float m_vecMaxs[3];
	static float m_vecMins[3];	
	temp = pos; 
	//since this wont ever be rotated, we dont have to bother with rotating this position
	switch(stage)
	{
		case 0: //new sprout!
		{
			temp[2] += 5.0;
			TE_SendBeam(client, pos, temp, 3.5, {0, 255, 0, 255}); //very new plant! we want it to be green.
		}
		case 1: //it grew abit! how cute!
		{
			temp[2] += 15.0;
			TE_SendBeam(client, pos, temp, 3.5, {50, 255, 0, 255}); //it grew abit, make it abit more yellow.
			m_vecMaxs = view_as<float>( { 5.0, 5.0, 10.0 } );
			m_vecMins = view_as<float>( { -5.0, -5.0, 0.0 } );	
			TE_DrawBox(client, temp, m_vecMins, m_vecMaxs, 3.5, view_as<int>({50, 255, 0, 255}));
		}
		case 2: //oh its abit more now!
		{
			temp[2] += 25.0;
			TE_SendBeam(client, pos, temp, 3.5, {100, 255, 0, 255}); //it grew abit, make it abit more yellow.
			m_vecMaxs = view_as<float>( { 10.0, 10.0, 20.0 } );
			m_vecMins = view_as<float>( { -10.0, -10.0, 0.0 } );	
			TE_DrawBox(client, temp, m_vecMins, m_vecMaxs, 3.5, view_as<int>({100, 255, 0, 255}));
		}
		case 3: //grow abit more, almost done!
		{
			temp[2] += 35.0;
			TE_SendBeam(client, pos, temp, 3.5, {150, 255, 0, 255}); //it grew abit, make it abit more yellow.

			m_vecMaxs = view_as<float>( { 15.0, 15.0, 30.0 } );
			m_vecMins = view_as<float>( { -15.0, -15.0, 0.0 } );
			TE_DrawBox(client, temp, m_vecMins, m_vecMaxs, 3.5, view_as<int>({150, 255, 0, 255}));
		}
		case 4: //its done!
		{
			float temp_2[3];
			float temp_3[3];
			temp_2 = pos;
			temp_3 = pos;
			temp[2] += 45.0;
			TE_SendBeam(client, pos, temp, 3.5, {255, 255, 0, 255}); //it grew abit, make it abit more yellow.

			temp_2[2] += 10.0;
			temp_3[2] += 35.0;
			temp_3[1] += 25.0;
			TE_SendBeam(client, temp_2, temp_3, 3.5, {255, 255, 0, 255}); //it grew abit, make it abit more yellow.

			m_vecMaxs = view_as<float>( { 20.0, 20.0, 40.0 } );
			m_vecMins = view_as<float>( { -20.0, -20.0, 0.0 } );
			TE_DrawBox(client, temp, m_vecMins, m_vecMaxs, 3.5, view_as<int>({255, 255, 0, 255}));
		}
	}
}

static void ShowMenu(int client, bool first)
{
	int index = InMenu[client];
	static GardenEnum garden;
	GardenList.GetArray(index, garden);
	
	static char num[16], buffer[64];
	if(garden.ReadyIn[client])
	{
		Menu menu = new Menu(Garden_GrowthHandle);
		
		TextStore_GetItemName(garden.Store[client], buffer, sizeof(buffer));
		menu.SetTitle("RPG Fortress\n \nGarden:\n%s\n ", buffer);
		
		int timeleft = RoundToCeil(garden.ReadyIn[client] - GetGameTime());
		if(timeleft > 0)
		{
			Format(buffer, sizeof(buffer), "%d:%02d", timeleft / 60, timeleft % 60);
			menu.AddItem(num, buffer, ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem(num, "Extract");
		}
		
		menu.AddItem(num, "Cancel");
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(first)
	{
		Menu menu = new Menu(Garden_PlantHandle);
		
		menu.SetTitle("RPG Fortress\n \nGarden:");
		
		int amount;
		int length = TextStore_GetItems();
		for(int i; i < length; i++)
		{
			KeyValues kv = TextStore_GetItemKv(i);
			if(kv)
			{
				kv.GetString("seed_result", buffer, sizeof(buffer));
				if(buffer[0])
				{
					TextStore_GetInv(client, i, amount);
					if(amount > 0)
					{
						IntToString(i, num, sizeof(num));
						TextStore_GetItemName(i, buffer, sizeof(buffer));
						Format(buffer, sizeof(buffer), "%s (%d)", buffer, amount);
						menu.AddItem(num, buffer);
					}
				}
			}
		}
		
		if(!menu.ItemCount)
			menu.AddItem(num, "No Seeds to Plant", ITEMDRAW_DISABLED);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	
	InMenu[client] = index;
}

public int Garden_PlantHandle(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			InMenu[client] = -1;
		}
		case MenuAction_Select:
		{
			static char buffer[48];
			menu.GetItem(choice, buffer, sizeof(buffer));
			
			int index = StringToInt(buffer);
			
			KeyValues kv = TextStore_GetItemKv(index);
			if(kv)
			{
				kv.GetString("seed_result", buffer, sizeof(buffer));
				if(buffer[0])
				{
					int amount;
					TextStore_GetInv(client, index, amount);
					if(amount > 0)
					{
						static GardenEnum garden;
						GardenList.GetArray(InMenu[client], garden);
						garden.Store[client] = index;
						garden.StartAt[client] = GetGameTime();
						garden.ReadyIn[client] = kv.GetFloat("seed_time", -0.1) + garden.StartAt[client];
						GardenList.SetArray(InMenu[client], garden);
						
						TextStore_SetInv(client, index, amount - 1);
						UpdateTrace[client] = 0.0;
					}
				}
			}
			
			ShowMenu(client, false);
		}
	}
	return 0;
}

public int Garden_GrowthHandle(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			InMenu[client] = -1;
		}
		case MenuAction_Select:
		{
			static GardenEnum garden;
			GardenList.GetArray(InMenu[client], garden);
			
			if(!choice)
			{
				KeyValues kv = TextStore_GetItemKv(garden.Store[client]);
				if(kv)
				{
					float luck = float(Stats_Luck(client));
					
					static char buffer[48];
					kv.GetString("seed_result", buffer, sizeof(buffer));
					if(buffer[0])
					{
						float low = kv.GetFloat("seed_min", 1.0);
						float high = kv.GetFloat("seed_max", 1.0);
						float rand = GetURandomFloat() * (1.0 + (luck / 50.0));
						if(rand > 1.0)
							rand = 1.0;
						
						TextStore_AddItemCount(client, buffer, RoundFloat(low + ((high - low) * rand)));
					}
					
					float rand = kv.GetFloat("seed_return");
					if(rand > 0.0)
					{
						rand *= 1.0 + (luck / 100.0);
						if(rand > GetURandomFloat())
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							TextStore_AddItemCount(client, buffer, 1);
						}
					}
				}
			}
			
			garden.ReadyIn[client] = 0.0;
			GardenList.SetArray(InMenu[client], garden);
			UpdateTrace[client] = 0.0;
			
			ShowMenu(client, true);
		}
	}
	return 0;
}