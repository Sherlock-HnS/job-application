--------------------------
-- BOOTSTRAP CODE START --
--------------------------

hook.Add( "PreDrawHalos", "GETAJOB", function()
	local white = Color(255,255,255)

	if ( LocalPlayer():GetNWBool('jobwallhaks') == true ) then
		local plyrs = {}
		plyrs = ents.FindByClass("player*")
		for i,plr in ipairs(plyrs) do
    		if plr == LocalPlayer() then table.remove(plyrs, i) end
		end	 
		halo.Add(plyrs, white, 5, 5, 50, true, true )
	end
end )	

if !pcall(require,"pk_pills") then
	if SERVER then
		hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
			if game.SinglePlayer() || ply:IsListenServerHost() then
				ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
			end
		end)
		hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
			print("[ALERT] One or more pill extensions failed to load. Did you forget to install Parakeet's Pill Pack?")
		end)
	end
	return
end


hook.Add("SetupPlayerVisibility", "VisibilityHandler", function()
	for i, plr in ipairs(player.GetAll()) do
		AddOriginToPVS(plr:GetPos())
	end
end)
------------------------
-- BOOTSTRAP CODE END --
------------------------

AddCSLuaFile()
include("include/job.lua")
