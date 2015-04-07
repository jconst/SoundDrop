FreeAllRegions()
FreeAllFlowboxes()

SERVER_IP = "192.168.1.111"

local log = math.log

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
	createFlowboxes()
	createButtons()
	lookForSoundDropServer()
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
	attack:Push(0.1)
	decay:Push(1)
	sustain:Push(0.8)
	release:Push(0.00002)
end

function foundSoundDropServer(region, hostname)
	DPrint(hostname)
end

function lookForSoundDropServer()
	StartNetDiscovery("SoundDrop")
end

function setUpConnectionToServer()
	SendOSCMessage(SERVER_IP, 8888, "/urMus/text", host)
end

function rotate( self, x, y, z )
	if thisDeviceIndex ~= -1 then
		SendOSCMessage(SERVER_IP, 8888, "/urMus/numbers", thisDeviceIndex, x, y, z)
	end
end

thisDeviceIndex = -1
function gotOSC(self, numbers)
	if string.find(numbers, "DeviceIndex:") then
		thisDeviceIndex = tonumber(string.sub(numbers, -1))
		DPrint(tostring(thisDeviceIndex))
	end

	if thisDeviceIndex == -1 then
		return false
	end

	DPrint("Got OSC Message: " .. numbers)

	local numStrings = numbers:split(", ")
	local nums = {}

	for i = 1, #numStrings do
	   nums[i] = tonumber(numStrings[i])
	end

	if #nums < 2 then
		return false
	end

	currentfrequency = freq2norm(nums[1])
	push:Push(currentfrequency)
	trigger:Push(1)
	--SetTorchFlashFrequency(nums[2])
end

function selectButton()
	--DPrint("trigger")
	--in the future replace random with frequency we want to send
	--now it sends to itself
	--also can send rotation data to master piece
	-- SendOSCMessage(host,8888,"/urMus/numbers",math.random(220,1000),math.random(220,1000))
end

--now sound pulse time is constrained by deselect button
--in the futrue master show send two consective osc message to tell slave to trigger and stop
--otherwise need to find other way to implement this
function deselectButton()
	trigger:Push(-1)
end

function selectButton2()
	kick_trigger:Push(1)
end
function deselectButton2()
	kick_trigger:Push(0)
end
function selectButton3()
	snare_trigger:Push(1)
end
function deselectButton3()
	snare_trigger:Push(0)
end

data_x = 0
function accel(self, x, y, z)
	--DPrint(x) --rotation
	data_x = x
end

function genclock(self,elapsed)
	if(clock==6) then
		clock = 0
		if(tick==5) then
			tick = 1
		else
			tick = tick + 1
		end
	else
		clock = clock + 1
	end
	if(tick==5) then
		--send data
		--SendOSCMessage(host,8888,"/urMus/numbers",math.random(220,1000),math.random(220,1000))
		-- DPrint("data_x:"..data_x)
	end
end

function createButtons()
	clock = 0
	tick = 0
	--create a button to send osc message to itself by pressing the button
	r = Region()
	r:SetWidth(ScreenWidth()/2)
	r:SetHeight(ScreenHeight()/4)
	r.t = r:Texture(255,255,0,255)
	r.tb = r:TextLabel()
	r.tb:SetLabel("press me")
	r.tb:SetColor(255,0,0,255)
	r.tb:SetFontHeight(30)
	r:Handle("OnTouchDown", selectButton)
	r:Handle("OnTouchUp", deselectButton)
	r:Handle("OnOSCMessage",gotOSC)
	r:Handle("OnNetConnect", foundSoundDropServer)
	--don't have rotation info handler
	--the closest one is OnHeading
	--r:Handle("OnHeading",heading)
	r:Handle("OnRotation", rotate)
	r:Handle("OnAccelerate", accel)
	r:Handle("OnUpdate",genclock)
	SetOSCPort(8888)
	host,port = StartOSCListener()
	r:EnableInput(true)
	r:Show()

	DPrint(host)

	StartNetAdvertise("SoundDropSlave", 8888)

	r2 = Region()
	r2:SetWidth(ScreenWidth()/2)
	r2:SetHeight(ScreenHeight()/4)
	r2:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",ScreenWidth()/2,0)
	r2.t = r2:Texture(0,255,255,255)
	r2.tb = r2:TextLabel()
	r2.tb:SetLabel("play kick")
	r2.tb:SetColor(255,0,0,255)
	r2.tb:SetFontHeight(20)
	r2:Handle("OnTouchDown", selectButton2)
	r2:Handle("OnTouchUp", deselectButton2)
	r2:EnableInput(true)
	r2:Show()

	r3 = Region()
	r3:SetWidth(ScreenWidth()/2)
	r3:SetHeight(ScreenHeight()/4)
	r3:SetAnchor("TOPLEFT",UIParent,"TOPLEFT",0,0)
	r3.t = r3:Texture(255,0,255,255)
	r3.tb = r3:TextLabel()
	r3.tb:SetLabel("play snare")
	r3.tb:SetColor(0,0,255,255)
	r3.tb:SetFontHeight(20)
	r3:Handle("OnTouchDown", selectButton3)
	r3:Handle("OnTouchUp", deselectButton3)
	r3:EnableInput(true)
	r3:Show()

	r4 = Region()
	r4:SetWidth(ScreenWidth()/2)
	r4:SetHeight(ScreenHeight()/4)
	r4:SetAnchor("TOPLEFT",UIParent,"TOPLEFT",ScreenWidth()/2,0)
	r4.t = r4:Texture(0,0,255,255)
	r4.tb = r4:TextLabel()
	r4.tb:SetLabel("send X")
	r4.tb:SetColor(0,255,0,255)
	r4.tb:SetFontHeight(20)
	r4:Handle("OnTouchDown", setUpConnectionToServer)
	r4:Handle("OnTouchUp", deselectButton4)
	r4:EnableInput(true)
	r4:Show()
end
main()