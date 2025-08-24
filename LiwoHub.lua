-- Game verification
local function verifyGame()
    local gameId = game.GameId
    local placeId = game.PlaceId
    
    -- Check for panning game indicators
    local validGame = false
    
    -- Method 1: Check for specific game elements
    if workspace:FindFirstChild("Characters") and 
       workspace:FindFirstChild("NPCs") and 
       game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and
       game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Shop") then
        validGame = true
    end
    
    -- Method 2: Check for specific remotes
    if game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") then
        local remotes = game:GetService("ReplicatedStorage").Remotes
        if remotes:FindFirstChild("Shop") then
            local shop = remotes.Shop
            if shop:FindFirstChild("SellAll") and shop:FindFirstChild("GetInventorySellPrice") then
                validGame = true
            end
        end
    end
    
    if not validGame then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Liwo.Hub - Wrong Game!";
            Text = "This script is designed forProspecting only!";
            Duration = 10;
        })
        return false
    end
    
    return true
end

-- Verify game before loading
if not verifyGame() then
    return -- Exit script if wrong game
end

local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))();
local Notification = Fatality:CreateNotifier();

Fatality:Loader({
	Name = "Liwo.Hub",
	Duration = 4
});

Notification:Notify({
	Title = "Liwo.Hub",
	Content = "Hello, "..game.Players.LocalPlayer.DisplayName..' Welcome back!',
	Icon = "clipboard"
})

local Window = Fatality.new({
	Name = "Liwo.Hub",
});

-- Liwo.Hub - Panning Automation Script
-- Script variables
local collectRunning = false
local shakeRunning = false
local autoFarmRunning = false

-- Merchant coordinates
local MERCHANT_COORDINATES = {
    Vector3.new(-194.5269775390625, -10, 372.69256591796875),
    Vector3.new(-349.61724853515625, 12.988398551940918, -518.1930541992188),
    Vector3.new(-1434, 147.78073120117188, -2736.49462890625),
    Vector3.new(-1395.7684326171875, 17.587644577026367, -2286.000244140625),
    Vector3.new(-1501.2432861328125, 355.0278625488281, -3229.7451171875),
    Vector3.new(-267.6394958496094, 22.31192398071289, 88.933837890625),
    Vector3.new(-4.6148223876953125, 22.126768112182617, 61.16460037231445),
    Vector3.new(632.3677368164062, -96.17879486083984, -2032.5926513671875),
    Vector3.new(58.80023193359375, 9.999998092651367, -1504.5),
    Vector3.new(803.99462890625, 26.182676315307617, -1721.5040283203125)
}

-- Pan checking functions
local function IsPanEmpty(Pan)
    return Pan:GetAttribute("Fill") == 0
end

local function IsPanFull(Pan)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local PlayerStats = LocalPlayer:FindFirstChild("Stats")
    if not PlayerStats then return false end
    
    local MaxCapacity = PlayerStats:GetAttribute("Capacity")
    if Pan:GetAttribute("Fill") >= MaxCapacity then
        return true
    end
    return false
end

-- SimplePath module (if not already loaded elsewhere)
local SimplePath = loadstring(game:HttpGet("https://raw.githubusercontent.com/00xima/SimplePath/main/src/SimplePath.lua"))()

-- Create invisible part for pathfinding targets
local function createTargetPart(position)
    local part = Instance.new("Part")
    part.Name = "PathTarget"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1, 1, 1)
    part.Position = position
    part.Parent = workspace
    return part
end

