local isExchangeRunning = false

AddHook(function(var)
    if var.v1 == "OnDialogRequest" and var.v2:find("end_dialog|exchange") then
        SendVariantList({
            v1 = "OnDialogRequest",
            v2 =
            "add_label_with_icon|big|`wSC BY FaRu``|left|5956|\n" ..
            "add_spacer|small|\n" ..
            "add_textbox|Script ini menyesuaikan semua server|\n" ..
            "add_textbox||\n" ..
            "add_spacer|small|\n" ..
            var.v2
        })
        return true
    end
end, "OnVariant")

function exchange(text)
    local msg = "`o[FaRu] `w" .. text
    SendPacket(2, "action|input\n|text|" .. msg)
end

local function startExchangeEngine()
    AddHook(function(type, pkt)
        if type == 2 and pkt:find("dialog_name|exchange") then

            if isExchangeRunning then
                LogToConsole("`4Exchange already running!")
                return true
            end

            LogToConsole("`2Starting Exchange...")

            runThread(function()
                isExchangeRunning = true
                local counter = 0

                while isExchangeRunning do
                    SendPacket(2, pkt .. "\n")
                    counter = counter + 1
                    Sleep(100)
                end

                LogToConsole("`4Exchange Stopped! Total: " .. counter)
            end)

            return true
        end
    end, "OnSendPacket")
end

AddHook(function(type, text)
    if type == 0 and text:find("/stopexc") then
        if not isExchangeRunning then
            LogToConsole("`4Exchange is not running!")
            return true
        end

        isExchangeRunning = false
        LogToConsole("`9AUTO EXCHANGE `4DISABLE!")
        return true
    end
end, "OnSendPacket")

startExchangeEngine()
exchange("`9AUTO EXCHANGE `2ACTIVE!")
