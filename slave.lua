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

--links
	dac.In:SetPull(sinosc.Out)
	push.Out:SetPush(sinosc.Freq)
	trigger.Out:SetPush(adsr.Trigger)
	attack.Out:SetPush(adsr.Attack)
	decay.Out:SetPush(adsr.Decay)
	sustain.Out:SetPush(adsr.Sustain)
	release.Out:SetPush(adsr.Release)
	sinosc.Amp:SetPull(adsr.Out)
	
	push:Push(currentfrequency)
	--can modify the parameters to get different sound
	trigger:Push(0)
	attack:Push(0.1)
	decay:Push(1)
	sustain:Push(0.8)
	release:Push(0.00002)
end

function gotOSC(self, num)
	DPrint("OSC: ".. num)
	currentfrequency = freq2norm(num)
	push:Push(currentfrequency)
	trigger:Push(1)
end

function selectButton()
	--DPrint("trigger")
	--in the future replace random with frequency we want to send
	--now it sends to itself
	--also can send rotation data to master piece
	SendOSCMessage(host,8888,"/urMus/numbers",math.random(220,1000))
end

--now sound pulse time is constrained by deselect button
--in the futrue master show send two consective osc message to tell slave to trigger and stop
--otherwise need to find other way to implement this
function deselectButton()
	trigger:Push(-1)
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
	SetOSCPort(8888)
	host,port = StartOSCListener()
	r:EnableInput(true)
	r:Show()
end
main()
