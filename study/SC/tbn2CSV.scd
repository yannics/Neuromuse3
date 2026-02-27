// procedure to select relevant play according to a given set of parameters
// then extract the pitches at different points in time and report in a CSV file
// from this CSV file, record all sounds for further analysis
// report in the CSV file ...
// NOTE: the roughness evaluation is comprehensively empirical but works with enough of relevance to be used in this current context with the brass physical model despite its extrem simplified basic computation...

s.boot;
// load synth...
/*
// /!\ IMPORTANT --------------------------------------------
// add or uncomment the following in the SynthDef before Out.ar
# freq, hasFreq = Pitch.kr(signal, clar:1);
freq.poll(t_poll, "label", 1);
*/
thisProcess.interpreter.executeFile("".resolveRelative +/+ "synths.scd");

(
// initialise the learning matrix to analyse...
// setting the parameters and their respective range...
~array2learn=[];
(0.1, 0.2..1.0).do
{
	|pressure|
	(0.1, 0.2..1.0).do
	{
		|lipsTension|
		(0.1, 0.2..2.5).do
		{
			|tubeLength|
			~array2learn=~array2learn.add([pressure, lipsTension, tubeLength])
		}
	}
};

// path of the file csv...
~csvPath="".resolveRelative +/+ "csv/tbn.csv";

// convert an array to a string with a delimiter...
~array2string = {
	|array, delimiter=", "|
	var str="";
	array.do{|i| str=str++i.asString++delimiter};
	str[..str.size-delimiter.size-1]
};

~thresClar=0.1; // threshold as minimal value of reliability
~delayRange= [0.1, 0.1, 0.1, 0.2, 0.5];
//~delayRange= [0.1, 0.2, 0.3, 0.5, 1, 1.5]; // analyse at different time offset (for instance instable signal)
~mainRoutineStepDuration=~delayRange.sum+1; // should be superior to ~delayRange.sum

// function to select potential relevant play...
~getFreqDel = {
	|subseq, i|
	var red=subseq.reshape((subseq.size/2).asInteger, 2).maxItem{|it| it[1]};
	if (red[1]>~thresClar)
	{
		File.use(~csvPath, "a", { |f| f.write(format("%, %\n",
			~array2string.(red),
			~array2string.(~array2learn[i])
		))})
	}
};

// convert seconds to h/m/s ...
~sec2hm = {
	|sec|
	format("%h%m%s", (sec/3600).trunc.asInteger, ((sec/60)-((sec/3600).trunc*60)).trunc.asInteger, (sec-((sec/60).trunc*60)).round.asInteger)
};

// routine playing synth and grab pitch at different times (according to the ~delayRange)
~subRoutine = { |i|
	var in=~array2learn[i];
	~array2play=[];
	Routine {
		// adjust the synth with its parameters...
		~theSynth=Synth(\tbn, [\pressure, in[0], \lipstension, in[1], \tubelength, in[2]]);
		~delayRange.do
		{
			|del|
			del.wait;
			~theSynth.set(\t_poll,1);
		};
		~theSynth.free;
		~getFreqDel.(~array2play.postln, i);
		// time remaining...
		format("% ... % left...", ~sec2hm.(~array2learn.size-i-1*~mainRoutineStepDuration), ~array2learn.size-i-1).postln;
	}.play;
};

// initiate osc to collect pitch and reliability...
~oscServer = OSCFunc({arg msg; ~array2play=~array2play.add(msg.last.asFloat)}, '/tr', s.addr);
)

//+++++++++++++++++++++++++++++++++++++++

(
// activate pitch analysis process
// start a new csv file...
File.delete(~csvPath);

// how long to get the cvs file...
format("This wil take % ... have a coffee ... :-)", ~sec2hm.(~array2learn.size*~mainRoutineStepDuration)).postln;

// writting csv file with potential relevant play...
r = Routine {
	~array2learn.size.do
	{
		|i|
		~subRoutine.(i);
		~mainRoutineStepDuration.wait
	};
	"csv completed... :-)".postln;
}.play
)

