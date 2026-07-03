--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const VerifyReplication = ReplicatedStorage.VerifyReplication

VerifyReplication.OnServerInvoke = function(_player: Player, targetInstance: Instance?): boolean
    -- When a client passes an instance to the server via a remote network boundary, the server will receive nil if the instance was created by the client.
    -- If the instance was created by the server and replicated, the server will successfully resolve the reference.
	return targetInstance ~= nil
end

-- Empty HumanoidDescription is intentional; only the bundled Animate LocalScript is used.
-- The dummy model is discarded after extracting the script.
const function createAnimateScript(rigType: Enum.HumanoidRigType): LocalScript
	const npc = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), rigType)
	const animateScript = npc:FindFirstChildOfClass("LocalScript") :: LocalScript

	animateScript.Name = `BaseAnimate{rigType.Name}`

	return animateScript
end

const function Init()
    -- Create the Animate scripts for each rig type and parent them to ReplicatedStorage.
    -- This extraction method also garbage collects the dummy model after extracting the script.
	createAnimateScript(Enum.HumanoidRigType.R15).Parent = ReplicatedStorage
	createAnimateScript(Enum.HumanoidRigType.R6).Parent = ReplicatedStorage
end

Init()
