
local MenuScene = class("MenuScene", function()
    return display.newScene("MenuScene")
end)

fruit=import("app.Fruit")

 
function MenuScene:ctor()
math.randomseed(tostring(os.time()):reverse():sub(1, 6))
   --math.newrandomseed() --初始化随机数

   self.xCount=8 --水平方向水果数
   self.yCount=8 --垂直方向水果数
   self.fruitGap=0 --水果间隔
   self.scoreStart=5 --水果消除基分
   self.scoreStep=10 --加成分数
   self.activeScore=0 --当前高亮水果的分数

   --第一个水果的坐标常量
   self.matrixLBX=(display.width-fruit.getWidth()*self.xCount-(self.yCount-1)*self.fruitGap)/2
   self.matrixLBY=(display.height-fruit.getWidth()*self.yCount-(self.xCount-1)*self.fruitGap)/2-30

   self:addNodeEventListener(cc.NODE_EVENT,function ( event)
       
        if event.name =="enterTransitionFinish" then
           self:initMartix()
        end
   end)

   self.highSorce=0
   self.stage=1
   self.target=23000
   self.curSorce=0
   self.bf=true
   audio.playMusic("music/mainbg.mp3",true)

   display.newSprite("playBG.png")
   :pos(display.cx, display.cy)
   :addTo(self)

   self:initUI()
  	
end

function MenuScene:initMartix()

  --创建空矩阵
  self.matrix={}
   --高亮水果
  self.actives={}
  --相同的水果
  self.remove={}

  for y=1,self.yCount do

    for x=1,self.xCount do

      if 1==y and 2==x then 
        --确保有可以消除的水果
        self:createAndDropFruit(x,y,self.matrix[1].fruitIndex)

      else

        self:createAndDropFruit(x,y,math.round(math.random()*999)%8+1)

      end

    end

  end

   self:performWithDelay(function()
           self:checkSame()
           self:removeActivedFruits()
           self:dropFruits()
           self:checkNextStage()
           end,0.55)

end

function MenuScene:createAndDropFruit(x,y,fruitIndex)
  
  local newFruit=fruit.new(x,y,fruitIndex)
  newFruit:setTouchEnabled(true)
  newFruit:addNodeEventListener(cc.NODE_TOUCH_EVENT,function (event,tag)

    if event.name=="ended" then

      if #self.actives==1 then

        if self.actives[1] ==newFruit then

          newFruit:setActive(false)
          self.actives={}
          return

        end
        
        --消除的音效
        local musicindex=#self.actives
        if(musicindex<2) then
          musicindex=2
        end
        if (musicindex>9) then
          musicindex=9
        end
        local tmpStr=string.format("music/broken%d.mp3",musicindex)
        audio.playSound(tmpStr)

       --检查是否可调换位置
        if self:inactive(newFruit) then
          self:change()

        --检查是否有连续的三个
          if self:checkSame() then
            return
          end

        --TODO:消除高亮水果，加分，并掉落
          self:performWithDelay(function()
           self:removeActivedFruits()
           self:dropFruits()
           self:checkNextStage()
           end,0.36)
    
         --检查是否还有可消除的水果
          if self:Check() then

           self:Return()

          end

        end

      elseif #self.actives>2 then
        return

      else 

        self:inactive(newFruit)
        --高亮音效
        audio.playSound("music/itemSelect.mp3")

      end
    
    end
      if event.name =="began" then
        return true
      end
    
  end)
  local endPosition=self:positionOfFruit(x,y)
  local startPosition=cc.p(endPosition.x,endPosition.y+display.height/2)
  newFruit:setPosition(startPosition)
  local speed=startPosition.y/(2*display.height)
  newFruit:runAction(cc.MoveTo:create(speed,endPosition))
  self.matrix[(y-1)*self.xCount+x]=newFruit
  self:addChild(newFruit)

end

