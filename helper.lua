-- =========================================================
-- HELPER SCRIPT (PNB + DROP CMD + FEATURE SCRIPT UI)
-- =========================================================

-- ================== CONFIG DEFAULT ==================
local itemid = 5640
local delayPerBlock = 2
local delayAuto = 50
local xmag = 11
local ymag = 110
-- ================================================

-- ================== EXCHANGE ==================

-- ================== STATE ==================
local pnbEnabled = false
local paused = false
local localNetID = GetLocal().netID
-- ===========================================

-- ================== UTIL ==================
function ontext(txt)
    SendVariant({v1 = "OnTextOverlay", v2 = txt})
end

function talkBubble(text)
    local msg = "`1[FARU]" `7 ..text
    SendVariant({
        v1 = "OnTalkBubble",
        v2 = getLocal().netID,
        v3 = msg
    })
end
-- ===========================================

-- ================== INIT PNB ==================
function initPNB()
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
end
-- =================================================

-- ================== BASIC PNB ==================
function place(x, y)
    SendPacketRaw(false, {
        type = 3,
        value = itemid,
        x = x * 32,
        y = y * 32,
        px = x,
        py = y
    })
end

function PlayerDetected()
    for _, p in pairs(getPlayerList()) do
        if p.netID ~= localNetID then
            return true
        end
    end
    return false
end
-- =================================================

-- ================== PNB THREAD ==================
runThread(function()
    while true do
        if not pnbEnabled then
            Sleep(200)
        else
            if PlayerDetected() then
                if not paused then
                    paused = true
                    LogToConsole("`4[PAUSE] Player detected, PNB paused")
                end
                Sleep(500)
            else
                if paused then
                    paused = false
                    LogToConsole("`2[RESUME] World empty, PNB resumed")
                    Sleep(1500)
                end

                Sleep(delayPerBlock)
                place(84,4)
                Sleep(delayPerBlock)
                place(85,4)
                Sleep(delayPerBlock)
                place(86,4)
                Sleep(delayPerBlock)
                place(87,4)
                Sleep(delayPerBlock)
                place(88,4)
                Sleep(delayPerBlock)
                place(89,4)

                Sleep(delayAuto)
            end
        end
    end
end)
-- =================================================

-- ================== DROP FUNCTIONS ==================
function drops(id, amount)
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|drop_item\n" ..
        "itemID|"..id.."|\n" ..
        "count|"..amount.."\n"
    )
end

function clock(idNeed, idConvert, amount)
    for _, inv in pairs(GetInventory()) do
        if inv.id == idNeed and inv.amount < amount then
            SendPacketRaw(false, {type = 10, value = idConvert})
        end
    end
end
-- ====================================================

local exchangeToggle = {}

function StartExchangeLoop(ex_id)
    runThread(function()
        while exchangeToggle[ex_id] do
            sendPacket(2,
                "action|dialog_return\n" ..
                "dialog_name|exchange_go\n" ..
                "buttonClicked|" .. ex_id .. "\n"
            )
            sleep(300)
        end
    end)
end
-- ==============================================

