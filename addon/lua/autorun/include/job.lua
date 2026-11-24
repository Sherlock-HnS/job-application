hook.Add("OnEntityCreated", "jobt_initialize_gem_2", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if ent.formTable.job_initialize then
                ent.formTable:job_initialize(entityply, ent, PuppetEntity)
                 hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex(), function(ply) if entityply == ply then return true end end)

                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())
                    end)

                local self = ent
                ent.Think = function()
                    local ply = self:GetPillUser()
                    local puppet = self:GetPuppet()
                    if not IsValid(puppet) or not IsValid(ply) then return end
                    local vel = ply:GetVelocity():Length()

                    if SERVER then
                        --Anims
                        local anims = table.Copy(self.formTable.anims.default or {})
                        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                        local anim
                        --local useSeqVel=true
                        local overrideRate

                        if (not self.anim or not anims[self.anim]) then
                            self.animFreeze = nil
                            self.animStart = nil
                        end

                        if self.animFreeze and not self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = nil
                        end

                        if self.anim and anims[self.anim] then
                            anim = anims[self.anim]
                            overrideRate = anims[self.anim .. "_rate"] or 1
                            local cycle = puppet:GetCycle()

                            if not self.animStart then
                                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                    self.anim = nil
                                    self.animCycle = nil

                                    if self.animFreeze then
                                        self.animFreeze = nil
                                    end
                                elseif self.animCycle then
                                    self.animCycle = cycle
                                end
                            end
                        elseif self.tickAnim and anims[self.tickAnim] then
                            anim = anims[self.tickAnim]
                            overrideRate = anims[self.tickAnim .. "_rate"] or 1
                            self.tickAnim = nil
                        elseif self.burrowed then
                            anim = anims["burrow_loop"]
                        elseif ply:WaterLevel() > 2 then
                            anim = anims["swim"] or anims["glide"] or anims["idle"]
                        elseif ply:IsOnGround() then
                            if ply:Crouching() then
                                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                else
                                    anim = anims["crouch"] or anims["idle"]
                                end
                            else
                                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                    anim = anims["run"] or anims["walk"] or anims["idle"]
                                elseif vel > ply:GetWalkSpeed() / 4 then
                                    anim = anims["walk"] or anims["idle"]
                                else
                                    anim = anims["idle"]
                                end
                            end
                        else
                            anim = anims["glide"] or anims["idle"]
                        end

                        if anim == anims["idle"] or anim == anims["crouch"] then
                            overrideRate = 1
                        end

                        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                            puppet:ResetSequence(puppet:LookupSequence(anim))
                            puppet:SetCycle(0)
                            self.animCycle = 0
                        end

                        self.animStart = nil
                        local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                        --if true then
                        if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                            local rate = overrideRate or vel / seq_vel

                            --goofy limitation (floods console with errors if above 12!)
                            if rate > 12 then
                                rate = 12
                            end

                            puppet:SetPlaybackRate(rate)
                        else
                            --puppet:SetPlaybackRate(1)
                        end

                        --print(puppet:GetCycle())
                        if self.formTable.movePoseMode then
                            --
                            if self.formTable.movePoseMode == "yaw" then
                                local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                puppet:SetPoseParameter("move_yaw", move_dir.y)
                            elseif self.formTable.movePoseMode == "xy" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                end
                            elseif self.formTable.movePoseMode == "xy-bot" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                    puppet:SetPoseParameter("move_scale", 1)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                    puppet:SetPoseParameter("move_yaw", 0)
                                    puppet:SetPoseParameter("move_scale", 0)
                                end
                            end
                        end

                        --Aimage
                        if self.formTable.aim then
                            if self.formTable.aim.xPose then
                                local yaw = math.AngleDifference(ply:EyeAngles().y, self:GetAngles().y)

                                if self.formTable.aim.xInvert then
                                    yaw = -yaw
                                end

                                puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                            end

                            if self.formTable.aim.yPose then
                                local pitch = math.AngleDifference(ply:EyeAngles().p, self:GetAngles().p)

                                if self.formTable.aim.yInvert then
                                    pitch = -pitch
                                end

                                puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                            end
                        end

                        --gliding and landing
                        if not ply:IsOnGround() and ply:WaterLevel() == 0 and self.formTable.glideThink then
                            self.formTable.glideThink(ply, self)
                        end

                        if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                            self.formTable.land(ply, self)
                        end

                        --water death
                        self.touchingWater = ply:WaterLevel() > 1

                        if not SherlockHNS and self.formTable.damageFromWater and self.touchingWater then
                            if self.formTable.damageFromWater == -1 then
                                --self:PillDie()
                                ply:Kill()
                            else
                                ply:TakeDamage(self.formTable.damageFromWater)
                                --TODO APPLY DAMAGE
                            end
                        end

                        --tick attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end

                        --auto attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack")
                            else
                                self:PillLoopStop("attack")
                            end

                            if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                                self.lastAttack = CurTime()
                            end
                        else
                            self:PillLoopStop("attack")
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack2")
                            else
                                self:PillLoopStop("attack2")
                            end

                            if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                self.lastAttack2 = CurTime()
                            end
                        else
                            self:PillLoopStop("attack2")
                        end

                        --charge
                        if not SherlockHNS and self:GetChargeTime() ~= 0 then
                            if ply:OnGround() then
                                local charge = self.formTable.charge
                                local angs = ply:EyeAngles()
                                self:PillAnimTick("charge_loop")
                                local hit_ent = ply:TraceHullAttack(ply:EyePos(), ply:EyePos() + angs:Forward() * 100, Vector(-20, -20, -20), Vector(20, 20, 20), charge.dmg, DMG_CRUSH, 1, true)

                                if IsValid(hit_ent) then
                                    self:PillAnim("charge_hit", true)
                                    --self:PillGesture("charge_hit")
                                    self:PillSound("charge_hit")
                                    self:SetChargeTime(0)
                                    self:PillLoopStop("charge")
                                end
                            else
                                self:SetChargeTime(0)
                                self:PillLoopStop("charge")
                            end
                        end

                        --Cloak
                        if self.formTable.cloak then
                            local cloak = self.formTable.cloak

                            if self.iscloaked then
                                local cloakamt = self:GetCloakLeft()

                                if cloakamt ~= -1 then
                                    cloakamt = cloakamt - FrameTime()

                                    if cloakamt < 0 then
                                        cloakamt = 0
                                        self:ToggleCloak()
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            else
                                local cloakamt = self:GetCloakLeft()

                                if cloakmt ~= -1 and cloakamt < cloak.max then
                                    cloakamt = cloakamt + FrameTime() * cloak.rechargeRate

                                    if cloakamt > cloak.max then
                                        cloakamt = cloak.max
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            end

                            local color = self:GetPuppet():GetColor()

                            if self.iscloaked then
                                if color.a > 0 then
                                    color.a = color.a - 5
                                    self:GetPuppet():SetColor(color)
                                end
                            else
                                if color.a < 255 then
                                    color.a = color.a + 5
                                    self:GetPuppet():SetColor(color)
                                end
                            end

                            --PrintTable(color)
                            if IsValid(self.wepmdl) and self.wepmdl:GetColor().a ~= color.a then
                                self.wepmdl:SetColor(color)
                            end
                        end

                        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                        --wepon-no longer SO hackey
                        if not self.formTable.hideWeapons then
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                            if IsValid(realWep) and realWep:GetModel() ~= "" then
                                --hiding the real thing [BROKEN]
                                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                    realWep:SetRenderMode(RENDERMODE_NONE)
                                end]]
                                if realWep.pill_attachment then
                                    if IsValid(self.wepmdl) then
                                        self.wepmdl:Remove()
                                    end

                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl.attachment = realWep.pill_attachment
                                    self.wepmdl:Spawn()

                                    if realWep.pill_offset then
                                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                                    end

                                    if realWep.pill_angle then
                                        self.wepmdl:SetWepAng(realWep.pill_angle)
                                    end

                                    realWep.pill_proxy = self.wepmdl
                                elseif not IsValid(self.wepmdl) then
                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl:Spawn()
                                    realWep.pill_proxy = self.wepmdl
                                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                    self.wepmdl:SetModel(realWep:GetModel())
                                end
                            elseif IsValid(self.wepmdl) then
                                self.wepmdl:Remove()
                            end
                        end
                    else
                        self:SetNWBool('clientsideshould', not pk_pills.convars.cl_thirdperson:GetBool())

                        if self:GetPillUser() ~= LocalPlayer() or true then
                            puppet:SetNoDraw(false)
                        end

                        local realWep = self:GetPillUser():GetActiveWeapon()

                        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                            realWep:SetNoDraw(true)
                        end
                    end

                    --Align pos and angles with player
                    if SERVER then
                        puppet:SetPos(ply:GetPos())
                        self:SetAngles(ply:GetAngles())
                    else
                        puppet:SetRenderOrigin(ply:GetPos())
                    end

                    if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 or self:GetNWBool('clientsideshould') then
                        local angs = ply:EyeAngles()
                        angs.p = 0

                        if SERVER then
                            puppet:SetAngles(angs)
                        else
                            --puppet:SetAngles(angs)
                            puppet:SetRenderAngles(angs)
                        end
                    end

                    self:NextThink(CurTime())

                    return true
                end


            else
            end
        end

        if ent.formTable.HandleAnimEvent_g_rac then
            print(1)
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if IsValid(PuppetEntity) then
                print(2)
                function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                    ent.formTable.HandleAnimEvent_g_rac(entityply, ent, inputName)
                    return true
                end
            end
        else
            print(0)
        end
    end)
