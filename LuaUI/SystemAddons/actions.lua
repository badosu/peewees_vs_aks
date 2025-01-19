--TODO more unification with LuaGadget's one
--TODO add LuaMessages

if addon.InGetInfo then
	return {
		name = "Actions",
		desc = "Adds handling of keybinding actions to lua",
		author = "Dave Rodgers, jk, badosu",
		date = "Mar 12, 2023",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
		api = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local textActions = {}
local keyPressActions = {}
local keyRepeatActions = {}
local keyReleaseActions = {}
--local syncActions = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helpers

-- Split a string into a table of substrings, based on a delimiter.
-- If not supplied, delimiter defaults to whitespace.
-- Consecutive delimiters are treated as one.
-- string.split(csvText, ',')	csvText:split(',')
local function ssplit(val, delimiter)
	delimiter = delimiter or "%s"
	local results = {}
	for part in string.gmatch(val, "[^" .. delimiter .. "]+") do
		table.insert(results, part)
	end
	return results
end

local function ParseTypes(types, def)
	if type(types) ~= "string" then
		types = def
	end
	local text = (types:find("t") ~= nil)
	local keyPress = (types:find("p") ~= nil)
	local keyRepeat = (types:find("R") ~= nil)
	local keyRelease = (types:find("r") ~= nil)
	return text, keyPress, keyRepeat, keyRelease
end

local function InsertCallInfo(callInfoList, addon, func, data)
	local layer = addon._info.layer
	local index = 1
	for i, ci in ipairs(callInfoList) do
		local w = ci[1]
		if w == addon then
			return false --  already in the table
		end
		if layer >= w._info.layer then
			index = i + 1
		end
	end
	table.insert(callInfoList, index, { addon, func, data })
	return true
end

local function InsertAction(map, cmd, addon, func, data)
	local callInfoList = map[cmd]
	if not callInfoList then
		callInfoList = {}
		map[cmd] = callInfoList
	end
	return InsertCallInfo(callInfoList, addon, func, data)
end

local function RemoveCallInfo(callInfoList, addon)
	local count = 0
	for i, callInfo in ipairs(callInfoList) do
		local w = callInfo[1]
		if w == addon then
			table.remove(callInfoList, i)
			count = count + 1
			-- break
		end
	end
	return count
end

local function ClearActionList(actionMap, addon)
	for _, callInfoList in pairs(actionMap) do
		RemoveCallInfo(callInfoList, addon)
	end
end

local function RemoveAction(map, addon, cmd)
	local callInfoList = map[cmd]
	if callInfoList == nil then
		return false
	end
	local count = RemoveCallInfo(callInfoList, addon)
	if #callInfoList <= 0 then
		map[cmd] = nil
	end
	return (count > 0)
end

local function TryAction(actionMap, cmd, optLine, optWords, isRepeat, release, actions)
	local callInfoList = actionMap[cmd]
	if not callInfoList then
		return false
	end
	for _, callInfo in ipairs(callInfoList) do
		--local addon = callInfo[1]
		local func = callInfo[2]
		local data = callInfo[3]
		if func(cmd, optLine, optWords, data, isRepeat, release, actions) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Insertions
--

local function AddAddonAction(addon, cmd, func, data, types, _)
	assert(_ == nil, "actionHandler:Foobar() is deprecated, use actionHandler.Foobar()!")

	-- make sure that this is a fully initialized addon
	if not addon._info then
		error(LUA_NAME .. "error adding action: please use addon:Initialize()")
	end

	-- default to text and keyPress  (not repeat or releases)
	local text, keyPress, keyRepeat, keyRelease = ParseTypes(types, "tp")

	local tSuccess, pSuccess, RSuccess, rSuccess = false, false, false, false

	if text then
		tSuccess = InsertAction(textActions, cmd, addon, func, data)
	end
	if keyPress then
		pSuccess = InsertAction(keyPressActions, cmd, addon, func, data)
	end
	if keyRepeat then
		RSuccess = InsertAction(keyRepeatActions, cmd, addon, func, data)
	end
	if keyRelease then
		rSuccess = InsertAction(keyReleaseActions, cmd, addon, func, data)
	end

	return tSuccess, pSuccess, RSuccess, rSuccess
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Removals
--

local function RemoveAddonAction(addon, cmd, types, _)
	assert(_ == nil, "actionHandler:Foobar() is deprecated, use actionHandler.Foobar()!")

	-- default to removing all
	local text, keyPress, keyRepeat, keyRelease = ParseTypes(types, "tpRr")

	local tSuccess, pSuccess, RSuccess, rSuccess = false, false, false, false

	if text then
		tSuccess = RemoveAction(textActions, addon, cmd)
	end
	if keyPress then
		pSuccess = RemoveAction(keyPressActions, addon, cmd)
	end
	if keyRepeat then
		RSuccess = RemoveAction(keyRepeatActions, addon, cmd)
	end
	if keyRelease then
		rSuccess = RemoveAction(keyReleaseActions, addon, cmd)
	end

	return tSuccess, pSuccess, RSuccess, rSuccess
end

local function RemoveAddonActions(addon, _)
	assert(_ == nil, "actionHandler:Foobar() is deprecated, use actionHandler.Foobar()!")

	ClearActionList(textActions, addon)
	ClearActionList(keyPressActions, addon)
	ClearActionList(keyRepeatActions, addon)
	ClearActionList(keyReleaseActions, addon)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Calls
--

local function KeyAction(press, _, _, isRepeat, _, actions)
	if not (actions and next(actions)) then
		return false
	end

	local actionSet

	if press then
		actionSet = isRepeat and keyRepeatActions or keyPressActions
	else
		actionSet = keyReleaseActions
	end

	for _, bAction in ipairs(actions) do
		local cmd = bAction["command"]
		local extra = bAction["extra"]
		local words = ssplit(extra)
		if TryAction(actionSet, cmd, extra, words, isRepeat, not press, actions) then
			return true
		end
	end

	return false
end

local function TextAction(line, _)
	assert(_ == nil, "actionHandler:Foobar() is deprecated, use actionHandler.Foobar()!")

	local words = MakeWords(line)
	local cmd = words[1]
	if not cmd then
		return false
	end
	-- remove the command from the words list and the raw line
	table.remove(words, 1)
	local _, _, line = line:find("[^%s]+[%s]+(.*)")
	if not line then
		line = "" -- no args
	end

	return TryAction(textActions, cmd, line, words, false, nil)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local actionHandler = {
	KeyAction = KeyAction,
	TextAction = TextAction,

	AddAction = AddAddonAction,
	RemoveAction = RemoveAddonAction,
	RemoveAddonActions = RemoveAddonActions,
	--LuaRules
	--GotChatMsg     = GotChatMsg
	--RecvFromSynced = RecvFromSynced
}

function addon.Initialize()
	-- handler:RegisterGlobal(addon, "actionHandler", actionHandler)
	SG.actions = actionHandler
end

function addon.AddonWillBeRemoved(addon, _)
	actionHandler.RemoveAddonActions(addon)
end

function addon.TextCommand(command)
	return actionHandler.TextAction(command)
end

function addon.KeyPress(key, mods, isRepeat, _, _, scanCode, actions)
	return actionHandler.KeyAction(true, key, mods, isRepeat, scanCode, actions)
end

function addon.KeyRelease(key, mods, _, _, scanCode, actions)
	return actionHandler.KeyAction(false, key, mods, false, scanCode, actions)
end
