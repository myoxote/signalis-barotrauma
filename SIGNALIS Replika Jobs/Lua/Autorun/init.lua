if CLIENT then return end

local characterIDs = {"Starling", "Storch"}
local jobIDs = {"Starling", "Storch"} 

local function MoveInvSlot(oldCharacter, newCharacter, invSlot)
	local item = oldCharacter.Inventory.GetItemInLimbSlot(invSlot)
	item.Drop() -- drop item to the ground
	local index = newCharacter.Inventory.FindLimbSlot(invSlot)
	newCharacter.Inventory.TryPutItem(item, index, true, false, newCharacter, true, false ) -- move item to new character
end

local function RespawnCharacter(character, jobID, speciesName)
	print("Respawning " .. character.Name .. " as " .. jobID)

	Entity.Spawner.AddCharacterToSpawnQueue(speciesName, character.WorldPosition, function(newCharacter)
		local client = nil
		for key, value in pairs(Client.ClientList) do
			if value.Character == character then
				client = value
			end
		end

		MoveInvSlot(character, newCharacter, InvSlotType.Card)
		MoveInvSlot(character, newCharacter, InvSlotType.Headset)
        MoveInvSlot(character, newCharacter, InvSlotType.OuterClothes)

		Entity.Spawner.AddEntityToRemoveQueue(character)

		if client == nil then
			return
		end

		newCharacter.TeamID = character.TeamID

		client.SetClientCharacter(newCharacter)

		local info = CharacterInfo(speciesName, client.Name, client.Name)

		print(client.CharacterInfo)
		-- print("jobID:", jobID)
		-- print("JobPrefab.Get(jobID):", JobPrefab.Get(jobID))
	    info.Job = Job(JobPrefab.Get(jobID), false)
	
		if client.CharacterInfo then
			info.Head = client.CharacterInfo.Head
		end
		info.Head.HairIndex = 1
		info.Head.BeardIndex = 0
		info.Head.MoustacheIndex = 0
		info.Head.FaceAttachmentIndex = 0

		newCharacter.Info = info
        newCharacter.TeamID = character.TeamID
	end)
end

Hook.Add("character.created", "convertJobsReplika", function(character)
	Timer.Wait(function()
		for key, jobID in pairs(jobIDs) do
			if character.HasJob(jobID) and character.IsHuman then
				RespawnCharacter(character, characterIDs[key], jobID)
			elseif not character.IsHuman and character.Name == characterIDs[key] then
				print("deleted duplicate character ", character.Name)
	
				if character.Inventory then
					for bb, items in pairs(character.Inventory.FindAllItems()) do
						Entity.Spawner.AddItemToRemoveQueue(items)
					end
				end
				Entity.Spawner.AddEntityToRemoveQueue(character)
			end
		end
	end, 500)
end)

Hook.Add("character.death", "transferItemsReplika", function(character)
    print(character, " - ", character.Name, " - ", character.JobIdentifier, " - ", character.IsHuman)
    if not character.Inventory then return end
    if character.IsHuman then return end

    for _, jobID in pairs(jobIDs) do
        if character.HasJob(jobID) then
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["duffelbag"], character.WorldPosition, nil, nil, function (item)
                for _, transferItem in pairs(character.Inventory.FindAllItems()) do
                    item.OwnInventory.TryPutItem(transferItem, nil, {InvSlotType.Any})
                end
            end)
        end
    end
end)