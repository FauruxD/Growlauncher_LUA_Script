run = false

function start()
  runThread(function()
      while run do
        sendPacket(2,"action|input\n|text|Hai Nama Saya "..getLocal().name)
        sleep(2000)
    end
  end
end

AddHook(function(type, pkt)
  if pkt:find("/start") then
    run = true
  elseif pkt:find("/stop") then
    run = false
      return true
  end
"OnSendPacket", end)

  SendVariantList({v1 = 'OnTalkBubble',v2 = GetLocal().netID,v3 = "`9Script Fetched! Enjoy",v4 = 0,v5 = 0}, -1, 1000)
