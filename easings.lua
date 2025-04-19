-- Easing functions in Lua  
local easings = {
    -- 线性
    {
        name = "Linear",
        func = function(t) return t end
    },
    
    -- 二次方
    {
        name = "EaseInQuad",
        func = function(t) return t * t end
    },
    {
        name = "EaseOutQuad",
        func = function(t) return t * (2 - t) end
    },
    {
        name = "EaseInOutQuad",
        func = function(t)
            return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
        end
    },
    
    -- 三次方
    {
        name = "EaseInCubic",
        func = function(t) return t * t * t end
    },
    {
        name = "EaseOutCubic",
        func = function(t)
            t = t - 1
            return t * t * t + 1
        end
    },
    {
        name = "EaseInOutCubic",
        func = function(t)
            return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
        end
    },
    
    -- 四次方
    {
        name = "EaseInQuart",
        func = function(t) return t * t * t * t end
    },
    {
        name = "EaseOutQuart",
        func = function(t)
            t = t - 1
            return 1 - t * t * t * t
        end
    },
    {
        name = "EaseInOutQuart",
        func = function(t)
            return t < 0.5 and 8 * t * t * t * t or 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1)
        end
    },
    
    -- 五次方
    {
        name = "EaseInQuint",
        func = function(t) return t * t * t * t * t end
    },
    {
        name = "EaseOutQuint",
        func = function(t)
            t = t - 1
            return 1 + t * t * t * t * t
        end
    },
    {
        name = "EaseInOutQuint",
        func = function(t)
            return t < 0.5 and 16 * t * t * t * t * t or 1 + 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1)
        end
    },
    
    -- 正弦
    {
        name = "EaseInSine",
        func = function(t) return 1 - math.cos(t * math.pi / 2) end
    },
    {
        name = "EaseOutSine",
        func = function(t) return math.sin(t * math.pi / 2) end
    },
    {
        name = "EaseInOutSine",
        func = function(t) return -(math.cos(math.pi * t) - 1) / 2 end
    },
    
    -- 指数
    {
        name = "EaseInExpo",
        func = function(t) return t == 0 and 0 or 2 ^ (10 * (t - 1)) end
    },
    {
        name = "EaseOutExpo",
        func = function(t) return t == 1 and 1 or 1 - 2 ^ (-10 * t) end
    },
    {
        name = "EaseInOutExpo",
        func = function(t)
            if t == 0 then return 0 end
            if t == 1 then return 1 end
            return t < 0.5 and 2 ^ (20 * t - 10) / 2 or (2 - 2 ^ (-20 * t + 10)) / 2
        end
    },
    
    -- 圆形
    {
        name = "EaseInCirc",
        func = function(t) return 1 - math.sqrt(1 - t * t) end
    },
    {
        name = "EaseOutCirc",
        func = function(t)
            t = t - 1
            return math.sqrt(1 - t * t)
        end
    },
    {
        name = "EaseInOutCirc",
        func = function(t)
            return t < 0.5 
                and (1 - math.sqrt(1 - 4 * t * t)) / 2 
                or (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
        end
    },
    
    -- 弹性
    {
        name = "EaseInElastic",
        func = function(t)
            if t == 0 then return 0 end
            if t == 1 then return 1 end
            return -2 ^ (10 * t - 10) * math.sin((t * 10 - 10.75) * (2 * math.pi) / 3)
        end
    },
    {
        name = "EaseOutElastic",
        func = function(t)
            if t == 0 then return 0 end
            if t == 1 then return 1 end
            return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
        end
    },
    {
        name = "EaseInOutElastic",
        func = function(t)
            if t == 0 then return 0 end
            if t == 1 then return 1 end
            return t < 0.5 
                and -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 
                or (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 + 1
        end
    },
    
    -- 回弹
    {
        name = "EaseInBounce",
        func = function(t) 
            t = 1 - t
            if t == 0 then return 0 end
            if t == 1 then return 1 end
            return t < 0.5 
                and -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 
                or (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 + 1
        end
    },
    {
        name = "EaseOutBounce",
        func = function(t)
            if t < 1 / 2.75 then
                return 7.5625 * t * t
            elseif t < 2 / 2.75 then
                t = t - 1.5 / 2.75
                return 7.5625 * t * t + 0.75
            elseif t < 2.5 / 2.75 then
                t = t - 2.25 / 2.75
                return 7.5625 * t * t + 0.9375
            else
                t = t - 2.625 / 2.75
                return 7.5625 * t * t + 0.984375
            end
        end
    },
    {
        name = "EaseInOutBounce",
        func = function(t)
            local function func(t)
                if t < 1 / 2.75 then
                    return 7.5625 * t * t
                elseif t < 2 / 2.75 then
                    t = t - 1.5 / 2.75
                    return 7.5625 * t * t + 0.75
                elseif t < 2.5 / 2.75 then
                    t = t - 2.25 / 2.75
                    return 7.5625 * t * t + 0.9375
                else
                    t = t - 2.625 / 2.75
                    return 7.5625 * t * t + 0.984375
                end
            end
            
            if t < 0.5 then 
                return  (1 - func(1 - 2 * t)) / 2 
            end

            return (1 + func(2 * t - 1)) / 2
        end
    }
}

return easings