//+++++++++++++++++++++++++++++++++++++++

(
// read csv file as array
~x = CSVFileReader.readInterpret(~csvPath);

// recording for roughness analysis... and more...
/*
// /!\ IMPORTANT --------------------------------------------
// rewrite makePath method (line 173) from file Recorder.sc
// in order to grab ~timestamp of the current recorded synth
// and its full pathname as ~recpath
makePath {
		var timestamp, path;
		var dir = thisProcess.platform.recordingsDir;
		timestamp = Date.localtime.stamp;
		~timestamp=timestamp;
		path = dir +/+ filePrefix ++ timestamp ++ "." ++ this.recHeaderFormat;
		~recpath=path;
		^path;
	}
*/

~recDir=(PathName(~csvPath.dirname).pathOnly +/+ "rec/").mkdir;
thisProcess.platform.recordingsDir = ~recDir;
s.recHeaderFormat = "wav";

~recCSV = { |i|
	var in=~x[i][2..];
	Routine {
		~theSynth=Synth(\tbn, [\pressure, in[0], \lipstension, in[1], \tubelength, in[2]]);
		s.record(duration:~delayRange.sum);
		~delayRange.sum.wait;
		~theSynth.free;
		s.sync;
	}.play;
};

//~roughness="/Users/yannics/bin/roughness";
~roughness="/Users/yannics/bin/enkode";
)

(
~csvPathIDPPRRRSRA="".resolveRelative +/+ "csv/tbn_ref.csv";
r = Routine {
	~x.size.do
	{
		|i|
		format("---> % left to record ...", ~x.size-i).postln;
		~recCSV.(i);
		~mainRoutineStepDuration.wait;
		//---------------------------
		//~roughnessAr=(~roughness+~recpath).unixCmdGetStdOutLines;
		~roughnessAr=(~roughness+"-re"+~recpath+"|xargs").unixCmdGetStdOut.asString.split($ );
		File.use(~csvPathIDPPRRRSRA, "a", { |f| f.write(format("%, %, %, %",
			// ID -->
			~timestamp.split(separator:$_)[1],
			// tbn parameter (P) -->
			~array2string.(~x[i][2..]),
			// pitch + reliability (PR) -->
			~array2string.(~x[i][..1]),
			// roughness + reliability + sone + reliability + amplitude (db) (RRSRA) -->
			~array2string.(~roughnessAr)
		))});
		//---------------------------
		s.sync;
	};
	"recCSV completed... :-)".postln;
}.play
)

//+++++++++++++++++++++++++++++++++++++++

