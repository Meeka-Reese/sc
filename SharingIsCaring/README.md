### Documentation
<p>
My project is a parody of Colugo's "Carnival" from his DAW, "BlockHead".
The instrument has 5 different instruments that are declared as synthdefs in the early parts of the code. These instruments can be selected by clicking on the associated button on the left. From there, you can click anywhere on the screen and the instrument will be created. Under the hood, I'm checking for any left clicks in my GUI window, adding a position to the selected instrument's dictionary and starting an infinite running PBind that handles the notes and the interaction between the "Player" and the instruments. Lower in the GUI field, I'm created a user view to go below the buttons in the main window, after that, I'm iterating through all of the keys in each of my instrument's position dictionaries and creating an icon at that location. I'm also using u.frame so that certain parameters are animated. The player moves around with the sliders on the bottom and the right. They aren't the most elegant solution but it saves some headache when so many of the controls are dependent on clicking in the main window. 
All instruments have panning relative to the "Player's" position and the "Player's" proximity effects volume.
</p>
<p>
In Addition to each instrument that's instantiated, there is a corresponding "X" button. When this button is clicked, the instrument's position will be removed from the instrument's dictionary and the instrument will be killed. At the bottom left, there's a button labeled "xxxxxxxxxxx", this is the kill all button. It won't kill the server, but it will remove all icons and Pbinds to do a soft kill. On the bottom right, there's a button labeled "XH". This button turns the view on and off for the buttons. Sadly, the buttons are still active, they're just invisible so caution is advized. 
</p>

### Instruments and their controls

* "000000000" - Noisy Drum synth. The strength of the envelope is dependent on the distance of the "Player" to the synth. The synth is also nooisyer higher on the screen.
* "111111111"  - Simple Noisy melody repeated. The noise fm levels of the instrument increase lower on the screen. 
* "222222222" - Pluck Synth with the frequency of the plucks dependent on the "Player's" y position. The synth also increases Reverb Wet Levels when the "Player" is farther away
* "333333333" - The first instance of the instrument is a bass and the following are pitched up by octaves and harmonics. Their note length is dependent on the "Player's" y
* "444444444" - Silly bird synth. I want to modify it some but for now it's a randomly generating pitch fluttery SinOsc. Pan and volume are controlled by "Player" position and distance
