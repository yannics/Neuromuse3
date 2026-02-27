(
/*
Structure of OSC msg
---> clique = (dur deg int)
[     tag,     seq,  reldur,     deg,     int,            opt_msg,  realdur]
[ msg.[0], msg.[1], msg.[2], msg.[3], msg.[4], msg[5..msg.size-2], msg.last]
.asFloat // OR .asInteger
opt_msg = i1, i2, ..., iN
seq : 1 for routine and 2 for paused routine -- 0 for stop
note currently played (nth 1 clique) -- i.e. msg.[3].asInteger
relative duration (nth 0 clique) -- i.e. msg.[2].asInteger -- must be understood as an indice (in this case 0 -> 1, 1 -> 2, ...)
effective duration -- i.e. msg.last.asFloat
opt: interval in semi-tone up(+)/down(-) (nth 2 clique) -- i.e. msg.[4].asInteger
opt: [note] corresponding to the interval
// ---------------------
// test incoming message
o = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; }, '/N3', recvPort:7771);
o.free;
\markovChainFlute.trace(true, true);
\cycleChainOrgue.trace(true, true);
*/

OSCdef(\markovChainFlute,
	{
		arg msg, time, addr, recvport;
		//[msg, recvport].postln;
		~trigFl = msg[1].asInteger;
		{
			if (~trigFl == 1)
			{
				~relFl = msg[2].asInteger;
				~degFl = msg[3].asInteger;
				~intFl = msg[4].asInteger;
				~tpsFl = msg.last.asFloat;
				~nextcliFl = msg[5..7];
			};
			if ((~trigFl == 0) || (~trigFl == 2))
			{
				~groupFl.set("amp", 0); //~volFl.valueAction = -inf;
				//~groupTbn.set("pressure", 0, "vp", 5); ~distTbn.valueAction = 1;
			}
			{
				// process Tbn
				if(~rtm.not && ~mute3)
				{
					~degTbn = if (~unisson) {~degOrg} {~degFl};
					~processNearest.(~degTbn, ~tpsFl);
				};
				// process Fl
				~flNote=(~degFl+(12*4+[0,12].choose));
				~groupFl.set("pch", ~flNote, "ibreath", 0.00536, "amp", ~ampFl*0.05, "gate", 1);
				~staccato.(~stacDurFl,~groupFl);
				if (~degOrg.isNil || ~intOrg.isNil || ~mute3.not)
				{
					~complementaryHarmContext = 12.rand.asArray
				}
				{
					~complementaryHarmContext = ~degContext.(~degFl, ~degOrg, ~intOrg, ~nextcliFl[1], ~markovHarm)
				};
				//~complementaryHarmContext.midicps.cpsname.postln;
			}
		}.defer
	}, '/N3', recvPort:7771
);

OSCdef(\cycleChainOrgue,
	{
		arg msg, time, addr, recvport;
		//[msg, recvport].postln;
		~trigOrg = msg[1].asInteger;
		{
			if (~trigOrg == 1)
			{
				~relOrg = msg[2].asInteger;
				~degOrg = msg[3].asInteger;
				~intOrg = msg[4].asInteger;
				~tpsOrg = msg.last.asFloat;
				~nextcliOrg = msg[5..7].asInteger;
				~rtmOrg = msg[8..msg.size-2].asInteger;
				//~rtmOrg.postln;
				//------------------------------
				// Noise
				if (~mute4)
				{
					~processNoise.(~degOrg, (~degOrg+~intOrg-11).mod(12), ~tpsOrg)
				};
				//------------------------------
				// Ulam
				if (~mute5)
				{
					// see for a panoramic with method .convertPan4toArray
					Routine.new(
						{
							var deg1 = (60..72).midicps[~degOrg];
							var deg2 = (60..72).midicps[(~degOrg+~intOrg-11).mod(12)];
							{
								// a tester
								//~revUlam = Synth(\rev4, [\in, ({ Ulam.ar(((~frequencies/~frequencies.minItem).round(0.01)*deg1).asInteger.scramble[..3], ~modeUlam, if(~modeUlam.asBoolean){(~tpsOrg*1.3).clip(6,12)}{~tpsOrg}, detune:~detune, rndAmp:~rndAmp) * if(~modeUlam.asBoolean){1}{1-~distUlam*2} }!4,\out, 0], ~groupUlam);
								//Distance.ar(
								 Ulam.ar(((~frequencies/~frequencies.minItem).round(0.01)*deg1).asInteger.scramble[..3], ~modeUlam, if(~modeUlam.asBoolean){(~tpsOrg*4/3).clip(6,12)}{~tpsOrg}, detune:~detune, rndAmp:~rndAmp)!4
								//, \dist.kr(~distUlam*~modeUlam))
							}.play(~groupUlam, ~revBusUlam);
							(~tpsOrg/2).wait;
							{
								//Distance.ar(
								 Ulam.ar(((~frequencies/~frequencies.minItem).round(0.01)*deg2).asInteger.scramble[..3], ~modeUlam, if(~modeUlam.asBoolean){(~tpsOrg*4/3).clip(6,12)}{~tpsOrg}, detune:~detune, rndAmp:~rndAmp)!4
								//, \dist.kr((~distUlam*~modeUlam)))
							}.play(~groupUlam, ~revBusUlam);
						}
					).play
				};
				//------------------------------
				// Tbn counterpoint routine
				if(~rtm && ~mute3)
				{
					Routine.new(
						{
							(~rtmOrg.normalizeSum*~tpsOrg).do
							{
								arg i;
								if (~unisson)
								{
									~degTbn = ~degOrg
								}
								{
									~degTbn = ~complementaryHarmContext.choose;
								};
								~processNearest.(~degTbn, i-0.1);
								i.wait;
							};
						}
					).play
				};
				//------------------------------
				// process orgue
				if ((~trigOrg == 1) && ~mute2)
				{
					(0..3).do{|i|
						{
							// orgue ----
							//var harm = [11, 5].choose;
							//var ser = [~a029744.(harm), (1,2..harm)].choose;
							var harm = 5;
							var ser = [~a029744.(11), (1,2..11)].choose.scramble[..4];
							var rat = [3, 4].choose;
							var sound, out;
							// deg
							~orgDegNote = ~degOrg+(12*rat);
							sound = BrownNoise.ar(0.001);
							sound = DynKlank.ar(`[~orgDegNote.midicps*ser, {a=({1.0.rand}!3).normalizeSum*~tpsOrg;EnvGen.kr(Env.linen( a[0], a[1], a[2]))}!harm,{10.0.rand}!harm], sound);
							sound = sound * EnvGen.kr(Env.linen(~tpsOrg/4, ~tpsOrg, ~tpsOrg+1));
							// int
							~orgIntNote = ~orgDegNote+~intOrg-11;
							out = BrownNoise.ar(0.001);
							out  = DynKlank.ar(`[~orgIntNote.midicps*ser, {a=({1.0.rand}!3).normalizeSum*~tpsOrg*2;EnvGen.kr(Env.linen(a[0], a[1], a[2]))}!harm,{10.0.rand}!harm], out);
							out = out * EnvGen.kr(Env.linen(~tpsOrg, 1, ~tpsOrg*2))*0.5;
							// mix
							sound = HPF.ar(sound+out, 120);
							sound = LPF.ar(sound*0.5, 1200);
							// effect
							4.do{sound = DelayC.ar(sound, 0.4, 0.4.rand, 1, sound) };
							sound = FreeVerb.ar(Distance.ar(sound, 0.5), 0.7, 100);
							DetectSilence.ar(sound, doneAction: 2);
							Out.ar(i, sound.tanh*\amp.kr(~ampOrg).varlag(0.5)*2);
						}.play(~groupOrg)
					}
				};
			}
		}.defer;
	}, '/N3', recvPort:7772
);

)
