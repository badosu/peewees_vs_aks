local cannon = piece("Cannon")
local turret = piece("Turret")
local flare = piece("flare")

-- signals
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

local function Step(front, back) end

local function Walk() end

function script.Create() end

local function Stopping() end

function script.StartMoving() end

function script.StopMoving() end

local function RestoreAfterDelay() end

function script.AimFromWeapon()
	return cannon
end

function script.QueryWeapon(_)
	return flare
end

function script.AimWeapon(_, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	Turn(turret, y_axis, heading, math.rad(1000))
	Turn(cannon, x_axis, -pitch, math.rad(500))

	WaitForTurn(turret, y_axis)
	WaitForTurn(cannon, x_axis)

	return true
end
