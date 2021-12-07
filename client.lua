QBCore = nil
-- AccountPrefix = "VLP"
AccountPrefix = "VLA"
CurrentAccount = nil
PlayerData = {}


Citizen.CreateThread(function()
  while QBCore == nil do
    TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)    
    Citizen.Wait(1)
  end
end)

RegisterCommand('31sj', function(source, raw, args)
    TriggerEvent("vlast-bank:openbank")
end)

RegisterNetEvent("vlast-bank:openbank")
AddEventHandler("vlast-bank:openbank", function(source, account)
    local data = {}

    if account == nil or account[1] == nil then
        PlayerData = QBCore.Functions.GetPlayerData()

        while PlayerData == nil do
            Citizen.Wait(1)
        end
        
        data.balance = PlayerData.money["bank"]
        data.name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
        data.account = PlayerData.charinfo.account
    else
        QBCore.Functions.TriggerCallback('vlast-bank:get-account', function(res)
            data.balance = res.balance
            data.account = res.account
            data.name = res.account
        end, "VLA-" .. account[1])
    end
    
    while data.name == nil do
        Citizen.Wait(5)
    end

    CurrentAccount = data.account
    SetNuiFocus(true, true)
    SendNUIMessage({type = "open", data = data})

    QBCore.Functions.TriggerCallback('vlast-bank:get-logs', function(data)
        SendNUIMessage({type = "update", content = "bank-history", data = data})
    end, data.account)
end)

-- RegisterCommand("testaccount", function(source, account, raw)
--     TriggerServerEvent("vlast-bank:create-account-if-not-exists", account[1], account[2])
-- end)

RegisterCommand("para", function()
    QBCore.Functions.TriggerCallback('vlast-bank:get-cash', function(data)
        QBCore.Functions.Notify("Nakit $" ..data, 'error')
    end)
end)

function UpdateSelf()
    local data = {}
    PlayerData = QBCore.Functions.GetPlayerData()
    
    while PlayerData == nil do
        Citizen.Wait(1)
    end
    
    data.balance = PlayerData.money["bank"]
    data.citizenid = PlayerData.citizenid
    data.name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    data.account = PlayerData.charinfo.account
    SendNUIMessage({type = "update", content = "self", data = data})
end

function UpdateBalance(amount)
    SendNUIMessage({type = "update", content = "balance", balance = amount})
end

RegisterCommand("close-bank", function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('get-history', function(data)
    QBCore.Functions.TriggerCallback('vlast-bank:get-logs', function(data)
        SendNUIMessage({type = "update", content = "bank-history", data = data})
    end, CurrentAccount)
end)

RegisterNUICallback('deposit', function(data)
    QBCore.Functions.TriggerCallback('vlast-bank:get-money', function(money)
        if tonumber(data.amount) <= money then
            TriggerServerEvent("vlast-bank:deposit-money", data.amount)
            QBCore.Functions.Notify("Hesabınıza " .. data.amount .. "$ para yatırıldı", 'error')
        else
            QBCore.Functions.Notify("Yeteri kadar nakitiniz yok", 'error')
        end
    end)
end)

RegisterNUICallback('withdraw', function(data)
    PlayerData = QBCore.Functions.GetPlayerData()
    
    if tonumber(data.amount) <= PlayerData.money["bank"] then
        TriggerServerEvent("vlast-bank:withdraw-money", data.amount)
        QBCore.Functions.Notify("Hesabınızdan " .. data.amount .. "$ para çıktı", 'error')
    else
        QBCore.Functions.Notify("Yeteri kadar bakiyeniz yok", 'error')
    end
end)

RegisterNUICallback('transfer', function(data)
    PlayerData = QBCore.Functions.GetPlayerData()

    if data.receiver == nil then
        QBCore.Functions.Notify("Alıcı bulunamadı", 'error')
        return
    end

    print(data.receiver, CurrentAccount)

    if data.receiver == CurrentAccount then
        QBCore.Functions.Notify("Kendinize havale yapamazsınız", 'error')
        return
    end

    if data.account:startswith(AccountPrefix) and tonumber(data.amount) > PlayerData.money["bank"] then
        QBCore.Functions.Notify("Yeteri kadar bakiyeniz yok", 'error')
        return
    end

    if data.account == PlayerData.charinfo.account and data.receiver:startswith(AccountPrefix) then
        TriggerServerEvent("vlast-bank:transfer:player-to-player", data.receiver, tonumber(data.amount), data.description)
        print("here 1")
    end
    
    if data.account ~= PlayerData.charinfo.account and not data.receiver:startswith(AccountPrefix) then
        TriggerServerEvent("vlast-bank:transfer:account-to-account", data.account, data.receiver, data.amount, data.description)
        print("here 2")
    end
    
    if data.account == PlayerData.charinfo.account and not data.receiver:startswith(AccountPrefix) then
        TriggerServerEvent("vlast-bank:transfer:player-to-account", data.account, data.receiver, data.amount, data.description)
        print("here 3")
    end
    
    if data.account ~= PlayerData.charinfo.account and data.receiver:startswith(AccountPrefix) then
        TriggerServerEvent("vlast-bank:transfer:account-to-player", data.account, data.receiver, data.amount, data.description)
        print("here 4")
    end
end)

RegisterNetEvent("vlast-bank:balance-changed")
AddEventHandler("vlast-bank:balance-changed", function(amount)
    if amount == nil then
        UpdateSelf()
    else
        UpdateBalance(amount)
    end
end)

string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end