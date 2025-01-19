if addon.InGetInfo then
	return {
		name = "CameraAnchors",
		desc = "Adds keybindings for Camera Anchors",
		author = "badosu, lonewolfdesign",
		date = "Mar 12, 2023",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = false,
	}
end

local GetCameraState = Spring.GetCameraState
local SetCameraState = Spring.SetCameraState
local GetConfigInt = Spring.GetConfigInt
local SendCommands = Spring.SendCommands

local cameraAnchors = {}

local function setCameraAnchor(_, _, args)
	local anchorId = args[1]
	local cameraState = GetCameraState()

	cameraAnchors[anchorId] = cameraState

	Spring.Echo("Camera anchor set: " .. anchorId)

	return true
end

local function focusCameraAnchor(_, _, args)
	local anchorId = args[1]
	local cameraState = cameraAnchors[anchorId]

	if not cameraState then
		return
	end

	-- make sure if last camera state minimized minimap to unminimize it
	-- overview camera hides minimap
	if GetConfigInt("MinimapMinimize", 0) == 0 then
		SendCommands("minimap minimize 0")
	end

	SetCameraState(cameraState, 0)

	return true
end

function addon.Initialize()
	SG.actions.AddAction(addon, "set_camera_anchor", setCameraAnchor, nil, "p")
	SG.actions.AddAction(addon, "focus_camera_anchor", focusCameraAnchor, nil, "p")
end