function MenuScene:checkNextStage()

  if self.curSorce<self.target then
    return 
  end

  --resultLayer 半透明显示消息
  local resultLayer=display.newColorLayer(cc.c4b(0,0,0,150))
  resultLayer:addTo(self)
  --吞噬事件
  resultLayer:setTouchEnabled(true)
  
  --更新数据
  if self.curSorce>=self.highSorce then
    self.highSorce=self.curSorce
  end
  self.stage=self.stage+1
  self.target=self.stage*200

   --停止计时器
   cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.ID)

  local STR=display.newTTFLabel({text="LEVEL UP",size=10})
  STR:addTo(resultLayer)
  :pos(display.cx,display.cy)
  local f=cc.ScaleTo:create(0.3,8)
  STR:runAction(f)
  local em=cc.ParticleSystemQuad:create("s.plist")
  local ba=cc.ParticleBatchNode:createWithTexture(em:getTexture())
  ba:addChild(em)
  self:addChild(ba)
  em:setPosition(display.cx,display.cy)

  self:performWithDelay(function()
    audio.stopMusic()
     resultLayer:removeFromParent()
     local newScene=import("app.scenes.MainScene"):new()
     display.replaceScene(newScene,"flipX",0.5)
  end,1.3)

end

function MenuScene:dropFruits()

  local emptyInfo={}

  --1.掉落已存在的水果
  --一列一列的处理
  for x=1,self.xCount do 

    local removedFruits=0
    local newY=0
    --从下往上处理
    for y=1,self.yCount do
      
       local temp=self.matrix[(y-1)*self.xCount+x]
       if temp==nil then

         --水果已被移除
         removedFruits=removedFruits+1

       else
         
         --如果水果下游空缺，则向下移动
         if removedFruits>0 then

          newY=y-removedFruits
          self.matrix[(newY-1)*self.xCount+x]=temp
          temp.y=newY
          self.matrix[(y-1)*self.xCount+x]=nil

          local endPosition=self:positionOfFruit(x, newY)
          local speed=(temp:getPositionY()-endPosition.y)/display.height
          temp:stopAllActions() --停止之前的所有运动
          temp:runAction(cc.MoveTo:create(speed,endPosition))

        end

      end

    end

     --记录本列最终空缺数
     emptyInfo[x]=removedFruits

  end

  for x=1,self.xCount do 

    for y=self.yCount-emptyInfo[x]+1,self.yCount do 

      self:createAndDropFruit(x, y,math.round(math.random()*999)%8+1)

    end

  end

     self:performWithDelay(function()
           self:checkSame()
           if #self.remove >=3 then
            self:removeActivedFruits()
            self:dropFruits()
            self:checkNextStage()
           end
           end,0.5)
  
end

function MenuScene:Return()
 
   --停止计时器
   cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.ID)
  local End=display.newColorLayer(cc.c4f(0,0,0,255))
    End:setCascadeOpacityEnabled(true)
    End:setOpacity(0)
    self:addChild(End)
    local ll=cc.ui.UILabel.new({UILabelType = 2, text = "GAME OVER", font = "fonts/earth70.fnt",size=100,color=cc.c3b(255,255,255)})
    ll:pos(display.cx-225,display.cy)
    ll:setCascadeOpacityEnabled(true)
    ll:setOpacity(0)
    self:addChild(ll)
    local action = cc.FadeTo:create(1,150)
    local action1=cc.FadeIn:create(1)
    ll:runAction(action1)
    End:runAction(action)
    End:setTouchEnabled(true)
    End:addNodeEventListener(cc.NODE_TOUCH_EVENT,function (event)

    self.actives={}
    End:stopAllActions()
    ll:stopAllActions()
    self:removeChild(ll)
    self:removeChild(End)
    for _,fruit in pairs(self.matrix) do
      fruit:removeFromParent()
    end
    
    --添加新的一组水果
    for y=1,self.yCount do

     for x=1,self.xCount do

      if 1==y and 2==x then 
        --确保有可以消除的水果
        self:createAndDropFruit(x,y,self.matrix[1].fruitIndex)

      else

        self:createAndDropFruit(x,y,math.round(math.random()*999)%8+1)

      end

     end

    end
      --更新得分
   self.curSorceLabel:setString(tostring(0))
   self.curSorce=0
   self.silderBar:setSliderValue(0)
   local v=self.silderBar:getSliderValue()
    local tick=function ()

          if v>=100 then

            self:Return()
            self.silderBar:setSliderValue(0)
          else

             v=v+1
             self.silderBar:setSliderValue(v)

          end

        end
    self.ID=cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick,0.5,false)

    self:performWithDelay(function()
           self:checkSame()
           self:removeActivedFruits()
           self:dropFruits()
           self:checkNextStage()
           end,0.55)


    if event.name=="began" then
       return true
    end

    end)

end