-- Simple pathfinding movement function using SimplePath
local function simpleMoveTo(targetPosition, timeout)
    timeout = timeout or 20
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return false, "No character" end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false, "Missing humanoid or rootpart" end
    
    -- Create a target part at the destination
    local targetPart = createTargetPart(targetPosition)
    
    -- Create SimplePath
    local Path = SimplePath.new(character)
    
    local reached = false
    local errorOccurred = false
    
    -- Set up event handlers
    Path.Reached:Connect(function()
        reached = true
    end)
    
    Path.Error:Connect(function(errorType)
        errorOccurred = true
    end)
    
    -- Run the path
    Path:Run(targetPart)
    
    -- Wait for arrival or timeout
    local startTime = tick()
    while (tick() - startTime) < timeout and not reached and not errorOccurred do
        wait(0.5)
    end
    
    -- Clean up
    Path:Destroy()
    targetPart:Destroy()
    
    if reached then
        return true, "Arrived at destination"
    elseif errorOccurred then
        return false, "Pathfinding error"
    else
        return false, "Movement timed out"
    end
end

-- Function to find closest merchant
local function findClosestMerchant()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local closestMerchant = nil
    local closestDistance = math.huge
    
    for _, merchantPos in pairs(MERCHANT_COORDINATES) do
        local distance = (rootPart.Position - merchantPos).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestMerchant = merchantPos
        end
    end
    
    return closestMerchant
end

-- Create UI tabs
local AutoFarm = Window:AddMenu({
	Name = "AUTO FARM",
	Icon = "zap"
})

local Manual = Window:AddMenu({
	Name = "MANUAL",
	Icon = "hand"
})

local Settings = Window:AddMenu({
	Name = "SETTINGS",
	Icon = "settings"
})

