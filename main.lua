_VERSION = "2.0"

local nuklear = require 'nuklear'

def_bezier = loadstring([[return ]]..io.open( "bezier.txt","r"):read("*a"))()
font = love.graphics.getFont()

WINDOW_WIDTH = 500
WINDOW_HEIGHT = 500
CIRCLE_R = 5
DETECTION_RANGE = 20
FONTSIZEH = font:getHeight()

local func = {x=250-100,y=250-100,w=200,h=200,mirror_x = 250+100,mirror_w = -200}
local easings = {easings = require 'easings',canvas = {},index = 1}
local bezier = {trans = {0,0,1,1},canvas = {}}

local mouse = {x=0,y=0}
local now_select = {1,false}
local copy_time = -2
local nowtime = 0 

local ui

local strings_trans = {value = table.concat(bezier.trans,",")}
local now_type = {value = 1,item = {'bezier','easings'}}
function now_type:get()
    return self.item[self.value]
end

local slider = {x=0,y=0,w=100,h=WINDOW_HEIGHT}
local visualization = {x=400,y=0,w=100,h=WINDOW_HEIGHT}
function strings_trans:update()
    self.value = table.concat(bezier.trans,",")
end



function func:mirror()
    local x = self.x
    self.x = self.mirror_x
    self.mirror_x = x
    local w = self.w
    self.w = self.mirror_w
    self.mirror_w = w
end

function func:copy()
    local _type = now_type:get()
    if _type == 'bezier' then
        love.system.setClipboardText(table.concat(bezier.trans,","))
    elseif _type == 'easings' then
        love.system.setClipboardText(easings.easings[easings.index].name)
    end
    copy_time = nowtime
end

function intervals_intersect(a1, a2, b1, b2)
    -- 规范化区间，确保起点小于终点
    local a_start, a_end = math.min(a1, a2), math.max(a1, a2)
    local b_start, b_end = math.min(b1, b2), math.max(b1, b2)

    -- 检查两个区间是否有交集
    return a_end >= b_start and b_end >= a_start
end

local function time_to_x(controlPoints,t)  
    -- 计算阶乘的辅助函数  
local function factorial(num)  
    if num == 0 then  
        return 1  
    else  
        local f = 1  
        for i = 1, num do  
            f = f * i  
        end  
        return f  
    end  
end  
    local n = #controlPoints - 1  
    local result = {0, 0}  -- 假设控制点为2D坐标  

    for i = 0, n do  
        -- 贝塞尔基函数的计算  
        local binomialCoeff = factorial(n) / (factorial(i) * factorial(n - i))  
        local term = binomialCoeff * (t ^ i) * ((1 - t) ^ (n - i))  

        result[1] = result[1] + term * controlPoints[i + 1][1]  
        result[2] = result[2] + term * controlPoints[i + 1][2]  
    end  

    return result
end  

