--!strict
const Players = game:GetService("Players")

const Player = Players.LocalPlayer

const AnimateBootstrapper = {}

--[[
    The container that Animate scripts are moved to permanently when they are bootstrapped.
    This is to ensure that the Animate scripts continue to execute even if the character is in workspace.
]]
AnimateBootstrapper._animateContainer = Instance.new("Folder")
AnimateBootstrapper._animateContainer.Name = "_BOOTSTRAPPED_ANIMATE_SCRIPTS"
AnimateBootstrapper._animateContainer.Parent = Player.PlayerScripts

const function _isInClientContainer(instance: Instance): boolean
	const character = Player.Character

	return instance:IsDescendantOf(Player.PlayerScripts)
		or instance:IsDescendantOf(Player.PlayerGui)
		or instance:IsDescendantOf(Player.Backpack)
		or (character ~= nil and instance:IsDescendantOf(character))
end

--[[
R6 and R15 Animate scripts automatically execute `playAnimation("idle", 0.1, Humanoid)` immediately before entering their primary loop. This function listens to the Animator for that initial animation track to verify execution.
    ]]
const function _waitForAnimationExecution(animator: Animator)
	if #animator:GetPlayingAnimationTracks() > 0 then
		return
	end

	animator.AnimationPlayed:Wait()
end

--[[
    Bootstraps the Animate script onto a target character.
    
    WARNING: Any additional LocalScripts that are a descendant of the character will also execute.
    It is recommended to bootstrap the character before rendering it visually. Otherwise, the 
    character may visibly flash or disappear while bootstrapping the Animate script.
    @yields 
    @param characterToAnimate The character model to animate.
    @param serverReplicatedAnimate The server-replicated Animate script to clone.
    @param replacementAnimateChildren An optional table of instances to replace the children of the Animate script with.
    @return The bootstrapped Animate script. This needs to be manually garbage collected.
    @error Throws an error if the character is missing a Humanoid or Animator.
]]
function AnimateBootstrapper.BootstrapAnimate(
	characterToAnimate: Model,
	serverReplicatedAnimate: LocalScript,
	replacementAnimateChildren: { Instance }?
): LocalScript
	const animate = serverReplicatedAnimate:Clone()
	const humanoid = characterToAnimate:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "Character must have a Humanoid in order to use AnimateBootstrapper!")
	const animator = humanoid:FindFirstChildOfClass("Animator")
	assert(animator, "Humanoid must have an Animator in order to use AnimateBootstrapper!")

	if replacementAnimateChildren then
		animate:ClearAllChildren()
		for _, child in replacementAnimateChildren do
			child.Parent = animate
		end
	end

	-- Animate R6 & R15 locate their character via script.Parent.
	-- LocalScripts only execute in specific client containers.
	if not _isInClientContainer(characterToAnimate) then
		characterToAnimate.Parent = Player.PlayerScripts
	end

	-- Move the Animate script to the character to initialize execution.
	animate.Parent = characterToAnimate
	_waitForAnimationExecution(animator)

	-- Move to AnimateContainer Permanently, otherwise if the character leaves client container with the script in it, the script will halt execution.
	animate.Parent = AnimateBootstrapper._animateContainer

	return animate
end

table.freeze(AnimateBootstrapper)

return AnimateBootstrapper
