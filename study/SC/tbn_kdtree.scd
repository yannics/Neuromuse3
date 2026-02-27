(
// load CSV data
// [ id, pressure, lips_tension, tube_length, freq, <-%, roughness, <-%, <-amp, <-%, db ]
// [  0,        1,            2,           3,    4,   5,         6,   7,     8,   9, 10 ]

// empirical and approximate function to evaluate roughness as a kind of asper knowing that the maximum frequency roughness is around 70 Hz.
~asp = { |freq| exp(-0.00355*squared(freq.cpsmidi-37.175)) };

~csvPathIDPPRRRSRA="".resolveRelative +/+ "csv/tbn_ref.csv";
~ref = CSVFileReader.readInterpret(~csvPathIDPPRRRSRA);
// create reference dictionary
~dref = Dictionary.newFrom(~ref.collect{|i|[i[0],i[1..]]}.flatten);
// create normalised dictionary rejecting cols 4, 6, 8 respectively reliability of pitches, roughness and roughness amp
~dnorm = Dictionary.newFrom(~ref.flop.collect{|a, i| if (i==0) {a} {if (i==6) {a.collect{|freq| ~asp.(freq)}.normalize} {a.normalize}}}.flop.collect{|i|[i[0],i[1..].reject{|it, ind| [4, 6, 8].includes(ind)}]}.flatten);
// utils
~deg2tree = { |i| "~treeDeg%".format(i).interpret};

// ref dataset
d = Dictionary.new;
d.add(\cols -> 10);
d.add(\data -> ~dref);
fork{ ~dsref = FluidDataSet.new(s); ~dsref.load(d); s.sync; };

// norm dataset
e = Dictionary.new;
e.add(\cols -> 7);
e.add(\data -> ~dnorm);
fork{ ~dsnorm = FluidDataSet.new(s); ~dsnorm.load(e); s.sync; };

// kdtree for each deg
(0..11).do{
	|ideg|

	fork{

		f = Dictionary.new;
		f.add(\cols -> 7);
		f.add(\data -> Dictionary.newFrom(~dref.select{|a| a[3].cpsmidi.round.mod(12).asInteger == ideg}.keys.collect{|k| [k,~dnorm[k]]}.asArray.flatten(1)));

		("~dsDeg%".format(ideg) + "= FluidDataSet.new(s)").interpret;
		"~dsDeg%".format(ideg).interpret.load(f);
		s.sync;
		("~treeDeg%".format(ideg) + "= FluidKDTree(s,numNeighbours:0)").interpret;
		"~treeDeg%".format(ideg).interpret.fit("~dsDeg%".format(ideg).interpret);
		s.sync;
	};
};

~tbnBuf = Buffer.new;
// init ~previous randomly
~previous = ~dnorm.choose;
// or according to a given deg
//~previous = "~dsDeg%".format(0).interpret.dump{|d| ~previous=d["data"].choose};
// or according to the roughness or else
//~previous = ...
~bassNoiseBuf = Buffer.new;
~prevOrg = ~dnorm.choose;
)

/*
TODO
- manage Lag transition as 'mode de jeu'
*/

//~dnorm.values.collect{|i|i.last}.mean
//~dnorm.values.collect(_.last).mean



