#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>

#define TFTeam_Unassigned 0
#define TFTeam_Spectator 1
#define TFTeam_Red 2
#define TFTeam_Blue 3

#define PLUGIN_VERSION	"1.1"
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
ConVar g_cvSlapMeEnable;
ConVar g_cvSlapTeam;
ConVar g_cvSlapLimit;

bool g_bEnabled;
bool g_bSlapMeEnable;
bool g_bRoundEnd;
int g_iSlapMode;
int g_iSlapTeam;
int g_iSlapLimit;
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
	
	g_cvSlapEnable = CreateConVar("sm_hothand_slap_enable", "1", "Enables/Disables Hot Hand Slap", _, true, 0.0, true, 1.0);
	g_cvSlapMode = CreateConVar("sm_hothand_slap_mode", "2", "Determins the slap behaviour, 1 for single slaps only, 2 for repeative slapping.", _, true, 1.0, true, 2.0);
	g_cvSlapInterval = CreateConVar("sm_hothand_slap_time", "0.2", "How many seconds should pass between each slap that is applied to that target (by default). Requires Mode 2.", _, true, 0.1, true, 120.0);
	g_cvSlapDamage = CreateConVar("sm_hothand_slap_damage", "10.0", "How much damage to deal to a victim per slap (by default). Requires Mode 2.", _, true, 0.0);
	g_cvSlapMinForce = CreateConVar("sm_hothand_min_force", "25.0", "How much min force should be applied to the client on each slap.", _, true, 0.0);
	g_cvSlapMaxForce = CreateConVar("sm_hothand_max_force", "500.0", "How much max force should be applied to the client on each slap.", _, true, 0.0);
	
	g_cvSlapMeEnable = CreateConVar("sm_hothand_slapme_enable", "1", "Enables/Disables Slapme Command of Hot Hand Slap", _, true, 0.0, true, 1.0);
	g_cvSlapTeam = CreateConVar("sm_hothand_slap_team", "0", "Restricts the slapme behaviour so it will not affect a specific team. Default is 0 for off. 2 for RED, 3 for BLU.", _, true, 0.0, true, 3.0);
	g_cvSlapLimit = CreateConVar("sm_hothand_slap_limit", "100", "Max amount of times a client can self slap themselves.", _, true, 0.0, true, 100.0);
	
	RegAdminCmd("sm_hotslap", Command_HotHandSlap, ADMFLAG_CHEATS, "Slap People! Usage: [client] [damage] [count if mode 2] [delay between slaps if mode 2].");
	RegAdminCmd("sm_hotslapme", Command_HotHandSlap_Single, ADMFLAG_GENERIC, "Slap yourself! Usage: [damage] [count if mode 2] [delay between slaps if mode 2].");
	
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
	HookConVarChange(g_cvSlapTeam, Hook_OnConVarChange);
	HookConVarChange(g_cvSlapLimit, Hook_OnConVarChange);
}