-- ================== UI : HELPER MENU ==================
function openHelperMenu()
    local status = pnbEnabled and "`2ENABLED" or "`4DISABLED"
    local dialog = [[
add_label_with_icon|big|`7Helper Menu|left|9472|
add_spacer|small|
add_label_with_icon|small|`0Hai! ]]..localPlayer().name..[[|right|14016|
add_label_with_icon|small|`0UserID : `3]]..GetLocal().userID..[[|left|12436|
add_label_with_icon|small|`0Current World `9]]..GetWorldName()..[[|left|3802|
add_label_with_icon|small|`0You're in Pos : `6[]]..(GetLocal().posX//32)..[[,]]..(GetLocal().posY//32)..[[]|left|12854|
add_spacer|small|
add_smalltext|PNB Status : ]]..status..[[|
add_spacer|small|
text_scaling_string|helperui|
add_button_with_icon|togglepnb|`7PNB Helper|staticGreyFrame|9472||
add_button_with_icon|featurescript|`7Feature Script|staticGreyFrame|9472||
add_button_with_icon|configpnb|`7PNB Config|staticGreyFrame|32||
add_button_with_icon|exchange_go|`7Exchange Menu|staticGreyFrame|12826||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
end_dialog|helpermenu|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ================== UI : FEATURE SCRIPT ==================
function openFeatureScript()
    local dialog = [[
add_label_with_icon|big|`7Feature Script|left|9472|
add_spacer|small|
add_smalltext|`8Daftar command dan fungsi script:|

add_spacer|small|
add_label_with_icon|small|`cPNB Command|left|18|
add_smalltext|`9/startpnb      `7Start Auto PNB|
add_smalltext|`9/stoppnb      `7Stop Auto PNB|
add_smalltext|`9/config      `7Stop Auto PNB|

add_spacer|small|
add_label_with_icon|small|`9World Lock|left|242|
add_smalltext|`9/w [amount]      `7Drop World Lock|
add_smalltext|`9/wx2 [amount]   `7Drop World Lock x2|
add_smalltext|`9/wx3 [amount]   `7Drop World Lock x3|
add_smalltext|`9/wall            `7Drop All World Lock|

add_spacer|small|
add_label_with_icon|small|`3Diamond Lock|left|1796|
add_smalltext|`3/d [amount]      `7Drop Diamond Lock|
add_smalltext|`3/dx2 [amount]   `7Drop Diamond Lock x2|
add_smalltext|`3/dx3 [amount]   `7Drop Diamond Lock x3|
add_smalltext|`3/dall            `7Drop All Diamond Lock|

add_spacer|small|
add_label_with_icon|small|`1Blue Gem Lock|left|7188|
add_smalltext|`1/b [amount]      `7Drop Blue Gem Lock|
add_smalltext|`1/bx2 [amount]   `7Drop Blue Gem Lock x2|
add_smalltext|`1/bx3 [amount]   `7Drop Blue Gem Lock x3|
add_smalltext|`1/ball            `7Drop All Blue Gem Lock|

add_spacer|small|
add_label_with_icon|small|`9Golden Gem Lock|left|8470|
add_smalltext|`9/g [amount]      `7Drop Golden Gem Lock|
add_smalltext|`9/gx2 [amount]   `7Drop Golden Gem Lock x2|
add_smalltext|`9/gx3 [amount]   `7Drop Golden Gem Lock x3|
add_smalltext|`9/gall            `7Drop All Golden Gem Lock|

add_spacer|small|
add_label_with_icon|small|`bThe Glorious Skull|left|13200|
add_smalltext|`b/t [amount]      `7Drop The Glorious Skull|
add_smalltext|`b/tx2 [amount]   `7Drop The Glorious Skull x2|
add_smalltext|`b/tx3 [amount]   `7Drop The Glorious Skull x3|
add_smalltext|`b/tall            `7Drop All The Glorious Skull|

add_spacer|small|
add_label_with_icon|small|`cThe Majestic Dragon|left|4428|
add_smalltext|`c/m [amount]      `7Drop The Majestic Dragon|
add_smalltext|`c/mx2 [amount]   `7Drop The Majestic Dragon x2|
add_smalltext|`c/mx3 [amount]   `7Drop The Majestic Dragon x3|
add_smalltext|`c/mall            `7Drop All The Majestic Dragon|

add_spacer|small|
add_label_with_icon|small|`wYin Yang Artifact|left|2950|
add_smalltext|`w/y [amount]      `7Drop Yin Yang Artifact|
add_smalltext|`w/yx2 [amount]   `7Drop Yin Yang Artifact x2|
add_smalltext|`w/yx3 [amount]   `7Drop Yin Yang Artifact x3|
add_smalltext|`w/yall            `7Drop All Yin Yang Artifact|

add_spacer|small|
add_label_with_icon|small|`#Bunny Valentine Artifact|left|5260|
add_smalltext|`#bv [amount]      `7Drop Bunny Valentine Artifact|
add_smalltext|`#bv2 [amount]   `7Drop Bunny Valentine Artifact x2|
add_smalltext|`#bv3 [amount]   `7Drop Bunny Valentine Artifact x3|
add_smalltext|`#bval            `7Drop All Bunny Valentine Artifact|

add_spacer|small|
add_label_with_icon|small|`8Chongqing Lion Artifact|left|7188|
add_smalltext|`8/c [amount]      `7Drop Chongqing Lion Artifact|
add_smalltext|`8/cx2 [amount]   `7Drop Chongqing Lion Artifact x2|
add_smalltext|`8/cx3 [amount]   `7Drop Chongqing Lion Artifact x3|
add_smalltext|`8/call            `7Drop All Chongqing Lion Artifact|

add_spacer|small|
add_smalltext|`8Contoh: `9/w 10 `7→ Drop 10 World Lock|
add_smalltext|`8`9/daw `7→ Drop All Lock|
end_dialog|featurescript|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ================== UI : CONFIG PNB ==================
function openPNBConfig()
    local dialog = [[
add_label_with_icon|big|`7PNB Configuration|left|9472|
add_spacer|small|
add_text_input|itemid|Item ID|]]..itemid..[[|5|
add_text_input|delaypb|Delay Per Block|]]..delayPerBlock..[[|5|
add_text_input|delayauto|Delay Auto|]]..delayAuto..[[|5|
add_text_input|xmag|Mag X|]]..xmag..[[|5|
add_text_input|ymag|Mag Y|]]..ymag..[[|5|
add_spacer|small|
add_button|savepnb|Save Config|
end_dialog|pnbconfig|Cancel||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ============ UI : EXCHANGE MENU =============
function ExchangeMenu()
    local dialog = [[
set_border_color|1,1,1,250
set_bg_color|25,25,25,200
embed_data|Dxti26evUE5XejCESGsSvGalM|MXmAzavaIDBFMBLLBJSoAnDBnrcEh
embed_data|b7w77XRTIt2Or2gg7LPkcDb8|TuJNf8OuPNSwTXty6xuP0rXVkpP9
embed_data|UBsS46Dti23Ig9mMhEJFBwnKOdWGg|otQLO5hWamVoTGF9iKg
embed_data|iAFUspUHCMeQIiGvnhir87mKCsct8w|WBu6iS37f5vhFP3mJUzdTlaD

set_default_color|`o
add_label_with_icon|big|`wHaggler Hank``|left|12826|
text_scaling_string|+++++++++++++++|
add_textbox|"You drive a hard bargain, friend. But I like a challenge! Let’s see if we can make this trade really worth our while."|
add_spacer|small|
add_button_with_icon|info_8470|`$Golden Gem Lock``|frame|8470|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_13200|`$The Glorious Skull``|frame|13200|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(8470) .. [[/100`` Golden Gem Lock``|
add_small_font_button|ex_84701001320010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_13200|`$The Glorious Skull``|frame|13200|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_8470|`$Golden Gem Lock``|frame|8470|100|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(13200) .. [[/1`` The Glorious Skull``|
add_small_font_button|ex_13200184701000|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_13200|`$The Glorious Skull``|frame|13200|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_4428|`$The Majestic Dragon``|frame|4428|1|

add_smalltext|`sYou have `w]].. growtopia.checkInventoryCount(13200) .. [[/100`` The Glorious Skull``|
add_small_font_button|ex_13200100442810|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_4428|`$The Majestic Dragon``|frame|4428|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_13200|`$The Glorious Skull``|frame|13200|100|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(4428) .. [[/1`` The Majestic Dragon``|
add_small_font_button|ex_44281132001000|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_4428|`$The Majestic Dragon``|frame|4428|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_2950|`$YingYang Universe Artifact``|frame|2950|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(4428) .. [[/100`` The Majestic Dragon``|
add_small_font_button|ex_4428100295010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_2950|`$YingYang Universe Artifact``|frame|2950|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_4428|`$The Majestic Dragon``|frame|4428|100|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(2950) .. [[/1`` YingYang Universe Artifact``|
add_small_font_button|ex_2950144281000|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_2950|`$YingYang Universe Artifact``|frame|2950|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_5260|`$Bunny Valentine Artifact``|frame|5260|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(2950) .. [[/100`` YingYang Universe Artifact``|
add_small_font_button|ex_2950100526010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_5260|`$Bunny Valentine Artifact``|frame|5260|1|
add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_2950|`$YingYang Universe Artifact``|frame|2950|100|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(5260) .. [[/1`` Bunny Valentine Artifact``|
add_small_font_button|ex_5260129501000|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9286|`$Lucky Fortune Cookie``|frame|9286|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_13200|`$The Glorious Skull``|frame|13200|50|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(9286) .. [[/1`` Lucky Fortune Cookie``|
add_small_font_button|ex_9286113200500|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9286|`$Lucky Fortune Cookie``|frame|9286|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_4428|`$The Majestic Dragon``|frame|4428|50|

add_smalltext|`sYou have `w0/100`` Lucky Fortune Cookie``|
add_small_font_button|ex_92861004428500|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|50|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_20054|`$Golden``|frame|20054|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10600) .. [[/50`` 2014 - Zodiac Year of the Horse``|
add_small_font_button|ex_10600502005410|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|200|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_20054|`$Golden``|frame|20054|4|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10600) .. [[/200`` 2014 - Zodiac Year of the Horse``|
add_small_font_button|ex_106002002005440|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9282|`$Huli Jing Scarf``|frame|9282|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|75|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(9282) .. [[/75`` Huli Jing Scarf``|
add_small_font_button|ex_92827510600750|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9280|`$Jin Chan Leash``|frame|9280|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|75|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(9280) .. [[/75`` Jin Chan Leash``|
add_small_font_button|ex_92807510600750|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10592|`$Oxen Battle Boots``|frame|10592|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|75|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10592) .. [[/75`` Oxen Battle Boots``|
add_small_font_button|ex_105927510600750|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10590|`$Oxen Battle Pants``|frame|10590|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|75|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10590) .. [[/75`` Oxen Battle Pants``|
add_small_font_button|ex_105907510600750|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_11628|`$Fireworks Feet``|frame|11628|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|50|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(11628) .. [[/75`` Fireworks Feet``|
add_small_font_button|ex_116287510600500|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9282|`$Huli Jing Scarf``|frame|9282|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(9282) .. [[/1`` Huli Jing Scarf``|
add_small_font_button|ex_928211060010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_9280|`$Jin Chan Leash``|frame|9280|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(9280) .. [[/1`` Jin Chan Leash``|
add_small_font_button|ex_928011060010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10592|`$Oxen Battle Boots``|frame|10592|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10592) .. [[/1`` Oxen Battle Boots``|
add_small_font_button|ex_1059211060010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10590|`$Oxen Battle Pants``|frame|10590|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10590) .. [[/1`` Oxen Battle Pants``|
add_small_font_button|ex_1059011060010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_11628|`$Fireworks Feet``|frame|11628|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10600|`$2014 - Zodiac Year of the Horse``|frame|10600|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(11628) .. [[/1`` Fireworks Feet``|
add_small_font_button|ex_1162811060010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20054|`$Golden``|frame|20054|7|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_5926|`$Ultra World Spray``|frame|5926|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20054) .. [[/7`` Golden``|
add_small_font_button|ex_200547592610|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20054|`$Golden``|frame|20054|10|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_2950|`$YingYang Universe Artifact``|frame|2950|10|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20054) .. [[/10`` Golden``|
add_small_font_button|ex_20054102950100|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20054|`$Golden``|frame|20054|15|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_2|`$Dirt``|frame|2|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20054) .. [[/15`` Golden``|
add_small_font_button|ex_2005415210|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20054|`$Golden``|frame|20054|10|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20054) .. [[/10`` Golden``|
add_small_font_button|ex_20054102005610|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20054|`$Golden``|frame|20054|50|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|5|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20054) .. [[/50`` Golden``|
add_small_font_button|ex_20054502005650|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|5|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_15096|`$Golden Sequin Fedora``|frame|15096|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/5`` Diamond``|
add_small_font_button|ex_2005651509610|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|8|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_9900|`$Trazer's Death Crown``|frame|9900|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/8`` Diamond``|
add_small_font_button|ex_200568990010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|12|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_3042|`$Fishing Hat``|frame|3042|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/12`` Diamond``|
add_small_font_button|ex_2005612304210|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|35|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_16544|`$Guts``|frame|16544|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/35`` Diamond``|
add_small_font_button|ex_20056351654410|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|50|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_19566|`$Nailong``|frame|19566|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/50`` Diamond``|
add_small_font_button|ex_20056501956610|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|75|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_8150|`$KoF``|frame|8150|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/75`` Diamond``|
add_small_font_button|ex_2005675815010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|80|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_15222|`$Eren Yeager``|frame|15222|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/80`` Diamond``|
add_small_font_button|ex_20056801522210|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_20056|`$Diamond``|frame|20056|123|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_17502|`$Spongebob``|frame|17502|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(20056) .. [[/123`` Diamond``|
add_small_font_button|ex_200561231750210|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_5260|`$Bunny Valentine Artifact``|frame|5260|100|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_10410|`$Chongqing Lion Artifact``|frame|10410|1|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(5260) .. [[/100`` Bunny Valentine Artifact``|
add_small_font_button|ex_52601001041010|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

add_button_with_icon|info_10410|`$Chongqing Lion Artifact``|frame|10410|1|

add_button_with_icon|DO_NOTHING||noflags|482||

add_button_with_icon|info_5260|`$Bunny Valentine Artifact``|frame|5260|100|

add_smalltext|`sYou have `w]] .. growtopia.checkInventoryCount(10410) .. [[/1`` Chongqing Lion Artifact``|
add_small_font_button|ex_10410152601000|GET!|disabled|0|0|
add_button_with_icon||END_LIST||||

end_dialog|exchange_go|Nevermind||
add_quick_exit|
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end


-- ================== HOOK ==================
function hook(type, str)

    -- open helper
    if str:find("/helper") or str:find("selection|gems_bundle06") then
        openHelperMenu()
        return true
    end

    -- toggle pnb
    if str:find("buttonClicked|togglepnb") then
        pnbEnabled = not pnbEnabled
        paused = false
        if pnbEnabled then
            initPNB()
            ontext("`2PNB Enabled")
        else
            ontext("`4PNB Disabled")
        end
        openHelperMenu()
        return true
    end

    -- open feature script
    if str:find("buttonClicked|featurescript") then
        openFeatureScript()
        return true
    end

    -- open config
    if str:find("buttonClicked|configpnb") then
        openPNBConfig()
        return true
    end

    -- save config
    if str:find("buttonClicked|savepnb") then
        itemid = tonumber(str:match("itemid|(%d+)")) or itemid
        delayPerBlock = tonumber(str:match("delaypb|(%d+)")) or delayPerBlock
        delayAuto = tonumber(str:match("delayauto|(%d+)")) or delayAuto
        xmag = tonumber(str:match("xmag|(%d+)")) or xmag
        ymag = tonumber(str:match("ymag|(%d+)")) or ymag
        ontext("`2PNB Config Saved")
        openHelperMenu()
        return true
    end
	
	-- command start/stop 
	if str:find("/startpnb") then 
		if not pnbEnabled then 
			pnbEnabled = true 
				paused = false 
					initPNB() 
				ontext("2PNB Started") 
			end 
		return true 
	end 
	
	if str:find("/stoppnb") then 
		pnbEnabled = false 
			ontext("4PNB Stopped") 
		return true 
	end
	
	if str:find("/config") then
		openPNBConfig()
		return true
	end
	
    -- ================= DROP COMMANDS =================
    if str:find("/w (%d+)") then
        local a = tonumber(str:match("/w (%d+)"))
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Lock!"); return true
    end
    if str:find("/wx2 (%d+)") then
        local a = tonumber(str:match("/wx2 (%d+)"))*2
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Locks!"); return true
    end
    if str:find("/wx3 (%d+)") then
        local a = tonumber(str:match("/wx3 (%d+)"))*3
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Locks!"); return true
    end
    if str:find("/wall") then
        for _,i in pairs(GetInventory()) do if i.id==242 then drops(242,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9World Locks!") end end
        return true
    end

    if str:find("/d (%d+)") then
        local a = tonumber(str:match("/d (%d+)"))
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dx2 (%d+)") then
        local a = tonumber(str:match("/dx2 (%d+)"))*2
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dx3 (%d+)") then
        local a = tonumber(str:match("/dx3 (%d+)"))*3
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dall") then
        for _,i in pairs(GetInventory()) do if i.id==1796 then drops(1796,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Diamond Locks!") end end
        return true
    end

    if str:find("/b (%d+)") then
        local a = tonumber(str:match("/b (%d+)"))
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/bx2 (%d+)") then
        local a = tonumber(str:match("/bx2 (%d+)"))*2
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/bx3 (%d+)") then
        local a = tonumber(str:match("/bx3 (%d+)"))*3
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/ball") then
        for _,i in pairs(GetInventory()) do if i.id==7188 then drops(7188,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Blue Gem Locks!") end end
        return true
    end

    if str:find("/g (%d+)") then
        local a = tonumber(str:match("/g (%d+)"))
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gx2 (%d+)") then
        local a = tonumber(str:match("/gx2 (%d+)"))*2
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gx3 (%d+)") then
        local a = tonumber(str:match("/gx3 (%d+)"))*3
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gall") then
        for _,i in pairs(GetInventory()) do if i.id==8470 then drops(8470,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Golden Gem Lock!") end end
        return true
    end

    if str:find("/t (%d+)") then
        local a = tonumber(str:match("/t (%d+)"))
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tx2 (%d+)") then
        local a = tonumber(str:match("/tx2 (%d+)"))*2
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tx3 (%d+)") then
        local a = tonumber(str:match("/tx3 (%d+)"))*3
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tall") then
        for _,i in pairs(GetInventory()) do if i.id==13200 then drops(13200,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9The Glorious Skull!") end end
        return true
    end

    if str:find("/m (%d+)") then
        local a = tonumber(str:match("/m (%d+)"))
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mx2 (%d+)") then
        local a = tonumber(str:match("/mx2 (%d+)"))*2
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mx3 (%d+)") then
        local a = tonumber(str:match("/mx3 (%d+)"))*3
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mall") then
        for _,i in pairs(GetInventory()) do if i.id==4428 then drops(4428,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9The Majestic Dragon!") end end
        return true
    end

    if str:find("/y (%d+)") then
        local a = tonumber(str:match("/y (%d+)"))
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yx2 (%d+)") then
        local a = tonumber(str:match("/yx2 (%d+)"))*2
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yx3 (%d+)") then
        local a = tonumber(str:match("/yx3 (%d+)"))*3
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yall") then
        for _,i in pairs(GetInventory()) do if i.id==2950 then drops(2950,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9YinYang Universe Artifacts!") end end
        return true
    end

    if str:find("/bv (%d+)") then
        local a = tonumber(str:match("/bv (%d+)"))
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bv2 (%d+)") then
        local a = tonumber(str:match("/bv2 (%d+)"))*2
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bv3 (%d+)") then
        local a = tonumber(str:match("/bv3 (%d+)"))*3
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bval") then
        for _,i in pairs(GetInventory()) do if i.id==5260 then 
            drops(5260,i.amount)
            talkBubble("`9Dropped `2"..i.amount.." `9Bunny Valentine Artifact!")
        end end
        return true
    end

    if str:find("/c (%d+)") then
        local a = tonumber(str:match("/c (%d+)"))
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/cx2 (%d+)") then
        local a = tonumber(str:match("/cx2 (%d+)"))*2
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/cx3 (%d+)") then
        local a = tonumber(str:match("/cx3 (%d+)"))*3
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/call") then
        for _,i in pairs(GetInventory()) do if i.id==10410 then drops(10410,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Chongqing Lion Artifact!") end end
        return true
    end
    -- =================================================

    lock = {242, 1796, 7188, 8470, 13200, 4428, 2950, 5260, 10410}
    if str:find("/daw") then
        for _,id in pairs(lock) do
            for _,i in pairs(GetInventory()) do
                if i.id==id then
                    drops(id,i.amount)
                    talkBubble("`9Dropped all Locks!")
                end
            end
        end
        return true
    end
    -- ================== EXCHANGE MENU =================
    if str:find("buttonClicked|exchange_go") then
        ExchangeMenu()
        return true
    end

    -- DETEKSI SEMUA BUTTON ex_
    local ex_id = str:match("buttonClicked|(ex_%d+)")
    if ex_id then
        -- toggle
        exchangeToggle[ex_id] = not exchangeToggle[ex_id]

        if exchangeToggle[ex_id] then
            log("Exchange ON: " .. ex_id)
            talkBubble("`2Started exchange: " .. ex_id)
            StartExchangeLoop(ex_id)
        else
            log("Exchange OFF: " .. ex_id)
            talkBubble("`2Stopped exchange: " .. ex_id)
        end
        return true
    end
    
    if str:find("action|input") and str:find("/stopexc") then
        for k,_ in pairs(exchangeToggle) do
            exchangeToggle[k] = false
        end
        log("All exchange loops stopped.")
        talkBubble("`2All exchange loops stopped.")
        return true
    end

    -- =================================================
    return false
end

AddHook(hook,"OnSendPacket")
-- =========================================================
talkBubble("`9Script Loaded! `9Type `2/helper `9to open the menu.")
LogToConsole("`3[Helper Script] `2Loaded Successfully! Type `9/helper `2to open the menu.")
-- =========================================================
