--
-- Author: lolol 
-- Date: 2016-03-05 23: 26: 23
--
local star = class("star", function()
    return display.newScene("star")
end)

function star:ctor()

    display.addSpriteFrames("fruit.plist","fruit.png")

	display.newSprite("mainBG.png")
	  :pos(display.cx,display.cy)
	  :addTo(self)

    local btnim={

    normal="#startBtn_N.png",
    pressed="#startBtn_S.png",

    }

    local btn= cc.ui.UIPushButton.new(btnim,{scale9=false})
    btn:onButtonClicked(function (event)
        local s=require("app.scenes.MainScene").new()
        display.replaceScene(s,"turnOffTiles",0.6)
        
    end)
    btn:align( display.CENTER,display.cx, display.cy-80)
    btn:addTo(self)

end
return star
