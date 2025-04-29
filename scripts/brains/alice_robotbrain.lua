<<<<<<< HEAD
require "behaviours/follow"
require "behaviours/wander"
require("behaviours/chaseandattack")
require "behaviours/faceentity"
local BrainCommon = require("brains/braincommon")

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6

local MAX_WANDER_DIST = 3

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local RobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self._isincombat = false
    self.target = nil
end)

local function GetLeader(inst)
    local leader = inst.components.follower and inst.components.follower.leader or
        inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()

    return leader
end

function RobotBrain:OnStart()
    local root =
    PriorityNode({
		BrainCommon.PanicTrigger(self.inst),

        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),

    }, .25)
    self.bt = BT(self.inst, root)
end

=======
require "behaviours/follow"
require "behaviours/wander"
require("behaviours/chaseandattack")
require "behaviours/faceentity"
local BrainCommon = require("brains/braincommon")

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6

local MAX_WANDER_DIST = 3

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local RobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self._isincombat = false
    self.target = nil
end)

local function GetLeader(inst)
    local leader = inst.components.follower and inst.components.follower.leader or
        inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()

    return leader
end

function RobotBrain:OnStart()
    local root =
    PriorityNode({
		BrainCommon.PanicTrigger(self.inst),

        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),

    }, .25)
    self.bt = BT(self.inst, root)
end

>>>>>>> 23121469d84d981b602c8a05fcc5a165255f6831
return RobotBrain