FreeAllRegions()
DPrint("")

--WriteURLData("http://www.clker.com/cliparts/q/O/x/X/K/K/white-ball-md.png", "whiteBall.png")

r = Region()
r:Show()
r.t = r:Texture(DocumentPath("whiteBall.png"))

r:SetHeight(10)
r:SetWidth(10)
r:SetAnchor("CENTER",0.5*ScreenWidth(),0.75*ScreenHeight())

function drop(self,elapsed)
    self.downOffset = self.downOffset + elapsed * self.speed
    DPrint(0.75*ScreenHeight()-self.downOffset)
	if 0.75*ScreenHeight()-self.downOffset <= 0 then
	 	self.downOffset = 0
	end
	self:SetAnchor("CENTER",0.5*ScreenWidth(),0.75*ScreenHeight()-self.downOffset)
end

r.downOffset = 0
r.speed = 200
r:Handle("OnUpdate", drop)

r2 = Region()
r2:SetWidth(ScreenWidth())
r2:SetHeight(ScreenHeight())
r2:SetLayer("BACKGROUND")
r2:SetAnchor("BOTTOMLEFT",0,0)
r2.t = r2:Texture(0,0,0,255)
r2:Show()

-- bring the arrow to the front
r:SetLayer("TOOLTIP")