if SERVER then
    util.AddNetworkString("jobhighlightCooldown")
end

if SERVER then
    resource.AddFile("resource/fonts/Basic5.ttf")
end

if CLIENT then
    surface.CreateFont("jobCooldown", {
        font = "times",
        size = 42,        
        weight = 500,
        antialias = true
    })
end


if CLIENT then
    local jobRushCooldownEnd = 0
    local jobCooldownSound = "job/papercooldownover.wav"
    local jobCooldownActive = false

    net.Receive("jobhighlightCooldown", function()
        jobRushCooldownEnd = CurTime() + 30
        jobCooldownActive = true
    end)

    hook.Add("HUDPaint", "jobAbilityHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local pillEnt = pk_pills.getMappedEnt(ply)
        if not IsValid(pillEnt) or pillEnt:GetPillForm() ~= "pill_job" then return end

        local size = 150
        local x1, y1 = 50, ScrH() - 250

        local remaining = math.max(0, jobRushCooldownEnd - CurTime())

        surface.SetMaterial(Material("hud/highlight", "smooth"))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x1, y1, size, size)

        if remaining > 0 then

            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(x1, y1, size, size)

            draw.SimpleText(
                tostring(math.ceil(remaining)),
                "jobCooldown",
                x1 + size / 2,
                y1 + size / 2,
                Color(255, 255, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        elseif jobCooldownActive then
            surface.PlaySound(jobCooldownSound)
            jobCooldownActive = false
        end
    end)
end