local GIFTS_PER_USE = TUNING.ALICE_GIFT_COUNT -- 从 tuning.lua 中获取礼物数量
--test
--new function 
--if an item is equipment and weight == 1, it will be remove after selected.
local GIFT_ITEMS = {
    materials = {
    --[[ 材料类 ]]--
        {prefab = "cutgrass", count = {min = 20, max = 40}, weight = 10}, -- 割下的草
        {prefab = "twigs", count = {min = 20, max = 40}, weight = 10}, -- 树枝
        {prefab = "log", count = {min = 10, max = 20}, weight = 10}, -- 木头
        {prefab = "charcoal", count = {min = 20, max = 40}, weight = 10}, -- 木炭
        {prefab = "cutreeds", count = {min = 20, max = 40}, weight = 10}, -- 采集的芦苇
        {prefab = "livinglog", count = {min = 10, max = 20}, weight = 5}, -- 活木头
        {prefab = "lightbulb", count = {min = 20, max = 40}, weight = 10}, -- 荧光果
        {prefab = "flint", count = {min = 20, max = 40}, weight = 10}, -- 燧石
        {prefab = "nitre", count = {min = 20, max = 40}, weight = 10}, -- 硝石
        {prefab = "rocks", count = {min = 20, max = 40}, weight = 10}, -- 石头
        {prefab = "marble", count = {min = 20, max = 40}, weight = 10}, -- 大理石
        {prefab = "moonrocknugget", count = {min = 20, max = 40}, weight = 10}, -- 月岩
        {prefab = "moonglass", count = {min = 20, max = 40}, weight = 10}, -- 月亮碎片
        {prefab = "goldnugget", count = {min = 10, max = 20}, weight = 10}, -- 黄金
        {prefab = "papyrus", count = {min = 20, max = 40}, weight = 5}, -- 莎草纸
        {prefab = "transistor", count = {min = 5, max = 10}, weight = 10}, -- 电子元件
        {prefab = "gears", count = {min = 20, max = 40}, weight = 5}, -- 齿轮
        {prefab = "wagpunk_bits", count = {min = 20, max = 40}, weight = 5}, -- 废料
        {prefab = "trinket_6", count = {min = 20, max = 40}, weight = 5}, -- 烂电线
        {prefab = "houndstooth", count = {min = 20, max = 40}, weight = 10}, -- 狗牙
        {prefab = "silk", count = {min = 20, max = 40}, weight = 10}, -- 蜘蛛丝
        {prefab = "beardhair", count = {min = 20, max = 40}, weight = 5}, -- 胡须
        {prefab = "beefalowool", count = {min = 20, max = 40}, weight = 10}, -- 牛毛
        {prefab = "poop", count = {min = 10, max = 20}, weight = 10}, -- 便便
        {prefab = "stinger", count = {min = 20, max = 40}, weight = 10}, -- 蜂刺
        {prefab = "pigskin", count = {min = 20, max = 40}, weight = 5}, -- 猪皮
        {prefab = "manrabbit_tail", count = {min = 20, max = 40}, weight = 5}, -- 兔绒
        {prefab = "coontail", count = {min = 10, max = 20}, weight = 10}, -- 猫尾
        {prefab = "rottenegg", count = {min = 20, max = 40}, weight = 10}, -- 腐烂鸟蛋
        {prefab = "guano", count = {min = 10, max = 20}, weight = 10}, -- 鸟粪
        {prefab = "tentaclespots", count = {min = 20, max = 40}, weight = 5}, -- 触手皮
        {prefab = "slurtle_shellpieces", count = {min = 20, max = 40}, weight = 10}, -- 外壳碎片
        {prefab = "mosquitosack", count = {min = 10, max = 20}, weight = 10}, -- 蚊子血囊
        {prefab = "slurper_pelt", count = {min = 20, max = 40}, weight = 10}, -- 啜食者皮
        {prefab = "goose_feather", count = {min = 10, max = 20}, weight = 10}, -- 麋鹿鹅羽毛
        {prefab = "dragon_scales", count = {min = 5, max = 10}, weight = 2}, -- 鳞片
        {prefab = "bearger_fur", count = {min = 5, max = 10}, weight = 2}, -- 熊皮
        {prefab = "shroom_skin", count = {min = 5, max = 10}, weight = 2}, -- 蘑菇皮
        {prefab = "glommerfuel", count = {min = 10, max = 20}, weight = 10}, -- 格罗姆的黏液
        {prefab = "boneshard", count = {min = 10, max = 20}, weight = 10}, -- 骨头碎片
        {prefab = "saltrock", count = {min = 20, max = 40}, weight = 10}, -- 盐晶
        {prefab = "cookiecuttershell", count = {min = 10, max = 20}, weight = 10}, -- 饼干切割机壳
        {prefab = "fireflies", count = {min = 20, max = 40}, weight = 5}, -- 萤火虫
        {prefab = "steelwool", count = {min = 20, max = 40}, weight = 5}, -- 钢丝棉
        {prefab = "purebrilliance", count = {min = 20, max = 40}, weight = 5}, -- 纯粹辉煌
        {prefab = "horrorfuel", count = {min = 20, max = 40}, weight = 5}, -- 纯粹恐惧
        {prefab = "voidcloth", count = {min = 10, max = 20}, weight = 5}, -- 暗影碎布
        {prefab = "dreadstone", count = {min = 20, max = 40}, weight = 5}, -- 绝望石
        {prefab = "wormlight", count = {min = 5, max = 10}, weight = 5}, -- 发光浆果
        {prefab = "lunarplant_husk", count = {min = 10, max = 20}, weight = 5}, -- 亮茄外壳
        {prefab = "walrus_tusk", count = {min = 5, max = 10}, weight = 5}, -- 海象牙
        {prefab = "lightninggoathorn", count = {min = 5, max = 10}, weight = 10}, -- 伏特羊角

        --[[ 魔法分类 ]]--
        {prefab = "thulecite", count = {min = 10, max = 20}, weight = 10}, -- 铥矿
        {prefab = "redgem", count = {min = 20, max = 40}, weight = 10}, -- 红宝石
        {prefab = "bluegem", count = {min = 20, max = 40}, weight = 10}, -- 蓝宝石
        {prefab = "purplegem", count = {min = 20, max = 40}, weight = 10}, -- 紫宝石
        {prefab = "greengem", count = {min = 20, max = 40}, weight = 1}, -- 绿宝石
        {prefab = "orangegem", count = {min = 20, max = 40}, weight = 2}, -- 橙宝石
        {prefab = "yellowgem", count = {min = 20, max = 40}, weight = 2}, -- 黄宝石
        {prefab = "opalpreciousgem", count = {min = 20, max = 40}, weight = 1}, -- 彩虹宝石
        {prefab = "nightmarefuel", count = {min = 20, max = 40}, weight = 10}, -- 噩梦燃料
        {prefab = "lunarplant_kit", count = {min = 5, max = 10}, weight = 5}, -- 亮茄修补套件
        {prefab = "voidcloth_kit", count = {min = 5, max = 10}, weight = 5}, -- 虚空修补套件
        {prefab = "alterguardianhatshard", count = {min = 1, max = 1}, weight = 5}, -- 启迪碎片
        {prefab = "eyeturret_item", count = {min = 1, max = 1}, weight = 5}, -- 眼睛炮塔
        {prefab = "shadowheart", count = {min = 1, max = 1}, weight = 10}, -- 暗影心房
    },

    equipments = {
        --[[ 装备 ]]--
        {prefab = "multitool_axe_pickaxe", count = {min = 1, max = 1}, weight = 10}, -- 多用斧稿
        {prefab = "featherfan", count = {min = 1, max = 1}, weight = 1}, -- 羽毛扇
        {prefab = "brush", count = {min = 1, max = 1}, weight = 1}, -- 刷子
        {prefab = "icepack", count = {min = 1, max = 1}, weight = 1}, -- 保鲜背包
        {prefab = "krampus_sack", count = {min = 1, max = 1}, weight = 1}, -- 坎普斯背包
        {prefab = "hambat", count = {min = 1, max = 1}, weight = 10}, -- 火腿棒
        {prefab = "nightsword", count = {min = 1, max = 1}, weight = 10}, -- 暗夜剑
        {prefab = "ruins_bat", count = {min = 1, max = 1}, weight = 5}, -- 铥矿棒
        {prefab = "orangestaff", count = {min = 1, max = 1}, weight = 1}, -- 懒人魔杖
        {prefab = "yellowstaff", count = {min = 1, max = 1}, weight = 5}, -- 唤星者魔杖
        {prefab = "greenstaff", count = {min = 1, max = 1}, weight = 5}, -- 分解法杖
        {prefab = "opalstaff", count = {min = 1, max = 1}, weight = 1}, -- 唤月者魔杖
        {prefab = "panflute", count = {min = 1, max = 1}, weight = 1}, -- 排箫
        {prefab = "waterballoon", count = {min = 10, max = 20}, weight = 10}, -- 水球
        {prefab = "ruinshat", count = {min = 1, max = 1}, weight = 10}, -- 铥矿皇冠
        {prefab = "armordreadstone", count = {min = 1, max = 1}, weight = 1}, -- 绝望石盔甲
        {prefab = "dreadstonehat", count = {min = 1, max = 1}, weight = 1}, -- 绝望石头盔
        {prefab = "armorskeleton", count = {min = 1, max = 1}, weight = 1}, -- 骨头盔甲
        {prefab = "skeletonhat", count = {min = 1, max = 1}, weight = 1}, -- 骨头头盔
        {prefab = "alterguardianhat", count = {min = 1, max = 1}, weight = 1}, -- 启迪之冠
        {prefab = "security_pulse_cage", count = {min = 1, max = 1}, weight = 1}, -- 火花柜
        {prefab = "security_pulse_cage_full", count = {min = 1, max = 1}, weight = 1}, -- 充能火花柜
        {prefab = "voidcloth_boomerang", count = {min = 1, max = 1}, weight = 1}, -- 阴郁回旋镖
        {prefab = "voidcloth_scythe", count = {min = 1, max = 1}, weight = 1}, -- 暗影收割者
        {prefab = "beargerfur_sack", count = {min = 1, max = 1}, weight = 1}, -- 极地熊獾桶
        {prefab = "staff_tornado", count = {min = 1, max = 1}, weight = 5}, -- 天气风向标
        {prefab = "yellowamulet", count = {min = 1, max = 1}, weight = 1}, -- 魔光护符
        {prefab = "greenamulet", count = {min = 1, max = 1}, weight = 1}, -- 建造护符
        {prefab = "voidcloth_umbrella", count = {min = 1, max = 1}, weight = 1}, -- 暗影伞
        {prefab = "sword_lunarplant", count = {min = 1, max = 1}, weight = 1}, -- 亮茄剑
        {prefab = "pickaxe_lunarplant", count = {min = 1, max = 1}, weight = 1}, -- 亮茄粉碎者
        {prefab = "staff_lunarplant", count = {min = 1, max = 1}, weight = 1}, -- 亮茄魔杖
        {prefab = "bomb_lunarplant", count = {min = 10, max = 20}, weight = 5}, -- 亮茄炸弹
        {prefab = "shovel_lunarplant", count = {min = 1, max = 1}, weight = 1}, -- 亮茄锄铲
        {prefab = "giftwrap", count = {min = 10, max = 20}, weight = 10}, -- 礼物包装
    },

    foods = {
        --[[ 食材 ]]--
        {prefab = "ice", count = {min = 20, max = 40}, weight = 10}, -- 冰
        {prefab = "pumpkin", count = {min = 10, max = 20}, weight = 10}, -- 南瓜
        {prefab = "eggplant", count = {min = 10, max = 20}, weight = 10}, -- 茄子
        {prefab = "cactus_flower", count = {min = 20, max = 40}, weight = 5}, -- 仙人掌花
        {prefab = "dragonfruit", count = {min = 20, max = 40}, weight = 5}, -- 火龙果
        {prefab = "cave_banana", count = {min = 20, max = 40}, weight = 5}, -- 香蕉
        {prefab = "meat_dried", count = {min = 10, max = 20}, weight = 10}, -- 肉干
        {prefab = "butter", count = {min = 20, max = 40}, weight = 5}, -- 黄油
        {prefab = "honey", count = {min = 20, max = 40}, weight = 10}, -- 蜂蜜
        {prefab = "royal_jelly", count = {min = 20, max = 40}, weight = 5}, -- 蜂王浆
        {prefab = "mandrake", count = {min = 20, max = 40}, weight = 1}, -- 曼德拉草
        {prefab = "cookedmandrake", count = {min = 20, max = 40}, weight = 1}, -- 烤熟的曼德拉草
        {prefab = "pepper", count = {min = 20, max = 40}, weight = 5}, -- 辣椒
        {prefab = "deerclops_eyeball", count = {min = 5, max = 10}, weight = 2}, -- 独眼巨鹿眼球
        {prefab = "minotaurhorn", count = {min = 5, max = 10}, weight = 2}, -- 守护者之角

        --[[ 烹饪料理 ]]--
        {prefab = "honeyham", count = {min = 20, max = 40}, weight = 10}, -- 蜜汁火腿
        {prefab = "turkeydinner", count = {min = 20, max = 40}, weight = 10}, -- 火鸡正餐
        {prefab = "mandrakesoup", count = {min = 20, max = 40}, weight = 5}, -- 曼德拉草汤
        {prefab = "talleggs", count = {min = 20, max = 40}, weight = 5}, -- 苏格兰高鸟蛋
        {prefab = "waffles", count = {min = 20, max = 40}, weight = 10}, -- 华夫饼
        {prefab = "icecream", count = {min = 20, max = 40}, weight = 10}, -- 冰淇淋
        {prefab = "baconeggs", count = {min = 20, max = 40}, weight = 10}, -- 培根煎蛋
        {prefab = "freshfruitcrepes", count = {min = 20, max = 40}, weight = 5}, -- 鲜果可丽饼
        {prefab = "bonesoup", count = {min = 20, max = 40}, weight = 5}, -- 骨头汤
        {prefab = "moqueca", count = {min = 20, max = 40}, weight = 5}, -- 海鲜杂烩
        {prefab = "voltgoatjelly", count = {min = 20, max = 40}, weight = 10}, -- 伏特羊肉冻
        {prefab = "dragonchilisalad", count = {min = 20, max = 40}, weight = 5}, -- 辣龙椒沙拉
        {prefab = "gazpacho", count = {min = 20, max = 40}, weight = 5}, -- 芦笋冷汤
        {prefab = "frogfishbowl", count = {min = 20, max = 40}, weight = 5}, -- 蓝带鱼排
    }
}

