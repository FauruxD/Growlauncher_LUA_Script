local ITEM_1 = 10628
local ITEM_2 = 3468  
local ITEM_3 = 7188       
local ITEM_RESULT = 12156

local NEED_1 = 200
local NEED_2 = 50
local NEED_3 = 20

local COMBINE_X = 3
local COMBINE_Y = 111
local STAND_X = COMBINE_X + 1
local STAND_Y = COMBINE_Y

function punch(x, y)
    local pkt = {}
    pkt.type = 3
    pkt.value = 18
    pkt.px = x
    pkt.py = y
    pkt.x = x * 32
    pkt.y = y * 32
    SendPacketRaw(false, pkt)
end

function talkBubble(text)
    SendVariant({
        v1 = "OnTalkBubble",
        v2 = getLocal().netID,
        v3 = text
    })
end

function iCount(id)
    return growtopia.checkInventoryCount(id)
end

function drop(id, count)
	sendPacket(2,[[action|dialog_return
	dialog_name|drop_item
	itemID|]] .. id .. [[|
	count|]] .. count .. [[
	
	]])
end

function takeVend(x, y)
	sendPacket(2, [[action|dialog_return
	dialog_name|vending
	tilex|]]..x..[[|
	tiley|]]..y..[[|
	buttonClicked|pullstocks
	
	setprice|0
	chk_peritem|1
	chk_perlock|0
	]])
end

function takeMag()
	sendPacket(2, [[action|dialog_return
	dialog_name|itemremovedfromsucker
	tilex|26|
	tiley|110|
	itemtoremove|200
	]])
end

function convert()
	sendPacket(2,[[action|dialog_return
dialog_name|continue
buttonClicked|convert_8470
]])
end

function getDroppedAmount(itemid)
    local total = 0
    for _, obj in pairs(getObjectList()) do
        if obj.itemid == itemid then
            total = total + obj.amount
        end
    end
    return total
end

function collectItem(itemid)
    for _, obj in pairs(getObjectList()) do
        if obj.itemid == itemid then
            sendPacketRaw(false, {
                type = 11,
                value = obj.id,
                x = obj.posX,
                y = obj.posY
            })
            sleep(150)
        end
    end
end

sleep(1000)
talkBubble("`1Auto Combine by FaRu")
sleep(1500)

while true do
    if iCount(7188) < 50 then
		     convert()
		     Sleep(200)
	   end
    -- Pergi ke posisi
    FindPath(STAND_X, STAND_Y)
    sleep(1500)

    talkBubble("`9Taking Ingredients...")
    takeVend(17, 106)
    sleep(1000)
	   takeVend(15, 110)
    sleep(1500)
    
    local g1 = getDroppedAmount(ITEM_1)
    local g2 = getDroppedAmount(ITEM_2)
    local g3 = getDroppedAmount(ITEM_3)

    local need1 = NEED_1 - g1
    local need2 = NEED_2 - g2
    local need3 = NEED_3 - g3
    talkBubble("`9Dropping Ingredients")
    if need1 > 0 and iCount(ITEM_1) >= need1 then
        drop(ITEM_1, need1)
        sleep(500)
    end

    if need2 > 0 and iCount(ITEM_2) >= need2 then
        drop(ITEM_2, need2)
        sleep(500)
    end

    if need3 > 0 and iCount(ITEM_3) >= need3 then
        drop(ITEM_3, need3)
        sleep(500)
    end

    sleep(2000)

    repeat
        sleep(500)
        g1 = getDroppedAmount(ITEM_1)
        g2 = getDroppedAmount(ITEM_2)
        g3 = getDroppedAmount(ITEM_3)
    until g1 >= NEED_1 and g2 >= NEED_2 and g3 >= NEED_3

    talkBubble("`4Combining...")
    punch(COMBINE_X, COMBINE_Y)
    sleep(200)
    punch(COMBINE_X, COMBINE_Y)
    sleep(200)
    punch(COMBINE_X, COMBINE_Y)
    sleep(3000)

    if iCount(ITEM_RESULT) > 0 then
        talkBubble("`cTaking Result...")
        collectItem(ITEM_RESULT)
        sleep(1000)
    end
	
    talkBubble("`8Next Combine...")
    sleep(2000)
end
