local PhysicsService = game:GetService("PhysicsService")

local CollisionGroups = {
	Ragdoll = "ZM_Ragdoll",
	VentBlocker = "ZM_VentBlocker",
}

local function register(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

function CollisionGroups.Setup()
	register(CollisionGroups.Ragdoll)
	register(CollisionGroups.VentBlocker)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Ragdoll, CollisionGroups.Ragdoll, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Ragdoll, CollisionGroups.VentBlocker, false)
end

return CollisionGroups