local AliceGift = Class(function(self, inst)
    self.inst = inst
    self.cooldown_data = {
        last_world_day = -1,
        world_id = nil
    }
    
    -- 调用初始化方法
    self:Initialize()  -- 确保权重初始化

    -- 在服务器端注册事件监听
    if TheNet and TheNet:GetIsServer() then
        -- 确保在玩家激活时初始化
        self.inst:ListenForEvent("ms_playeractivated", function()
            self:InitializeWorldData()
        end)

        self.inst:ListenForEvent("alice_gift_trigger", function()
            if self:CheckCooldown() then
                self:GiveGifts()
                self:UpdateCooldown()
             else
                local current_day = self:GetCurrentWorldDay()
                local days_left = self.cooldown_data.last_day - current_day + 1
                if self.inst.components.talker then
                    self.inst.components.talker:Say(string.format(
                        "礼物冷却中！还需%d天", math.max(0, days_left)
                    ))
                end
            end
        end)
    end
end)

-- 初始化世界数据
function AliceGift:InitializeWorldData()
    if self.cooldown_data.world_id == nil then
        self.cooldown_data.world_id = self:GetWorldID()
        self.cooldown_data.last_day = self:GetCurrentWorldDay() - 1
        -- print("[AliceGift] 初始化世界数据: ", 
        --       self.cooldown_data.world_id, 
        --       self.cooldown_data.last_day)
    end
