/* -----------------------------------------------------------
 * Lighting Sketch
 * -----------------------------------------------------------
 * Provides a sandbox to play with local illumination models
 * using fragment shaders.
 *
 */
 
import saito.objloader.*;
import controlP5.*;
import peasy.*;

PeasyCam cam;
ControlP5 cp5;

OBJModel model;
float[] modelScales;
PShader[] shaders;
PShader lit;
PImage tex;

color bgc = color(64,71,73); 
PVector bgColor;

// Control Parameters
float shininess = 0.90,
      fresnel = 0.08,
      exposure = 1.0,
      transmitMin = 0.20,
      transmitMax = 0.80,
      wax = 1.5,
      aI  = 0.10,        // light intensities
      dI  = 0.50,
      sI  = 0.40;
boolean sphere = true;
DropdownList dlShaders,
             dlModels;
ColorPicker bgCp;

void setup() 
{
  size(1040, 600, P3D);
  frameRate(60);
  noStroke();
  background(bgc);
  smooth(4);
  updateBg();
  
  cam = new PeasyCam(this, height);
  cp5 = new ControlP5(this);
  setupControls(cp5);
  
  // Models
  modelScales = new float[4];
  addModel("Cow", 50);
  addModel("Suzanne", 140);
  addModel("Bunny", 100);
  addModel("Model1", 0.7);
  
  loadModel("Cow", 50);       // Default model
  
  // Texture  
  tex = loadImage("cafe.jpg");
  
  // Shaders
  shaders = new PShader[4];
  addShader("Cook");
  addShader("Glowy");
  addShader("Trans");
  addShader("Irrad");

  lit = shaders[0];           // Default shader
}

void draw() 
{
  background(bgc);
  ambientLight(bgc >> 16 & 0xFF, bgc >> 8 & 0xFF, bgc & 0xFF);
  lightSpecular(235,240,255);
  shininess(shininess);
  pointLight(255, 255, 255, width/2, height, 200);
  fill(250,250,250); // Default fill
  
  // Shader uniforms
  lit.set("AmbientIntensity", aI);
  lit.set("DiffuseIntensity", dI);
  lit.set("SpecularIntensity", sI);
  lit.set("BgColor", bgColor);
  lit.set("Resolution", (float) width, (float) height);
  lit.set("Exposure", exposure);
  lit.set("Fresnel", fresnel);
  lit.set("Waxiness", wax);
  lit.set("TransmitMin", transmitMin);
  lit.set("TransmitMax", transmitMax);
  
  shader(lit);
  
  pushMatrix();
  model.draw();
  popMatrix();
  
  if(sphere) {
    pushMatrix();
    float _cos = cos(millis()*.0025f);
    float _sin = sin(millis()*.0025f);
    translate(100 * _cos, -200, -100 * _sin);
    fill(150,269,86);
    sphereDetail(100);
    sphere(40);
    popMatrix();
  }
  
  resetShader();
  
  gui();
}


//
// Helpers
//

void loadModel(String name, float scale) 
{
  String fname = name.toLowerCase()+".obj";
  model = new OBJModel(this, fname, "relative", TRIANGLE_FAN);
  model.scale(scale);
  model.translateToCenter();
  model.disableTexture();
  //model.disableMaterial();
}

//
// Gui Controls
//

void gui() 
{
  noLights();
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  fill(25,25,25,80);
  rect(0,0,350,200);
  cp5.draw();
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

int si = 0,
    mi = 0;

void addShader(String name)
{
  String frag = "shaders/"+name.toLowerCase()+".frag.glsl";
  shaders[si] = loadShader(frag, "shaders/vert.glsl");
  shaders[si].set("texture", tex);
  dlShaders.addItem(name, si);
  si++;
}

void addModel(String name, float scale)
{
  modelScales[mi] = scale;
  dlModels.addItem(name, mi);
  mi++;
}

void controlEvent(ControlEvent c) {
  if (c.isFrom(dlShaders)) {
    lit = shaders[int(c.getValue())];
  } else if(c.isFrom(dlModels)) {
    int iv = int(c.getValue());
    String sv = dlModels.item(iv).getName();
    loadModel(sv, modelScales[iv]);
  } else if(c.isFrom(bgCp)) {
    int r = int(c.getArrayValue(0));
    int g = int(c.getArrayValue(1));
    int b = int(c.getArrayValue(2));
    int a = int(c.getArrayValue(3));
    bgc = color(r, g, b, a);
    updateBg();
  }
}

void updateBg()
{
  int r = bgc >> 16 & 0xFF;
  int g = bgc >> 8 & 0xFF;
  int b = bgc & 0xFF;
  bgColor = new PVector(r/255.0, g/255.0, b/255.0);
}

void setupControls(ControlP5 cp5)
{
  cp5.setAutoDraw(false);
  
  e("shininess", 0.5, 1.0, 10, 20);
  e("exposure", 1.0, 3.0, 120, 20);
  e("fresnel", 0.01, 0.5, 230, 20);
  
  e("aI", 0, 1.25, 10, 50);
  e("dI", 0, 1.25, 120, 50);
  e("sI", 0, 1.25, 230, 50);
  
  e("wax", 0.0, 3.0, 10, 80);
  e("transmitMin", 0.0, 1.0, 120, 80);
  e("transmitMax", 0.0, 1.0, 230, 80);
  
  cp5.addToggle("sphere")
     .setPosition(10,140)
     .setSize(10, 10);
  
  bgCp = cp5.addColorPicker("bgpicker")
          .setPosition(10, height-70)
          .setColorValue(bgc);
   
  cp5.addTextlabel("palette", "PALETTE", 6, 110);
   
  dlModels = cp5.addDropdownList("Models")
                .setPosition(10, 133);
  dlShaders = cp5.addDropdownList("Shaders")
                 .setPosition(120, 133);
}

void e(String name, float rx, float ry, float x, float y) 
{
  cp5.addSlider(name)
   .setRange(rx, ry)
   .setPosition(x, y)
   .setSliderMode(Slider.FLEXIBLE)
   .getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE)
   .setPaddingX(0);
}

