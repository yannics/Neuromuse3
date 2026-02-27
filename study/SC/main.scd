(
Server.killAll;
s = Server.default;
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*5; // default is 8192
s.options.maxNodes = 4096*2; // default is 1024
s.boot;
Safety.setLimit(0.8);
s.latency = 0.2; // default = 0.2

s.waitForBoot({

	// debugging
	//OSCFunc.trace(true,true);

	thisProcess.openUDPPort(7771); // \markovChainFlute
	thisProcess.openUDPPort(7772); // \cycleChainOrgue

	~folder_path = PathName.new("".resolveRelative +/+ "rec/");
	~loader = Array.new;
	~folder_path.entries.do{|path|~loader=~loader.add(Buffer.read(s,path.fullPath))};
	~bnbuf=~loader.choose;

	thisProcess.interpreter.executeFile("".resolveRelative +/+ "synths.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "tbn_kdtree.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "funcs.scd");
	//thisProcess.interpreter.executeFile("".resolveRelative +/+ "gui.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "osc.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "osc/touchosc.scd");

	// -----------

	~groupOrg = Group.new;

	~revBusFla = Bus.audio(s, 1);
	~revBusFlb = Bus.audio(s, 1);
	~revBusFlc = Bus.audio(s, 1);
	~revBusFld = Bus.audio(s, 1);
	~groupFl = Group.new;
	~revGroupFl = Group.new(~groupFl, \addAfter);

	~distBusTbna = Bus.audio(s, 2);
	~distBusTbnb = Bus.audio(s, 2);
	~groupTbn = Group.new;
	~distGroupTbn = Group.new(~groupTbn, \addAfter);

	~groupNoise = Group.new;

	~frequencies = [ 1174.659, 854.9481, 659.2551, 640.4874, 622.25397, 493.8833, 415.3047, 391.99542, 369.99442, 320.2437, 293.66476, 269.29178, 246.94165, 233.08187, 207.65235, 190.41803, 184.99721, 179.73072, 174.61412, 155.56349, 146.83238 ];

	~modeUlam = false;
	~rndAmp = 0.1;
	~detune = 5;

	~revBusUlam = Bus.audio(s, 4);
	~groupUlam = Group.new;
	~revGroupUlam = Group.new(~groupUlam, \addAfter);

	~ampFl=0; //0.10714286565781
	~ampOrg=0; //0.049450576305389
	~volNoise = 0; //0.16208791732788
	// ulam 0.13736265897751
	// tbn 0.47527474164963

	~mute1=false;
	~mute2=false;
	~mute3=false;
	~mute4=false;
	~mute5=false;

	~unisson=0.asBoolean; // flute>0, orgue>1
	~nearestUnisson=0.asBoolean;
	~rtm=0.asBoolean;
	~denom=16;

	~trigFl=0;
	~trigOrg=0;

	~stacDur=10;
	~stacDurFl=10;
	~glissando=0.1;

	~count = 0; // see function ~processNearest
	~durFact = 1/2;//2/3; ??????

	~revFla = Synth(\rev0, [\in, ~revBusFla.index, \out, 0], ~revGroupFl);
	~revFlb = Synth(\rev0, [\in, ~revBusFlb.index, \out, 1], ~revGroupFl);
	~revFlc = Synth(\rev0, [\in, ~revBusFlc.index, \out, 2], ~revGroupFl);
	~revFld = Synth(\rev0, [\in, ~revBusFld.index, \out, 3], ~revGroupFl);
	~revGroupFl.set(\mix, 0.9, \del, 14.5, \rev0, 10, \lpf, 8000);

	~distTbna = Synth(\tbnfx , [\in, ~distBusTbna.index, \out, 0], ~distGroupTbn);
	~distTbnb = Synth(\tbnfx , [\in, ~distBusTbnb.index, \out, 2], ~distGroupTbn);
	~distGroupTbn.set(\dist, 1);

	~revUlam = Synth(\rev4, [\in, ~revBusUlam.index, \out, 0], ~revGroupUlam);

	s.sync;
	})
)
/*
//+++++++++++++++++++++++++
// TEST INSTALLATION
a = 0.1;{ Pan4.ar(PinkNoise.ar, 0, 0, a) }.play;
// FRONT/LEFT
{Out.ar(0, PinkNoise.ar*a)}.play;
{ Pan4.ar(PinkNoise.ar, -1, 1, a) }.play;
// FRONT/RIGHT
{Out.ar(1, PinkNoise.ar*a)}.play;
{ Pan4.ar(PinkNoise.ar, 1, 1, a) }.play;
// BACK/LEFT
{Out.ar(2, PinkNoise.ar*a)}.play;
{ Pan4.ar(PinkNoise.ar, -1, -1, a) }.play;
// BACK/RIGHT
{Out.ar(3, PinkNoise.ar*a)}.play;
{ Pan4.ar(PinkNoise.ar, 1, -1, a) }.play;
//+++++++++++++++++++++++++
*/