function getBezier(startTime, endTime, startValue, endValue,nowtime,bezierTable,accuracy)
    -- 计算时间点在时间范围内的百分比
    local timePercent = (nowtime - startTime) / (endTime - startTime)

    if #bezierTable % 2 ~= 0 then
        return false
    end

    local bezier_tab = {{0,0}}
    for i=1,#bezierTable,2 do
        bezier_tab[#bezier_tab + 1] = {bezierTable[i],bezierTable[i + 1]}
    end
    bezier_tab[#bezier_tab + 1] = {1,1}
    bezierTable = bezier_tab

    --二分求解 
    local accuracy = 0.0005
    --精度
    local left = 0
    local right = 1
    local mid = 0.5

    if timePercent == 1 or timePercent == 0 then
        return startValue + (endValue - startValue) * time_to_x(bezierTable,timePercent)[2]
    end

    while right - left > accuracy do --精度之外
        --算出x和时间百分比的距离
        mid = (left + right) / 2
        local mid_x = time_to_x(bezierTable,mid)[1]
        if mid_x < timePercent then -- 往右偏
            left = mid
        elseif mid_x > timePercent then --往左偏
            right = mid
        else-- 同
            break
        end
    end
    timePercent = mid
    -- 根据插值点计算数值
    return startValue + (endValue - startValue) * time_to_x(bezierTable,timePercent)[2]
end

function get_trans(...)
    local v = {...}
    local _type = now_type:get()
    if _type == 'bezier' then
        return getBezier(0, 1, 0, 1,v[1],bezier.trans)
    elseif _type =='easings'then
        return easings.easings[easings.index].func(v[1])
    end
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    ui = nuklear.newUI()
    local CANVAS_FUNCTION = {WIN_W = 100,WIN_H = 100,X = 25,Y = 25,W = 50,H = 50}

    --绘制每一个曲线图像 方便集成nuklear

    --easings
    for i = 1,#easings.easings do
        table.insert(easings.canvas,love.graphics.newCanvas(CANVAS_FUNCTION.WIN_W, CANVAS_FUNCTION.WIN_H))
        love.graphics.setCanvas(easings.canvas[#easings.canvas])

        --easings曲线
        love.graphics.setColor(0.3,1,1,1)
        love.graphics.setLineWidth(3)
        local accuracy = 250
        local points = {}
        for time = 0,accuracy do
            local y = easings.easings[i].func(time/accuracy)
            table.insert(points,time / accuracy * CANVAS_FUNCTION.W + CANVAS_FUNCTION.X)
            table.insert(points,CANVAS_FUNCTION.Y+CANVAS_FUNCTION.H-CANVAS_FUNCTION.H* y)
        end
        love.graphics.line(points)

        --x y轴
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(5)
        love.graphics.line(CANVAS_FUNCTION.X,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H,CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H)
        love.graphics.line(CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y,CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H)

        love.graphics.setCanvas()

    end
    --bezier
    for i = 1,#def_bezier do
        
        table.insert(bezier.canvas,love.graphics.newCanvas(CANVAS_FUNCTION.WIN_W, CANVAS_FUNCTION.WIN_H))
        love.graphics.setCanvas(bezier.canvas[#bezier.canvas])

        --bezier曲线
        love.graphics.setColor(0.3,1,1,1)
        love.graphics.setLineWidth(3)
        local accuracy = 250
        local points = {}
        for time = 0,accuracy do
            local y = getBezier(0,accuracy,0,1,time,def_bezier[i])
            table.insert(points,time / accuracy * CANVAS_FUNCTION.W + CANVAS_FUNCTION.X)
            table.insert(points,CANVAS_FUNCTION.Y+CANVAS_FUNCTION.H-CANVAS_FUNCTION.H* y)
        end
        love.graphics.line(points)

        --x y轴
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(5)
        love.graphics.line(CANVAS_FUNCTION.X,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H,CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H)
        love.graphics.line(CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y,CANVAS_FUNCTION.X + CANVAS_FUNCTION.W,CANVAS_FUNCTION.Y + CANVAS_FUNCTION.H)

        love.graphics.setCanvas()
        
    end
end

function love.draw()
    --bg
    love.graphics.setColor(0.3,0.3,0.3,1)
    love.graphics.rectangle("fill",0,0,WINDOW_WIDTH,WINDOW_HEIGHT)

    ui:draw()

    --bezier曲线
    love.graphics.setColor(0.3,1,1,1)
    love.graphics.setLineWidth(3)
    local accuracy = 500
    local points = {}
    for time = 0,accuracy do
        local y = get_trans(time/accuracy)

        table.insert(points,time / accuracy * func.w + func.x)
        table.insert(points,func.y+func.h-func.h* y)
    end
    love.graphics.line(points)


    if now_type:get() == 'bezier' then 

        --控制点
        love.graphics.setColor(0,1,1,1)
        love.graphics.setLineWidth(1)
        for i=1,#bezier.trans,2 do
            love.graphics.circle("line",func.x+func.w*bezier.trans[i],func.y+func.h-func.h*bezier.trans[i+1],CIRCLE_R)
        end

        --控制点连线
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.setLineWidth(2)
        local line_table = {func.x,func.y+func.h}
        for i=1,#bezier.trans,2 do
            table.insert(line_table,func.x+func.w*bezier.trans[i])
            table.insert(line_table,func.y+func.h-func.h*bezier.trans[i+1])
        end

        table.insert(line_table,func.x+func.w)
        table.insert(line_table,func.y)

        love.graphics.line(line_table)

        love.graphics.setColor(1,1,1,1)

        --trans
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(table.concat(bezier.trans,","),func.x,func.y + func.h,func.w,"center")
    
    end

    --x y轴
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(5)
    love.graphics.line(func.x,func.y+func.h,func.x+func.w,func.y+func.h)
    love.graphics.line(func.x+func.w,func.y,func.x+func.w,func.y+func.h)


    

    --copy提示
    if copy_time + 1 >= nowtime then
        love.graphics.setColor(1,1,1,1 - (nowtime-copy_time))
        love.graphics.printf("copy success!",0,WINDOW_HEIGHT - FONTSIZEH,WINDOW_WIDTH,'center')
    end

end

function love.update(dt)


    nowtime = nowtime + dt
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    ui:frameBegin()
    local HEIGHT = 30
        if ui:windowBegin(now_type:get(), slider.x, slider.y, slider.w, slider.h,
            'border', 'title') then
            
            ui:layoutRow('dynamic', HEIGHT, 1)

            ui:label("Type")
            changed = ui:combobox(now_type,now_type.item)

            ui:label("Copy: Ctrl + c")
            if ui:button("Copy") then func:copy() end

            ui:label("Mirror: m")
            if ui:button("Mirror") then func:mirror() end
            
            if now_type:get() == 'bezier' then
                -- trans
                ui:label("trans:")
                local _, changed = ui:edit('box', strings_trans)
                if changed then
                    local trans = {}
                    -- 第一步：将非数字和非.的字符替换为空格
                    local cleaned = strings_trans.value:gsub("[^0-9.]", " ")
        
                    -- 第二步：提取所有由数字和.组成的连续字符
                    local result = {}
                    for item in cleaned:gmatch("%S+") do
                        -- 确保提取的内容是有效的数字格式（如避免单独的.或多个.的情况）
                        if item:match("^[0-9]*%.?[0-9]+$") or item:match("^[0-9]+%.?[0-9]*$") then
                            table.insert(trans, item)
                        end
                    end
                    --特殊处理 
                    if math.floor(#trans / 2) == 0 then
                        trans = {1,1}
                    end
                    bezier.trans = loadstring([[return {]]..table.concat( trans, ", ", 1,math.floor(#trans / 2) *2  )..[[}]])()
                end
            end
            if now_type:get() == 'bezier' then
                --add sub
                if ui:button("add") then
                    table.insert( bezier.trans,0.5)
                    table.insert( bezier.trans,0.5)
                    strings_trans:update()
                    end

                if ui:button("sub") and #bezier.trans > 2 then
                    table.remove( bezier.trans, #bezier.trans )
                    table.remove( bezier.trans, #bezier.trans )
                    strings_trans:update()
                end
            end
        end
        ui:windowEnd()



        if ui:windowBegin('Visualization',visualization.x, visualization.y, visualization.w, slider.h,
            'border', 'title','scrollbar') then

            ui:layoutRow('dynamic', 50, 1)

            if now_type:get() == 'bezier' then
                for i = 1,#def_bezier do
                    if ui:button("bezier "..i,bezier.canvas[i]) then
                        bezier.trans = def_bezier[i]
                        strings_trans:update()
                    end
                end
            elseif now_type:get() == 'easings' then
                for i = 1,#easings.easings do
                    if ui:button(easings.easings[i].name,easings.canvas[i]) then
                        easings.index = i
                    end
                end
            end
        end
    ui:windowEnd()
    ui:frameEnd()
    
    if now_type:get() ~= 'bezier' then return end

    if not now_select[2] then return end
    
    bezier.trans[now_select[1] *2 - 1] = (mouse.x - func.x) / func.w
    bezier.trans[now_select[1] *2] = (func.y + func.h - mouse.y) / func.h
    bezier.trans[now_select[1] *2 - 1] = math.max(math.min(bezier.trans[now_select[1] *2 - 1],1),0)
    strings_trans:update()

end
function love.mousepressed(x,y,button, istouch, presses)
    if ui:mousepressed(x, y, button, istouch, presses) then return  end

    if now_type:get() ~= 'bezier' then return end

    local trans_pos =   {}
    
    for i = 1,#bezier.trans,2 do
        table.insert( trans_pos, {func.x+func.w*bezier.trans[i],func.y+func.h-func.h*bezier.trans[i+1]} )
    end

    for i = 1,#trans_pos do
        if intervals_intersect(mouse.x-DETECTION_RANGE,mouse.x+DETECTION_RANGE,trans_pos[i][1]-DETECTION_RANGE,trans_pos[i][1]+DETECTION_RANGE) and 
            intervals_intersect(mouse.y-DETECTION_RANGE,mouse.y+DETECTION_RANGE,trans_pos[i][2]-DETECTION_RANGE,trans_pos[i][2]+DETECTION_RANGE) then
            now_select = {i,true}
            return
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if ui:mousereleased(x, y, button, istouch, presses) then    end

    if now_type:get() ~= 'bezier' then return end

    now_select[2] = false
end

function love.keypressed(key, scancode, isrepeat)
    if ui:keypressed(key, scancode, isrepeat) then  return  end

    if key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
        func:copy()
    end
    if key == "m" then
        func:mirror()
    end
end



function love.keyreleased(key, scancode)
if ui:keyreleased(key, scancode) then   return  end
end

function love.mousemoved(x, y, dx, dy, istouch)
if ui:mousemoved(x, y, dx, dy, istouch) then    return  end
end

function love.textinput(text)
if ui:textinput(text) then  return  end
end

function love.wheelmoved(x, y)
if ui:wheelmoved(x, y) then return  end
end