end)

hook.Add("Think", "TrackPillCostumes_job", function()
    for _, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        if !IsValid(ent) then continue end
        local ply = ent:GetPillUser()
        local puppet = ent:GetPuppet()

        if not IsValid(puppet) or not IsValid(ply) then continue end

        if ent.formTable.think_n_job then
            ent.formTable.think_n_job(ply, ent)
        end
    end
end)



if SERVER then
    AddCSLuaFile()
    util.AddNetworkString('job_jumpscare_gen')

else

    hook.Remove("CalcView", "momo_calcview")

    hook.Add("CalcView", "momo_calcview", function(ply, pos, ang, fov)
        local ent = pk_pills.getMappedEnt(LocalPlayer())

        if IsValid(ent) and ply:GetViewEntity() == ply then
            local startpos

            if ent.formTable.type == "phys" then
                startpos = ent:LocalToWorld(ent.formTable.camera and ent.formTable.camera.offset or Vector(0, 0, 0))
            else
                startpos = pos
            end

            if pk_pills.convars.cl_thirdperson:GetBool() then

                if ent.formTable.ThirdPersonBone then

                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.ThirdPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)

                        local dist

                        if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                            dist = ent:BoundingRadius() * 5
                        else
                            dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                        end
                        local startpos = bonePos + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.ThirdPersonBone[3])
                        local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                        local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                        local tr = util.TraceHull({
                            start = startpos,
                            endpos = startpos + offset,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })

                        local view = {}
                        view.origin = tr.HitPos
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = true

                        return view
                    end
                end

                local dist

                if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                    dist = ent:BoundingRadius() * 5
                else
                    dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                end

                local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                local tr = util.TraceHull({
                    start = startpos,
                    endpos = startpos + offset,
                    filter = ent.camTraceFilter,
                    mins = Vector(-5, -5, -5),
                    maxs = Vector(5, 5, 5),
                    mask = MASK_VISIBLE
                })

                local view = {}
                view.origin = tr.HitPos
                view.angles = ang
                view.fov = fov
                view.drawviewer = true

                return view
            else
                if ent.formTable.FirstPersonBone then
                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.FirstPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                        local view = {}
                        view.origin = bonePos + LocalPlayer():GetForward() * (ent.formTable.FirstPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.FirstPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.FirstPersonBone[3])
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = false
                        return view
                    end
                end
            end
        end
    end)


    


    hook.Add("SetupPlayerVisibility", "VisibilityHandler_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if ( pillentity:GetNWInt('Swallhaks', 0) >= CurTime() ) then

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            AddOriginToPVS(plr:GetPos())
                        end
                    end
                end
            end
        end
    end)

    hook.Add( "PreDrawHalos", "jobseason_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if ( pillentity:GetNWInt('Fwallhaks', 0) >= CurTime() ) then
                local entities = {}

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            if ent == ply then continue end 
                            if ent == pillentity then continue end 
                            if ent:IsPlayer() and ent:Team() == TEAM_SPECTATOR then continue end

                            if ent:GetColor().a <= 30 then continue end
                            if ent:GetClass() == "pill_puppet" then continue end

                            table.insert(entities, ent)
                            
                        end
                    end
                end

                local alpha = 0
                local endTime = pillentity:GetNWInt('Fwallhaks', 0) 

                if endTime > CurTime() then
                    local totalDuration = 10
                    local startTime = endTime - totalDuration
                    local fadeDuration = 1
                    if CurTime() < startTime + fadeDuration then
                        alpha = Lerp((CurTime() - startTime) / fadeDuration, 0, 155)
                    elseif CurTime() > endTime - fadeDuration then
                        alpha = Lerp((endTime - CurTime()) / fadeDuration, 0, 155)
                    else
                        alpha = 155
                    end
                end

                halo.Add(entities, Color(alpha,0,alpha), 5, 5, 50, true, true)
            end
        end
    end )


    net.Receive('job_jumpscare_gen', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "job_jumpscare_" .. LocalPlayer():SteamID()

        --print(state)

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 75 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)
end

