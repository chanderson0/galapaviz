#include "ofMain.h"
#include "ofApp.h"

//========================================================================
int main( ){
    ofGLWindowSettings settings;
    settings.setGLVersion(3,3); /// < select your GL Version here
//    settings.width = 1024;
//    settings.height = 768;
    ofCreateWindow(settings);
    ofRunApp(new ofApp());

}
