(
var w = Window("Untitled #2: Unfolding work", Rect(Window.screenBounds.width-360, Window.screenBounds.height, 525, 438));
w.front.alwaysOnTop_(true). background_(Color.black);
w.view.decorator = FlowLayout(w.view.bounds);
w.alpha = 0.7;
l=82;
//-----------------------------------------
// INSTRUMENT
~tFl = StaticText(w,l@30).background_(Color.black).string_("Flute").align_(\center).stringColor_(Color.white);
~tTbn = StaticText(w,l*2@30).background_(Color.black).string_("Trombone").align_(\center).stringColor_(Color.white);
~tOrg = StaticText(w,l@30).background_(Color.black).string_("Orgue").align_(\center).stringColor_(Color.white);
~tNoise = StaticText(w,l@30).background_(Color.black).string_("Noise").align_(\center).stringColor_(Color.white);
~tUlam = StaticText(w,l@30).background_(Color.black).string_("Ulam").align_(\center).stringColor_(Color.white);
//~tNoise=Button(w, l@30).states_([["Noise",Color.white, Color.black],["Ulam",Color.white, Color.black]]);
//~tNoise.action_({|butt|~noiseUlam=butt.value; if(~noiseUlam==0){~modeButt.visible_(false)} {~modeButt.visible_(true)}});
w.view.decorator.nextLine;
//-----------------------------------------
// IP/SWITCH
~ipFl=StaticText(w,l@20).string_("127.0.0.1").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 9));
~voidtbn=StaticText(w,l@20).string_("unisson > ").align_(\right).stringColor_(Color.white).font_(Font("Monaco", 10));
~flOrgButt=Button(w, l+5@20).states_([["flute",Color.black, Color.gray(0.8)],["orgue",Color.black, Color.gray(0.8)]]);
~flOrgButt.action_({|butt|~unisson=butt.value; if((~unisson==0) && (~rtm==1)){~voidtbn.string="harmony > "} {~voidtbn.string="unisson > "}});
~ipOrg=StaticText(w,l@20).string_("127.0.0.1").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 9));
~voidNoise=StaticText(w,l@20).string_("mode  > ").align_(\right).stringColor_(Color.white).font_(Font("Monaco", 11));
~modeButt=Button(w, l@20).states_([["reson", Color.black, Color.gray(0.8)],["sine", Color.black, Color.gray(0.8)]]);
~modeButt.action_({|butt|~modeUlam=butt.value});
w.view.decorator.nextLine;
//-----------------------------------------
// PORT/SWITCH
~portFl=StaticText(w,l@20).background_(Color.grey).string_("7771").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 12));
~nearRndButt=Button(w, l*2+9@20).states_([["Nearest",Color.black, Color.gray(0.8)],["Random",Color.black, Color.gray(0.8)]]);
~nearRndButt.action_({|butt|~nearestUnisson=1-butt.value});
~portOrg=StaticText(w,l@20).background_(Color.grey).string_("7772").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 12));
~voidNoise=StaticText(w, l@20).background_(Color.grey).string_("Hz").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 12));
~voidUlam=StaticText(w, l@20).background_(Color.grey).string_("").align_(\center).stringColor_(Color.white).font_(Font("Monaco", 12));
w.view.decorator.nextLine;
//-----------------------------------------
// OSC-MSG/SWITCH
~recv1=StaticText(w,l@20).background_(Color.black).align_(\left).stringColor_(Color.red);
~recv1.font_(Font("Monaco", 10));
~recv1.string = " > ";
~recv2=StaticText(w,l@20).background_(Color.black).align_(\left).stringColor_(Color.red);
~recv2.font_(Font("Monaco", 10));
~recv2.string = " > ";
~rtmButt=Button(w, l+5@20).states_([["RTM",Color.black, Color.gray(0.8)],["RTM",Color.white, Color.gray(0.2)]]).value_(1);
~rtmButt.action_({|butt|~rtm=1-butt.value; if((~unisson==0) && (~rtm==1)){~voidtbn.string="harmony > "} {~voidtbn.string="unisson > "}});
~recv3=StaticText(w,l@20).background_(Color.black).align_(\left).stringColor_(Color.red);
~recv3.font_(Font("Monaco", 10));
~recv3.string = " > ";
~recv4=StaticText(w,l@20).background_(Color.black).align_(\left).stringColor_(Color.red);
~recv4.font_(Font("Monaco", 10));
~recv4.align=\center;
~recv4.string = "[      ]";
~recv5=StaticText(w,l@20).background_(Color.black).align_(\left).stringColor_(Color.red);
~recv5.font_(Font("Monaco", 10));
~recv5.align=\center;
~recv5.string = "[      ]";
w.view.decorator.nextLine;
//-----------------------------------------
// SLIDDER
~volFl=EZSlider(w, l/2-2@300, "  Vol.", \db.asSpec.step_(0.01).default_(-inf),unitWidth:0, numberWidth:60,layout:\vert);
~volFl.action_({|ez|~ampFl=ez.value.dbamp; ~groupFl.set("amp", ~ampFl*0.05)});
~volFl.setColors(Color.grey,Color.white);
~stacFl=EZSlider(w, l/2-2@300, "  Stac.", ControlSpec(10, 0.01, \exp, 0.001, 10),unitWidth:0, numberWidth:60,layout:\vert);
~stacFl.action_({|ez|~stacFl=ez.value});
~stacFl.setColors(Color.grey,Color.white);
~distTbn=EZSlider(w, l*2/3@300, "  Dist.", ControlSpec(1, 0, \lin, 0.01, 1), unitWidth:0, numberWidth:60,layout:\vert);
~distTbn.setColors(Color.grey,Color.white);
~distTbn.action_({|ez| ~distGroupTbn.set(\dist, ez.value, \amp, 4)});
~stacTbn=EZSlider(w, l*2/3@300, "  Stac.", ControlSpec(10, 0.01, \exp, 0.001, 10), unitWidth:0, numberWidth:60,layout:\vert);
~stacTbn.setColors(Color.grey,Color.white);
~stacTbn.action_({|ez|~stacDur=ez.value});
~glissTbn=EZSlider(w, l*2/3@300, "  Gliss.", ControlSpec(0.1, 1, \lin, 0.01, 0.1), unitWidth:0, numberWidth:60,layout:\vert);
~glissTbn.setColors(Color.grey,Color.white);
~glissTbn.action_({|ez|~glissando=ez.value});
~volOrg=EZSlider(w, l@300, "  Volume", \db.asSpec.step_(0.01).default_(-inf), unitWidth:0, numberWidth:60,layout:\vert);
~volOrg.setColors(Color.grey,Color.white);
~volOrg.action_({|ez|~ampOrg=ez.value.dbamp;~groupOrg.set(\amp,~ampOrg)});
~volNoise=EZSlider(w, l@300, "  Volume", \db.asSpec.step_(0.01).default_(-inf), unitWidth:0, numberWidth:60,layout:\vert);
~volNoise.setColors(Color.grey,Color.white);
~volNoise.action_({|ez| ~groupNoise.set(\amp,ez.value.dbamp)});
~volUlam=EZSlider(w, l/2-2@300, "  Vol.", \db.asSpec.step_(0.01).default_(-inf), unitWidth:0, numberWidth:60,layout:\vert);
~volUlam.setColors(Color.grey,Color.white);
~volUlam.action_({|ez| ~revGroupUlam.set(\amp, ez.value.dbamp)});
~dwNoise=EZSlider(w, l/2-2@300, "  d/w", ControlSpec(0, 1, \lin, 0.01, 0.5), unitWidth:0, numberWidth:60,layout:\vert);
~dwNoise.setColors(Color.grey,Color.white);
~dwNoise.action_({|ez| ~revGroupUlam.set(\mix, ez.value)});
w.view.decorator.nextLine;
//-----------------------------------------
~pp1=Button(w, l@20).states_([["🔈",Color.black, Color.gray(0.8)],["🔇",Color.white, Color.gray(0.2)]]).value_(1);
~pp1.action_({|butt|~mute1=butt.value.asBoolean; if(~mute1)
	{
		~fla.free; ~flb.free; ~flc.free; ~fld.free;
		~recv1.stringColor_(Color.red);
		~recv1.string = " >"
	}
	{
		~fla = Synth(\wFlute, [\out, ~revBusFla], ~groupFl);
		~flb = Synth(\wFlute, [\out, ~revBusFlb], ~groupFl);
		~flc = Synth(\wFlute, [\out, ~revBusFlc], ~groupFl);
		~fld = Synth(\wFlute, [\out, ~revBusFld], ~groupFl);
		~groupFl.set("amp", ~ampFl*0.05)
	}
});
~pp2=Button(w, l*2+9@20).states_([["🔈",Color.black, Color.gray(0.8)],["🔇",Color.white, Color.gray(0.2)]]).value_(1);
~pp2.action_({|butt|~mute2=butt.value.asBoolean; if(~mute2)
	{
		~tbna.free; ~tbnb.free;
		~recv2.stringColor_(Color.red);
		~recv2.string = " >"
	}
	{
		~tbna = Synth(\tbn, [\out, ~distBusTbna], ~groupTbn);
		~tbnb = Synth(\tbn, [\out, ~distBusTbnb], ~groupTbn);
	}
});
~pp3=Button(w, l@20).states_([["🔈",Color.black, Color.gray(0.8)],["🔇",Color.white, Color.gray(0.2)]]).value_(1);
~pp3.action_({|butt|~mute3=butt.value.asBoolean; if (~mute3) { ~recv3.string = " >" }});
~pp4=Button(w, l@20).states_([["🔈",Color.black, Color.gray(0.8)],["🔇",Color.white, Color.gray(0.2)]]).value_(1);
~pp4.action_({|butt|
	~mute4=butt.value.asBoolean;
	if (~mute4.not)
	{ ~recv4.stringColor_(Color.white) }
	{ ~recv4.string = "[      ]"; ~recv4.stringColor_(Color.red) }
});
~pp5=Button(w, l@20).states_([["🔈",Color.black, Color.gray(0.8)],["🔇",Color.white, Color.gray(0.2)]]).value_(1);
~pp5.action_({|butt|
	~mute5=butt.value.asBoolean;
	if (~mute5.not)
	{ ~recv5.stringColor_(Color.white) }
	{ ~recv5.string = "[      ]"; ~recv5.stringColor_(Color.red) }
});
//-----------------------------------------
w.onClose_({ OSCdef.freeAll; s.freeAll });
)