end

-- 获取当前世界的天数
function AliceGift:GetCurrentWorldDay()
    -- 优先使用cycles组件
    if TheWorld.components.cycles then
        return TheWorld.components.cycles:GetCycles()
    end
    
    -- 使用全局状态作为备用
    if TheWorld.state and TheWorld.state.cycles then
        return TheWorld.state.cycles
    end
    
    return 0
end

-- 获取世界唯一ID
function AliceGift:GetWorldID()
    -- 尝试多种方式获取唯一ID
    if TheWorld.meta and TheWorld.meta.session_identifier then
        return TheWorld.meta.session_identifier
    elseif TheWorld.ismastersim and TheWorld.shard then
        return tostring(TheWorld.shard:GetShardId())
    elseif TheWorld.GUID then
        return tostring(TheWorld.GUID)
    end
    
    return "default_world"
end

-- 在组件初始化时设置权重偏好
function AliceGift:Initialize()
    -- 默认权重比例（平衡型）
    self.category_weights = {
        materials = 35,
        equipments = 35,
        foods = 30
    }
    
    -- 读取偏好设置
    local preference = TUNING.GIFT_WEIGHT_PREFERENCE or "balanced"
    
    -- 根据偏好调整权重
    if preference == "materials" then
        self.category_weights = {materials = 50, equipments = 30, foods = 20}
    elseif preference == "equipments" then
        self.category_weights = {materials = 30, equipments = 50, foods = 20}
    elseif preference == "foods" then
        self.category_weights = {materials = 30, equipments = 30, foods = 40}
    end
    
    -- 确保权重总和为100（可选）
    local total = self.category_weights.materials + 
                 self.category_weights.equipments + 
                 self.category_weights.foods
    if total ~= 100 then
        -- 自动归一化
        self.category_weights.materials = math.floor(self.category_weights.materials * 100 / total)
        self.category_weights.equipments = math.floor(self.category_weights.equipments * 100 / total)
        self.category_weights.foods = 100 - self.category_weights.materials - self.category_weights.equipments
    end
