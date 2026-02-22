-- ================== CONFIG ==================
itemid = 5640 -- 432 -- Magplant 5640
delayPerBlock = 2
delayAuto = 70
xmag = 24
ymag = 109
-- ============================================


-- ================== INIT MAG & CHEAT ==================
SendPacket(2,
    "action|dialog_return\n" ..
    "dialog_name|itemsucker_block\n" ..
    "tilex|"..xmag.."|\n" ..
    "tiley|"..ymag.."|\n" ..
    "buttonClicked|getplantationdevice\n"
)

Sleep(400)

SendPacket(2,
    "action|dialog_return\n" ..
    "dialog_name|cheats\n" ..
    "itemid|"..itemid.."\n" ..
    "slot|6\n" ..
    "checkbox_cheat_autofish|1\n" ..
    "checkbox_cheat_antibounce|1\n" ..
    "checkbox_cheat_speed|0\n" ..
    "checkbox_cheat_double_jump|1\n" ..
    "checkbox_cheat_jump|0\n" ..
    "checkbox_cheat_heat_resist|1\n" ..
    "checkbox_cheat_strong_punch|0\n" ..
    "checkbox_cheat_long_punch|1\n" ..
    "checkbox_cheat_long_build|0\n" ..
    "checkbox_cheat_autocollect|1\n" ..
    "checkbox_cheat_fastpull|0\n" ..
    "checkbox_cheat_fastdrop|0\n" ..
    "checkbox_cheat_fasttrash|0\n" ..
    "chat|\n"
)

EditToggle("Antilag", true)
EditToggle("No Particle", true)
EditToggle("Player", true)

-- ======================================================


-- ================== FUNCTION ==================
function place(x, y)
    local pkt = {}
    pkt.x = x * 32
    pkt.y = y * 32
    pkt.px = x
    pkt.py = y
    pkt.type = 3
    pkt.value = itemid
    SendPacketRaw(false, pkt)
end

function punch(x, y)
    local pkt = {}
    pkt.x = x * 32
    pkt.y = y * 32
    pkt.px = x
    pkt.py = y
    pkt.type = 3
    pkt.value = 18
    SendPacketRaw(false, pkt)
end
-- ======================================================


-- ================== PLAYER DETECTION ==================
local localNetID = GetLocal().netID
paused = false

function PlayerDetected()
    for _, p in pairs(getPlayerList()) do
        if p.netID ~= localNetID then
            return true
        end
    end
    return false
end
-- ======================================================


-- ================== MAIN LOOP ==================
a = math.floor(GetLocal().posX / 32)
b = math.floor(GetLocal().posY / 32)

place(a +2, b)
while true do
    -- AUTO PAUSE
    if PlayerDetected() then
        if not paused then
            paused = true
            LogToConsole("`4[PAUSE] Player terdeteksi, PNB dijeda...")
        end
        Sleep(500)

    -- AUTO RESUME
    else
        if paused then
            paused = false
            LogToConsole("`2[RESUME] World kosong, PNB dilanjutkan.")
            Sleep(1500) -- delay resume biar natural
        end

        Sleep(delayPerBlock)
        place(21, 1)
        Sleep(delayPerBlock)
        place(24, 1)
        Sleep(delayPerBlock)
        place(25, 1)
        Sleep(delayPerBlock)
        place(23, 1)
        Sleep(delayPerBlock)
        place(22, 1)
        Sleep(delayPerBlock)
        place(26, 1)
        Sleep(delayAuto)
    end
end
-- ======================================================