/*
// initial script implemented in enkode from version 7.0 with the option -re
// ~roughness="/Users/yannics/bin/roughness";
// analysis done with the bash script roughness
// - Praat analysis for the loudness profile (time step 0.001)
// - lisp for computation:
//   - get peaks from the loudness profile
//   - get mean of reciprocal periods as ∆t of the peaks
//   - get mean amplitude as ∆l (as loudness in sone unit) of two consecutive peaks
//   - add reliability with the standard deviation such as (- 1 (std-dev (normalize ∆t|∆l)))
#!/bin/bash

# $1 audio file
# $2 time step
# $3 streamline parameter
#    if $3 is a float then streamline with threshold
#    if $3 is an integer and > 1 then streamline with window size

tspa=$2
slp=$3

dirpraat='/Applications/Praat.app/Contents/MacOS/Praat'
dirsbcl='/opt/local/bin/sbcl'

usage(){
    echo "Usage: roughness sound_file [SERIAL_OPTIONS] time_step streamline_parameter"
}

version(){
    echo "Version 1.0.1"
}

get_abs_filename() {
    # $1 : relative filename
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

# check if some needed command line are installed
check_if_installed(){
    if which $1 >/dev/null
    then :
    else
	echo "bash: $1: command not found"
	echo "Please install $1 to run this program"
	if [ -z "$2" ]
	then :
	else
	    echo $2
	fi
	if [ -z "$START" ]
	then :
	else
	    rm -rf $workDir/.tmp*
	fi
	exit 1
    fi
}

dirpraat='/Applications/Praat.app/Contents/MacOS/Praat'
if [ ! -e $dirpraat ]
then check_if_installed praat; dirpraat=`readlink -f $(which praat)`;
fi
dirsbcl='/opt/local/bin/sbcl'
if [ ! -e $dirsbcl ]
then dirsbcl='/usr/local/bin/sbcl'
     if [ ! -e $dirsbcl ]
     then dirsbcl=`pwd`/sbcl
	  if [ ! -e $dirsbcl ]
	  then check_if_installed sbcl; dirsbcl=`readlink -f $(which sbcl)`;
	  fi
     fi
fi

soundpath=$(get_abs_filename "$1")

workDir=$(dirname $soundpath)

mkdir $workDir/tmp/

# time step Praat analysis -- 0.001 by default
if [ -z $tspa ]
then
    tspa=0.001
else
    tspa=$2
fi

# no streamline by default
if [ -z $slp ]
then
    slp=nil
else
    slp=$3
fi

#if [ -z $var ]; then echo "var is unset"; else echo "var is set to '$var'"; fi

# ---------------------------------------------
# script PRAAT
echo "form Get loudness profil
	sentence file ...
endform

Read from file... 'file$'
current_sound$ = selected$ (\"Sound\")
td = Get total duration
select Sound 'current_sound$'
do (\"To Cochleagram...\", $tspa, 0.1, 0.03, 0.03)
Rename: \"cochlea\"

select Sound 'current_sound$'
To Intensity: 100, 0, \"yes\"
amp = Get mean: 0, 0, \"energy\"
fileappend $workDir/tmp/amp 'amp'

a = 0
tps = 0
while 'tps' < 'td'
  selectObject: \"Cochleagram cochlea\"
  tps = a*$tspa
  To Excitation (slice): 'tps'
  dat = do(\"Get loudness\")
  fileappend $workDir/tmp/profile 'dat' 'newline$'
  selectObject: \"Excitation cochlea\"
  Remove
  a = a+1
endwhile

select all
Remove" > $workDir/tmp/cochlea.praat

$dirpraat --run $workDir/tmp/cochlea.praat $soundpath

# ---------------------------------------------
echo ";; read loudness profile file
(defun read-file (file)
  (mapcar #'read-from-string
	  (with-open-file (in-stream file
				     :direction :input
				     :element-type 'character)
	    (loop with length = (file-length in-stream)
	       while (< (file-position in-stream) length)
	       collect (read-line in-stream)))))

;; format data to a valid sequence

(defun mk-seq (profil &optional (tspa 0.001))
  (let (r) (dotimes (i (length profil) r) (push (* tspa i) r))
       (mapcar #'list (reverse r) profil)))

;; get primitive

(defun minmax (seq)
  (let ((r (list (cons 0 (car seq)))))
    (loop for i in (cdr seq)
       do
	 (cond ((= (caddar r) (cadr i)) (push (cons 0 i) r))
	       ((< (caddar r) (cadr i)) (push (cons 1 i) r))
	       ((> (caddar r) (cadr i)) (push (cons -1 i) r))))
    r))

;; get peaks and valleys

(defun stream-minmax (seq)
  (let ((r (list (car seq))))
    (loop for e in (cdr seq)
       do
	 (when (not (or (equalp (car e) (caar r)) (equalp (car e) 0))) (push e r))) (append (last seq) r)))

(defun peaks (seq)
  (let ((r)
	(m-lst (stream-minmax (minmax seq))))
    (loop for i in m-lst do (when (= 1 (car i)) (push i r)))
    (if (= -1 (caadr m-lst))
	(cons (cdar m-lst) (mapcar #'cdr (reverse r)))
        (mapcar #'cdr (reverse r)))))

(defun valleys (seq)
  (let ((r)
	(m-lst (stream-minmax (minmax seq))))
    (loop for i in m-lst do (when (= -1 (car i)) (push i r)))
    (if (= 1 (caadr m-lst))
	(cons (cdar m-lst) (mapcar #'cdr (reverse r)))
        (mapcar #'cdr (reverse r)))))

 ;; streamline ...

 (defun arithm-weight-mean (lst)
  (if (= 1 (length lst)) (car lst)
      (let ((lst1 (mapcar #'car lst)) (lst2 (if (zerop (eval (cons '+ (mapcar #'cadr lst))))
						(mapcar #'(lambda (x) (1+ x)) (mapcar #'cadr lst))
						(mapcar #'cadr lst))))
	(list
	 (* 1.0 (/ (eval (cons '+ (mapcar #'* lst1 lst2))) (eval (cons '+ lst2))))
	 (* 1.0 (/ (eval (cons '+ (mapcar #'* lst2 lst1))) (eval (cons '+ lst1))))))))

(defun streamline (seq &optional opt)
  (cond ((null opt) (mapcar #'cdr (stream-minmax (minmax seq))))
	((floatp opt)
	 (let ((look-lst (list (car seq)))
	       (temp-lst (list (car seq)))
	       (out-lst))
	   (loop for e in (cdr seq)
		 do
		    (if (> (abs (- (cadar look-lst) (cadr e))) (abs opt))
			(progn (push e look-lst) (push (arithm-weight-mean temp-lst) out-lst) (setq temp-lst '()) (push e temp-lst))
			(progn (push e look-lst) (push e temp-lst)))) (reverse out-lst)))
	((and (integerp opt) (> opt 1))
	 (remove nil (maplist #'(lambda (x) (if (> opt (length x)) nil (arithm-weight-mean (subseq x 0 opt)))) seq)))
	(t seq)))

;; standard deviation

(defun mean (lst) (/ (reduce #'+ lst) (length lst)))
(defun normalize (lst) (let ((maxval (reduce #'max lst))) (loop for i in lst collect (/ i maxval))))
(defun std-dev (lst) (let ((meanval (mean lst))) (sqrt (/ (loop for i in lst sum (expt (- i meanval) 2)) (length lst)))))

;;-----------------------------------" > $workDir/tmp/roughness.lisp

echo "(defparameter *profil* (read-file \"$workDir/tmp/profile\"))" >> $workDir/tmp/roughness.lisp

echo "(defparameter *peaks* (peaks (streamline (mk-seq *profil* $tspa) $slp)))" >> $workDir/tmp/roughness.lisp

echo "(defparameter *periods* (loop for i from 0 to (- (length *peaks*) 2) collect (- (car (nth (1+ i) *peaks*)) (car (nth i *peaks*)))))" >> $workDir/tmp/roughness.lisp

echo "(defparameter *amps* (loop for i from 0 to (- (length *peaks*) 2) collect (abs (- (cadr (nth (1+ i) *peaks*)) (cadr (nth i *peaks*))))))" >> $workDir/tmp/roughness.lisp

echo "(with-open-file (str \"$workDir/tmp/res\"
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format str \"~S~&~S~&~S~&~S\" (/ 1 (mean *periods*)) (- 1 (std-dev (normalize *periods*))) (mean *amps*) (- 1 (std-dev (normalize *amps*)))))" >> $workDir/tmp/roughness.lisp

$dirsbcl --script $workDir/tmp/roughness.lisp

cat $workDir/tmp/res
echo ""
cat $workDir/tmp/amp
echo ""
rm $workDir/tmp/res $workDir/tmp/cochlea.praat $workDir/tmp/roughness.lisp $workDir/tmp/profile $workDir/tmp/amp
rmdir $workDir/tmp
*/