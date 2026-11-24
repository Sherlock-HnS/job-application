hook.Add("OnEntityCreated", "jobt_initialize_gem_2", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
local entity
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 90, {
        filter = function(v)

            local trace = util.TraceLine({
                start = ent:EyePos(),
                endpos = v:EyePos(),
                filter = {ent, ply},
                mask = MASK_VISIBLE
            })
            return not trace.Hit
        end,
    })
else
for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 130)) do
            if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                if v == ent or v == ply then continue end

                if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                    local trace = util.TraceLine({
                        start = ent:EyePos(),
                        endpos = v:EyePos(),
                        filter = {ent, ply},
                        mask = MASK_VISIBLE
                    })

                    if not trace.Hit then
                        entity = v
                        break
                    end
                end
            end
        end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 7.5, {
                camera = "job_jumpscare_gen",
                offset = 60,
                animation = "kill",
                sound = "kill",
            })
        end

        if not IsValid(entity) then return end

        local pill = ent:GetPuppet()

        if entity:IsPlayer() then
            entity:Freeze(true)
            entity:AddFlags(FL_NOTARGET)
            entity:DrawViewModel(false)
            entity:SetActiveWeapon(nil)

            net.Start('job_jumpscare_gen')
            net.WriteEntity(pill)
            net.WriteBool(true)
            net.Send(entity)
        else
            entity:NextThink(CurTime() + 1e9)
        end

        entity:SetPos(pill:GetPos() + pill:GetForward() * 60)

        ent.jumpscare_entity = entity
        ent.entitylastpos = entity:GetPos()
        ent.entitylastang = entity:GetAngles()

        ent.JumpscareStart = CurTime()

            
        ply:Freeze(true)

        ent:PillAnim('kill')
        ent:PillSound('kill')

        timer.Simple(7.5, function()
            if not (IsValid(entity) and IsValid(ent)) then return end

            ply:Freeze(false)

            if entity:IsPlayer() then
                entity:Kill(ply)

                net.Start('job_jumpscare_gen')
                net.WriteEntity(pill)
                net.WriteBool(false)
                net.Send(entity)

                entity:RemoveFlags(FL_NOTARGET)
                entity:Freeze(false)
                entity:DrawViewModel(true)
            else
                entity:NextThink(CurTime())
                entity:TakeDamage(1e9, ply)
            end
        end)

        timer.Simple(10, function()
            ent:PillSound('afterkill')
        end)

        timer.Simple(10, function()
            ply.OnHold = false
            entity = nil -- clear after done
        end)
    end,
},


	
    --Right Click Attack Function
    attack2 = {
        mode = "trigger",
        func = function(ply, ent)
        end,
    },
    
    
    

noragdoll=true,
	
	-- R click function
   	reload=function(ply,ent)
 if not IsValid(ply) then return end

        ent.highlightlineplaying = true

        local cooldown = 30
        local lastUse = ply._lastWallUse or 0
        local now = CurTime()

        if now - lastUse < cooldown then
            local timeLeft = math.ceil(cooldown - (now - lastUse))
            ply:ChatPrint("Highlight on cooldown: " .. timeLeft .. "s left.")
            return
        end

        if ply.OnHold then return end

        ent:PillSound("highlight")
        ply:SetNWBool("jobwallhaks", true)
        ply.wallsdelay = true
        ply._lastWallUse = now
        timer.Simple(10, function()
            if IsValid(ply) then
                ply:SetNWBool("jobwallhaks", false)
            end
        end)

        timer.Simple(cooldown, function()
            if IsValid(ply) then
                ply.wallsdelay = false
            end
        end)
        
         if SERVER then
            net.Start("jobhighlightCooldown")
            net.Send(ply) 
        end
    end,

	
    -- F Click function
    flashlight=function(ply,ent)

    end,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end,
    

    think_n_job = function(ply, ent)
        if ent.jumpscare_entity then
            local entity = ent.jumpscare_entity
            if IsValid(entity) then

                local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                if entity:Health() < 0.1 and entity:IsPlayer() then
                    ent.jumpscare_entity = nil
                else
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local lengthofentitybody = (maxs.z - mins.z)/0.7

                    local lerpFactor = math.Clamp((CurTime() - ent.JumpscareStart) / 0.5, 0, 1)
                    local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                    local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                    entity:SetPos(NewVector)
                end
            end
        end
    end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "highlight", name = "Revelar jogadores", key = IN_RELOAD, cooldown = 30, duration = 10,
            CanUse = function(ply) return not ply.OnHold end,
            OnUse = function(ply, ent)
                ent:PillSound("highlight")
                ply:SetNWBool("jobwallhaks", true)
            end,
            OnEnd = function(ply) if IsValid(ply) then ply:SetNWBool("jobwallhaks", false) end end },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)



    hook.Add("Think", "TrackPillCostumesjob", function()
    for i, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        if !IsValid(ent) then continue end
        local ply = ent:GetPillUser()
        local puppet = ent:GetPuppet()

        if not IsValid(puppet) or not IsValid(ply) then continue end

        if ent.formTable.think_n_job then
            ent.formTable.think_n_job(ply, ent)
        end
    end
end)