end

-- 分类选择函数
function AliceGift:GetRandomCategory()
    local total_weight = self.category_weights.materials +
                         self.category_weights.equipments +
                         self.category_weights.foods
    
    local rand = math.random(total_weight)
    
    -- 材料类检查
    if rand <= self.category_weights.materials then
        return "materials"
    end
    
    -- 装备类检查
    if rand <= self.category_weights.materials + self.category_weights.equipments then
        return "equipments"
    end
    
    -- 否则返回食物类
    return "foods"
end

-- 权重随机函数（保持在组件内）
function AliceGift:GetRandomItem(category)
    local items = GIFT_ITEMS[category]
    if not items then return nil end

    -- 计算总权重
    local total_weight = 0
    for _, item in ipairs(items) do
        total_weight = total_weight + item.weight
    end
    -- print("[DEBUG:Alice Gift] Total weight calculated:", total_weight)

    -- 生成随机数
    local rand = math.random(total_weight)
    -- print("[DEBUG:Alice Gift] Random number generated:", rand)
    local accumulated = 0

    -- 轮盘赌算法
    for _, item in ipairs(items) do
        accumulated = accumulated + item.weight
        -- print("[DEBUG:Alice Gift] Accumulated weight:", accumulated, "Current item:", item.prefab)
        if rand <= accumulated then
            -- print("[DEBUG:Alice Gift] Selected item:", item.prefab)
            return item
        end
    end
    -- print("[DEBUG:Alice Gift] No item selected")
    -- 原有权重随机逻辑...
