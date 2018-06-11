#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION	"1.0"
#define PLUGIN_DESC	"Admin Slap but it's like being slapped by a Pyro."
#define PLUGIN_NAME	"[TF2] Hothand Admin Slap"
#define PLUGIN_AUTH	"Glubbable"
#define PLUGIN_URL	"https://steamcommunity.com/groups/GlubsServers"

#define HOTHANDSLAP_SOUND1 "weapons/slap_hit1.wav"
#define HOTHANDSLAP_SOUND2 "weapons/slap_hit2.wav"
#define HOTHANDSLAP_SOUND3 "weapons/slap_hit3.wav"
#define HOTHANDSLAP_SOUND4 "weapons/slap_hit4.wav"

public const Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
}

ConVar g_cvSlapEnable;
ConVar g_cvSlapMode;
ConVar g_cvSlapInterval;
ConVar g_cvSlapDamage;
ConVar g_cvSlapMinForce;
ConVar g_cvSlapMaxForce;

bool g_bEnabled;
bool g_bRoundEnd;
int g_iSlapMode;
float g_flSlapInterval;
float g_flSlapDamage;
float g_flMinForce;
float g_flMaxForce;

int g_iSlapCount[MAXPLAYERS + 1];
float g_flSlapTargetDamage[MAXPLAYERS + 1];
Handle g_hSlapTimer[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("playercommands.phrases");
	
	g_cvSlapEnable = CreateConVar("sm_hothand_slap_enable", "1", "Enables/Disables Hot Hand Admin Slap", _, true, 0.0, true, 1.0);
	g_cvSlapMode = CreateConVar("sm_hothand_slap_mode", "2", "Determins the slap behaviour, 1 for single slaps only, 2 for repeative slapping.", _, true, 1.0, true, 2.0);
	g_cvSlapInterval = CreateConVar("sm_hothand_slap_time", "0.2", "How many seconds should pass between each slap that is applied to that target (by default). Requires Mode 2.", _, true, 0.1);
	g_cvSlapDamage = CreateConVar("sm_hothand_slap_damage", "10.0", "How much damage to deal to a victim per slap (by default). Requires Mode 2.", _, true, 0.0);
	g_cvSlapMinForce = CreateConVar("sm_hothand_min_force", "25.0", "How much min force should be applied to the client on each slap.", _, true, 0.0);
	g_cvSlapMaxForce = CreateConVar("sm_hothand_max_force", "500.0", "How much max force should be applied to the client on each slap.", _, true, 0.0);
	
	RegAdminCmd("sm_hotslap", Command_HotHandSlap, ADMFLAG_CHEATS, "Usage: [client] [damage] [count if mode 2] [delay between slaps if mode 2].");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	
	InitializeValues();
	HookConVars();
	PreCacheAssets();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		CleanClient(iClient);
	}
}

public void OnMapStart()
{
	PreCacheAssets();
}

public void OnClientPostAdminCheck(int iClient)
{
	CleanClient(iClient);
}

public void OnClientDisconnect(int iClient)
{
	CleanClient(iClient);
}

public void OnConfigsExecuted()
{
	InitializeValues();
}

public Action Event_RoundStart(Handle hEvent, const char[] sName, bool bDB)
{
	g_bRoundEnd = false;
}

public Action Event_RoundEnd(Handle hEvent, const char[] sName, bool bDB)
{
	g_bRoundEnd = true;
}

void HookConVars()
{
	HookConVarChange(g_cvSlapEnable, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapMode, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapInterval, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapDamage, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapMinForce, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapMaxForce, Hook_OnConVarChange);
}

void InitializeValues()
{
	g_bEnabled = GetConVarBool(g_cvSlapEnable);
	g_iSlapMode = GetConVarInt(g_cvSlapMode);
	g_flSlapInterval = GetConVarFloat(g_cvSlapInterval);
	g_flSlapDamage = GetConVarFloat(g_cvSlapDamage);
	g_flMinForce = GetConVarFloat(g_cvSlapMinForce);
	g_flMaxForce = GetConVarFloat(g_cvSlapMaxForce);
	
	g_bRoundEnd = false;
}

void PreCacheAssets()
{
	PrecacheSound2(HOTHANDSLAP_SOUND1);
	PrecacheSound2(HOTHANDSLAP_SOUND2);
	PrecacheSound2(HOTHANDSLAP_SOUND3);
	PrecacheSound2(HOTHANDSLAP_SOUND4);
}

void CleanClient(int iClient)
{
	g_iSlapCount[iClient] = 0; 
	g_hSlapTimer[iClient] = null;
	g_flSlapTargetDamage[iClient] = 0.0;
}

public void Hook_OnConVarChange(Handle hCvar, const char[] sOldValue, const char[] sNewValue)
{
	if (hCvar == g_cvSlapEnable && (StringToInt(sNewValue) != StringToInt(sOldValue)))
	{
		g_bEnabled = GetConVarBool(g_cvSlapEnable);
	}
	
	else if (hCvar == g_cvSlapMode && (StringToInt(sNewValue) != StringToInt(sOldValue)))
	{
		g_iSlapMode = GetConVarInt(g_cvSlapMode);
	}
	
	else if (hCvar == g_cvSlapInterval && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_flSlapInterval = GetConVarFloat(g_cvSlapInterval);
	}
	
	else if (hCvar == g_cvSlapDamage && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_flSlapDamage = GetConVarFloat(g_cvSlapDamage);
	}
	
	else if (hCvar == g_cvSlapMinForce && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_flMinForce = GetConVarFloat(g_cvSlapMinForce);
	}
	
	else if (hCvar == g_cvSlapMaxForce && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_flMaxForce = GetConVarFloat(g_cvSlapMaxForce);
	}
}

