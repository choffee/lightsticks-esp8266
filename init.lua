print('init.lua ver 1.2')
remaining, used, total=file.fsinfo()

print("\nFile system info:\nTotal : "..total.." Bytes\nUsed: "..used.." Bytes\nRemain: "..remaining.." Bytes\n")
print("\ndofile(\"lightserver.lua\") should start things up")
