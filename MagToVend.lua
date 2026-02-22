x = GetLocal().pos.x/32
y = GetLocal().pos.y/32
local xmag = 0
local ymag = 97
local waitingRemove = false

AddHook(function(var)
    if var.v1 == "OnTalkBubble" and var.v2:find("You are removing") and waitingRemove then
        xmag = xmag + 1
        log("xmag sekarang:", xmag)
        waitingRemove = false
        return true
    end
end, "OnVariant")

while true do
	waitingRemove = true
	SendPacket(2,"action|dialog_return\ndialog_name|itemremovedfromsucker\ntilex|"..xmag.."|\ntiley|"..ymag.."|\nitemtoremove|100\n")
	Sleep(200)
	SendPacket(2,"action|dialog_return\ndialog_name|vending\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|addstocks\n\nsetprice|0\nchk_peritem|1\nchk_perlock|0\n")
	Sleep(200)
end