end

-- 冷却检查
function AliceGift:CheckCooldown()
    -- 确保世界数据已初始化
    self:InitializeWorldData()
    
    local current_world_id = self:GetWorldID()
    local current_day = self:GetCurrentWorldDay()
    
    -- 调试输出
    print(string.format(
        "[AliceGift] 冷却检查: 世界=%s, 当前天数=%d, 上次天数=%d, 上次世界=%s",
        current_world_id, current_day,
        self.cooldown_data.last_day,
        self.cooldown_data.world_id
    ))
    
    -- 如果是新世界，允许领取
    if self.cooldown_data.world_id ~= current_world_id then
        -- print("[AliceGift] 检测到新世界，允许领取")
        return true
    end
    
    -- 检查是否是新的一天
    return current_day > self.cooldown_data.last_day
end

-- 更新冷却状态
function AliceGift:UpdateCooldown()
    self.cooldown_data.last_day = self:GetCurrentWorldDay()
    self.cooldown_data.world_id = self:GetWorldID()
    
    print(string.format(
        "[AliceGift] 冷却更新: 世界=%s, 天数=%d",
        self.cooldown_data.world_id,
        self.cooldown_data.last_day
    ))
end

-- 保存/加载
function AliceGift:OnSave()
    return {
        cooldown_data = self.cooldown_data
    }