-- AUTO FARM TAB
do
	local FarmControls = AutoFarm:AddSection({
		Position = 'left',
		Name = "FARM CONTROLS"
	});
	
	-- Auto Farm Toggle
	FarmControls:AddToggle({
		Name = "Auto Farm",
		Callback = function(state)
			autoFarmRunning = state
			if state then
				Notification:Notify({
					Title = "Auto Farm",
					Content = "Auto farm started!",
					Duration = 3,
					Icon = "play"
				})
				task.spawn(function()
					while autoFarmRunning do
						local success, errorMessage = pcall(function()
							-- Check if we have collection coordinates
							if not _G.COLLECTION_COORDINATES then
								Notification:Notify({
									Title = "Error",
									Content = "No collection coordinates set",
									Duration = 4,
									Icon = "map-pin"
								})
								return
							end
							
							-- Check if we have shaking coordinates  
							if not _G.SHAKING_COORDINATES then
								Notification:Notify({
									Title = "Error",
									Content = "No shaking coordinates set",
									Duration = 4,
									Icon = "map-pin"
                })
                return
            end
            
							-- Move to collection spot
							Notification:Notify({
								Title = "Auto Farm",
								Content = "Moving to collection spot",
								Duration = 2,
								Icon = "navigation"
							})
							local moveSuccess, moveMessage = simpleMoveTo(_G.COLLECTION_COORDINATES, 15)
							if not moveSuccess then
								Notification:Notify({
									Title = "Auto Farm",
									Content = "Failed to reach collection spot",
									Duration = 3,
									Icon = "x"
								})
								wait(2)
                return
            end
            
							-- Start collecting
            collectRunning = true
							Notification:Notify({
								Title = "Auto Farm",
								Content = "Starting collection",
								Duration = 2,
								Icon = "pickaxe"
							})
							
							while collectRunning and autoFarmRunning do
                    local player = game.Players.LocalPlayer
								local character = player.Character
								if not character then 
									Notification:Notify({
										Title = "Auto Farm",
										Content = "Character not found, retrying...",
										Duration = 2,
										Icon = "alert-triangle"
									})
									wait(1)
									break
								end
								
								-- Find any pan in character
								local pan = nil
								for _, child in pairs(character:GetChildren()) do
									if child:IsA("Tool") and string.lower(child.Name):find("pan") then
										pan = child
										break
									end
								end
                    
                    if pan then
									if IsPanFull(pan) then
										Notification:Notify({
											Title = "Auto Farm",
											Content = "Pan is full! Moving to shaking phase...",
											Duration = 3,
											Icon = "check"
										})
										collectRunning = false
										break
									end
									
									-- Collect
									local collectScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Collect")
									if collectScript then
										collectScript:InvokeServer(1)
									else
										Notification:Notify({
											Title = "Auto Farm",
											Content = "Collect script not found in pan",
											Duration = 3,
											Icon = "x"
										})
										collectRunning = false
                                    break
									end
								else
									Notification:Notify({
										Title = "Auto Farm",
										Content = "No pan found in character",
										Duration = 3,
										Icon = "x"
									})
									collectRunning = false
									autoFarmRunning = false  -- Stop auto farm completely
									break
								end
								
                                    wait(0.1)
                            end
                            
							if not autoFarmRunning then return end
                            
                            -- Move to shaking spot
							Notification:Notify({
								Title = "Auto Farm",
								Content = "Moving to shaking spot",
								Duration = 2,
								Icon = "navigation"
							})
							moveSuccess, moveMessage = simpleMoveTo(_G.SHAKING_COORDINATES, 15)
							if not moveSuccess then
								Notification:Notify({
									Title = "Auto Farm",
									Content = "Failed to reach shaking spot",
									Duration = 3,
									Icon = "x"
								})
								wait(2)
								return
							end
							
							-- Start shaking
							shakeRunning = true
							Notification:Notify({
								Title = "Auto Farm",
								Content = "Starting shaking",
								Duration = 2,
								Icon = "shuffle"
							})
							
							while shakeRunning and autoFarmRunning do
								local player = game.Players.LocalPlayer
								local character = player.Character
								if not character then 
									Notification:Notify({
										Title = "Auto Farm",
										Content = "Character not found during shaking, retrying...",
										Duration = 2,
										Icon = "alert-triangle"
									})
									wait(1)
									break
								end
								
								-- Find any pan in character
								local pan = nil
								for _, child in pairs(character:GetChildren()) do
									if child:IsA("Tool") and string.lower(child.Name):find("pan") then
										pan = child
                                    break
                                end
                            end
                            
								if pan then
									if IsPanEmpty(pan) then
										Notification:Notify({
											Title = "Auto Farm",
											Content = "Pan is empty! Starting next cycle...",
											Duration = 3,
											Icon = "check"
										})
										shakeRunning = false
										break
									end
									
									-- Shake
									local shakeScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Shake")
									if shakeScript then
										shakeScript:FireServer()
									else
										Notification:Notify({
											Title = "Auto Farm",
											Content = "Shake script not found in pan",
											Duration = 3,
											Icon = "alert-triangle"
										})
									end
									
									-- Also invoke Pan script
									local panScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Pan")
									if panScript then
										panScript:InvokeServer()
									else
										Notification:Notify({
											Title = "Auto Farm",
											Content = "Pan script not found in pan",
											Duration = 3,
											Icon = "alert-triangle"
										})
									end
								else
									Notification:Notify({
										Title = "Auto Farm",
										Content = "No pan found during shaking",
										Duration = 3,
										Icon = "x"
									})
									shakeRunning = false
									autoFarmRunning = false  -- Stop auto farm completely
									break
								end
								
								wait(0.1)
							end
							
							if not autoFarmRunning then return end
							
							-- Cycle complete notification
							Notification:Notify({
								Title = "Auto Farm",
								Content = "Cycle completed! Starting next cycle in 2 seconds...",
								Duration = 3,
								Icon = "refresh-cw"
							})
							
							wait(2) -- Wait before next cycle
                end)
                
                if not success then
							Notification:Notify({
								Title = "Auto Farm Error",
								Content = tostring(errorMessage),
								Duration = 5,
								Icon = "alert-triangle"
							})
							autoFarmRunning = false
							wait(5)
						end
						
						if not autoFarmRunning then break end
					end
            end)
        else
            collectRunning = false
            shakeRunning = false
				Notification:Notify({
					Title = "Auto Farm",
					Content = "Auto farm stopped",
					Duration = 3,
					Icon = "stop"
            })
        end
		end
	})
	

end

