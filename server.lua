QBCore = nil

TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end

QBCore.Functions.CreateCallback('vlast-bank:get-cash', function(source, cb)
    cb(QBCore.Functions.GetPlayer(source).Functions.GetMoney())
end)

QBCore.Functions.CreateCallback('vlast-bank:get-money', function(source, cb, account)
    local cash = 0

    if account == nil then
        player = QBCore.Functions.GetPlayer(source)
        cash = player.Functions.GetMoney()
        cb(cash)
        return
    end

    if account:startswith("US9Vlast") then
        QBCore.Functions.ExecuteSql(false, "SELECT * FROM `players` WHERE `charinfo` LIKE '%"..account.."%'", function(result)
            if result[1] ~= nil then
                cb(json.decode(result[1].money).bank)
                return
            else
                TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
            end
        end)
    end

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = account
    }, function(result) 
        if result[1] ~= nil then
            cb(result[1].balance)
            return
        else
            TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
        end
    end)
end)

QBCore.Functions.CreateCallback("vlast-bank:get-account", function(source, cb, account)
    exports['ghmattimysql']:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = account
    }, function(result)
        if result[1] ~= nil then
            cb(result[1])
        else
            cb("test")
        end
    end)
end)

QBCore.Functions.CreateCallback("vlast-bank:get-logs", function(source, cb, account)
    exports['ghmattimysql']:execute("SELECT * FROM bank_logs WHERE receiver=@account OR transmitter=@account ORDER BY created_at DESC", {
        ["@account"] = account
    }, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('vlast-bank:create-account-if-not-exists')
AddEventHandler('vlast-bank:create-account-if-not-exists', function(name, defaultAmount)
    local account = "VLA-"..name
    local amount = 0

    if defaultAmount ~= nil then amount = defaultAmount end

    exports['ghmattimysql']:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = account
    }, function(result)
        if result[1] == nil then 
            exports['ghmattimysql']:execute("INSERT INTO bank_accounts (account, balance) VALUES (@account, @balance)", {
                ["@account"] = account,
                ["@balance"] = amount
            }, function(result) return end)
        end
    end)
end)

RegisterServerEvent("vlast-bank:deposit-money")
AddEventHandler("vlast-bank:deposit-money", function(amount, account)
    player = QBCore.Functions.GetPlayer(source)
    player.Functions.RemoveMoney("cash", amount)

    if account == nil then
        TriggerClientEvent("vlast-bank:balance-changed", source, player.PlayerData.money.bank + amount)
        player.Functions.AddMoney("bank", amount)
        CreateLog(player.PlayerData.charinfo.account, "ATM", amount, "Para Yatırma İşlemi")
        return
    end

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = account
    }, function(bankAccount)
        if bankAccount[1] ~= nil then
            exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                ["@balance"] = bankAccount[1].balance + amount,
                ["@account"] = account
            })
            
            TriggerClientEvent("vlast-bank:balance-changed", source, bankAccount[1].balance + amount)
            CreateLog(account, "ATM", amount, "Para Yatırma İşlemi")
        else
            TriggerClientEvent('QBCore:Notify', "Hesap bulunamadı", "error")
        end
    end)
end)

RegisterServerEvent("vlast-bank:withdraw-money")
AddEventHandler("vlast-bank:withdraw-money", function(amount, account)
    player = QBCore.Functions.GetPlayer(source)
    player.Functions.AddMoney("cash", amount)

    if account == nil then
        player = QBCore.Functions.GetPlayer(source)
        TriggerClientEvent("vlast-bank:balance-changed", source, player.PlayerData.money.bank - amount)
        player.Functions.RemoveMoney("bank", amount)
        CreateLog("ATM", player.PlayerData.charinfo.account, amount, "Para Çekme İşlemi")
        return
    end

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = account
    }, function(bankAccount)
        if bankAccount[1] ~= nil then
            exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                ["@balance"] = bankAccount[1].balance - amount,
                ["@account"] = account
            })
            
            TriggerClientEvent("vlast-bank:balance-changed", source, bankAccount[1].balance - amount)
            CreateLog("ATM", account, amount, "Para Çekme İşlemi")
        else
            TriggerClientEvent('QBCore:Notify', "Hesap bulunamadı", "error")
        end
    end)
end)

RegisterServerEvent('vlast-bank:transfer:player-to-player')
AddEventHandler('vlast-bank:transfer:player-to-player', function(transmitter, amount, description)
    local src = source
    local sender = QBCore.Functions.GetPlayer(src)

    QBCore.Functions.ExecuteSql(false, "SELECT * FROM `players` WHERE `charinfo` LIKE '%"..transmitter.."%'", function(result)
        if result[1] ~= nil then
            local receiver = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)

            if receiver ~= nil then
                local PhoneItem = receiver.Functions.GetItemByName("phone")
                receiver.Functions.AddMoney('bank', amount)
                sender.Functions.RemoveMoney('bank', amount)

                if PhoneItem ~= nil then
                    TriggerClientEvent('QBCore:Notify', receiver.PlayerData.source, "Hesabınıza " .. amount .. "$ para geldi", "error")
                    TriggerClientEvent("vlast-bank:balance-changed", receiver.PlayerData.source, receiver.money.bank)
                end
            else
                local moneyInfo = json.decode(result[1].money)
                moneyInfo.bank = round((moneyInfo.bank + amount))
                QBCore.Functions.ExecuteSql(false, "UPDATE `players` SET `money` = '"..json.encode(moneyInfo).."' WHERE `citizenid` = '"..result[1].citizenid.."'")
                sender.Functions.RemoveMoney('bank', amount)
            end

            TriggerClientEvent("vlast-bank:balance-changed", src, sender.money.bank)
            TriggerClientEvent('QBCore:Notify', src, transmitter .. " hesabına " .. amount .. "$ gönderdiniz", "error")
            CreateLog(transmitter, receiver.PlayerData.charinfo.account, amount, description)
        else
            TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
        end
    end)