local function AdvancedPillSound(SoundData, ent)
    if IsValid(ent) then
        SoundData = SoundData or {}
        SoundData.stringe = SoundData.stringe or {}
        SoundData.soundLevel = SoundData.soundLevel or 75
        SoundData.pitchPercent = SoundData.pitchPercent or 100
        SoundData.volume = SoundData.volume or 1
        SoundData.channel = SoundData.channel or CHAN_AUTO
        SoundData.soundFlags = SoundData.soundFlags or 0
        SoundData.dsp = SoundData.dsp or 0
        SoundData.filter = SoundData.filter or nil

        local chosenSound = SoundData.stringe

        if istable(SoundData.stringe) then
            local index = math.random(1, #SoundData.stringe)
            chosenSound = SoundData.stringe[index]
        end

        ent:EmitSound(
            chosenSound,
            SoundData.soundLevel,
            SoundData.pitchPercent,
            SoundData.volume,
            SoundData.channel,
            SoundData.soundFlags,
            SoundData.dsp,
            SoundData.filter
        )
    end
    return true
end


local function jobjackietien_jumpscare(ply, ent, duration, customanimstuff)
    if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
    if ent.IsInJumpscare >= CurTime() then return end
    if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
    if ent.IsInJumpscareCooldown >= CurTime() then return end

    local jumpscare_entity = nil

    if SherlockHNS then
        jumpscare_entity = SherlockHNS.FindVictim(ply, ent:LocalToWorld(Vector(0, 0, 50)), 90)
    else
    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
            if ent2 == ply then continue end
            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

            if IsValid(ent2) then
                jumpscare_entity = ent2
                break
            end
        end
    end
    end

    if SherlockHNS and IsValid(jumpscare_entity) and jumpscare_entity:IsPlayer() then
        return pk_pills.playHNSJumpscare(ply, ent, jumpscare_entity, duration, {
            camera = "job_jumpscare_gen",
            onStart = customanimstuff,
        })
    end

    if jumpscare_entity ~= nil then
        
        ent.JuumpscareStart = CurTime()

        ent.jumpscare_entity = jumpscare_entity
        ent.entitylastpos = jumpscare_entity:GetPos()
        ent.entitylastang = jumpscare_entity:GetAngles()

        local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

        targetAngle.p = 0
        targetAngle.r = 0

        ply:SetNWInt("DisableMovement_jumpscare_pill_job", duration+CurTime())
        jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_job", duration+CurTime())

        ent.IsInJumpscare = CurTime() + duration

        local puppet = ent:GetPuppet()

        if jumpscare_entity:IsPlayer() then
            net.Start('job_jumpscare_gen')
            net.WriteEntity(puppet)
            net.WriteBool(true)
            net.Send(jumpscare_entity)
        else
            jumpscare_entity:NextThink(duration+0.1+CurTime())
        end
        
        jumpscare_entity:AddFlags(FL_NOTARGET)

        ent:CallOnRemove("jobJumpscare"..ent:EntIndex(), function()
            if !IsValid(jumpscare_entity) then return end

            hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())

            jumpscare_entity:RemoveFlags(FL_NOTARGET)
            ent.jumpscare_entity = nil

            if jumpscare_entity:IsPlayer() then
                net.Start('job_jumpscare_gen')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(CurTime())
            end
            jumpscare_entity:SetPos(ent.entitylastpos)
            jumpscare_entity:SetAngles(ent.entitylastang)
            jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_job", CurTime())
        end)

        customanimstuff()
    end
