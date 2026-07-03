--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const VerifyReplication = ReplicatedStorage.VerifyReplication

VerifyReplication.OnServerInvoke = function(_player: Player, targetInstance: Instance?): boolean
	return targetInstance ~= nil
end

-- Usage Example:

-- Create an Animate script for a given rig type for use on clients
const function createAnimateScript(rigType: Enum.HumanoidRigType): LocalScript
	const npc = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), rigType)
	const animateScript = npc:FindFirstChildOfClass("LocalScript") :: LocalScript

	animateScript.Name = `BaseAnimate{rigType.Name}`

	return animateScript
end

const function Init()
	createAnimateScript(Enum.HumanoidRigType.R15).Parent = ReplicatedStorage
	createAnimateScript(Enum.HumanoidRigType.R6).Parent = ReplicatedStorage
end

Init()
