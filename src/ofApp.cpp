#include "ofApp.h"

static const int plotHeight = 128;
static const int bufferSize = 512;
static const int sampleRate = 44100;
static const long timeBetweenKicksMs = 300;

static const int kNumShaders = 3;
static const int kAudioLines = 512;

static const int kNumExtraParams = 8;

//--------------------------------------------------------------
void ofApp::setup(){
    ofSetBackgroundAuto(false);
    ofSetFrameRate(120);
    ofSetVerticalSync(true);

    audioAnalyzer.setup(bufferSize, sampleRate);
    audioAnalyzer.setOnsetAlpha(3.0);

    const int width = ofGetWidth();
    const int height = ofGetHeight();
    const float margin = 100.0;
    bins = bufferSize / 2;

    cout << "bins: " << bins << endl;

    fftOut = new float[bins];
    memset(fftOut, 0, sizeof(float) * bins);

    fftSmoothOut = new float[bins];
    memset(fftSmoothOut, 0, sizeof(float) * bins);

    currShaderIdx = 3;
    prevShaderIdx = 2;

    drawDebug = false;
    rmsSmoothed = 0;
    rms = 0;
    rmsCumul = 0;
    rmsSmoothAmt = 0;
    transitionAmt = 0;

    reloadShaders();
    currScene.allocate(ofGetWidth(), ofGetHeight(), GL_RGBA);
    prevScene.allocate(ofGetWidth(), ofGetHeight(), GL_RGBA);

    emptyImg.allocate(1, 1, OF_IMAGE_COLOR);
    plane.set(ofGetWidth(), ofGetHeight(), 1, 1, OF_PRIMITIVE_TRIANGLES);
    audioTex.allocate(bins, kAudioLines, GL_R16F, GL_RED, GL_FLOAT);
    audioTexFbo.allocate(bins, kAudioLines, GL_R16F);
    audioTexPixels.allocate(bins, kAudioLines, 1);

    gui.setup();

    audioSource.set("audioSource", 3, 0, soundStream.getDeviceList().size());
    gui.add(audioSource);

    fixedParams.setName("Fixed Params");
    fftSmoothing.set("fftSmoothing", 0.2, 0, 1);
    fixedParams.add(fftSmoothing);
    rmsSmoothing.set("rmsSmoothing", 0.2, 0, 1);
    fixedParams.add(rmsSmoothing);
    alphaOverdraw.set("alphaOverdraw", 0.2, 0, 1);
    fixedParams.add(alphaOverdraw);

    gui.add(fixedParams);

    sliderGroup.setName("Sliders");
    knobGroup.setName("Knobs");
    for (int i = 0; i < kNumExtraParams; ++i) {
        {
            char buf[50];
            sprintf(buf, "slider%02d", i);

            ofParameter<float> param;
            param.set(buf, 0, 0, 1);

            sliders.push_back(std::move(param));
            sliderGroup.add(sliders.back());
        }
        {
            char buf[50];
            sprintf(buf, "knob%02d", i);

            ofParameter<float> param;
            param.set(buf, 0, 0, 1);

            knobs.push_back(std::move(param));
            knobGroup.add(knobs.back());
        }
    }
    gui.add(sliderGroup);
    gui.add(knobGroup);

    gui.setPosition(ofGetWidth() - gui.getWidth() - 10, 10);

    midiController.setup();

    // Do this last
    ofSoundStreamListDevices();

    soundStream.setDeviceID(audioSource);
    selectedAudioSource = audioSource;

    soundStream.setup(this, 0, 1, sampleRate, bufferSize, 4);
}

//--------------------------------------------------------------
void ofApp::update(){
    long now = ofGetElapsedTimeMillis();

    // Update params from MIDI
    if (ofGetFrameNum() % 30 == 15) {
        if (!midiController.midiIn.isOpen()) {
            midiController.setup();
        }
    }

    if (midiController.midiIn.isOpen()) {
        if (midiController.knobNew[0]) {
            fftSmoothing.set(midiController.knobs[0]);
        }
        if (midiController.knobNew[1]) {
            rmsSmoothing.set(midiController.knobs[1]);
        }
        if (midiController.knobNew[2]) {
            alphaOverdraw.set(midiController.knobs[2]);
        }

        for (int i = 0; i < kNumExtraParams; ++i) {
            if (midiController.sliderNew[i]) {
                midiController.sliderNew[i] = false;
                sliders[i].set(midiController.sliders[i]);
            }
            if (midiController.knobNew[i]) {
                midiController.knobNew[i] = false;
                knobs[i].set(midiController.knobs[i]);
            }
        }
    }

    if (selectedAudioSource != audioSource) {
        soundStream.close();
        soundStream.setDeviceID(audioSource);
        soundStream.setup(this, 0, 1, sampleRate, bufferSize, 4);
        selectedAudioSource = audioSource;
    }

    memcpy(fftOut, audioAnalyzer.getSpectrum(), sizeof(float) * bufferSize / 2);

    if (ofGetFrameNum() % 30 == 0) {
        reloadShaders();
    }

    for (int i = 0; i < bins; ++i) {
        float h = ofMap(fftOut[i], log10(0.001), log10(1.0), 0.0, 1.0, true);
        float val = h; //ofClamp(16.0 * log10(fftOut[i] + 1), 0.0, 1.0);

        if (val > fftSmoothOut[i]) {
            fftSmoothOut[i] = val;
        } else {
            fftSmoothOut[i] += (val - fftSmoothOut[i]) * fftSmoothing;
        }
    }

    float newRms = audioAnalyzer.getRms();
    rmsDiff = newRms - rmsDiff;
    rmsDiffCumul += rmsDiff;
    rms = newRms;

    rmsSmoothAmt = (rms - rmsSmoothed) * rmsSmoothing;
    rmsSmoothed += rmsSmoothAmt;
    rmsCumul += rmsSmoothed;

}

