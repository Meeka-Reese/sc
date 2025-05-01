(
//======================================================GLOBAL VARIABLES =========================================================

~selectedObject = 0;


~positionsD0 = Dictionary();
~positionsD1 = Dictionary();
~positionsD2 = Dictionary();
~positionsD3 = Dictionary();
~positionsD4 = Dictionary();
~allPos = Dictionary();
~closePos = Dictionary();

~synthD0 = Dictionary();
~synthD1 = Dictionary();
~synthD2 = Dictionary();
~synthD3 = Dictionary();
~synthD4 = Dictionary();

~synthVolD0 = Dictionary();

~buttonsD0 = Dictionary();
~buttonsDSave = Dictionary();
//dictionaries to store synth and position data


~playerX = 0;
~playerY = 0;

~bounds = Rect(100,100,100,100);
~index0 = 0;
~index1 = 0;
~index2 = 0;
~index3 = 0;
~index4 = 0;
//instrument indexs
Server.default.freeAll;
Server.default.reboot;
s.options.memSize = 2.pow(20); //memory aloc cause this get's crazy sometimes

//=======================================================  CLASSES =========================================================
~buttonWithIndex = { |index, x, y,dictPos,dictSynth|
	var btn = Button.new(~buttonContainer, Rect(x + 40, y + 40, 20, 20)).states_([
		["X",Color.white,Color.red]
	])
	.action_({ |btn|
		dictPos.removeAt(index);
		dictSynth[index].stop;
		dictSynth.removeAt(index);
		btn.remove;
		w.refresh;
	});
	btn;
};
// Class to create all buttons with the same behaviour


//========================================================== SYNTH1 ==========================================================



SynthDef(\synth1, {
	|carrierFreq=440, carrierLvl=1, modulatorRatio=1, modulatorIndex=1, outputAmp=1, gate=1,freqmult=1,leftVol=1,rightVol=1,length=1,index=0,noiseLevel=1,positionX = 0, positionY = 0,playerX,playerY|
	var mod, sig, env, lfo,lfo2,lfo3, env2,lOut,rOut,arr,rlfo,verbMix, buffer,rms,noise,noiseEnv,rvbAm,dist;



	rvbAm = (((((positionX/540) - playerX) ** 2) + (((positionY/440) - playerY) ** 2)).sqrt).abs;
	//reverb based on distance
	carrierFreq = midicps(carrierFreq - 24);
	verbMix = 0.4;
	noise = WhiteNoise.ar(noiseLevel * 0.7);
	//length.value.postln;
	rlfo = SinOsc.kr(1) * 5;
	env = EnvGen.kr(
		Env([1, 0.5, 0.4, 0], [Clip.kr((0.2/(length)),0.01,0.05), 0.01, 0.1], 8),
		gate: Impulse.kr(4/length),
		doneAction: 2
	);
	noiseEnv = EnvGen.kr(
		Env([0, 1, 0.4, 0], [(length), 0.5, 1,0]),
		doneAction: 2
	);
	noise = noise * noiseEnv;

	env2 = EnvGen.kr(
		Env([1, 0.5, 0.4, 0], [Clip.kr((0.1/(length)),0.01,0.025), 0.01, 0.1], 8),
		gate: Impulse.kr(1/length),
		doneAction: 2
	);
	5.do
	{
		carrierFreq = (carrierFreq + env);
	};
	//Make the pitch more transient
	lfo = SinOsc.ar(carrierFreq + MouseX.kr * 4 * (1 + env * 2) * freqmult) * 0.1;
	lfo2 = SinOsc.ar((carrierFreq) - MouseX.kr * 4 * (1 + env * 2)) * 0.1;
	lfo3 = SinOsc.ar((carrierFreq * 2),0,0.1);
	//My instruments added together. The lfo name is misleading. MouseX.kr is kinda silly because I think it only get's evaluated at initialization but it is what it is


	sig = ((SinOsc.ar(carrierFreq, 0, carrierLvl) * outputAmp * 0.2) * env);
	sig = sig + lfo3;



	rOut = (lfo + lfo2 * env2) + sig;
	lOut = rOut;
	lOut = lOut + (rOut * 0.1);
	rOut = rOut + (lOut * 0.1);
	rOut = FreeVerb.ar(rOut,verbMix + (rightVol/4) + rvbAm,0.5,0.2) + (noise * (1 - rvbAm));
	lOut = FreeVerb.ar(lOut,verbMix + (leftVol/4) + rvbAm,0.5,0.2) + (noise * (1 - rvbAm));
	rOut = BHiPass.ar(rOut,clip(((rlfo * 5) + 200 + (500 * rvbAm)),20,5000),1);
	lOut = BHiPass.ar(lOut,clip(((rlfo * 5) + 200 + (500 * rvbAm)),20,5000),1);
	//summing, filter and effects

	arr = [lOut * leftVol *(1 - rvbAm),rOut*rightVol*(1 - rvbAm)];
	//panning
	rms = (Clip.kr(sig,-1,1));
	rms = Slew.kr(rms,50,50,1);

	SendReply.kr(Impulse.kr(20), '/volume', rms, index);
	//sending rms data to GUI

	Out.ar(0, arr);



}).add;
OSCdef(\volumeMonitor, { |msg|
	var index = msg[2];
	var volume = msg[3];


	~synthVolD0.put(index, volume);

}, '/volume');

//========================================================== SYNTH 2 ==========================================================

SynthDef(\synth2, {|note = 60, length=1, leftVol, rightVol,noiseVol,x,y|
	var sig, arr, env, lOut, noise;
	leftVol.postln;


	note = midicps(note);
	noise = WhiteNoise.ar(noiseVol);
	sig = SinOsc.ar(note * (1 + noise), mul: 0.1);
	//noise fm
	arr = sig!2;
	env = EnvGen.kr(
		Env([0, 1, 0.4, 0], [(length/2), 0.5, 1,0]),
		doneAction: 2
	);

	lOut = sig;


	arr = [lOut * leftVol * 1.2,lOut*rightVol * 1.2];
	//panning
	arr = arr * env;
	Out.ar(0,arr);

}).add;

//========================================================== SYNTH 3 ==========================================================
SynthDef(\synth3, {|note = 60, length=0.2, lengthMult,leftVol, rightVol,positionX = 0, positionY = 0,playerX,playerY|
	var pluckL, pluckR, env, arr,rvbAm;

	rvbAm = (((((positionX/540) - playerX) ** 2) + (((positionY/440) - playerY) ** 2)).sqrt).abs;
	note = midicps(note) * 2;
	env = EnvGen.kr(
		Env([0, 1, 0.4, 0], [(length/lengthMult), 0.5, 1, 0]),
		doneAction: 2
	);

	pluckL = Pluck.ar(WhiteNoise.ar(0.1), Impulse.kr(1), note.reciprocal, note.reciprocal, 4) * env;
	pluckR = Pluck.ar(WhiteNoise.ar(0.1), Impulse.kr(1), note.reciprocal, note.reciprocal, 4) * env;
	//repeated pulses with whitenoise as their exciter
	pluckL = BHiPass.ar(pluckL, 1000);
	pluckR = BHiPass.ar(pluckR,1000);
	pluckL = FreeVerb.ar(pluckL,rvbAm,0.5,0.3);
	pluckR = FreeVerb.ar(pluckR,rvbAm,0.5,0.3);
	//effects
	pluckL = pluckL + (pluckR * 0.1);
	pluckR = pluckR + (pluckL * 0.1);
	//signal bleed
	arr = [pluckL * leftVol * 1.2, pluckR * rightVol * 1.2];
	//Poll.kr(Impulse.kr(1), rvbAm, "rvb value:");
	Out.ar(0, arr);

}).add;
//========================================================== SYNTH 4 ==========================================================
SynthDef(\synth4, {|note = 60, length=1, lengthMult,leftVol, rightVol, noiseVol = 0.2,octave = 1,positionX = 0, positionY = 0,playerX,playerY|
	var osc1, env,arr, noise, closest = 50000, lfo, volMul = 1, playerProx;

	lfo = SinOsc.ar(4);
	playerProx = ((((positionX/540) - playerX) ** 2) + (((positionY/440) - playerY) ** 2)).sqrt;
	//distance between instrument and player

	~positionsD3.keys.do({|key|
		var x, y, arr, distance;
		arr = ~positionsD3[key];
		x = arr[0];
		y = arr[1];
		distance = (((x - positionX) ** 2) + ((y - positionY) ** 2)).sqrt;
		closest = Select.kr(
			(distance < closest).asInteger,
			[
				closest,
				distance
			]
		);
	});
	//trying to evaluate for closest so that later this info can be used for Select
	volMul = Select.kr(
		(closest < 180).asInteger,
		[
			1,
			lfo
		]
		//closest pos not currently working. I think I need to pass the values into the synthdef from the outside but I don't have the time
	);
	octave = Select.kr(
		(octave % 2 > 0).asInteger,
		[
			2**octave,
			octave
		]
	);
	octave = clip(octave, 1, 20);
	//swapping from harmonic to octave. Also not working as intended

	env = EnvGen.kr(
		Env([0, 1, 0.4, 0], [(length/lengthMult), 0.5, 1, 0]),
		doneAction: 2
	);
	noise = WhiteNoise.ar(noiseVol/2);
	note = midicps(note) * 0.25 * (octave /2 );
	osc1 = SinOsc.ar(note, mul: 0.3 * (1 + noise)) * env * 0.6 * volMul * clip((1.2-playerProx),0.3,1);
	//noise am
	osc1 = Select.ar(
		(octave > 2).asInteger,
		[
			osc1 * 0.6,
			BHiPass.ar(osc1,clip((150 * octave),100,3000))
		]
	);
	//if note is not bass, hipass
	arr = Select.ar(
		(octave > 2).asInteger,
		[
			[osc1,osc1],
			[osc1*leftVol,osc1*rightVol]
		]
	);
	//if note is not bass, stereo

	//Poll.kr(Impulse.kr(1), closest, "closest value:");
	//Poll.kr(Impulse.kr(1), playerProx, "player proximity:");

	Out.ar(0,arr);
}).add;
//========================================================== SYNTH 5 ==========================================================
SynthDef(\synth5, {|leftVol = 1, rightVol = 1, positionX = 0, positionY = 0,playerX,playerY|
	var bird1, bird2, env, lfo, lfo2, playerProx;
	env = EnvGen.kr(
		Env([1, Rand(0.5,4), 4, Rand(0.5,4)], [1, 0.5, Rand(0.5,4), 0.5]),
		doneAction: 2);
	playerProx = ((((positionX/540) - playerX) ** 2) + (((positionY/440) - playerY) ** 2)).sqrt;
	//ditance to player


	lfo = SinOsc.ar(EnvGen.kr(
		Env([1, 2, 0.43, Rand(0.5,4)], [1, 0.5, Rand(0.2,1), 0.5]),
		doneAction: 2));
	lfo2 = SinOsc.ar(clip((lfo * 3), 0.2,Rand(10,25)));
	//bird pitch fuckery
	bird1 = SinOsc.ar(lfo * 400 * (env * 50));
	bird1 = bird1 * lfo2;
	bird1 = BHiPass.ar(bird1,1000);
	bird1 = BLowPass.ar(bird1,9000);

	Out.ar(0,[bird1 * leftVol * 0.02 * (1 - playerProx),bird1 * rightVol * 0.02 * (1-playerProx)]);
	//volume pan proximity control

}).add;
//========================================================== UI ==========================================================




~ui = Dictionary[
	\font -> Dictionary[
		\global -> Font("Hiragino Sans", 12),
		\title -> Font("Hiragino Sans", 110),
		\bird -> Font("Monaco", 3.5, true),
	],
	\color -> Dictionary[
		\background -> Color.fromHexString("#F5F5F5"),
		\slider -> Color.fromHexString("#FFF6F6"),
		\button -> [
			"#E0E0E0",
			"#FFBA49",
			"#99EBE8",
			"#EF5B5B"
		].collect({ |color| Color.fromHexString(color) }),
		\window -> Color.black,
	],
	\bounds -> Dictionary[
		\window -> Rect(400, 400, 700, 550),
		\title -> Rect(10, 12.5, 300, 100),
		\editSlider -> Rect(20, 130, 200, 50),
		\fxSlider -> Rect(20, 200, 200, 50),
		\bird1 -> Rect(20, 270, 50, 50),
		\bird2 -> Rect(95, 270, 50, 50),
		\woodPecker -> Rect(170, 270, 50, 50),
		\makeNewFxButton -> Rect(20, 340, 50, 50),
		\autoOn -> Rect(95, 340, 50, 50),
		\shh -> Rect(170, 340, 50, 50),
		\ascii -> Rect(220, 10, 400, 400),
		//create ui elements
	],
];
// Ui add, Most of this I don't need. I stole it from Birb but at this point I'm scared it would topple my jenga tower of code if I deleted anything
w = Window.new("Window", ~ui[\bounds][\window])
.front
.background_(~ui[\color][\background])

.alwaysOnTop_(true);
//========================================================== MOUSE DOWN ==========================================================



u = UserView.new(w,w.view.bounds).background_(Color.new255(0,0,0,255));
u.background = Color.black;
~buttonContainer = CompositeView(u, Rect(0, 0, 800, 600));
~buttonContainer.background = Color.clear;
~buttonContainer.visible = true;
u.mouseDownAction = { |view, x, y|
	w.view.mouseDownAction.value(view, x, y); // Forward clicks to window
};
w.view.mouseDownAction = { |view,x, y|
	//create on mouse click


	/*var arrayName = ("~positions" ++ ~selectedObject).asSymbol;
	var targetArray = currentEnvironment.at(arrayName);
	currentEnvironment.put(arrayName,targetArray ++ [[x,y]]);
	targetArray.size.postln;
	arrayName.postln;*/
	//I'm having some issues here. Its gonna be dumb but for time sake I have to switch to a ton of if statements. I tried to use currentEnviorment to access the arrays but it's being wonky

	//That was my note to myself before I gave up and wrote it all out with dumb repeating if statements
	var tempar;
	var limitedValx = x/540;
	var limitedValy = y/400;
	//limited to normalize
	if (~selectedObject == 0)
	{


		~positionsD0.put(~index0,[x,y]);


		b =~buttonWithIndex.(~index0, x,y,~positionsD0,~synthD0);
		~buttonsD0.put(~index0 + ~index1 + ~index2 + ~index3 + ~index4,b);
		if (~bounds.containsPoint(x@y))
		{

		};

		p = Pbind(
			\instrument, \synth1,
			\carrierFreq, Ptuple([Prand([48, 0, 59, 55, 57, 0, 60, 48, 57, 0], 2),Pseq([72,0,60],5),Pseq([36],4)],inf),
			\dur, Pwrand([2,4,8] * limitedValy,[0.33,0.33,0.5],inf),\sustain, 1* limitedValy,   \freqmult,Prand([0.5,1],inf),\leftVol, Pfunc ({(1-limitedValx + ~playerX)/2}), \rightVol, Pfunc ({(limitedValx + 1 - ~playerX)/2}),\index,~index0, \noiseLevel, Pfunc ({limitedValy + (~playerY) - 1}),\positionX, x, \positionY, y, \playerX, Pfunc {~playerX}, \playerY, Pfunc {~playerY}
		).play;
		//using PFunc so that I can dynamically pass the position in and out
		~synthD0.put(~index0,p);
		//adding Pbind to synth def

		~index0 = ~index0 + 1;
	};
	if (~selectedObject == 1)
	{
		~positionsD1.put(~index1,[x,y]);
		b =~buttonWithIndex.(~index1, x,y,~positionsD1,~synthD1);
		~buttonsD0.put(~index0 + ~index1 + ~index2 + ~index3 + ~index4,b);

		p = Pbind(
			\instrument, \synth2,
			\note, Pseq([48, 0, 59, 55, 57, 0, 60, 48, 57, 0], inf), \dur, Pseq([Pseq([1,2,2,4,1]), 12, Pseq([4,4,8])],inf),\sustain, 1,\leftVol, Pfunc ({(1-limitedValx + ~playerX)/2}), \rightVol, Pfunc ({(limitedValx + 1 - ~playerX)/2}), \noiseVol, limitedValy
		).play;


		~synthD1.put(~index1,p);
		~index1 = ~index1 + 1;

	};
	if (~selectedObject == 2)
	{
		~positionsD2.put(~index2,[x,y]);
		b =~buttonWithIndex.(~index2, x,y,~positionsD2,~synthD2);
		~buttonsD0.put(~index0 + ~index1 + ~index2 + ~index3 + ~index4,b);
		p = Pbind(
			\instrument, \synth3,
			\note, Pseq([60, 62, 59, 55, 57, 50], inf), \dur, Pseq([0.5,1,1,2,0.5],inf)* Pfunc ({ 1.1 - ~playerY}),\sustain, 0.45,\lengthMult, Pfunc{1.1 - ~playerY}, \leftVol, Pfunc ({(1-limitedValx + ~playerX)/2}), \rightVol, Pfunc ({(limitedValx + 1 - ~playerX)/2}), \positionX, x, \positionY, y, \playerX, Pfunc {~playerX}, \playerY, Pfunc {~playerY}
		).play;
		~synthD2.put(~index2,p);
		~index2 = ~index2 + 1;
	};

	if (~selectedObject == 3)
	{
		~positionsD3.put(~index3,[x,y]);
		b =~buttonWithIndex.(~index3, x,y,~positionsD3,~synthD3);
		~buttonsD0.put(~index0 + ~index1 + ~index2 + ~index3 + ~index4,b);
		p = Pbind(
			\instrument, \synth4,
			\note, Pseq([60, 62,64,57], inf), \dur, (Pseq([5,9,6,8,5],inf) / 2) + ~positionsD3.size,\sustain, 0.45,\lengthMult, Pfunc{0.55 - (~playerY/2)}, \leftVol, Pfunc ({(1-limitedValx + ~playerX)/2}), \rightVol, Pfunc ({(limitedValx + 1 - ~playerX)/2}),\noiseVol, Pfunc {limitedValy/16 + (~playerY / 20)}, \octave, ~index3 + 1, \positionX, x, \positionY, y, \playerX, Pfunc {~playerX}, \playerY, Pfunc {~playerY}
		).play;
		~synthD3.put(~index3,p);
		~index3 = ~index3 + 1;
	};
	if (~selectedObject == 4)
	{
		~positionsD4.put(~index4,[x,y]);
		b =~buttonWithIndex.(~index4, x,y,~positionsD4,~synthD4);
		~buttonsD0.put(~index0 + ~index1 + ~index2 + ~index3 + ~index4,b);
		p = Pbind(
			\instrument, \synth5,
			\dur, (Pseq([5,9,6,8,5],inf)) + ~positionsD4.size,\sustain, 0.45, \leftVol, Pfunc ({(1-limitedValx + ~playerX)/2}), \rightVol, Pfunc ({(limitedValx + 1 - ~playerX)/2}), \positionX, x, \positionY, y, \playerX, Pfunc {~playerX}, \playerY, Pfunc {~playerY}
		).play;


		~synthD4.put(~index4,p);
		~index4 = ~index4 + 1;
	};
	//this is the dumbest thing I've ever written


	//refresh window after creation

	w.refresh;

};

//========================================================== DRAW ==========================================================

//ui drawing
u.drawFunc_({

	var numRows = 32;
	var numCol = 35;
	var spacing = 15;
	var dotSize = 3;
	var xOffset = 110;
	var tempArr = [];
	var prevFillCol = Color.black;


	Pen.fillColor = Color.gray;

	numRows.do{|row|
		numCol.do{|col|
			var x = xOffset + (col * spacing);
			var y = row * spacing;

			Pen.fillOval(Rect(x - (dotSize/2), y - (dotSize/2), dotSize, dotSize));
			//grid of dots
		};
	};




	//add all instantiated icons
	~positionsD0.keys.do{|keys|

		var tempar = ~positionsD0[keys];
		var x = tempar[0];
		var y = tempar[1];
		var vol = ~synthVolD0[keys] ? 0;
		var lineNum = 50 + (vol * 20);
		var lineLength = 35;
		var newLineLength = lineLength;



		lineNum.do{ arg i;
			var angle = 2pi * (i+(keys * 4) / lineNum); // Full circle (0 to 2π)
			var endX = x + (newLineLength * sin(angle)) + (sin((u.frame/2) + vol) * 3); // Fixed length X
			var endY = y + (newLineLength * cos(angle)) + (cos((u.frame/4) + vol) * 3); // Fixed length Y
			//generating circle of lines radiating out from origin which are moving with the frame
			if (sin(i) >= 0.5) {
				newLineLength = newLineLength * sin(i) * 1.9* (sin(u.frame * 0.1 + (i)) + (vol * 1));
				Pen.strokeColor = Color.red;
			} {
				Pen.strokeColor = Color.black;
				newLineLength = newLineLength * 0.8;
			};



			Pen.fillColor = Color.new255(100,255,180,255);
			Pen.fillOval(Rect(endX, endY, 5, 5));
			Pen.line(x @ y, endX @ endY);
			Pen.stroke;
		};

	};


	~positionsD1.keys.do{|keys|

		var tempar = ~positionsD1[keys];
		var x = tempar[0];
		var y = tempar[1];
		var lineNum = 30;

		var lineLength = 30;
		var newLineLength = lineLength;

		lineNum.do{ arg i;
			var angle = 2pi * (i+(keys * 4) / lineNum); // Full circle (0 to 2π)
			var endX = x + (newLineLength * sin(angle)) + (sin(i + (u.frame * 0.2)) * 4); // Fixed length X
			var endY = y + (newLineLength * cos(angle)) + (sin(i) * 4); // Fixed length Y

			Pen.strokeColor = Color.new255((255/lineNum)*i,255 -((255/lineNum)*i) ,100 + (i*5), 255);



			Pen.fillColor = Color.new255(160,130,190,255);
			Pen.fillOval(Rect(endX, endY, 10, 10));
			Pen.line(x @ y, endX @ endY);
			Pen.stroke;
		};

	};

	~positionsD2.keys.do{|keys|

		var tempar = ~positionsD2[keys];
		var x = tempar[0];
		var y = tempar[1];
		var lineNum = 30;

		var lineLength = 40;
		var newLineLength = lineLength;


		lineNum.do{ arg i;
			var angle = 2pi * (i+(keys * 4) / lineNum); // Full circle (0 to 2π)
			var endX = x + ((newLineLength - (3 * cos(u.frame* (~playerY + 0.1))) * sin(angle)) + (sin(i) * 5));
			var endY = y + ((newLineLength - (3 * cos(u.frame* (~playerY + 0.1) * 1.3)) * cos(angle)) + (sin(i) * 20));
			Pen.strokeColor = Color.new255((255/lineNum)*i,255 -((255/lineNum)*i) ,100 + (i*3), 255);



			Pen.fillColor = Color.new255(160 + (cos(i + u.frame/10) * 50),130,190 + (sin(i) * 30),255);
			Pen.fillOval(Rect(endX, endY, 10, 10));
			Pen.line(x @ y, endX @ endY);
			Pen.stroke;
		};

	};
	~positionsD3.keys.do{|keys|

		var tempar = ~positionsD3[keys];
		var x = tempar[0];
		var y = tempar[1];
		var lineNum = 15;

		var lineLength = 20;
		var newLineLength = lineLength;


		lineNum.do{ arg i;
			var angle = 2pi * (i+(keys * 4) / lineNum); // Full circle (0 to 2π)
			var endX = x + ((newLineLength - (3 * cos(u.frame* (~playerY + 0.1))) * sin(angle)) + (sin(i) * 5));
			var endY = y + ((newLineLength - (3 * cos(u.frame* (~playerY + 0.1) * 1.3)) * cos(angle)) + (sin(i) * 20));

			Pen.strokeColor = Color.new255((255/lineNum)*i,255 -((255/lineNum)*i) ,100 + (i*3), 255);



			Pen.fillColor = Color.new255((240 + (cos(i + u.frame/10) * 50)).clip(0,255),130,190 + (sin(i) * 30),255);
			Pen.fillOval(Rect(endX, endY, 40 * (1 + (2 * ~playerX)), 10));
			Pen.line(x - (1 +(30 * ~playerX)) @ y, endX @ endY);
			Pen.stroke;

		};

	};
	~positionsD4.keys.do{|keys|

		var tempar = ~positionsD4[keys];
		var x = tempar[0];
		var y = tempar[1];
		var lineNum = 20;

		var lineLength = 25;
		var newLineLength = lineLength;


		lineNum.do{ arg i;
			var angle = (u.frame * 0.1) * (i+(keys * 4) / lineNum); //changing value of pi to create spiny 3d effect
			var endX = x + ((newLineLength - (3 * cos(u.frame * 0.05)) * sin(angle)) + (sin(i) * 5));
			var endY = y + ((newLineLength - (3 * cos(u.frame * 0.1)) * cos(angle)) + (sin(i) * 20));

			Pen.strokeColor = Color.new255((100/lineNum)*i,255 -((100/lineNum)*i) ,100 + (i*3), 255);



			Pen.fillColor = Color.new255((100 + (cos(i + u.frame/10) * 50)).clip(0,255),130,190 + (sin(i) * 30),255);
			Pen.fillRect(Rect(endX, endY, 5 * (1 + (2 * ~playerX)), 5 + 30*sin(u.frame*0.05)));

			Pen.line(x - (1 +(30 * ~playerX)) @ y, endX @ endY);
			Pen.stroke;

		};

	};
	~allPos = Dictionary();
	~closePos = Dictionary();
	tempArr = [];
	~allPos = Dictionary();


	//================================================PLAYER SPIDER LOGIC=========================================================
	~mergePreserve = { |dict1, dict2, dict3, dict4, dict5|
		var merged = dict1.copy;
		var dicts = [dict2, dict3, dict4, dict5];
		var addKey = dict1.size; // Start counting after dict1's keys


		dicts.do { |dict|
			dict.keys.do { |key|
				merged[(key.asString ++ "_" ++ addKey).asSymbol] = dict[key];
				addKey = addKey + 1;
			};
		};
		merged;
	};

	// Merge all dictionaries
	~allPos = ~mergePreserve.(~positionsD0, ~positionsD1, ~positionsD2, ~positionsD3, ~positionsD4);


	~closePos = Dictionary();


	~allPos.keys.do { |key|
		var a, x, y, changeX, changeY, hyp;
		a = ~allPos[key];
		x = a[0];
		y = a[1];
		changeX = (x - ((~playerX * 480) + 125)).squared;
		changeY = (y - ((~playerY * 440) + 25)).squared;
		hyp = (changeX + changeY).sqrt;
		~closePos[hyp] = [x, y]; // Overwrites if hyp is the same
	};

	// Sort distances
	tempArr = ~closePos.keys.asArray.sort;


	//use sorted distances so that the 6 closest instruments have a line drawn from them to the player



	6.do({|i|
		var pos, x, y, key;



		key = tempArr[i];

		if (~closePos[key] != nil) {
			pos = ~closePos[key];
			x = pos[0];
			y = pos[1];
			Pen.strokeColor = Color.white;
			Pen.width_(2);
			Pen.line(((~playerX * 480) + 125)@((~playerY * 440) + 25), x@y);
			Pen.stroke;
			//draw line to player
		}

	});




	Pen.strokeColor = Color.white;
	Pen.addRect(Rect((~playerX * 480) + 105,~playerY * 440,40,40));
	//draw player with outline.
	Pen.draw(3);
	Pen.strokeColor = Color.gray;
	Pen.fill;
	Pen.width_(1);
	Pen.line(100@10,100@475);
	Pen.stroke;


});
u.animate_(true);
u.frameRate_(30);
//========================================================== UI OBJECTS ==========================================================






//Buttons
Button.new(w, Rect(5, 5, 88, 80)).states_([
	["000000000",Color.new255(50,40,70),Color.new255(220,250,240)
	]
])
.action_({
	~selectedObject = 0;
	//~selectedObject.value.postln;
});
Button.new(w, Rect(5, 95, 88, 80)).states_([
	["11111111111",Color.new255(50,40,70),Color.new255(240,230,235)
	]
])
.action_({
	~selectedObject = 1;
	//~selectedObject.value.postln;
});
Button.new(w, Rect(5, 185, 88, 80)).states_([
	["222222222",Color.new255(50,40,70),Color.new255(250,220,250)
	]
])
.action_({
	~selectedObject = 2;
	//~selectedObject.value.postln;
});
Button.new(w, Rect(5, 275, 88, 80)).states_([
	["333333333",Color.new255(50,40,70),Color.new255(220,220,250)
	]
])
.action_({
	~selectedObject = 3;
	//~selectedObject.value.postln;
});
Button.new(w, Rect(5, 365, 88, 80)).states_([
	["444444444",Color.new255(50,40,70),Color.new255(230,245,215)
	]
])
.action_({
	~selectedObject = 4;
	//~selectedObject.value.postln;
});

Button.new(w, Rect(640, 490, 40, 40)).states_([
	["XH", Color.new255(50, 40, 70), Color.new255(255, 100, 115)],
	["XH", Color.new255(255, 255, 255), Color.new255(50, 40, 20)]
])
.action_({|btn|
	var buttonVal = btn.value;
	switch(buttonVal,
		1,
		{
			u.background = Color.black;
			~buttonContainer.visible = false;
			//x Off

		},
		0,
		{

			~buttonContainer.visible = true;
			u.background = Color.black;
			//x On

		}
	);
});

//Clearing X Button
Button.new(w, Rect(5,455,88,88)).states_([
	["XXXXXXXXX",Color.new255(255,255,255),Color.new255(255,80,80)]
]).action_({
	//add clearing function
	~synthD0.keys.do({|pbind|
		~synthD0[pbind].stop;

	});
	~synthD1.keys.do({|pbind|
		~synthD1[pbind].stop;

	});
	~synthD2.keys.do({|pbind|
		~synthD2[pbind].stop;

	});
	~synthD3.keys.do({|pbind|
		~synthD3[pbind].stop;

	});
	~synthD4.keys.do({|pbind|
		~synthD4[pbind].stop;

	});
	~buttonsD0.keys.do({|btn|
		~buttonsD0[btn].remove;
	});


	~synthD0.clear;
	~synthD1.clear;
	~synthD2.clear;
	~synthD3.clear;
	~synthD4.clear;
	~buttonsD0.clear;
	~positionsD0.clear;
	~positionsD1.clear;
	~positionsD2.clear;
	~positionsD3.clear;
	~positionsD4.clear;
	~synthVolD0.clear;
	~index0 = 0;
	~index1 = 0;
	~index2 = 0;
	~index3 = 0;
	~index4 = 0;
});


//sliders
x = Slider.new(w, Rect(100,490,525,40)).action_({|slider|
	~playerX = slider.value;



});

y = Slider.new(w, Rect(640,0,40,480)).orientation_(\vertical).action_({|slider|
	~playerY = 1 - slider.value;
});





)





