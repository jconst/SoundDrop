FreeAllRegions()
DPrint("")

--WriteURLData("http://www.clker.com/cliparts/q/O/x/X/K/K/white-ball-md.png", "whiteBall.png")

-- Create background
bg = Region()
bg:SetWidth(ScreenWidth())
bg:SetHeight(ScreenHeight())
bg:SetLayer("BACKGROUND")
bg:SetAnchor("BOTTOMLEFT",0,0)
bg.t = bg:Texture(0,0,0,255)
bg:Show()

-- Create a ball releaser
bg.t:SetBrushColor(255,255,255,255)
bg.t:SetBrushSize(7)
bg.t:Ellipse(0.5*ScreenWidth(), 0.75*ScreenHeight(), 10 , 10) -- I don't know why this doesn't work

-- Create a ball
ball = Region()
ball:Show()
ball.t = ball:Texture(DocumentPath("whiteBall.png"))

ball:SetHeight(10)
ball:SetWidth(10)
ball:SetAnchor("CENTER",0.5*ScreenWidth(),0.75*ScreenHeight())
ball:SetLayer("TOOLTIP")

-- ball dropping event handler

ball.speed = 0
ball.downOffset = 0

function drop(self,elapsed)
    self.downOffset = self.downOffset + elapsed * self.speed
    self.speed = self.speed + 150 * elapsed
    DPrint(0.75*ScreenHeight()-self.downOffset)
	if 0.75*ScreenHeight()-self.downOffset <= 0 then
	 	self.downOffset = 0
	 	self.speed = 0
	end
	self:SetAnchor("CENTER",0.5*ScreenWidth(),0.75*ScreenHeight()-self.downOffset)
end

ball:Handle("OnUpdate", drop)
