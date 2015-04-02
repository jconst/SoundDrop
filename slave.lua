FreeAllRegions()
FreeAllFlowboxes()

local log = math.log

function freq2norm(freq)
	return 12.0/96.0*log(freq/55)/log(2)
end

function main()
	createFlowboxes()
	createButtons()
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

function gotOSC(self, num, flashFrequency)
	DPrint("OSC: ".. num.." "..flashFrequency)
	currentfrequency = freq2norm(num)
	push:Push(currentfrequency)
	trigger:Push(1)
	--SetTorchFlashFrequency(flashFrequency)
end

function selectButton()
	--DPrint("trigger")
	--in the future replace random with frequency we want to send
	--now it sends to itself
	--also can send rotation data to master piece
	SendOSCMessage(host,8888,"/urMus/numbers",math.random(220,1000),math.random(220,1000))
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
--need to add rotation info here
function heading()
end
function createButtons()
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
	--don't have rotation info handler
	--the closest one is OnHeading
	--r:Handle("OnHeading",heading)
	SetOSCPort(8888)
	host,port = StartOSCListener()
	r:EnableInput(true)
	r:Show()
	
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
end
main()

