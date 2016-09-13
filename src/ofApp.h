#pragma once

#include "ofMain.h"
#include "ofxGui.h"
#include "ofxFft.h"
#include "ofxAudioAnalyzer.h"
#include "MidiController.h"

class ofApp : public ofBaseApp {

public:
    void setup();
    void update();
    void draw();

    void keyPressed(int key);
    void keyReleased(int key);
    void mouseMoved(int x, int y );
    void mouseDragged(int x, int y, int button);
    void mousePressed(int x, int y, int button);
    void mouseReleased(int x, int y, int button);
    void mouseEntered(int x, int y);
    void mouseExited(int x, int y);
    void windowResized(int w, int h);
    void dragEvent(ofDragInfo dragInfo);
    void gotMessage(ofMessage msg);

    void audioReceived(float* input, int bufferSize, int nChannels);

    bool shaderExists(int idx);
    void reloadShaders();

    ofSoundStream soundStream;
    int selectedAudioSource;

    ofxFft* fft;
    ofxAudioAnalyzer audioAnalyzer;
    ofTexture audioTex;
    ofFbo audioTexFbo;
    ofFloatPixels audioTexPixels;
    ofImage emptyImg;
    ofPlanePrimitive plane;

    MidiController midiController;

    float *inputAudio;
    float *fftOut, *fftSmoothOut;
    int bins;

    float rmsSmoothed, rmsSmoothAmt, rms;
    float rmsCumul;
    float rmsDiff, rmsDiffCumul;

    int currShaderIdx, prevShaderIdx;
    ofShader currShader, prevShader;
    ofFbo currScene, prevScene;

    bool transitioning;
    float transitionAmt;

    bool drawDebug;
    ofxPanel gui;
    ofParameterGroup fixedParams;
    ofParameter<int> audioSource;
    ofParameter<float> fftSmoothing;
    ofParameter<float> rmsSmoothing;
    ofParameter<float> alphaOverdraw;

    ofParameterGroup sliderGroup;
    vector<ofParameter<float>> sliders;
    ofParameterGroup knobGroup;
    vector<ofParameter<float>> knobs;
};
