--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const AnimateBootstrapper = require(ReplicatedStorage:WaitForChild("AnimateBootstrapper"))

const VerifyReplication = ReplicatedStorage:WaitForChild("VerifyReplication")

const function isServerReplicated(targetInstance: Instance): boolean
	return VerifyReplication:InvokeServer(targetInstance)
end

const function loopMoveRandomly(npc: Model)
	const humanoid = npc:FindFirstChildOfClass("Humanoid") :: Humanoid
	const primaryPart = npc.PrimaryPart :: BasePart

	while npc.Parent do
		const randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
		const targetPosition = primaryPart.Position + randomOffset
		humanoid:MoveTo(targetPosition)
		humanoid.MoveToFinished:Wait()
	end
end

const function animateNPC(npc: Model, animateScript: LocalScript, replacementAnimateChildren: { Instance }?)
	if not isServerReplicated(animateScript) then
		error(
			[[Animate script must be server replicated! Otherwise, animations won't play in the live game. See: https://devforum.roblox.com/t/studio-vs-live-server-discrepancy-failure-with-animate-script-generated-by-createhumanoidmodelfromdescriptionasync/4685167]]
		)
	end

	return AnimateBootstrapper.BootstrapAnimate(npc, animateScript, replacementAnimateChildren)
end

const function createSelfNPC(): (Model, LocalScript, Enum.HumanoidRigType)
	const player = Players.LocalPlayer
	const character = player.Character or player.CharacterAdded:Wait()
	const humanoid = character:WaitForChild("Humanoid") :: Humanoid
	const rigType = humanoid.RigType
	const description = humanoid:GetAppliedDescription()
	const model = Players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
	model.Name = `{player.DisplayName} NPC`
	model:PivotTo(CFrame.new(0, 100, 0))

	return model, model:FindFirstChildOfClass("LocalScript") :: LocalScript, rigType
end

const function initSelfNPC()
	const npc, selfAnimateScript, rigType = createSelfNPC()
	local baseAnimateScript = ReplicatedStorage:WaitForChild(`BaseAnimate{rigType.Name}`) :: LocalScript

	-- Remove the client-created Animate script, otherwise it will error in the live game and run in studio.
	selfAnimateScript.Parent = nil

	-- Animate script children are character animations, so we replace the base animations with our own.
	animateNPC(npc, baseAnimateScript, selfAnimateScript:GetChildren())

	npc.Parent = workspace
	task.spawn(loopMoveRandomly, npc)
	return npc
end

const function loopResetSelfNPC(lifespan: number)
	while true do
		const npc = initSelfNPC()
		task.wait(lifespan)
		print(`Resetting NPC after {lifespan} seconds`)
		npc:Destroy()
	end
end

const function Init()
	task.spawn(loopResetSelfNPC, 60)
end

Init()
