# BIRB SUPERCOLLIDER ANALYSIS!
### Intro
<p>
The largest parts of the doccumentation over the specific parts of the supercollider instrument are saved as comments to the scd file. The original author of the project didn't comment their file well so all but two of the comments are mine. I'm going to give a brief rundown, but the .scd is there for a more indepth analysis
</p>

### Analysis
<p>
The scd project startss off by zeroing out the project. The first few lines open a meter, and boots the server. It then allocates memory for the project. After that it reboots, kills all servers and frees all buffers. It then sets varible s = to the local server. Then the project initializes all of the buffers used for transfering audio and fx values. After that, the SynthDef's for the recordBuffer, short bird, other birds, and wood pecker are declared. Below, there's a task called "rout". This task send a loop of messages to all of the birds with random values for their parameters. The UI section contains the declaration for the window, text, all of the buttons and sliders, and the sending of values to the synths depending on the values selected. For instance, the "rout" task is triggered when the "auto" button is on and it turns off when the button is off. The last part of the project is the asci generation. Here a string is declared with the initial asci bird. This bird is fed into a function that prints out the new state for the bird depending on the parameters selected. The code distorts the bird by inserting spaces in the asci sequence
</p>

### Link to original project post

[Steftones' Github repo for Birb](https://github.com/Steftones/Birb)