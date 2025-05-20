#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#pragma semicolon 1
#pragma newdecls required

Handle g_Sync;
Handle g_Timer;
Handle g_Cookie;
bool g_ShowTimeleft[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Timeleft on screen",
	author = "FAQU"
};

public void OnPluginStart()
{
	g_Cookie = RegClientCookie("timeleft_hud_toggle", "Toggle timeleft HUD visibility", CookieAccess_Protected);
	
	RegConsoleCmd("sm_tl", Command_ToggleTimeleft, "Toggles the timeleft HUD on/off");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnMapStart()
{
	g_Sync = CreateHudSynchronizer();
	g_Timer = CreateTimer(1.00, Timer_Timeleft, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	delete g_Sync; 
	delete g_Timer;
}

public void OnClientCookiesCached(int client)
{
	char buffer[8];
	GetClientCookie(client, g_Cookie, buffer, sizeof(buffer));
	
	if (buffer[0] == '\0')
	{
		g_ShowTimeleft[client] = true;
		SetClientCookie(client, g_Cookie, "1");
	}
	else
	{
		g_ShowTimeleft[client] = (buffer[0] == '1');
	}
}

public void OnClientDisconnect(int client)
{
	g_ShowTimeleft[client] = true;
}

public Action Command_ToggleTimeleft(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	g_ShowTimeleft[client] = !g_ShowTimeleft[client];
	
	SetClientCookie(client, g_Cookie, g_ShowTimeleft[client] ? "1" : "0");
	
	PrintToChat(client, "[SM] Timeleft HUD has been %s.", g_ShowTimeleft[client] ? "enabled" : "disabled");
	
	return Plugin_Handled;
}

public Action Timer_Timeleft(Handle timer)
{
	int time;
	char timeleft[32];
	
	GetMapTimeLeft(time);
	
	if (time > -1)
	{
		if (time > 3600)
		{
			FormatEx(timeleft, sizeof(timeleft), "Timeleft: %ih %02im", time / 3600, (time / 60) % 60);
		}
		else if (time < 60)
		{
			FormatEx(timeleft, sizeof(timeleft), "Timeleft: %02is", time);
		}
		else 
		{
			FormatEx(timeleft, sizeof(timeleft), "Timeleft: %im %02is", time / 60, time % 60);
		}
	}
			
	SetHudTextParams(-1.0, 0.06, 1.10, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && g_ShowTimeleft[i])
		{
			ShowSyncHudText(i, g_Sync, timeleft);
		}
	}
	
	return Plugin_Continue;
}