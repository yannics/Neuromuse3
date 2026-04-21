(
/*
SynthDef(\rev4, {
	arg
	in = 0,
	out = 0,
	predelaytime = 0.048,
	decaytimec = 5,
	decaytimea = 1,
	drywet = 0.5,
	level = 0.2;
	var input, numc, numa, temp;
	input = In.ar(in, 4);
	numc = 4; // number of comb delays
	numa = 6; // number of allpass delays
	temp = DelayN.ar(input, 0.1, predelaytime);
	temp = Mix.fill(numc, { CombL.ar(temp, 0.1, rrand(0.01, 0.1), decaytimec) });
	numa.do({ temp = AllpassN.ar(temp, 0.051, rrand(0.01, 0.05), decaytimea) });
	XOut.ar(out, drywet, temp * level.curvelin(0, 1, 0, 1, log(10)));
}).add;
*/
SynthDef(\rev4, {
	// basic reverb from Eli Fieldsteel
	// https://youtu.be/oR4VZy2LJ60?t=1680
	|in, predelay=0.1, revtime=10, lpf=4500, mix=0.5, amp=1, out=0|
	var dry, wet, temp, sig;
	dry = In.ar(in, 4);
	temp = In.ar(in, 4);
	wet = 0;
	temp = DelayN.ar(temp, 0.2, predelay);
	16.do {temp = AllpassN.ar(temp, 0.05, {Rand(0.001, 0.05)}!4, revtime);
		temp=LPF.ar(temp, lpf);
		wet = wet + temp;
	};
	sig = XFade2.ar(dry, wet, mix*2-1, amp); // 0 = 100% dry, 1 = 100% wet
	Out.ar(out, sig);
}).add;

SynthDef(\rev0, {
	arg
	in=60,
	out=0,
	amp=0.8,
	mix=0.06,
	lpf=5000,
	rev=2.5,
	dec=0.05,
	del=0.003;
	var wet, dry, temp, sig;
	mix=mix.clip(0.1);
	temp=In.ar(in,1);
	wet=0;
	temp=DelayN.ar(temp, dec, dec);
	16.do{
		temp=AllpassN.ar(temp, 0.06, Rand(0.001, 0.06), rev);
		temp=LPF.ar(temp, lpf);
		wet=wet+temp;
	};
	XOut.ar(out, mix, temp);
}).add;

SynthDef("wFlute", { arg out=0, pch = 72, ibreath = 0.09, ifeedbk1 = 0.4, ifeedbk2 = 0.4, gate = 1, amp = 0, lag = 0.5;
	var kenv1, sr, cr, block;
	var signalOut, ifqc;
	var aflow1, asum1, asum2, afqc, ax, apoly, asum3, avalue, aflute1;
	var fdbckArray;
	sr = SampleRate.ir; // 44100.0
	cr = ControlRate.ir; // 689.062 -- 0.0014512482185928
	block = cr.reciprocal;
	ifqc = pch.midicps;
	// noise
	kenv1 = PinkNoise.ar(0.3,1);
	// create air flow --- add respiration with VarLag
	aflow1 = LFClipNoise.ar( sr, kenv1 );
	asum1 = ( ibreath * aflow1 ) + kenv1 ;
	afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;
	fdbckArray = LocalIn.ar( 1 );
	aflute1 = fdbckArray;
	asum2 = asum1 + ( aflute1 * ifeedbk1 );
	ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );
	apoly = ax - ( ax.cubed );
	asum3 = apoly + ( aflute1 * ifeedbk2 );
	avalue = LPF.ar( asum3, 2000 );
	aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );
	fdbckArray = [ aflute1 ];
	LocalOut.ar( fdbckArray );
	signalOut = avalue * EnvGen.kr(Env.asr(0.001, 1, 0.1), gate);
	OffsetOut.ar( out, LeakDC.ar(signalOut) * amp.varlag(lag) );
}).add;

