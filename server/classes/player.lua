function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, loadout, name, coords)
	local self = {}

	self.accounts = accounts
	self.coords = coords
	self.group = group
	self.identifier = identifier
	self.inventory = inventory
	self.job = job
	self.loadout = loadout
	self.name = name
	self.playerId = playerId
	self.source = playerId
	self.variables = {}
	self.weight = weight
	self.maxWeight = Config.MaxWeight

	ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.group))

	self.triggerEvent = function(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	self.logEvent = function(eventName, ...)
		TriggerEvent(eventName, self.source, ...)
	end

	self.setCoords = function(coords)
		self.updateCoords(coords)
		self.triggerEvent('esx:teleport', coords)
	end

	self.updateCoords = function(coords)
		self.coords = {x = ESX.Math.Round(coords.x, 1), y = ESX.Math.Round(coords.y, 1), z = ESX.Math.Round(coords.z, 1), heading = ESX.Math.Round(coords.heading or 0.0, 1)}
	end

	self.getCoords = function(vector)
		if vector then
			return vector3(self.coords.x, self.coords.y, self.coords.z)
		else
			return self.coords
		end
	end

	self.kick = function(reason)
		DropPlayer(self.source, reason)
	end

	self.setMoney = function(money, recursion)
		money = ESX.Math.Round(money)
		self.setAccountMoney('money', money, recursion)

		if(recursion ~= true)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.setMoney(money) end)
		end
	end

	self.getBank = function()
		return self.getAccount('bank').money
	end

	self.removeBank = function(money, detail)
		self.removeAccountMoney('bank', money, detail)
	end

	self.addBank = function(money, detail)
		self.addAccountMoney('bank', money, detail)
	end

	self.getMoney = function()
		return self.getAccount('money').money
	end

	self.addMoney = function(money, recursion)
		money = ESX.Math.Round(money)
		self.addAccountMoney('money', money, recursion)

		if(recursion ~= true)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.addMoney(money, true) end)
		end
	end

	self.removeMoney = function(money, recursion)
		if(recursion ~= true)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.removeMoney(money, true) end)
		end

		money = ESX.Math.Round(money)
		self.removeAccountMoney('money', money, recursion)
	end

	self.getIdentifier = function()
		return self.identifier
	end

	self.setGroup = function(newGroup, recursion)
		if(recursion ~= true)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.set("group", newGroup) end)
		end

		ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.identifier, self.group))
		self.group = newGroup
		ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.group))
	end

	self.getGroup = function()
		return self.group
	end

	self.set = function(k, v, recursion)
		if(recursion ~= true)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) if(user)then user.set(k, v) end end)
		end

		self.variables[k] = v
	end

	self.get = function(k)
		return self.variables[k]
	end

	self.getAccounts = function(minimal)
		if minimal then
			local minimalAccounts = {}

			for k,v in ipairs(self.accounts) do
				minimalAccounts[v.name] = v.money
			end

			return minimalAccounts
		else
			return self.accounts
		end
	end

	self.getAccount = function(account)
		for k,v in ipairs(self.accounts) do
			if v.name == account then
				return v
			end
		end
	end

	self.getInventory = function(minimal)
		if minimal then
			local minimalInventory = {}

			for k,v in ipairs(self.inventory) do
				if v.count > 0 then
					minimalInventory[v.name] = v.count
				end
			end

			return minimalInventory
		else
			return self.inventory
		end
	end

	self.getJob = function()
		return self.job
	end

	self.getLoadout = function(minimal)
		if minimal then
			local minimalLoadout = {}

			for k,v in ipairs(self.loadout) do
				minimalLoadout[v.name] = {ammo = v.ammo, quality = v.quality, serial = v.serial}
				if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

				if #v.components > 0 then
					local components = {}

					for k2,component in ipairs(v.components) do
						if component ~= 'clip_default' then
							table.insert(components, component)
						end
					end

					if #components > 0 then
						minimalLoadout[v.name].components = components
					end
				end
			end

			return minimalLoadout
		else
			return self.loadout
		end
	end

	self.getName = function()
		return self.name
	end

	self.setName = function(newName)
		self.name = newName
	end

	self.setAccountMoney = function(accountName, money, detail)
		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				local prevMoney = account.money
				local newMoney = ESX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('esx:setAccountMoney', account)
				self.logEvent('log:setAccountMoney', account, prevMoney, detail)
			end
		end
	end

	self.addAccountMoney = function(accountName, money, detail)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = account.money + ESX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('esx:setAccountMoney', account)
				self.logEvent('log:addAccountMoney', account, money, detail)
			end
		end
	end

	self.removeAccountMoney = function(accountName, money, detail)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = account.money - ESX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('esx:setAccountMoney', account)
				self.logEvent('log:removeAccountMoney', account, money, detail)
			end
		end
	end

	self.getInventoryItem = function(name)
		local found = false
		local newItem

		for k,v in ipairs(self.inventory) do
			if v.name == name then
				found = true
				return v
			end
		end

		-- Ran only if the item wasn't found in your inventory
		local item = ESX.Items[name]

		-- if item exists -> run
		if(item)then
			-- Create new item
			newItem = {}
			for key,val in pairs(item) do
				newItem[key] = val
			end
			newItem.count = 0
			newItem.batch = {}
			newItem.batchCount = 0
			newItem.usable = ESX.UsableItemsCallbacks[name] ~= nil

			-- Insert into players inventory
			table.insert(self.inventory, newItem)

			-- Return the item that was just added
			return newItem
		end

		return
	end

	self.addInventoryItem = function(name, count, itemBatch)
		local item = self.getInventoryItem(name)

		if item then
			count = ESX.Math.Round(count)
			item.count = item.count + count
			if itemBatch then
				if not itemBatch.batch then
					itemBatch.batch = ESX.GetBatch()
				end
				if item.batch[itemBatch.batch] then
					item.batch[itemBatch.batch].count = item.batch[itemBatch.batch].count + count
				else
					if itemBatch.lifetime and not itemBatch.expiredtime then
						itemBatch.expiredtime = os.time() + itemBatch.lifetime
					end
					item.batch[itemBatch.batch] = {count = count, info = itemBatch}
				end
				item.batchCount = item.batchCount + count
			end
			self.weight = self.weight + (item.weight * count)

			TriggerEvent('esx:onAddInventoryItem', self.source, item.name, item.count, item.batch)
			self.triggerEvent('esx:addInventoryItem', item.name, item.count, false, item)
			return true
		end
	end

	self.removeInventoryItem = function(name, count, batchNumber)
		local item = self.getInventoryItem(name)

		if item then
			count = ESX.Math.Round(count)
			local newCount = item.count - count

			if newCount >= 0 then
				item.count = newCount
				batchNumber = not batchNumber and self.get('removeBatch') or batchNumber
				if batchNumber and item.batch[batchNumber] then
					local batchCount = item.batch[batchNumber].count - count
					if batchCount > 0 then
						item.batch[batchNumber].count = batchCount
					else
						item.batch[batchNumber] = false
					end
					item.batchCount = item.batchCount - count
				end

				if newCount == 0 then
					item.batch = {}
					item.batchCount = 0
				end

				self.weight = self.weight - (item.weight * count)

				TriggerEvent('esx:onRemoveInventoryItem', self.source, item.name, item.count, batchNumber)
				self.triggerEvent('esx:removeInventoryItem', item.name, item.count, false, item.batch)
				return true
			end
		end
	end

	self.setInventoryItem = function(name, count)
		local item = self.getInventoryItem(name)

		if item and count >= 0 then
			count = ESX.Math.Round(count)

			if count > item.count then
				self.addInventoryItem(item.name, count - item.count)
			else
				self.removeInventoryItem(item.name, item.count - count)
			end
		end
	end

	self.getWeight = function()
		return self.weight
	end

	self.getMaxWeight = function()
		return self.maxWeight
	end

	self.canCarryItem = function(name, count)
		if ESX.Items[name].limit and ESX.Items[name].limit ~= -1 then
			if count > ESX.Items[name].limit then
				return false
			elseif (self.getInventoryItem(name).count + count) > ESX.Items[name].limit then
				return false
			end
		end
		local currentWeight, itemWeight = self.weight, ESX.Items[name].weight
		local newWeight = currentWeight + (itemWeight * count)
		return newWeight <= self.maxWeight
	end

	self.canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
		local firstItemObject = self.getInventoryItem(firstItem)
		local testItemObject = self.getInventoryItem(testItem)

		if ESX.Items[testItem].limit and ESX.Items[testItem].limit ~= -1 and testItemObject.count + testItemCount > ESX.Items[testItem].limit then
			return false
		else
			if firstItemObject.count >= firstItemCount then
				local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
				local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))
				return weightWithTestItem <= self.maxWeight
			end
		end

		return false
	end

	-- xPlayer.canSwapItems({bread=2,meat=1}, {burger=1})
	self.canSwapItems = function(oldItems, newItems)
		local weightWithoutFirstItem, weightChangeItems = self.weight, 0
		for name,count in pairs(newItems) do
			local item = self.getInventoryItem(name)
			if ESX.Items[name].limit and ESX.Items[name].limit ~= -1 and item.count + count > ESX.Items[name].limit then
				return false
			end
			weightChangeItems = weightChangeItems + (item.weight * count)
		end

		for name,count in pairs(oldItems) do
			local item = self.getInventoryItem(name)
			if item.count >= count then				
				weightWithoutFirstItem = weightWithoutFirstItem - (item.weight * count)
			else
				return false
			end
		end

		local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + weightChangeItems)
		return weightWithTestItem <= self.maxWeight
	end

	self.swapItems = function(removeItems, addItems)
		if type(removeItems) ~= 'table' then removeItems = {[removeItems] = 1} end
		if type(addItems) ~= 'table' then addItems = {[addItems] = 1} end
		if self.canSwapItems(removeItems, addItems) then
			for name,count in pairs(removeItems) do
				self.removeInventoryItem(name, count)
			end
			for name,count in pairs(addItems) do
				self.addInventoryItem(name, count)
			end
			return true
		end
		return false
	end

	self.setMaxWeight = function(newWeight)
		self.maxWeight = newWeight
		self.triggerEvent('esx:setMaxWeight', self.maxWeight)
	end

	self.setJob = function(job, grade)
		grade = tostring(grade)
		local lastJob = json.decode(json.encode(self.job))

		if ESX.DoesJobExist(job, grade) then
			local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

			self.job.id    = jobObject.id
			self.job.name  = jobObject.name
			self.job.label = jobObject.label

			self.job.grade        = tonumber(grade)
			self.job.grade_name   = gradeObject.name
			self.job.grade_label  = gradeObject.label
			self.job.grade_salary = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end

			TriggerEvent('esx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('esx:setJob', self.job)
		else
			print(('[ExtendedMode] [^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(self.identifier))
		end
	end

	self.addWeapon = function(weaponName, ammo, itemInfo)
		if not self.hasWeapon(weaponName) then
			local weaponLabel = ESX.GetWeaponLabel(weaponName)
			local quality = itemInfo and itemInfo.quality or 100
			local serial = itemInfo and itemInfo.serial or ESX.RandomString(8)

			table.insert(self.loadout, {
				name = weaponName,
				ammo = ammo,
				quality = quality,
				batch = serial,
				serial = serial,
				label = weaponLabel,
				components = {},
				tintIndex = 0
			})

			self.triggerEvent('esx:addWeapon', weaponName, ammo)
			self.triggerEvent('esx:addInventoryItem', weaponLabel, false, true)
		else
			itemInfo.weapon = weaponName
			itemInfo.count = ammo
			self.addInventoryItem(weaponName, ammo, itemInfo)
		end
	end

	self.addWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if not self.hasWeaponComponent(weaponName, weaponComponent) then
					table.insert(self.loadout[loadoutNum].components, weaponComponent)
					self.triggerEvent('esx:addWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('esx:addInventoryItem', component.label, false, true)
				end
			end
		end
	end

	self.addWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo + ammoCount
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.updateWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			if ammoCount < weapon.ammo then
				weapon.ammo = ammoCount
			end
		end
	end

	self.updateWeaponQuality = function(weaponName, quality)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.quality = quality
		end
	end

	self.setWeaponTint = function(weaponName, weaponTintIndex)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local weaponNum, weaponObject = ESX.GetWeapon(weaponName)

			if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
				self.loadout[loadoutNum].tintIndex = weaponTintIndex
				self.triggerEvent('esx:setWeaponTint', weaponName, weaponTintIndex)
				self.triggerEvent('esx:addInventoryItem', weaponObject.tints[weaponTintIndex], false, true)
			end
		end
	end

	self.getWeaponTint = function(weaponName)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			return weapon.tintIndex
		end

		return 0
	end

	self.removeWeapon = function(weaponName, ammo)
		local weaponLabel

		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				weaponLabel = v.label

				for k2,v2 in ipairs(v.components) do
					self.removeWeaponComponent(weaponName, v2)
				end

				table.remove(self.loadout, k)
				break
			end
		end

		if weaponLabel then
			self.triggerEvent('esx:removeWeapon', weaponName, ammo)
			self.triggerEvent('esx:removeInventoryItem', weaponLabel, false, true)
		end
	end

	self.removeWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if self.hasWeaponComponent(weaponName, weaponComponent) then
					for k,v in ipairs(self.loadout[loadoutNum].components) do
						if v == weaponComponent then
							table.remove(self.loadout[loadoutNum].components, k)
							break
						end
					end

					self.triggerEvent('esx:removeWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('esx:removeInventoryItem', component.label, false, true)
				end
			end
		end
	end

	self.removeWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo - ammoCount
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.hasWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			for k,v in ipairs(weapon.components) do
				if v == weaponComponent then
					return true
				end
			end

			return false
		else
			return false
		end
	end

	self.hasWeapon = function(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return true
			end
		end

		return false
	end

	self.getWeapon = function(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return k, v
			end
		end

		return
	end

	self.showNotification = function(msg, flash, saveToBrief, hudColorIndex)
		self.triggerEvent('esx:showNotification', msg, flash, saveToBrief, hudColorIndex)
	end

	self.showHelpNotification = function(msg, thisFrame, beep, duration)
		self.triggerEvent('esx:showHelpNotification', msg, thisFrame, beep, duration)
	end

	return self
end