void InitializeValues()
{
	g_bEnabled = GetConVarBool(g_cvSlapEnable);
	g_iSlapMode = GetConVarInt(g_cvSlapMode);
	g_flSlapInterval = GetConVarFloat(g_cvSlapInterval);
	g_flSlapDamage = GetConVarFloat(g_cvSlapDamage);
	g_flMinForce = GetConVarFloat(g_cvSlapMinForce);
	g_flMaxForce = GetConVarFloat(g_cvSlapMaxForce);
	g_bSlapMeEnable = GetConVarBool(g_cvSlapMeEnable);
	g_iSlapTeam = GetConVarInt(g_cvSlapTeam);
	g_iSlapLimit = GetConVarInt(g_cvSlapLimit);
	
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
	
	else if (hCvar == g_cvSlapMeEnable && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_bSlapMeEnable = GetConVarBool(g_cvSlapMeEnable);
	}
	else if (hCvar == g_cvSlapTeam && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_iSlapTeam = GetConVarInt(g_cvSlapTeam);
	}
	
	else if (hCvar == g_cvSlapLimit && (StringToFloat(sNewValue) != StringToFloat(sOldValue)))
	{
		g_iSlapLimit = GetConVarInt(g_cvSlapLimit);
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
		g_hSlapTimer[iTarget] = CreateTimer(flTime, Timer_RepeatSlap, GetClientUserId(iTarget), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(g_hSlapTimer[iTarget], true);
	}
}

void PerformSlapMe(int iClient, float flDamage, int iCount, float flTime)
{
	if (!g_bEnabled || !g_bSlapMeEnable) return;
	
	if (g_iSlapMode == 1 || iCount <= 1)
	{
		SlapTarget(iClient, flDamage);
	}
		
	else if (g_iSlapMode == 2 && iCount > 1)
	{
		g_iSlapCount[iClient] = iCount;
		g_flSlapTargetDamage[iClient] = flDamage;
		g_hSlapTimer[iClient] = CreateTimer(flTime, Timer_RepeatSlap, GetClientUserId(iClient), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(g_hSlapTimer[iClient], true);
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

public Action Timer_RepeatSlap(Handle hTimer, any iUserID)
{
	if (!g_bEnabled || g_bRoundEnd) return Plugin_Stop;
	
	int iClient = GetClientOfUserId(iUserID);
	if (iClient <= 0) return Plugin_Stop;
	
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

public Action Command_HotHandSlap_Single(int iClient, int iArgs)
{
	if (!g_bEnabled || g_bRoundEnd)
	{
		ReplyToCommand(iClient, "[SM] This command is currently unavailable!");
		return Plugin_Handled;
	}
	
	int iTeam = GetClientTeam(iClient);
	if (iTeam == g_iSlapTeam || iTeam == TFTeam_Spectator || iTeam == TFTeam_Unassigned)
	{
		ReplyToCommand(iClient, "[SM] Error. This command is not available for this team!");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		ReplyToCommand(iClient, "[SM] Error. You must be alive to use this command!");
		return Plugin_Handled;
	}
	
	float flDamage = g_flSlapDamage;
	if (iArgs > 0)
	{
		char sArg1[32];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		if (StringToFloatEx(sArg1, flDamage) == 0.0 || flDamage < 0.0)
		{
			ReplyToCommand(iClient, "[SM] Error. Damage cannot be below 0.");
			return Plugin_Handled;
		}
	}
	
	int iCount = 0;
	if (iArgs > 1)
	{
		char sArg2[32];
		GetCmdArg(2, sArg2, sizeof(sArg2));
		if (StringToIntEx(sArg2, iCount) == 0 || iCount < 0)
		{
			ReplyToCommand(iClient, "[SM] Error. Count cannot be below 0.");
			return Plugin_Handled;
		}
		
		if (iCount > g_iSlapLimit && g_iSlapLimit != 0)
		{
			ReplyToCommand(iClient, "[SM] Error. Slap Count is above limit of %i slaps!", g_iSlapLimit);
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(iClient, "[SM] Error. Multi-slap is not enabled!");
			return Plugin_Handled;
		}
	}
	
	float flTime = g_flSlapInterval;
	if (iArgs > 2)
	{
		char sArg3[32];
		GetCmdArg(3, sArg3, sizeof(sArg3));
		if (StringToFloatEx(sArg3, flTime) == 0.1 || flTime < 0.1)
		{
			ReplyToCommand(iClient, "[SM] Error. Delay Time cannot be below 0.1 seconds.");
			return Plugin_Handled;
		}
		
		if (flTime > 120.0)
		{
			ReplyToCommand(iClient, "[SM] Error. Delay Time cannot be above 120 seconds.");
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(iClient, "[SM] Error. Multi-slap is not enabled!");
			return Plugin_Handled;
		}
	}
	
	PerformSlapMe(iClient, flDamage, iCount, flTime);
	return Plugin_Handled;
}

public Action Command_HotHandSlap(int iClient, int args)
{
	if (!g_bEnabled || g_bRoundEnd)
	{
		ReplyToCommand(iClient, "[SM] This command is currently unavailable!");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_hotslap <#userid|name> [damage] [count] [delay]");
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
			ReplyToCommand(iClient, "[SM] Error. Damage cannot be below 0.");
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
			ReplyToCommand(iClient, "[SM] Error. Count cannot be below 0.");
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(iClient, "[SM] Error. Multi-slap is not enabled!");
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
			ReplyToCommand(iClient, "[SM] Error. Delay Time cannot be below 0.1 seconds.");
			return Plugin_Handled;
		}
		
		if (time > 120.0)
		{
			ReplyToCommand(iClient, "[SM] Error. Delay Time cannot be above 120 seconds.");
			return Plugin_Handled;
		}
		
		else if (g_iSlapMode < 2)
		{
			ReplyToCommand(iClient, "[SM] Error. Multi-slap is not enabled!");
			return Plugin_Handled;
		}
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		PerformSlap(iClient, target_list[i], damage, count, time);
	}

	if (tn_is_ml)
	{
		char client_name[MAX_NAME_LENGTH];
		GetClientName(iClient, client_name, sizeof(client_name));
		
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
		GetClientName(iClient, client_name, sizeof(client_name));

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