stock void PrecacheSound2(const char[] sPath)
{
	PrecacheSound(sPath, true);
	char sBuffer[PLATFORM_MAX_PATH];
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sPath);
	AddFileToDownloadsTable(sBuffer);
}

void PerformSlap(int iClient, int iTarget, float flDamage, int iCount, float flTime)
{
	if (!g_bEnabled) return;
	
	char sClientName[MAX_NAME_LENGTH];
	GetClientName(iClient, sClientName, sizeof(sClientName));
	
	char sTargetName[MAX_NAME_LENGTH];
	GetClientName(iTarget, sTargetName, sizeof(sTargetName));
	
	if (g_iSlapMode == 1 || iCount <= 1)
	{
		LogAction(iClient, iTarget, "%s has slapped %s.", sClientName, sTargetName);
		SlapTarget(iTarget, flDamage);
	}
		
	else if (g_iSlapMode == 2 && iCount > 1)
	{
		LogAction(iClient, iTarget, "%s has slapped %s for a total of %i times.", sClientName, sTargetName, iCount);
		g_iSlapCount[iTarget] = iCount;
		g_flSlapTargetDamage[iTarget] = flDamage;
		g_hSlapTimer[iTarget] = CreateTimer(flTime, Timer_RepeatSlap, iTarget, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(g_hSlapTimer[iTarget], true);
	}
}

void SlapTarget(int iClient, float flDamage)
{
	if (g_flMinForce != g_flMaxForce && g_flMinForce < g_flMaxForce)
	{
		float vecForce[3];
		int iRandom = GetRandomInt(1, 2);
		float flRandomValue = GetRandomFloat(g_flMinForce, g_flMaxForce);
		
		switch (iRandom)
		{
			case 1: vecForce[0] += flRandomValue;
			case 2: vecForce[0] -= flRandomValue;
		}
		
		iRandom = GetRandomInt(1, 2);
		switch (iRandom)
		{
			case 1: vecForce[1] += flRandomValue;
			case 2: vecForce[1] -= flRandomValue;
		}
		
		vecForce[2] += flRandomValue;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecForce);
	}
	
	int iRandomSound = GetRandomInt(1, 4);
	switch (iRandomSound)
	{
		case 1: EmitSoundToAll(HOTHANDSLAP_SOUND1, iClient);
		case 2: EmitSoundToAll(HOTHANDSLAP_SOUND2, iClient);
		case 3: EmitSoundToAll(HOTHANDSLAP_SOUND3, iClient);
		case 4: EmitSoundToAll(HOTHANDSLAP_SOUND4, iClient);
	}
	
	SDKHooks_TakeDamage(iClient, 0, 0, flDamage, DMG_CLUB);
}

public Action Timer_RepeatSlap(Handle hTimer, int iClient)
{
	if (!g_bEnabled || g_bRoundEnd) return Plugin_Stop;
	if (!IsClientConnected(iClient) || !IsClientInGame(iClient)) return Plugin_Stop;
	if (g_iSlapCount[iClient] == 0 || g_hSlapTimer[iClient] != hTimer) return Plugin_Stop;
	if (!IsPlayerAlive(iClient)) return Plugin_Continue;
	
	float flDamage = g_flSlapTargetDamage[iClient];
	SlapTarget(iClient, flDamage);
	
	if (g_iSlapCount[iClient] != 0)
	{
		g_iSlapCount[iClient]--;
	}
	
	return Plugin_Continue;
}

public Action Command_HotHandSlap(int client, int args)
{
	if (!g_bEnabled || g_bRoundEnd)
	{
		ReplyToCommand(client, "[SM] This command is currently unavailable!");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hotslap <#userid|name> [damage] [count] [delay]");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	float damage = g_flSlapDamage;
	if (args > 1)
	{
		char arg1[20];
		GetCmdArg(2, arg1, sizeof(arg1));
		if (StringToFloatEx(arg1, damage) == 0.0 || damage < 0.0)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
	}

	int count = 0;
	if (args > 2)
	{
		char arg2[20];
		GetCmdArg(3, arg2, sizeof(arg2));
		if (StringToIntEx(arg2, count) == 0 || count < 0)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(client, "[SM] Multi-slap is not enabled!");
			return Plugin_Handled;
		}
	}
	
	float time = g_flSlapInterval;
	if (args > 3)
	{
		char arg3[20];
		GetCmdArg(4, arg3, sizeof(arg3));
		if (StringToFloatEx(arg3, time) == 0.1 || time < 0.1)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
		
		if (time > 60.0)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(client, "[SM] Multi-slap is not enabled!");
			return Plugin_Handled;
		}
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		PerformSlap(client, target_list[i], damage, count, time);
	}

	if (tn_is_ml)
	{
		char client_name[MAX_NAME_LENGTH];
		GetClientName(client, client_name, sizeof(client_name));
		
		for (int ii = 1; ii <= MaxClients; ii++)
		{
			if (!IsClientConnected(ii) || !IsClientInGame(ii)) continue;
			if (CheckCommandAccess(ii, "showadminactivity", ADMFLAG_GENERIC))
			{
				PrintToChat(ii, "[SM] %t by %s", "Slapped target", target_name, client_name);
			}
		}
	}

	else
	{
		char client_name[MAX_NAME_LENGTH];
		GetClientName(client, client_name, sizeof(client_name));

		for (int ii = 1; ii <= MaxClients; ii++)
		{
			if (!IsClientConnected(ii) || !IsClientInGame(ii)) continue;
			if (CheckCommandAccess(ii, "showadminactivity", ADMFLAG_GENERIC))
			{
				PrintToChat(ii, "[SM] %t by %s", "Slapped target", "_s", target_name, client_name);
			}
		}
	}

	return Plugin_Handled;
}