function MenuScene:removeActivedFruits()

  local fruitScore=self.scoreStart
  local piont=#self.remove
  for _,fruit in pairs(self.remove)do
    
     if(fruit)then

      --从矩阵中删除
      self.matrix[(fruit.y-1)*self.xCount+fruit.x]=nil
      --爆炸特效
      local time=0.3
      --爆炸圈
      local circleSprite=display.newSprite("circle.png")
            :pos(fruit:getPosition())
            :addTo(self)
      circleSprite:setScale(0)
      circleSprite:runAction(cc.Sequence:create(cc.ScaleTo:create(time,1.0),
        cc.CallFunc:create(function ( ) circleSprite:removeFromParent() end)))

      --爆炸碎片
      local emitter=cc.ParticleSystemQuad:create("stars.plist")
      emitter:setPosition(fruit:getPosition())
      local batch=cc.ParticleBatchNode:createWithTexture(emitter:getTexture())
      batch:addChild(emitter)
      self:addChild(batch)
      --分数特效
      self:scorePopupEffect(fruitScore,fruit:getPosition())
      fruitScore=fruitScore+self.scoreStep
      fruit:removeFromParent()

      end

  end

  --清空高亮数组
  self.remove={}
  self.actives={}
  --更新当前得分
  self.curSorce=self.curSorce+piont*50+20*piont*(piont-1)/2
  self.curSorceLabel:setString(tostring(self.curSorce))

  --清空高亮水果分数统计
  self.activeScoreLabel:setString("")
  self.activeScore=0

end

function MenuScene:scorePopupEffect(score, px, py)
  local labelScore = cc.ui.UILabel.new({UILabelType = 2, text = tostring(score), font = "fonts/earth32.fnt"})

  local move = cc.MoveBy:create(0.8, cc.p(0, 80))
  local fadeOut = cc.FadeOut:create(0.8)
  local action = transition.sequence({
    cc.Spawn:create(move,fadeOut),
    -- 动画结束移除 Label
    cc.CallFunc:create(function() labelScore:removeFromParent() end)
  })

  labelScore:pos(px, py)
    :addTo(self)
    :runAction(action)
end

function MenuScene:Check()

  for y=1,self.yCount do 

    for x=1,self.xCount do

      local checkfruit=self.matrix[(y-1)*self.xCount+x]
      if (x+1)<=self.xCount then

         local rightFruit=self.matrix[(y-1)*self.xCount+x+1]
         if checkfruit.fruitIndex==rightFruit.fruitIndex then
          return false
         end

      end
      if(y+1)<=self.yCount then

         local upFruit=self.matrix[y*self.xCount+x]
         if checkfruit.fruitIndex==upFruit.fruitIndex then
          return false
         end

      end

    end

  end

  return true
end



function MenuScene:inactive(newFruit)

  if #self.actives==1 then
 
    local changeFruit_ID =self.actives[1]
    local bechangeFruit_ID =newFruit

    if (changeFruit_ID.x+1 == bechangeFruit_ID.x and changeFruit_ID.y == bechangeFruit_ID.y) or
       (changeFruit_ID.x-1 == bechangeFruit_ID.x and changeFruit_ID.y == bechangeFruit_ID.y) or
       (changeFruit_ID.x == bechangeFruit_ID.x and changeFruit_ID.y == bechangeFruit_ID.y+1) or
       (changeFruit_ID.x == bechangeFruit_ID.x and changeFruit_ID.y == bechangeFruit_ID.y-1) then

    else

      changeFruit_ID:setActive(false)
      self.actives={}
      return false

    end

  end

 newFruit:setActive(true)
 table.insert(self.actives,newFruit)
 return true

end

function MenuScene:change()
  
  local changeFruit_ID =self.actives[1]
  local bechangeFruit_ID =self.actives[2]
  local temp
  local x1,x2 =changeFruit_ID.x,bechangeFruit_ID.x
  local y1,y2 =changeFruit_ID.y,bechangeFruit_ID.y
  local px1,py1 =changeFruit_ID:getPosition()
  local px2,py2 =bechangeFruit_ID:getPosition()
  local a1=cc.MoveTo:create(0.3,cc.p(px2,py2))
  local a2=cc.MoveTo:create(0.3,cc.p(px1,py1))
  changeFruit_ID:runAction(a1)
  bechangeFruit_ID:runAction(a2)
  temp=self.matrix[(changeFruit_ID.y-1)*self.xCount+changeFruit_ID.x]
  self.matrix[(changeFruit_ID.y-1)*self.xCount+changeFruit_ID.x]=bechangeFruit_ID
  self.matrix[(bechangeFruit_ID.y-1)*self.xCount+bechangeFruit_ID.x]=temp
  changeFruit_ID:setID(x2,y2)
  bechangeFruit_ID:setID(x1,y1)
  changeFruit_ID:setActive(false)
  bechangeFruit_ID:setActive(false)
  
