--!strict
--[[
	Runs Roblox's stock Animate LocalScript on client-owned characters (e.g. NPCs
	in workspace) without forking it. LocalScripts only run under PlayerScripts,
	PlayerGui, Backpack, or the local player's Character: so we briefly parent
	the model into a valid container, start Animate, then park the script under
	PlayerScripts permanently, while the model can live wherever and still be animated.
]]
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const AnimateBootstrapper = {}

-- Created lazily under PlayerScripts.
local animateContainer: Folder

const function _isInClientContainer(instance: Instance): boolean
	const Player = Players.LocalPlayer
	const character = Player.Character

	return instance:IsDescendantOf(Player.PlayerScripts)
		or instance:IsDescendantOf(Player.PlayerGui)
		or instance:IsDescendantOf(Player.Backpack)
		-- Player.Character in workspace counts as a valid LocalScript container.
		-- Arbitrary NPCs in workspace do NOT, they need the PlayerScripts hop below.
		or (character ~= nil and instance:IsDescendantOf(character))
end

const BOOTSTRAP_TIMEOUT_SECONDS = 3

-- Waits for stock Animate's first idle on this Animator (R6/R15 startup order).
-- Resumes on AnimationPlayed or errors after BOOTSTRAP_TIMEOUT_SECONDS.
const function _waitForAnimationExecution(animator: Animator)
	if #animator:GetPlayingAnimationTracks() > 0 then
		return
	end

	local thread = coroutine.running()
	local outcome: "played" | "timeout"? = nil

	local connection: RBXScriptConnection
	connection = animator.AnimationPlayed:Connect(function()
		if outcome ~= nil then
			return
		end
		outcome = "played"
		connection:Disconnect()
		task.spawn(thread)
	end)

	task.delay(BOOTSTRAP_TIMEOUT_SECONDS, function()
		if outcome ~= nil then
			return
		end
		outcome = "timeout"
		connection:Disconnect()
		task.spawn(thread)
	end)

	coroutine.yield() -- suspended until one of the above resumes us

	if outcome == "timeout" then
		error(
			`Animate did not start within {BOOTSTRAP_TIMEOUT_SECONDS} second(s). `
				.. "Is the Animate script server-replicated?"
		)
	end
end

const function _getOrCreateAnimateContainer(): Folder
	if animateContainer then
		return animateContainer
	end

	animateContainer = Instance.new("Folder")
	animateContainer.Name = "_ANIMATEBOOTSTRAPPER_ANIMATE_SCRIPTS"
	animateContainer.Parent = Players.LocalPlayer.PlayerScripts
	return animateContainer
end

--[[
    Bootstraps the Animate script onto a target character.
    
    WARNING: Any additional LocalScripts that are a descendant of the character will also execute.
    It is recommended to bootstrap the character before rendering it visually. Otherwise, the 
    character may visibly flash or disappear while bootstrapping the Animate script.
    @yields
    @param characterToAnimate The character model to animate.
    @param serverReplicatedAnimate The server-replicated Animate script to clone. Must be server-replicated; package does not verify.
    @param replacementAnimateChildren An optional table of instances to replace the children of the Animate script with. ClearAllChildren() replaces all children.
    @return Returned for advanced use; destroyed automatically when the character is destroyed unless already removed.
    @error Throws if Humanoid/Animator missing, or Animate does not start within BOOTSTRAP_TIMEOUT_SECONDS.
]]
function AnimateBootstrapper.BootstrapAnimate(
	characterToAnimate: Model,
	serverReplicatedAnimate: LocalScript,
	replacementAnimateChildren: { Instance }?
): LocalScript
	if RunService:IsServer() then
		error("AnimateBootstrapper cannot be used on the server!")
	end

	const humanoid = characterToAnimate:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "Character must have a Humanoid in order to use AnimateBootstrapper!")
	const animator = humanoid:FindFirstChildOfClass("Animator")
	assert(animator, "Humanoid must have an Animator in order to use AnimateBootstrapper!")

	const animate = serverReplicatedAnimate:Clone()
	-- Garbage collect the Animate script when the character is destroyed.
	characterToAnimate.Destroying:Once(function()
		animate:Destroy()
	end)

	if replacementAnimateChildren then
		animate:ClearAllChildren()
		for _, child in replacementAnimateChildren do
			child.Parent = animate
		end
	end

	-- Animate R6 & R15 locate their character via script.Parent.
	-- LocalScripts only execute in specific client containers.
	const originalParent = characterToAnimate.Parent
	if not _isInClientContainer(characterToAnimate) then
		characterToAnimate.Parent = Players.LocalPlayer.PlayerScripts
	end

    const ok, err = pcall(function()
		-- Move the Animate script to the character to initialize execution.
		animate.Parent = characterToAnimate
		_waitForAnimationExecution(animator)

		-- Park the script under PlayerScripts so it keeps running when the model is in
		-- workspace (LocalScripts on workspace NPCs do not run). Stock Animate reads
		-- script.Parent once at startup and keeps Humanoid/Animator in locals, so this
		-- reparent is safe after idle has started.
		animate.Parent = _getOrCreateAnimateContainer()
	end)

	characterToAnimate.Parent = originalParent

    if not ok then
        animate:Destroy()
        error(err)
    end

	return animate
end

table.freeze(AnimateBootstrapper)

return AnimateBootstrapper
