x = GetLocal().posX/32
y = GetLocal().posY/32
xmag = 16
ymag = 105
for i = 1, 15 do
SendPacket(2,"action|dialog_return\ndialog_name|itemremovedfromsucker\ntilex|"..xmag.."|\ntiley|"..ymag.."|\nitemtoremove|100\n")
Sleep(200)
SendPacket(2,"action|dialog_return\ndialog_name|vending\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|addstocks\n\nsetprice|0\nchk_peritem|1\nchk_perlock|0\n")
Sleep(200)
end
