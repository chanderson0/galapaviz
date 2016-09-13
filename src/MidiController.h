//
//  MidiController.h
//  galapaViz
//
//  Created by Christopher Anderson on 08/20/16.
//
//

#ifndef MidiController_h
#define MidiController_h

#include "ofMain.h"
#include "ofxMidi.h"

class MidiController : public ofxMidiListener {
public:
    ~MidiController();
    void setup();

    void newMidiMessage(ofxMidiMessage& eventArgs);

    ofxMidiIn midiIn;

    float sliders[8];
    bool sliderNew[8];
    float knobs[8];
    bool knobNew[8];

    // Bitpacked: 1 - S, 2 - M, 4 - R
    int buttons[8];
};

#endif /* MidiController_h */