end

function MenuScene:checkSame(newFruit)

 local same=0 

 if newFruit then
  if newFruit.isSelected==false then
    newFruit.isSelected=true
  end
 end

--------------------------------------横项检查---------------------------------------
 for i=1,self.yCount do
   
   for j=1,self.xCount-1 do
     
     local temp= self.matrix[(i-1)*self.xCount+j]

     if temp.fruitIndex == self.matrix[(i-1)*self.xCount+j+1].fruitIndex then

      same =same+1

     elseif same >=2 then

      self:addSame(temp)
      same=0

     else

      same=0

     end

   end
   
   if same>=2 then
    self:addSame(self.matrix[(i-1)*self.xCount+self.xCount])
   end
   same=0

 end
 ------------------------------------横项检查结束--------------------------------------

 ------------------------------------纵项检查------------------------------------------
for i=1,self.xCount do
   
   for j=1,self.yCount-1 do
     
     local temp= self.matrix[(j-1)*self.xCount+i]

     if temp.fruitIndex == self.matrix[j*self.xCount+i].fruitIndex then

      same =same+1
     elseif same >=2 then

      self:addSame(temp)
      
      same=0

     else

      same=0

     end

   end
   
   if same>=2 then
    self:addSame(self.matrix[(self.yCount-1)*self.xCount+i])
   end
   same=0

 end
 --------------------------------------纵项检查结束--------------------------------------


 if #self.remove <3 then

 self:performWithDelay(function()
   if #self.actives==2 then
    self:change()
    self.actives={}
   end
  end,0.3)
 return true

 else

  return false

 end

end

function MenuScene:addSame(fruit)

   if false==fruit.isSelected then

    fruit.isSelected=true
    table.insert(self.remove,fruit)

  end

  --检查左边的水果
  if(fruit.x-1)>=1 then

    local leftNeighbor=self.matrix[(fruit.y-1)*self.xCount+fruit.x-1]
    if(leftNeighbor.isSelected==false)and(leftNeighbor.fruitIndex==fruit.fruitIndex)then

      leftNeighbor.isSelected=true
      table.insert(self.remove,leftNeighbor)
      self:addSame(leftNeighbor)

    end

  end

  --检查fruit右边的水果
  if(fruit.x+1)<=self.xCount then

      local rightNeighbor=self.matrix[(fruit.y-1)*self.xCount+fruit.x+1]
      if(rightNeighbor.isSelected==false)and(rightNeighbor.fruitIndex==fruit.fruitIndex)then

        rightNeighbor.isSelected=true
        table.insert(self.remove,rightNeighbor)
        self:addSame(rightNeighbor)

      end

  end

  --检查fruit上边的水果
  if(fruit.y+1)<=self.yCount then

      local upNeighbor=self.matrix[fruit.y*self.xCount+fruit.x]
      if(upNeighbor.isSelected==false)and(upNeighbor.fruitIndex==fruit.fruitIndex)then

        upNeighbor.isSelected=true
        table.insert(self.remove,upNeighbor)
        self:addSame(upNeighbor)

      end

  end

       --检查fruit下边的水果
  if(fruit.y-1)>=1 then

    local downNeighbor=self.matrix[(fruit.y-2)*self.xCount+fruit.x]
    if(downNeighbor.isSelected==false)and(downNeighbor.fruitIndex==fruit.fruitIndex)then

      downNeighbor.isSelected=true
      table.insert(self.remove,downNeighbor)
      self:addSame(downNeighbor)

    end

  end

end

function MenuScene:positionOfFruit(x,y)

  local px=self.matrixLBX+(fruit.getWidth()+self.fruitGap)*(x-1)+fruit.getWidth()/2
  local py=self.matrixLBY+(fruit.getWidth()+self.fruitGap)*(y-1)+fruit.getWidth()/2
  return cc.p(px,py)

