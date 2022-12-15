import controlP5.*;
import java.util.*;
//See [https://sojamo.de/libraries/controlP5/reference/index.html]

ControlP5 cp5;
Numberbox nbxWidth, nbxHeight, nbxPosterize, nbxHuePalette;
CheckBox cbxAutoHeight;

static final int fullHoverBounds = 20;

Camera camera;

PImage input = null, palettized = null, output = null;
int stepSizeX = 1, stepSizeY = 1;

color[] palette;

String currScreen = "";

void setup()
{
    //Initialize P5
    fullScreen();
    noSmooth();
    imageMode(CENTER);
    stroke(255);
    strokeWeight(2);
    textAlign(LEFT, CENTER);
    textSize(10);

    //Initialize images
    input = loadImage("input.jpg");
    output = createImage(10, 10, RGB);
    camera = new Camera(input.width/4, input.height/2, width/2, height);

    //Add UI Sliders
    cp5 = new ControlP5(this);

    nbxPosterize = cp5.addNumberbox("posterize")
                   .setPosition(width/2-220, height-150)
                   .setSize(200, 20)
                   .setRange(2, 255)
                   .setScrollSensitivity(1.0)
                   .setDirection(Controller.HORIZONTAL)
                   .setValue(2);

    nbxWidth = cp5.addNumberbox("width")
                  .setPosition(width/2-220, height-100)
                  .setSize(200, 20)
                  .setRange(1, 2048)
                  .setScrollSensitivity(1.0)
                  .setDirection(Controller.HORIZONTAL)
                  .setValue(64);

    nbxHeight = cp5.addNumberbox("height")
                   .setPosition(width/2-220, height-50)
                   .setSize(200, 20)
                   .setRange(0, 2048)
                   .setScrollSensitivity(1.0)
                   .setDirection(Controller.HORIZONTAL)
                   .setValue(0);

    nbxHuePalette = cp5.addNumberbox("hue")
                   .setPosition(width/2+20, height-150)
                   .setSize(200, 20)
                   .setRange(0, 128)
                   .setScrollSensitivity(1.0)
                   .setDirection(Controller.HORIZONTAL)
                   .setValue(0);
}

class Color
{
    public color value;

    Color(color value)
    {
        this.value = value;
    }
}

//Extract pixel art, each pixel is the average of surrounding pixels
//then find common color palette from output image

//The main algorithm where we extract the pixel art from the input image
void extract()
{
    input.loadPixels();

    int outputW = (int)nbxWidth.getValue();
    int outputH = (int)nbxHeight.getValue();

    stepSizeX = input.width/outputW;

    if (outputH == 0) //Auto guess height
    {
        stepSizeY = stepSizeX;

        outputH = (int)(outputW*input.height/input.width);

    }
    else //Manual override auto guess
    {
        stepSizeY = input.height/outputH;
    }

    output = createImage(outputW, outputH, RGB);
    output.loadPixels();

    for(int x = 0; x < outputW; x++)
    {
        for(int y = 0; y < outputH; y++)
        {
            //Map input image pixels to output image
            int outPixels = x+y*outputW;

            int inPixelX = x*stepSizeX + stepSizeX/2;
            int inPixelY = y*stepSizeY + stepSizeY/2;

            int inPixels = inPixelX+inPixelY*input.width;
            inPixels = (int)clamp(inPixels, 0, input.pixels.length-1); //Prevent index out of range

            //TODO: Weighted average of pixels in that area with falloff about the center

            output.pixels[outPixels] = input.pixels[inPixels];
        }
    }

    output.updatePixels();
    // output.filter(POSTERIZE, (int)nbxPosterize.getValue());
}

void keyReleased()
{
    if(key == 'r') //Reload
    {
        extract();
    }
    else if(key == 's') //Save output image
    {
        output.save("data/output.png");
    }
}

boolean mouseOverUI()
{
    return between(mouseX, width/2-225, width/2+225) && between(mouseY, height-155, height);
}

void mouseWheel(MouseEvent event)
{
    if(currScreen == "bothImg" && !mouseOverUI())
    {
        camera.onZoom(event.getCount());
    }
}

void controlEvent(ControlEvent event)
{
    if (
        event.isFrom(nbxWidth)
        || event.isFrom(nbxHeight)
        || event.isFrom(nbxPosterize)
    )
    {
        extract();
    }
    else if (
        event.isFrom(nbxHuePalette)
    )
    {
        palettize((int)nbxHuePalette.getValue(), PalettizeMethod.KMeans);
    }
}

void draw()
{
    background(30, 30, 38);

    Slider s = cp5.get(Slider.class, "test");

    if (mouseX < fullHoverBounds && mouseY < fullHoverBounds) // Show input image
    {
        currScreen = "inputImg";
        cp5.hide();
        image(input, width/2, height/2);
        textAlign(CENTER, CENTER);
        textSize(20);
        text("INPUT", width/2, 30);
    }
    else if (mouseX > width-fullHoverBounds && mouseY < fullHoverBounds) // Show output image
    {
        currScreen = "outputImg";
        cp5.hide();
        image(output, width/2, height/2);
        textAlign(CENTER, CENTER);
        textSize(20);
        text("OUTPUT", width/2, 30);
    }
    else //Show both input image and output image side-by-side
    {
        currScreen = "bothImg";
        cp5.show();

        if(mousePressed && !mouseOverUI())
        {
            camera.move(mouseX - pmouseX, mouseY - pmouseY);
        }

        //TODO: Replace CENTER with CORNERS to render images

        //Draw input image
        // stroke(100);
        camera.render(input, input.width, input.height, 0, 0);

        // if(camera.effectiveZoom > 7)
        {
            strokeWeight(0.1);
            stroke(255, 100);
            // camera.renderGrid(input.width, input.height, 0, 0, stepSizeX, stepSizeY, output.width, output.height);
        }

        //Draw output image
        if(palettized != null)
        {
            camera.render(palettized, input.width, input.height, width/2, 0);
        }
        else
        {
            camera.render(output, input.width, input.height, width/2, 0);
        }

        noClip();

        //Draw divider line
        stroke(255);
        line(width/2, 0, width/2, height);

        //Offset info
        textAlign(LEFT, CENTER);
        textSize(10);
        text(camera.getCamData(), width/2+20, height-20);

        //Resolution info
        text(input.width + "x" + input.height, 20, height-20);
        textAlign(RIGHT, CENTER);
        text(output.width + "x" + output.height, width-20, height-20);
    }
}

//===== UTILS =====//
float clamp(float x, float min, float max)
{
    return min(max, max(x, min));
}

boolean between(float x, float start, float end)
{
    return start <= x && x <= end;
}