//--------------------------------------------------------------
void ofApp::draw(){
    float resolution[] = {(float)ofGetWidth(), (float)ofGetHeight()};
    float time = ofGetElapsedTimef();

    ofEnableAlphaBlending();

    audioTexFbo.begin();
    audioTex.draw(0, 1);
    audioTexFbo.end();
    audioTexFbo.readToPixels(audioTexPixels);

    float* d = audioTexPixels.getData();
    for (int i = 0; i < bins; ++i) {
        d[i] = fftSmoothOut[i];
    }
    audioTex.loadData(audioTexPixels);

    currScene.begin();
        currShader.begin();
            currShader.setUniform1f("time", time);
            currShader.setUniform1f("rms", rmsSmoothed);
            currShader.setUniform1f("rmsDelta", rmsSmoothAmt);
            currShader.setUniform1f("rmsDeltaCumul", rmsDiffCumul);
            currShader.setUniform1f("rmsCumul", rmsCumul);
            currShader.setUniform2fv("resolution", resolution);
            currShader.setUniformTexture("audioTex", audioTex, 1);
            currShader.setUniform2f("audioTexSize", audioTex.getWidth(), audioTex.getHeight());

            // TODO: precompute string names
            for (int i = 0; i < kNumExtraParams; ++i) {
                char buf[50];
                sprintf(buf, "slider%02d", i);
                currShader.setUniform1f(buf, sliders[i]);
                sprintf(buf, "knob%02d", i);
                currShader.setUniform1f(buf, knobs[i]);
            }

            emptyImg.draw(-1.0,-1.0, 2.0,2.0);
            plane.draw();
        currShader.end();
    currScene.end();

    ofSetColor(255, 255 * alphaOverdraw);
    currScene.draw(0, 0);

    if (drawDebug) {
        ofSetColor(255, 255);
        audioTex.draw(10,10);

        ofSetColor(255, 255, 255, 255);
        ofDrawRectangle(10, 10 + audioTex.getHeight() + 10, audioTex.getWidth() * rmsSmoothed, 20);

        gui.draw();
    }
}

void ofApp::audioReceived(float* input, int bufferSize, int nChannels) {
    audioAnalyzer.analyze(input, bufferSize);
}

void ofApp::reloadShaders() {
    char buf[50];

    sprintf(buf, "shaders/messin-%03d.fsh", currShaderIdx);
    currShader.load("shaders/messin.vsh", buf);

    sprintf(buf, "shaders/messin-%03d.fsh", prevShaderIdx);
    prevShader.load("shaders/messin.vsh", buf);
}

bool ofApp::shaderExists(int idx) {
    char buf[50];
    sprintf(buf, "shaders/messin-%03d.fsh", idx);

    ofFile f(buf);
    return f.exists();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if (key == OF_KEY_RIGHT) {
        if (!transitioning) {
            prevShaderIdx = currShaderIdx;
            currShaderIdx++;
            if (!shaderExists(currShaderIdx)) {
                currShaderIdx = 0;
            }

            cout << "Advancing curr:" << currShaderIdx << " prev:" << prevShaderIdx << endl;
            reloadShaders();
        }
    } else if (key == OF_KEY_LEFT) {
        if (!transitioning) {
            prevShaderIdx = currShaderIdx;
            currShaderIdx--;
            if (currShaderIdx < 0) {
                int i = 0;
                for (; shaderExists(i); ++i);
                currShaderIdx = i - 1;
            }

            cout << "Regressing curr:" << currShaderIdx << " prev:" << prevShaderIdx << endl;
            reloadShaders();
        }
    } else if (key == 'd') {
        drawDebug = !drawDebug;
    }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){
    currScene.allocate(ofGetWidth(), ofGetHeight(), GL_RGBA);
    prevScene.allocate(ofGetWidth(), ofGetHeight(), GL_RGBA);
}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