-- MANUAL CONTROLS TAB
do
	local Collection = Manual:AddSection({
		Position = 'left',
		Name = "COLLECTION"
	});
	
	local Shaking = Manual:AddSection({
		Position = 'center',
		Name = "SHAKING"
	});
	
	local Utilities = Manual:AddSection({
		Position = 'right',
		Name = "UTILITIES"
	});
	
	-- Collection Controls
	Collection:AddButton({
		Name = "Start Collection",
		Callback = function()
			if collectRunning then
				Notification:Notify({
					Title = "Collection",
					Content = "Collection already running!",
					Duration = 3,
					Icon = "alert-triangle"
				})
				return
			end
			
			collectRunning = true
			Notification:Notify({
				Title = "Collection",
				Content = "Manual collection started",
				Duration = 3,
				Icon = "play"
        })
        
        task.spawn(function()
				while collectRunning do
					local player = game.Players.LocalPlayer
					local character = player.Character
					if not character then break end
					
					-- Find any pan in character
					local pan = nil
					for _, child in pairs(character:GetChildren()) do
						if child:IsA("Tool") and string.lower(child.Name):find("pan") then
							pan = child
							break
						end
					end
					
					if pan then
						if IsPanFull(pan) then
							Notification:Notify({
								Title = "Collection",
								Content = "Pan is full!",
								Duration = 3,
								Icon = "check"
							})
							collectRunning = false
							break
						end
						
						-- Collect
						local collectScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Collect")
						if collectScript then
							collectScript:InvokeServer(1)
                end
            else
						Notification:Notify({
							Title = "Collection",
							Content = "No pan found",
							Duration = 3,
							Icon = "x"
						})
						collectRunning = false
						break
					end
					
					wait(0.1)
            end
        end)
		end
	})
	
	Collection:AddButton({
		Name = "Stop Collection",
		Callback = function()
			collectRunning = false
			Notification:Notify({
				Title = "Collection",
				Content = "Collection stopped",
				Duration = 3,
				Icon = "stop"
			})
		end
	})
	
	-- Shaking Controls
	Shaking:AddButton({
		Name = "Start Shaking",
		Callback = function()
			if shakeRunning then
				Notification:Notify({
					Title = "Shaking",
					Content = "Shaking already running!",
					Duration = 3,
					Icon = "alert-triangle"
				})
				return
			end
			
			shakeRunning = true
			Notification:Notify({
				Title = "Shaking",
				Content = "Manual shaking started",
				Duration = 3,
				Icon = "play"
			})
			
			task.spawn(function()
				while shakeRunning do
        local player = game.Players.LocalPlayer
					local character = player.Character
					if not character then break end
					
					-- Find any pan in character
					local pan = nil
					for _, child in pairs(character:GetChildren()) do
						if child:IsA("Tool") and string.lower(child.Name):find("pan") then
							pan = child
							break
						end
					end
					
					if pan then
						if IsPanEmpty(pan) then
							Notification:Notify({
								Title = "Shaking",
								Content = "Pan is empty!",
								Duration = 3,
								Icon = "check"
							})
							shakeRunning = false
							break
						end
						
						-- Shake
						local shakeScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Shake")
						if shakeScript then
							shakeScript:FireServer()
						end
						
						-- Also invoke Pan script
						local panScript = pan:FindFirstChild("Scripts") and pan.Scripts:FindFirstChild("Pan")
						if panScript then
							panScript:InvokeServer()
						end
					else
						Notification:Notify({
							Title = "Shaking",
							Content = "No pan found",
							Duration = 3,
							Icon = "x"
						})
						shakeRunning = false
						break
					end
					
					wait(0.1)
				end
			end)
		end
	})
	
	Shaking:AddButton({
		Name = "Stop Shaking",
		Callback = function()
			shakeRunning = false
			Notification:Notify({
				Title = "Shaking",
				Content = "Shaking stopped",
				Duration = 3,
				Icon = "stop"
            })
        end
	})
	
	-- Utilities
	Utilities:AddButton({
		Name = "Sell All Items",
		Callback = function()
			Notification:Notify({
				Title = "Selling",
				Content = "Selling items...",
				Duration = 2,
				Icon = "dollar-sign"
			})
			
			task.spawn(function()
				local success, errorMessage = pcall(function()
					local result = game:GetService("ReplicatedStorage").Remotes.Shop.SellAll:InvokeServer()
					
					if result then
						if result == 0 then
							Notification:Notify({
								Title = "Selling",
								Content = "No items to sell",
								Duration = 3,
								Icon = "info"
							})
						else
							local formattedResult = tostring(result):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
							Notification:Notify({
								Title = "Selling",
								Content = "Sold items for " .. formattedResult .. " coins!",
								Duration = 4,
								Icon = "dollar-sign"
							})
						end
					else
						Notification:Notify({
							Title = "Selling",
							Content = "Sell failed",
							Duration = 3,
							Icon = "x"
						})
					end
				end)
				
				if not success then
					Notification:Notify({
						Title = "Selling Error",
						Content = tostring(errorMessage),
						Duration = 4,
						Icon = "alert-triangle"
					})
				end
			end)
		end
	})
	
	Utilities:AddButton({
		Name = "Check Inventory Value",
		Callback = function()
			Notification:Notify({
				Title = "Checking",
				Content = "Getting inventory value...",
				Duration = 2,
				Icon = "search"
			})
			
			task.spawn(function()
				local success, result = pcall(function()
					local inventoryValue = game:GetService("ReplicatedStorage").Remotes.Shop.GetInventorySellPrice:InvokeServer()
					return inventoryValue
				end)
				
				if success then
					if result and result > 0 then
						local formattedValue = tostring(result):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
						Notification:Notify({
							Title = "Inventory Value",
							Content = "Your inventory is worth " .. formattedValue .. " coins",
							Duration = 5,
							Icon = "dollar-sign"
            })
        else
						Notification:Notify({
							Title = "Inventory Value",
							Content = "Your inventory is empty or has no value",
							Duration = 3,
							Icon = "info"
            })
        end
				else
					Notification:Notify({
						Title = "Error",
						Content = "Failed to get inventory value",
						Duration = 3,
						Icon = "x"
					})
				end
			end)
		end
	})