end

hook.Add("SetupMove", "DisablePlayerMovement_job", function(ply, mv, cmd)
    if ply:GetNWInt("DisableMovement_jumpscare_pill_job") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)

hook.Add("PlayerFootstep", "job_DisableStep", function(ply, pos, foot, sound, volume, rf)
    if ply.pk_pill_ent == nil then return end
    if !IsValid(ply.pk_pill_ent) then return end
    if ply.pk_pill_ent:GetNWBool("job_pill_scan") then
        return true
    end
end)

if SERVER then
    util.AddNetworkString("jobhighlightCooldown")
end

if SERVER then
    resource.AddFile("resource/fonts/Basic5.ttf")
end

pk_pills.packStart("job","job","icon/JOBICON.png")

pk_pills.register("pill_job",{

    printName="Job Application",
	
    model="models/blast/Job_application.mdl",
	
	modelScale="1",

    noragdoll = true,
    muteSteps = true,
    _job_pill_ds = true,
	
    anims={
        default={
            idle="idle",
			run="run",
            walk="walk",
			kill="kill",
        },
    },

    FirstPersonBone = {
        'Body',
        20,
        0,
        30,
    },
   ThirdPersonBone = {
       'Body',
        10,
        22,
        30,
    },
	
    moveSpeed={
        walk=75,
        run=530,
        ducked=200,
    },
	
    sounds={
		kill='job/kill.wav',
        afterkill = pk_pills.helpers.makeList("job/afterkill#.wav", 4),
        highlight = pk_pills.helpers.makeList("job/highlight#.wav", 3),
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=250000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_yaw",
		yPose="aim_pitch",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
    
    job_initialize=function(ply,ent,puppet)

    end,

attack = {
    mode = 'trigger',
    func = function(ply, ent)
        local entity -- make it local to avoid persisting between attacks

        local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 130, {
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