end)

RegisterServerEvent('vlast-bank:transfer:account-to-player')
AddEventHandler('vlast-bank:transfer:account-to-player', function(transmitter, receiver, amount, description)
    local src = source
    local sender = QBCore.Functions.GetPlayer(src)

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = transmitter
    }, function(accountResult)
        if accountResult[1] ~= nil then
            local transmitterAccount = accountResult[1]

            QBCore.Functions.ExecuteSql(false, "SELECT * FROM `players` WHERE `charinfo` LIKE '%"..receiver.."%'", function(result)
                if result[1] ~= nil then
                    local receiverPlayer = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
                    
                    exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                        ["@balance"] = transmitterAccount.balance - amount,
                        ["@account"] = transmitter
                    })

                    if receiverPlayer ~= nil then
                        local PhoneItem = receiverPlayer.Functions.GetItemByName("phone")
                        receiverPlayer.Functions.AddMoney('bank', amount)
        
                        if PhoneItem ~= nil then
                            TriggerClientEvent('QBCore:Notify', receiverPlayer.PlayerData.source, "Hesabınıza " .. amount .. "$ para geldi", "error")
                            TriggerClientEvent("vlast-bank:balance-changed", receiverPlayer.PlayerData.source, receiverPlayer.PlayerData.money.bank)
                        end
                    else
                        local moneyInfo = json.decode(result[1].money)
                        moneyInfo.bank = round((moneyInfo.bank + amount))
                        QBCore.Functions.ExecuteSql(false, "UPDATE `players` SET `money` = '"..json.encode(moneyInfo).."' WHERE `citizenid` = '"..result[1].citizenid.."'")
                    end
        
                    TriggerClientEvent("vlast-bank:balance-changed", src, transmitterAccount.balance - amount)
                    TriggerClientEvent('QBCore:Notify', src, receiver .. " hesabına " .. amount .. "$ gönderdiniz", "error")
                    CreateLog(transmitter, receiver, amount, description)
                else
                    TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, "Geçersiz bir hesaptan işlem yaptınız", "error")
        end
    end)
end)

RegisterServerEvent('vlast-bank:transfer:player-to-account')
AddEventHandler('vlast-bank:transfer:player-to-account', function(transmitter, receiver, amount, description)
    local src = source
    local sender = QBCore.Functions.GetPlayer(src)

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = receiver
    }, function(result)
        if result[1] ~= nil then
            local receiverAccount = result[1]

            exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                ["@balance"] = receiverAccount.balance + amount,
                ["@account"] = receiver
            })

            sender.Functions.RemoveMoney('bank', amount)
            TriggerClientEvent("vlast-bank:balance-changed", src, sender.PlayerData.money.bank)
            TriggerClientEvent('QBCore:Notify', src, receiver .. " hesabına " .. amount .. "$ gönderdiniz", "error")
            CreateLog(transmitter, receiver, amount, description)
        else
            TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
        end
    end)
end)

RegisterServerEvent('vlast-bank:transfer:account-to-account')
AddEventHandler('vlast-bank:transfer:account-to-account', function(transmitter, receiver, amount, description)
    local src = source

    exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
        ["@account"] = transmitter
    }, function(transmitter)
        if transmitter[1] ~= nil then
            local transmitterAccount = transmitter[1]
            exports["ghmattimysql"]:execute("SELECT * FROM bank_accounts WHERE account=@account", {
                ["@account"] = receiver
            }, function(receiver)
                if receiver[1] ~= nil then
                    exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                        ["@balance"] = receiver[1].balance + amount,
                        ["@account"] = receiver[1].account
                    })
                else
                    TriggerClientEvent('QBCore:Notify', src, "İban bulunamadı", "error")
                    return
                end
            end)

            exports["ghmattimysql"]:execute("UPDATE bank_accounts SET balance=@balance WHERE account=@account", {
                ["@balance"] = transmitterAccount.balance - amount,
                ["@account"] = transmitter[1].account
            })

            TriggerClientEvent("vlast-bank:balance-changed", src, transmitterAccount.balance - amount)
            TriggerClientEvent('QBCore:Notify', src, receiver .. " hesabına " .. amount .. "$ gönderdiniz", "error")
            CreateLog(transmitter[1].account, receiver, amount, description)
        else
            TriggerClientEvent('QBCore:Notify', src, "Geçersiz bir hesaptan işlem yaptınız", "error")
        end
    end)
end)

function CreateLog(transmitter, receiver, amount, description)
    exports['ghmattimysql']:execute("INSERT INTO bank_logs (transmitter, receiver, amount, description) VALUES (@transmitter, @receiver, @amount, @description)", {
        ["@transmitter"] = transmitter,
        ["@receiver"] = receiver,
        ["@amount"] = amount,
        ["@description"] = description
    })
end

RegisterServerEvent("vlast-base:PlayerCanMakeHeist")
AddEventHandler("vlast-base:PlayerCanMakeHeist", function(bool)
    TriggerClientEvent("vlast-base:setHeistStats", -1, bool)
end)

RegisterServerEvent("vlast-base:PlayerCanMakeVezne")
AddEventHandler("vlast-base:PlayerCanMakeVezne", function(bool)
    TriggerClientEvent("vlast-base:setVezneStats", -1, bool)
end)