FreeAllRegions()
FreeAllFlowboxes()

SERVER_IP = "192.168.1.104"

local log = math.log
timeSinceTrigger = 0
timeSinceFlashToggle = 0
flashlightOn = false
shouldFlash = false

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function freq2norm(freq)
	return 12.0/96.0*log(freq/55)/log(2)
end

function main()
	setupOSC()
	createFlowboxes()
	createButtons()
	lookForSoundDropServer()
end

function setupOSC()
	SetOSCPort(8888)
	host,port = StartOSCListener()
	DPrint(host)
end

function createFlowboxes()

	currentfrequency = freq2norm(800)

--flowboxes
	sinosc = FlowBox(FBSinOsc)
	dac = FlowBox(FBDac)
	push = FlowBox(FBPush)
	trigger = FlowBox(FBPush)
	attack = FlowBox(FBPush)
	decay = FlowBox(FBPush)
	sustain = FlowBox(FBPush)
	release =  FlowBox(FBPush)
	adsr = FlowBox(FBADSR)
	kick = FlowBox(FBSample)
	kick:AddFile("kick.wav")
	kick_trigger = FlowBox(FBPush)
	snare = FlowBox(FBSample)
	snare:AddFile("snare.wav")
	snare_trigger = FlowBox(FBPush)

--links
	dac.In:SetPull(sinosc.Out)
	dac.In:SetPull(kick.Out)
	dac.In:SetPull(snare.Out)
	push.Out:SetPush(sinosc.Freq)
	trigger.Out:SetPush(adsr.Trigger)
	attack.Out:SetPush(adsr.Attack)
	decay.Out:SetPush(adsr.Decay)
	sustain.Out:SetPush(adsr.Sustain)
	release.Out:SetPush(adsr.Release)
	sinosc.Amp:SetPull(adsr.Out)
	kick_trigger.Out:SetPush(kick.Amp)
	snare_trigger.Out:SetPush(snare.Amp)

	push:Push(currentfrequency)
	kick_trigger:Push(0)
	snare_trigger:Push(0)
	--can modify the parameters to get different sound
	trigger:Push(0)
	attack:Push(0.05)
	decay:Push(1)
	sustain:Push(0.6)
	release:Push(0.00002)
end

function connectAndStart()
	SendOSCMessage(SERVER_IP, 8888, "/urMus/text", host)
	shouldFlash = true
end

function gotOSC(self, message)
	if string.find(message, "DeviceIndex:") then
		gotDeviceIndex(message)
	else
		gotSoundCommand(message)
	end
	return true
end

thisDeviceIndex = -1
function gotDeviceIndex(message)
	thisDeviceIndex = tonumber(string.sub(message, -1))
	DPrint("DeviceIndex: " .. tostring(thisDeviceIndex))
end

function gotSoundCommand(freq)
	DPrint("freq:"..freq)
	currentfrequency = freq2norm(freq)
	push:Push(currentfrequency)
	trigger:Push(1)
	timeSinceTrigger = 0
end

function selectButton()
	gotSoundCommand(math.random(220,1000))
end

function selectButton2()
	kick_trigger:Push(1)
end
function deselectButton2()
	kick_trigger:Push(0)
end

function stopFlash()
	shouldFlash = false
end

function accel(self, x, y, z)
	if thisDeviceIndex ~= -1 then
		SendOSCMessage(SERVER_IP, 8888, "/urMus/numbers", thisDeviceIndex, x)
	end
end

function update(self,elapsed)
	timeSinceFlashToggle = timeSinceFlashToggle + elapsed
	if timeSinceFlashToggle > 0.15 then
		flashlightOn = not flashlightOn
		SetTorch(flashlightOn and shouldFlash)
		timeSinceFlashToggle = 0
	end

	timeSinceTrigger = timeSinceTrigger + elapsed
	if timeSinceTrigger > 0.05 then
		trigger:Push(-1)
		timeSinceTrigger = 0
	end
end

function createButtons()
	r = Region()
	r:SetWidth(ScreenWidth()/2)
	r:SetHeight(ScreenHeight()/4)
	r.t = r:Texture(255,255,0,255)
	r.tb = r:TextLabel()
	r.tb:SetLabel("test sound")
	r.tb:SetColor(255,0,0,255)
	r.tb:SetFontHeight(25)
	r:Handle("OnTouchDown", selectButton)
	r:Handle("OnOSCMessage", gotOSC)
	r:Handle("OnAccelerate", accel)
	r:Handle("OnUpdate",update)
	r:EnableInput(true)
	r:Show()

	rKick = Region()
	rKick:SetWidth(ScreenWidth()/2)
	rKick:SetHeight(ScreenHeight()/4)
	rKick:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",ScreenWidth()/2,0)
	rKick.t = rKick:Texture(0,255,255,255)
	rKick.tb = rKick:TextLabel()
	rKick.tb:SetLabel("play kick")
	rKick.tb:SetColor(255,0,0,255)
	rKick.tb:SetFontHeight(20)
	rKick:Handle("OnTouchDown", selectButton2)
	rKick:Handle("OnTouchUp", deselectButton2)
	rKick:EnableInput(true)
	rKick:Show()

	start = Region()
	start:SetWidth(ScreenWidth()/2)
	start:SetHeight(ScreenHeight()/4)
	start:SetAnchor("TOPLEFT",UIParent,"TOPLEFT",0,0)
	start.t = start:Texture(0,0,255,255)
	start.tb = start:TextLabel()
	start.tb:SetLabel("connect & start")
	start.tb:SetColor(0,255,0,255)
	start.tb:SetFontHeight(18)
	start:Handle("OnTouchDown", connectAndStart)
	start:EnableInput(true)
	start:Show()

	stop = Region()
	stop:SetWidth(ScreenWidth()/2)
	stop:SetHeight(ScreenHeight()/4)
	stop:SetAnchor("TOPLEFT",UIParent,"TOPLEFT",ScreenWidth()/2,0)
	stop.t = stop:Texture(255,0,255,255)
	stop.tb = stop:TextLabel()
	stop.tb:SetLabel("stop flash")
	stop.tb:SetColor(0,0,255,255)
	stop.tb:SetFontHeight(20)
	stop:Handle("OnTouchDown", stopFlash)
	stop:EnableInput(true)
	stop:Show()
end
main()