/*
source 1: https://github.com/retroriff/SuperCollider-SynthDefs/blob/master/Winds.scd

By Wilson, Cottle and Collins

source 2: https://github.com/dsheeler/supercollider_experiments/blob/master/ixi_SC_tutorial_10.sc

// Waveguide flute based upon Hans Mikelson's Csound slide flute (ultimately derived from Perry Cook's)
// STK slide flute physical model.  SuperCollider port by John E. Bower, who kindly allowed for the
// flute's inclusion in this tutorial.

// Please note that this instrument remains buggy. It's best used in lower registers ( alto or bass
// flute range ).  Intonation and tuning gets off as you go higher, especially above 72.midicps.
// This is a work in progress.  Please feel free to contribute any corrections via the sc-users
// list or by emailing me directly.  Thanks!

(

SynthDef("waveguideFlute", { arg scl = 0.2, pch = 72, ipress = 0.9, ibreath = 0.09, ifeedbk1 = 0.4,
							ifeedbk2 = 0.4, dur = 1, gate = 1, amp = 2;

	var kenv1, kenv2, kenvibr, kvibr, sr, cr, block;
	var poly, signalOut, ifqc;
	var aflow1, asum1, asum2, afqc, atemp1, ax, apoly, asum3, avalue, atemp2, aflute1;
	var fdbckArray;

	sr = SampleRate.ir;
	cr = ControlRate.ir;
	block = cr.reciprocal;

	ifqc = pch.midicps;

	// noise envelope
	kenv1 = EnvGen.kr(Env.new(
		[ 0.0, 1.1 * ipress, ipress, ipress, 0.0 ], [ 0.06, 0.2, dur - 0.46, 0.2 ], 'linear' )
	);
	// overall envelope
	kenv2 = EnvGen.kr(Env.new(
		[ 0.0, amp, amp, 0.0 ], [ 0.1, dur - 0.02, 0.1 ], 'linear' ), doneAction: 2
	);
	// vibrato envelope
	kenvibr = EnvGen.kr(Env.new( [ 0.0, 0.0, 1, 1, 0.0 ], [ 0.5, 0.5, dur - 1.5, 0.5 ], 'linear') );

	// create air flow and vibrato
	aflow1 = LFClipNoise.ar( sr, kenv1 );
	kvibr = SinOsc.ar( 5, 0, 0.1 * kenvibr );

	asum1 = ( ibreath * aflow1 ) + kenv1 + kvibr;
	afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;

	fdbckArray = LocalIn.ar( 1 );

	aflute1 = fdbckArray;
	asum2 = asum1 + ( aflute1 * ifeedbk1 );

	//ax = DelayL.ar( asum2, ifqc.reciprocal * 0.5, afqc * 0.5 );
	ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );

	apoly = ax - ( ax.cubed );
	asum3 = apoly + ( aflute1 * ifeedbk2 );
	avalue = LPF.ar( asum3, 2000 );

	aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

	fdbckArray = [ aflute1 ];

	LocalOut.ar( fdbckArray );

	signalOut = avalue;

	OffsetOut.ar( 0, [ signalOut * kenv2, signalOut * kenv2 ] );

}).load(s);

)

// test the flute
s.sendMsg("/s_new", "waveguideFlute", -1, 0, 0, "amp", 0.5, "dur", 5, "ipress", 0.90, "ibreath", 0.00536, "ifeedbk1", 0.4, "ifeedbk2", 0.4, "pch", 60 );

// test the flute player's skills:
(

Routine({
	var pitches, durations;

	pitches = Pseq( [ 47, 49, 53, 58, 55, 53, 52, 60, 54, 43, 52, 59, 65, 58, 59, 61, 67, 64, 58, 53, 66, 73 ], inf ).asStream;
	durations = Pseq([ Pseq( [ 0.15 ], 17 ), Pseq( [ 2.25, 1.5, 2.25, 3.0, 4.5 ], 1 ) ], inf).asStream;

	17.do({
		var rhythm;
		rhythm = durations.next;
		s.sendMsg("/s_new", "waveguideFlute", -1, 0, 0, "amp", 0.6, "dur", rhythm, "ipress", 0.93,
			"ibreath", 0.00536, "ifeedbk1", 0.4, "ifeedbk2", 0.4, "pch", pitches.next );
		rhythm.wait;
	});

	5.do({
		var rhythm;
		rhythm = durations.next;
		s.sendMsg("/s_new", "waveguideFlute", -1, 0, 0, "amp", 0.6, "dur", rhythm + 0.25, "ipress",
			0.93, "ibreath", 0.00536, "ifeedbk1", 0.4, "ifeedbk2", 0.4, "pch", pitches.next
		);
		rhythm.wait;
	});

}).play;
)
*/

SynthDef(\tbnfx, {
	arg
	in = 0,
	out = 0,
	rt60 = 5,
	mix = 0,
	dist = 0,
	del = 0,
	amp = 1;
	var src, sig;
	src = In.ar(in, 2);
	sig = NHHall.ar(src, rt60, 0);
	sig = Balance2.ar(src, sig, mix);
	sig = Distance.ar(sig, dist) * amp;
	Out.ar(out, DelayN.ar(sig, del));
	}
).add;

SynthDef(\tbn,
	{
		/*
		https://faust.grame.fr/
		--> install Faust (with MacPorts for instance):
		    $ sudo port install faust
		--> generate Brass Ugen from a Faust dsp file:
		    $ SUPERCOLLIDER_HEADERS=$HOME/supercollider-develop/include faust2supercollider brass.dsp -noprefix -ks
		  - required the header pointing out the SuperCollider source code path to the include directory
		  - -noprefix removes the standard Faust -prefix
		  - -ks as keep source (cpp file)
		--> then create a directory named brass (for instance) containing (at least) the .sc and .scx files and move it to the Platform.userExtensionDir
		*/
		| out=0, pressure=0.0, breathgain=0.1, breathcutoff=2000.0, vibratofreq=5.0, vibratogain=0.25, tubelength=0.5, lipstension=0.5, mute=0.5, vp=0.1, vl=0.1, vt=0.1, t_poll, gate=1 |
		var in, freq, hasFreq;
		in = Brass.ar(Lag.kr(pressure * EnvGen.kr(Env.asr(0.001, 1, 0.1), gate), vp), breathgain, breathcutoff, vibratofreq, vibratogain, Lag.kr(tubelength, vt), Lag.kr(lipstension, vl), mute);
		//# freq, hasFreq = Pitch.kr(in, clar:1, maxFreq:2000, minFreq:100);
		//freq.poll(t_poll, "tbn3", 1);
		Out.ar(out, in);
	}
).add;

