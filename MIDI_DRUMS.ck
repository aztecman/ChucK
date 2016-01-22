/* MIDI based Drum Machine
By AZTECMAN      -       AZTECMANMUSIC@GMAIL.COM         -          
This code is based on examples 5.4, 11.1, 11.2 and Chapter 9 
from PROGRAMMING FOR MUSICIANS AND DIGITAL ARTISTS */

/* The program uses a simple algorithm to find BPM.
You should create a pulse (MIDI out) from your DAW
(I used Propellerhead: Reason (175 BPM) for this example)
For windows you'll need to set up two ports on loopMIDI.
*/

MidiIn min;
MidiOut mout;
time timeInfo;
1 => int addInf;
1 => float beatsPerSamp;
0 => int measure; // smallest unit chunk of time
0 => int phrase; // phrase = 4 * measure
0 => int progress; // progress = 4 * phrase [note: this variable currently doesn't control anything, but is useful for compositional control]

//These ports may be different. To check the values, go to Window:Device Browser:MIDI
1 => int port1; //recieces a steady pulse from D.A.W. 
1 => int port2; //sends MIDI data from ChucK to the D.A.W.                 

//Here are the drum patterns:

//   1  and  2  and  3  and  4  and     (16th notes)
    [1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0] @=> int kickPattern1[];
    [1,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0] @=> int kickPattern2[];

    [0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0] @=> int snarePattern1[];
    [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0] @=> int snarePattern2[];

    [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0] @=> int hatPattern1[];
    [1,0,1,0,0,0,1,0,0,0,1,0,0,1,1,0] @=> int hatPattern2[];

    [0,0,1,0,1,0,1,0,0,1,0,0,1,0,1,0] @=> int rimPattern1[];
    [0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,0] @=> int rimPattern2[];

// function to play pattern arrays
fun void playMeasure(int kickA[], int snareA[], int hatA[],int rimA[], float beattime)
{  // (5) playSection function, arrayarguments control patterns
    for (0 => int i; i < kickA.cap(); i++)
    {
       <<<measure,": measure">>>;
       <<<phrase, ": phrase">>>;
        <<<progress,": progress">>>;
        
        if (kickA[i])
        {
           MIDInote(1, 36, 127); // B0
        }                      
        if (snareA[i])
        {
           MIDInote(1, 37, 127); // C1
        }
        if (hatA[i])
        {
           MIDInote(1, 38, 127); // C#1
        }
        if (rimA[i])
        {
           MIDInote(1, 39, Math.random2(105,115)); // D1
        }
  
        beattime::samp => now;
        
        // random events (glitches):
        if(phrase % 2==0)Std.ftoi(Math.random2f(0,1.6))=>kickPattern1[6];
        if(measure % 2==0)Std.ftoi(Math.random2f(0,1.4))=>kickPattern1[3];
        if(phrase % 2==0)Std.ftoi(Math.random2f(0,1.5))=>hatPattern1[13]=>hatPattern1[15];
        if(measure % 2==0)Std.ftoi(Math.random2f(0,1.4))=>rimPattern1[13]=>rimPattern1[15];
        if(phrase % 2==0)Std.ftoi(Math.random2f(0,1.2))=>rimPattern2[Math.random2(11,15)];
        // to increase chance of an event raise this^ number (imagine a coin with a weighted face)
        // use "measure" (for the if statement) to perform the "coin flip" more often, or "phrase" for more widely spaced glitches
        }
}         

if( !min.open(port1) )  // Tries to open it on port1
{
    <<< "Error: MIDI port did not open on port1: ", port1 >>>; // handles failure well
    me.exit();
}

if( !mout.open(port2) )         // Try to open the MIDI port
{
    <<< "Error: MIDI port did not open on port2: ", port2 >>>;//fail gracefully
    me.exit();
}

MidiMsg msg2;                   //  Make a MIDI message holder

MidiMsg msg1;           // Makes object to hold MIDI messages
fun void MIDInote(int onoff, int note, int velocity)
{                              // Function to send MIDI noteOn/Off
    if (onoff == 0) 128 => msg2.data1;  // If noteOff, set status byte to 128...
    else 144 => msg2.data1;     //  ...else set status  byte to 144.
    note => msg2.data2;
    velocity => msg2.data3;
    mout.send(msg2);
}

while( true )          // Infinite loop
{         
    min => now;        // Sleeps until a MIDI input message comes
                       // Awaken to receive MIDI msg 
    while( min.recv(msg1) )
    {
        //<<< msg1.data1, msg1.data2, msg1.data3 >>>;
        if (msg1.data1 == 144) {
             if(addInf==1) now=>timeInfo; 
                    if(addInf==-1) {
                        if(now!=timeInfo){(now-timeInfo)/(samp*16.01) => beatsPerSamp;} //calculates the BPM (note: in theory 16 should behave correctly, however the synchronization is more accurate with a slight push.)
                    }          
            -1 *=>addInf;
 
        if(beatsPerSamp>0){ 
            //this area controls the overall pattern-flow
                                if(measure==1) {playMeasure(kickPattern1,snarePattern2,hatPattern1,rimPattern1,beatsPerSamp);}
                           else if(measure==2) {playMeasure(kickPattern2,snarePattern2,hatPattern1,rimPattern2,beatsPerSamp);}
                           else if(measure==3) {playMeasure(kickPattern1,snarePattern2,hatPattern1,rimPattern1,beatsPerSamp);}
                           else if(measure==4&&phrase%2==0) {playMeasure(kickPattern2,snarePattern2,hatPattern1,rimPattern2,beatsPerSamp);}
                           else if(measure==4&&phrase%2!=0) {playMeasure(kickPattern2,snarePattern1,hatPattern2,rimPattern2,beatsPerSamp);}

                        
            measure++;
                           if(measure>4){ 1 => measure; phrase++;}
                           if(phrase>=5){ 1 => phrase; progress++;}
        } 
        }
        
    }
}
