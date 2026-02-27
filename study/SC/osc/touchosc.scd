(
OSCdef.new(
	\flute_amp,
	{
		| msg, time, addr, port |
		~ampFl=msg[1].asFloat;
		~groupFl.set("amp", ~ampFl*0.05)
	},
	'/1/fader11'
);

OSCdef.new(
	\flute_stacc,
	{
		| msg, time, addr, port |
		~stacDurFl = msg[1].asFloat.linlin(0,1,10,0.1);
	},
	'/1/fader12'
);

OSCdef.new(
	\flute_mute,
	{
		| msg, time, addr, port |
		~mute1 = msg[1].asBoolean;
		if(~mute1)
		{
			~fla = Synth(\wFlute, [\out, ~revBusFla], ~groupFl);
			~flb = Synth(\wFlute, [\out, ~revBusFlb], ~groupFl);
			~flc = Synth(\wFlute, [\out, ~revBusFlc], ~groupFl);
			~fld = Synth(\wFlute, [\out, ~revBusFld], ~groupFl);
			~groupFl.set("amp", ~ampFl*0.05)
		}
		{
			~fla.free; ~flb.free; ~flc.free; ~fld.free;
		};
	},
	'/1/toggle1'
);

OSCdef.new(
	\orgue_amp,
	{
		| msg, time, addr, port |
		~ampOrg = msg[1].asFloat; ~groupOrg.set(\amp, ~ampOrg);
	},
	'/1/fader2'
);

OSCdef.new(
	\orgue_mute,
	{
		| msg, time, addr, port |
		~mute2=msg[1].asBoolean;
	},
	'/1/toggle2'
);

OSCdef.new(
	\noise_amp,
	{
		| msg, time, addr, port |
		~volNoise=msg[1].asFloat;
		~groupNoise.set(\amp, ~volNoise);
	},
	'/1/fader4'
);

OSCdef.new(
	\noise_mute,
	{
		| msg, time, addr, port |
		~mute4=msg[1].asBoolean;
	},
	'/1/toggle4'
);

OSCdef.new(
	\ulam_amp,
	{
		| msg, time, addr, port |
		//msg.postln;
		~revGroupUlam.set(\amp, msg[1].asFloat*2);
	},
	'/1/fader51'
);

	OSCdef.new(
	\ulam_sine_reson,
	{
		| msg, time, addr, port |
		~modeUlam=msg[1].asBoolean
	},
	'/1/toggle51'
);

OSCdef.new(
	\ulam_dw,
	{
		| msg, time, addr, port |
		// 0 = dry, 1 = wet
		~revGroupUlam.set(\mix, msg[1].asFloat)
	},
	'/1/fader52'
);

OSCdef.new(
	\ulam_mute,
	{
		| msg, time, addr, port |
		~mute5=msg[1].asBoolean;
	},
	'/1/toggle5'
);

OSCdef.new(
	\trombone_mute,
	{
		| msg, time, addr, port |
		~mute3=msg[1].asBoolean;
		if(~mute3)
		{
			~tbna = Synth(\tbn, [\out, ~distBusTbna], ~groupTbn);
			~tbnb = Synth(\tbn, [\out, ~distBusTbnb], ~groupTbn);
		}
		{
			~tbna.free; ~tbnb.free;
		};
	},
	'/1/toggle3'
);

OSCdef.new(
	\trombone_rtm,
	{
		| msg, time, addr, port |
		~rtm=msg[1].asBoolean;
	},
	'/1/toggle33'
);

OSCdef.new(
	\trombone_nearest,
	{
		| msg, time, addr, port |
		~nearestUnisson=msg[1].asBoolean;
	},
	'/1/toggle32'
);

OSCdef.new(
	\trombone_unisson,
	{
		| msg, time, addr, port |
		~unisson=msg[1].asBoolean;
	},
	'/1/toggle31'
);

OSCdef.new(
	\trombone_dist,
	{
		| msg, time, addr, port |
		~distGroupTbn.set(\dist, 1-msg[1].asFloat, \amp, 4)
	},
	'/1/fader31'
);

OSCdef.new(
	\trombone_stacc,
	{
		| msg, time, addr, port |
		~stacDur=msg[1].asFloat.linlin(0,1,10,0.1);
	},
	'/1/fader32'
);

OSCdef.new(
	\trombone_gliss,
	{
		| msg, time, addr, port |
		~glissando=msg[1].asFloat.linlin(0,1,0.1,1);
	},
	'/1/fader33'
);
)
/*
// code a metronome ....

o = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; }, '/1/flute');
// create the OSCFunc
o.free;

(
{
	var in = SoundIn.ar(0);
	var rms = MovingAverage.rms(in, s.sampleRate * 0.1, s.sampleRate).poll;
	var trig1 = SetResetFF.ar(rms > 0.01, rms < 0.01);
	var trig2 = SetResetFF.ar(rms > 0.1, rms < 0.1);
	var sig = [ Silent.ar(), Saw.ar(110, 0.1), Saw.ar(220, 0.1)];
	(trig1 + trig2).poll;
	SelectX.ar((trig1 + trig2).lag(0.2), sig)
}.play
)
*/