SynthDef(\noise,
	{
		|out=0, buf, numFrames,
		//deg=9, oct=4,
		dur=1,
		pulseFreq=220, numapb=6,
		freqLFO=0.08333, bwLFO=0.08333, amp=0.5|
		var env, sig;
		env = EnvGen.kr(Env.linen(dur/2, dur/2, dur+1, 1, \sine), doneAction: 2);
		//env = EnvGen.kr(Env.triangle(dur, 1/2), doneAction: 2);
		sig = BBandStop.ar(
			BufRd.ar(
				2,
				buf,
				Stepper.ar(Impulse.ar(pulseFreq /*(deg+(12*oct)).midicps*/), 0, 1, numFrames, [10011, 10111, 10110, 10101])),
			//SinOsc.kr(dur.reciprocal,pi/2).linlin(-1,1,20,18000),
			//env.explin(0.01,1,20000,minf),
			LFDNoise1.ar(freqLFO, 5000, 5020),
			LFDNoise1.ar(bwLFO, 5, 5.001)) * env;
		numapb.do({ sig = AllpassN.ar(sig, 0.051, rrand(0.01, 0.05), rrand(0.5, 1)) });
		sig = Limiter.ar(sig, 0.1, 0.1) * 4 * amp;
		Out.ar(out, Limiter.ar(sig, 0.23, 0.1) * 4 * amp)
	}
).add;

)

/*
// generating image for documentation
// env orgue
(
a = 6;
d = [
	Env.linen(a/4, a, a+1, 1).discretize((2*a+(a/4)+1)*10).as(Array),
	Env.linen(a, 1, a*2, 1).discretize((a*3+1)*10).as(Array)];
p = d.plot(name:format("Env[orgue] (duration = %): [deg] -> black, [int] -> gray", a));
p.plotColor_([ Color.black, Color.gray(0.8)]);
p.superpose_(true);
p.setProperties(\gridColorX, Color.white,
  \gridColorY, Color.white,\fontColor, Color.white);
p.refresh;
)
// env noise
(
a = 6;
d = [
	Env.new(levels: [0, 1, 1, 0], times: [a/2, a/2, a+1], curve:\sine).discretize((a*2+1)*10).as(Array),
	Env.new(levels: [0, 0, 1, 1, 0], times: [a/2, a/2, a/2, a+1], curve:\sine).discretize((2*a+(a/2)+1)*10).as(Array)];
p = d.plot(name:format("Env[noise] (duration = %): [deg] -> black, [int] -> gray", a));
p.plotColor_([ Color.black, Color.gray(0.8)]);
p.superpose_(true);
p.setProperties(\gridColorX, Color.white,
  \gridColorY, Color.white,\fontColor, Color.white);
p.refresh;
)
*/

/*
For the SuperCollider documentation schelp relative to Faust, the following bash script (named faust4schelp) gives all needed informations from the DSP file.
Syntax: $ faust4schelp <faustFile>.dsp
--------------------------------------
#!/bin/bash

INFILE=$1

if [[ -e "$INFILE" ]]; then

	# Convert dsp to json
	BASENAME=${INFILE%.dsp}
	JSONNAME=$INFILE.json
	faust -json $INFILE -O . > /dev/null

	name=`jq -r '.name' $JSONNAME`
	version=`jq -r '.version' $JSONNAME`
	inputs=`jq -r '.inputs' $JSONNAME`
	outputs=`jq -r '.outputs' $JSONNAME`
	description=`jq -r '.meta[] | select(.description) | join("")' $JSONNAME`
	author=`jq -r '.meta[] | select(.copyright) | join("")' $JSONNAME`

	echo "-------------------------"
	echo "Name: $name"
	echo "Version: $version"
	echo "Author: $author" | sed -re 's/[(]c[)]//g'
	echo "Description: $description"
	echo "Inputs: $inputs"
	echo "Outputs: $outputs"
	echo "Arguments (init, min, max):"
	jq -r '.ui[] | .items[] | .items[] | [.label,.init,.min,.max] | @csv' $JSONNAME | sed -e "s/^/  /g;s/\"\,/\: /g;s/\"//g;s/\,/ /g"
	echo "-------------------------"

	# Delete json file
	rm $JSONNAME

else
	echo "Could not find $INFILE"
	exit
fi
--------------------------------------
*/