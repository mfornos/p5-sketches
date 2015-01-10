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
float shininess = 0.50,
      fresnel = 0.20,
      exposure = 1.0,
      albedo = 0.9,
      transmitMin = 0.17,
      transmitMax = 0.50,
      wax = 0.45,
      lx, ly, lz,        // light position
      lr,
      Ka  = 0.05,        // light intensities
      Kd  = 0.50,
      Ks  = 0.40;
boolean sphere = true,
        light  = false;
DropdownList dlShaders,
             dlModels;
ColorPicker bgCp;

void setup() 
{
  size(1040, 600, P3D);
  light(200, -200, width, 50);
  frameRate(60);
  noStroke();
  background(bgc);
  smooth(4);
  updateBg();
  
  cam = new PeasyCam(this, height);
  cp5 = new ControlP5(this);
  setupControls(cp5);
  
  // Models
  modelScales = new float[6];
  addModel("Cow", 50);
  addModel("Suzanne", 140);
  addModel("Bunny", 100);
  addModel("Model1", 0.7);
  addModel("Model2", 0.7);
  addModel("Model3", 0.7);
  
  loadModel("Cow", 50);       // Default model
  
  // Texture  
  tex = loadImage("cafe.jpg");
  
  // Shaders
  shaders = new PShader[5];
  addShader("GGX");
  addShader("Glowy");
  addShader("Trans");
  addShader("Irrad");
  addShader("Cook");

  lit = shaders[0];           // Default shader
}

void draw() 
{
  background(bgc);
  fill(234, 237, 194); // Default fill
  
  if(light) {
    pushMatrix();
    translate(lx, ly, lz);
    fill(255);
    noStroke();
    sphere(lr);
    noFill();
    popMatrix();
  }
  
  lightSpecular(235,240,255);
  shininess(shininess);
  spotLight(255, 255, 255, lx, ly, lz, 0, 0, -1, 0, 0);

  // Shader uniforms
  lit.set("Ka", Ka);
  lit.set("Kd", Kd);
  lit.set("Ks", Ks);
  lit.set("Lr", lr);
  lit.set("bgColor", bgColor);
  lit.set("gamma", 2.2);
  lit.set("albedo", albedo);
  lit.set("resolution", (float) width, (float) height);
  lit.set("exposure", exposure);
  lit.set("fresnel", fresnel);
  lit.set("waxiness", wax);
  lit.set("transmitMin", transmitMin);
  lit.set("transmitMax", transmitMax);
  
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

void light(float x, float y, float z, float r)
{
  lx = x;
  ly = y;
  lz = z;
  lr = r;
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
  rect(0,0,337,170);
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
  
  e("shininess", 0., 1.0, 10, 20);
  e("exposure", 0, 2.0, 120, 20);
  e("fresnel", 0.01, 0.5, 230, 20);
  
  e("Ka", 0, 0.5, 10, 50);
  e("Kd", 0, 1, 120, 50);
  e("Ks", 0, 1, 230, 50);
  
  e("wax", 0.0, 3.5, 10, 80);
  e("transmitMin", 0.0, 1.0, 120, 80);
  e("transmitMax", 0.0, 1.0, 230, 80);
  
  cp5.addToggle("sphere")
     .setPosition(10, 140)
     .setSize(10, 10);
  cp5.addToggle("light")
     .setPosition(50, 140)
     .setSize(10, 10);
 
  cp5.addTextlabel("palette", "PALETTE", 6, 110);
   
  dlModels = cp5.addDropdownList("Models")
                .setPosition(10, 133);
  dlShaders = cp5.addDropdownList("Shaders")
                 .setPosition(120, 133);
  
  e("lx", -width/2, width/2, 10, height-45);
  e("ly", -height/2, height/2, 120, height-45);
  e("lz", -width/2, width/2, 230, height-45);
  e("lr", 5, 65, 340, height-42);
  e("albedo", 0.1, 0.95, 10, height-17);
  
  bgCp = cp5.addColorPicker("bgpicker")
          .setPosition(10, height-120)
          .setColorValue(bgc);
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