end

function AliceGift:OnLoad(data)
    if data and data.cooldown_data then
        self.cooldown_data = data.cooldown_data
        -- print("[AliceGift] 加载冷却数据: ", 
        --       self.cooldown_data.world_id, 
        --       self.cooldown_data.last_day)
    end

     -- 确保权重已初始化（存档加载后）
    if not self.category_weights then
        -- print("[AliceGift] 存档加载后重新初始化权重")
        self:Initialize()
    end
    
    -- 确保在加载后初始化世界数据
    TheWorld:DoTaskInTime(0, function()
        self:InitializeWorldData()
    end)
end


-- 物品发放（组件方法）
function AliceGift:GiveGifts()
    -- 确保玩家实体有效
    if not self.inst:IsValid() or self.inst.prefab ~= "alice" then 
        -- print("[AliceGift] 玩家不是Alice，跳过")
        return 
    end
    -- print("[AliceGift] 开始发放礼物")
    local gifts = {}
    local gift_count = GIFTS_PER_USE  -- 固定3个礼物
    for i = 1, gift_count do
        local category = self:GetRandomCategory()
        local item = self:GetRandomItem(category)
        
        if item then
            -- 生成物品
            local item_inst = SpawnPrefab(item.prefab)
            if item_inst and item_inst:IsValid() then
                -- 确定数量
                local count = math.random(item.count.min, item.count.max)
                if item_inst.components.stackable then
                    -- 适配堆叠上限
                    count = math.min(count, item_inst.components.stackable.maxsize)
                    item_inst.components.stackable:SetStackSize(count)
                else
                    count = 1
                end
                
                -- 尝试放入背包
                local success = false
                if self.inst.components.inventory then
                    success = self.inst.components.inventory:GiveItem(item_inst, nil, self.inst:GetPosition())
                end
                
                -- 记录结果
                table.insert(gifts, {
                    prefab = item.prefab,
                    name = STRINGS.NAMES[item.prefab:upper()] or item.prefab,
                    count = count,
                    dropped = not success
                })

                -- 背包满时安全掉落
                if not success then
                    self.inst:DropItem(item_inst)
                end

            else
                -- 生成失败时记录日志（可选）
                -- print("[DEBUG:Alice Gift] 无法生成物品:", item.prefab)
            end
        end
    end
    
    -- 显示获得提示
    if #gifts > 0 then
        local message = "获得了礼物："
        for _, gift in ipairs(gifts) do
            message = message..string.format("\n%s×%d%s", 
                gift.name, 
                gift.count,
                gift.dropped and " (掉落在地)" or ""
            )
        end
        
        if self.inst.components.talker then
            self.inst.components.talker:Say(message)
        end
        
        -- 固定简单公告
        if TheNet:GetIsServer() then
            TheNet:Announce(string.format("%s 开启了每日礼物！", self.inst.name))
        end
    end
end

return AliceGift