end

function MenuScene:initUI()
   -- high sorce
  display.newSprite("#high_score.png")
    :align(display.LEFT_CENTER, display.left + 15, display.top - 30)
    :addTo(self)

  display.newSprite("#highscore_part.png")
    :align(display.LEFT_CENTER, display.cx + 10, display.top - 26)
    :addTo(self)

  self.highSorceLabel = cc.ui.UILabel.new({UILabelType = 2, text = tostring(self.highSorce), font = "fonts/earth38.fnt"})
    :align(display.CENTER, display.cx + 105, display.top - 24)
        :addTo(self)
  
  -- 声音
  local kk= display.newSprite("#sound.png")
    kk:align(display.CENTER, display.right -60, display.top - 30)
    kk:setTouchEnabled(true)
    kk:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
     
     if self.bf then
        audio.stopMusic(false)
        self.bf=false
      -- body
    
  else
    
    audio.playMusic("music/mainbg.mp3",true)
    self.bf=true
   end
    end)
   kk:addTo(self)
  -- stage
  display.newSprite("#stage.png")
    :align(display.LEFT_CENTER, display.left + 15, display.top - 80)
    :addTo(self)

  display.newSprite("#stage_part.png")
    :align(display.LEFT_CENTER, display.left + 170, display.top - 80)
    :addTo(self)

  self.highStageLabel = cc.ui.UILabel.new({UILabelType = 2, text = tostring(self.stage), font = "fonts/earth32.fnt"})
    :align(display.CENTER, display.left + 214, display.top - 78)
        :addTo(self)
  
  -- target
  display.newSprite("#tarcet.png")
    :align(display.LEFT_CENTER, display.cx - 50, display.top - 80)
    :addTo(self)

  display.newSprite("#tarcet_part.png")
    :align(display.LEFT_CENTER, display.cx + 130, display.top - 78)
    :addTo(self)

  self.highTargetLabel = cc.ui.UILabel.new({UILabelType = 2, text = tostring(self.target), font = "fonts/earth32.fnt"})
      :align(display.CENTER, display.cx + 195, display.top - 76)
      :addTo(self)

  -- current sorce
  display.newSprite("#score_now.png")
    :align(display.CENTER, display.cx, display.top - 150)
    :addTo(self)

  self.curSorceLabel = cc.ui.UILabel.new({UILabelType = 2, text = tostring(self.curSorce), font = "fonts/earth48.fnt"})
      :align(display.CENTER, display.cx, display.top - 150)
      :addTo(self)

  self.activeScoreLabel=display.newTTFLabel({text="",size=30})
      :pos(display.width/2, 120)
      :addTo(self)
  self.activeScoreLabel:setColor(display.COLOR_WHITE)

  
  -- TODO:倒计时条
  local sliderImages = {
        bar = "#The_time_axis_Tunnel.png",
        button = "#The_time_axis_Trolley.png",
    }
   self.silderBar=cc.ui.UISlider.new(display.LEFT_TO_RIGHT,sliderImages,{scale9=false})
        :setSliderSize(display.width,125)
        :setSliderValue(0)
        :align(display.LEFT_BOTTOM,0,0)
        :addTo(self)
        self.silderBar:setTouchEnabled(true)

        local v=self.silderBar:getSliderValue()

        local tick=function ()

          if v>=100 then

            self:Return()
            self.silderBar:setSliderValue(0)

          else

             v=v+1
             if self.silderBar==nil then
              print("yes")
              return
            end
             self.silderBar:setSliderValue(v)

          end

        end

        self.ID=cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick,0.5,false)

        self.silderBar:onSliderPressed(function ()
          cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.ID)
          -- body
        end)
        self.silderBar:onSliderRelease(function ( )

            v=self.silderBar:getSliderValue()
          if v+1>100 then
            self.silderBar:setSliderValue(99)
          else
            self.silderBar:setSliderValue(v)
          end

          local tick=function ()

          if v>=100 then

            self:Return()
            self.silderBar:setSliderValue(0)
          else
            
             v=v+1
             if v>100 then
             self.silderBar:setSliderValue(100)
             else
              self.silderBar:setSliderValue(v)
             end

          end

        end

        self.ID=cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick,0.5,false)


          -- body
        end)

end

function MenuScene:onEnter()
end

function MenuScene:onExit()
end

return MenuScene