end

-- SETTINGS TAB
do
	local Coordinates = Settings:AddSection({
		Position = 'left',
		Name = "COORDINATES"
	});
	
	local UISettings = Settings:AddSection({
		Position = 'right',
		Name = "UI SETTINGS"
	});
	
	-- Coordinate Settings
	Coordinates:AddButton({
		Name = "Set Collection Coords",
		Callback = function()
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart")
			
			_G.COLLECTION_COORDINATES = rootPart.Position
			Notification:Notify({
				Title = "Coordinates",
				Content = "Collection coords set: " .. math.floor(rootPart.Position.X) .. ", " .. math.floor(rootPart.Position.Y) .. ", " .. math.floor(rootPart.Position.Z),
				Duration = 4,
				Icon = "map-pin"
			})
		end
	})
	
	Coordinates:AddButton({
		Name = "Set Shaking Coords",
		Callback = function()
        local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart")
			
			_G.SHAKING_COORDINATES = rootPart.Position
			Notification:Notify({
				Title = "Coordinates",
				Content = "Shaking coords set: " .. math.floor(rootPart.Position.X) .. ", " .. math.floor(rootPart.Position.Y) .. ", " .. math.floor(rootPart.Position.Z),
				Duration = 4,
				Icon = "map-pin"
                })
            end
	})
	
	-- UI Settings
	UISettings:AddKeybind({
		Name = "Toggle UI",
		Default = Enum.KeyCode.Semicolon,
		Callback = function()
			-- Keybind functionality is handled automatically by Fatality
		end
	})
end

-- Final notification
Notification:Notify({
	Title = "Liwo.Hub",
	Content = "Panning automation loaded successfully!",
	Duration = 4,
	Icon = "check"
})
