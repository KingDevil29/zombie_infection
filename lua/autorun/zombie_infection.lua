-----------------------------------------------------
if SERVER then
	resource.AddSingleFile("sound/death.wav") --death sound xD
	util.AddNetworkString("doZombieGesture")
	--config
	local infectious = {"npc_zombie"} --which npcs can infect the player?
	local chance = 1 --the chance of the player getting infected (for each claw strike).

	local function timersStop(ply)
		timer.Remove("zombie_Infected_" .. ply:SteamID())
		timer.Remove("zombie_HealthIncrease_" .. ply:SteamID())
	end

	local function turnZombie(ply)
		--weapons
		ply:StripWeapons() --priority so we don't see weapons in our hands at the start.
		ply:Give("zombie_claws")
		--rest
		ply:SetHealth(0)
		ply:Freeze(true)
		ply:SetJumpPower(0)
		ply:SetNWBool("isZombie", true)
		ply:SetRunSpeed(ply:GetWalkSpeed())
		ply:SendLua('surface.PlaySound("death.wav")')

		timer.Simple(2.7, function()
			if not ply:IsValid() then return end
			ply:ScreenFade(SCREENFADE.IN, color_white, 0.1, 0.1)

			timer.Simple(0.2, function()
				if ply:IsValid() then
					ply:ScreenFade(SCREENFADE.IN, color_white, 2, 1)
				end
			end)
		end)

		net.Start("doZombieGesture")
		net.WriteEntity(ply)
		net.WriteInt(ACT_HL2MP_ZOMBIE_SLUMP_RISE, 32)
		net.Broadcast()

		timer.Create("zombie_HealthIncrease_" .. ply:SteamID(), 0.001, 300, function()
			ply:SetHealth(ply:Health() + 1)
		end)

		timer.Simple(3.5, function()
			if ply:IsValid() then
				ply:Freeze(false)
			end
		end)

		timer.Remove("zombie_Infected_" .. ply:SteamID())
	end

	hook.Add("PlayerFootstep", "zombie_ChangeFootstep", function(ply)
		if ply:GetNWBool("isZombie") then
			ply:EmitSound("npc/zombie/foot" .. math.random(1, 3) .. ".wav")

			return true
		end
	end)

	hook.Add("PlayerUse", "zombie_DisableUse", function(ply, ent) return not ply:GetNWBool("isZombie") end)

	hook.Add("EntityTakeDamage", "zombie_InfectVictim", function(target, dmg)
		local attacker = dmg:GetAttacker()

		if target:IsPlayer() and not target:GetNWBool("isZombie") and not timer.Exists("zombie_Infected_" .. target:SteamID()) then
			if attacker:IsNPC() and table.HasValue(infectious, attacker:GetClass()) or attacker:IsPlayer() and attacker:GetNWBool("isZombie") then
				if math.random(1, chance) == 1 then
					target:PrintMessage(HUD_PRINTCENTER, "You've become infected.")

					timer.Create("zombie_Infected_" .. target:SteamID(), 1, 0, function()
						if target:Alive() then
							if math.random(1, 10) == 1 then
								target:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 60)
							end

							target:TakeDamage(1)
						end
					end)
				end
			end
		end
	end)

	hook.Add("PlayerDeath", "zombie_InfectEnd", function(victim, wep, attacker)
		if victim:IsPlayer() then
			if victim:GetNWBool("isZombie") then
				timersStop(victim)
				victim:SetNWBool("isZombie", false)

				return
			elseif timer.Exists("zombie_Infected_" .. victim:SteamID()) then
				victim.riseInfo = {
					pos = victim:GetPos(),
					model = victim:GetModel()
				}
			end

			if attacker:GetNWBool("isZombie") then
				net.Start("doZombieGesture")
				net.WriteEntity(attacker)
				net.WriteInt(ACT_GMOD_GESTURE_TAUNT_ZOMBIE, 32)
				net.Broadcast()
				attacker:SetHealth(attacker:Health() + math.random(25, 50))
			end
		end
	end)

	hook.Add("PlayerSpawn", "zombie_InfectedRise", function(ply)
		if ply.riseInfo then
			timer.Simple(0.1, function()
				if not ply:IsValid() then return end
				ply:SetModel(ply.riseInfo.model)

				timer.Simple(0.1, function()
					if ply:IsValid() then
						ply:SetPos(ply.riseInfo.pos)
						ply.riseInfo = nil
						turnZombie(ply)
					end
				end)
			end)
		end
	end)

	hook.Add("Think", "zombie_InfectedRelationship", function()
		for k, v in pairs(ents.FindByClass("npc_*")) do
			if table.HasValue(infectious, v:GetClass()) then
				for _, ply in pairs(player.GetAll()) do
					if ply:GetNWBool("isZombie") then
						v:AddEntityRelationship(ply, D_NU, 99)
					else
						v:AddEntityRelationship(ply, D_HT, 99)
					end
				end
			end
		end
	end)

	hook.Add("PlayerDisconnected", "zombie_InfectEnd", function(asshole)
		timersStop(asshole)
	end)

	hook.Add("playerCanChangeTeam", "zombie_DisableJob", function(ply)
		return not ply:GetNWBool("isZombie"), "You can't change jobs as a zombie!"
	end)

	concommand.Add("turnZombie", function(ply)
		if ply:IsAdmin() then
			local target = ply:GetEyeTrace().Entity

			if target:IsPlayer() and target:Alive() and not target:GetNWBool("isZombie") then
				turnZombie(target)
			else
				ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid target.")
			end
		else
			ply:PrintMessage(HUD_PRINTCONSOLE, "You need to be an admin to run this command.")
		end
	end)
else
	hook.Add("CalcView", "zombie_ThirdPerson", function(ply, pos, ang, fov)
		if ply:GetNWBool("isZombie") then
			local view = {}
			view.origin = pos - (ang:Forward() * 100)
			view.ang = ang
			view.fov = fov
			view.drawviewer = true

			return view
		end
	end)

	net.Receive("doZombieGesture", function()
		net.ReadEntity():AnimRestartGesture(GESTURE_SLOT_CUSTOM, net.ReadInt(32), true)
	end)
end

hook.Add("CalcMainActivity", "zombie_ChangeAnim", function(ply)
	if ply:GetNWBool("isZombie") then
		local seq = "zombie_walk_01"

		if ply:Crouching() then
			seq = "zombie_cwalk_01"
		end

		return true, ply:LookupSequence(seq)
	end
end)
