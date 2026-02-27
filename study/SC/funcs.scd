(
//https://oeis.org/A029744
~a029744 = {
	|n=6|
	[1]++(2,3..n.asInteger).collect{
		|it|
		(it.even).if
		(
			{2**(it/2)},
			{3*(2**((it-3)/2))}
		).asInteger
	}
};

~staccato={ |dur, synth| { dur.wait; synth.set(\gate, 0) }.fork };

~processNearest =
{ |deg, dur|
	~tbnBuf.free;
	~tbnBuf = Buffer.loadCollection(s, ~previous, action: {
		~deg2tree.(deg).kNearest(~tbnBuf, action:{ |idl|
			var id;

			if (~dnorm.findKeyForValue(~previous).asInteger == idl[0].asInteger)
			{
				// choose other deg (kind of bisbigliando)
				if (~nearestUnisson)
				{id=idl[1..].choose.asInteger}
				{id=idl[1..][~count.mod(idl.size-1)].asInteger; ~count=~count+1}
			}
			{id=idl[0].asInteger; ~count=0;};

			~previous=~dnorm[id];
			//~previous[4..].postln;

			~dsref.getPoint(id, ~tbnBuf, {~tbnBuf.getn(0, 10, {|x|
				~groupTbn.set(
					"pressure", x[0],
					"lipstension", x[1],
					"tubelength", x[2],
					"vt", ~glissando * dur,
					"vl", ~glissando * dur,
					"vp", ~glissando * dur,
					//"del", 0.2.linrand,
					"gate", 1
				);
				~staccato.(~stacDur.clip(0.0001, dur), ~groupTbn);
			})}) // end .getPoint
		}) // end .kNearest
	}) // end Buffer.loadCollection
};

~processNoise =
{ |deg1, deg2, duration|
	var freqs = (60..72).midicps;
	var pbf = { |deg, dur|
		~bassNoiseBuf.free;
		~bassNoiseBuf = Buffer.loadCollection(s, ~prevOrg, action: {
			~deg2tree.(deg).kNearest(~bassNoiseBuf, action: { |idl|
				var id;
				if (~dnorm.findKeyForValue(~prevOrg).asInteger == idl[0].asInteger)
				{id=idl[1..].choose.asInteger}
				{id=idl[0].asInteger};
				~bnbuf=~loader.select{|buf| buf.path.findAllRegexp(id.asString).isEmpty.not}[0];
				Synth(\noise, [\buf, ~bnbuf, \numFrames, ~bnbuf.numFrames, \amp, ~volNoise, \dur, dur, \pulseFreq, freqs[deg]], ~groupNoise);
			})
	})};
	// display frequency
	Routine.new(
		{
			pbf.(deg1, duration);
			//format("pbf process 1... dur = %", duration).postln;
			//{~recv4.string = "[" + freqs[deg1].asInteger.asString.padLeft(4," ") + "]"}.defer;
			(duration/2).wait;
			pbf.(deg2, duration);
			//format("pbf process 2... dur = %", duration).postln;
			//{~recv4.string = "[" + freqs[deg2].asInteger.asString.padLeft(4," ") + "]"}.defer;
		}
	).play
};

// requires gsa.sc + MarkovSet.sc Yann Ics branch
// ---> https://github.com/yannics/GSA
// ---> https://github.com/yannics/MathLib/tree/yannics-patch-1
thisProcess.interpreter.executeFile("".resolveRelative +/+ "/import/chord.scd");
~markovHarm = MarkovSet.new(remanence: 3, updateSeeds: true);
"Wait a minute ...".postln;
~markovHarm.parseSeq(~chord, {"Parsing data completed!".postln});

~degContext = {
	|current_deg_fl, deg_org, int_org, next_deg_fl, markovset|
	var currentOrg = [deg_org, (deg_org+int_org-11)%12];
	var currentHarmContext = current_deg_fl.asArray ++ currentOrg;
	var nextHarmContext = next_deg_fl.asArray ++ currentOrg;
	var res = markovset.nextIncludes(currentHarmContext, nextHarmContext);
	var diff = res.difference(nextHarmContext);
	if (diff.isEmpty) {res} {diff};
};

)