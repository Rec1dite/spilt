import controlP5.*;
//See [https://sojamo.de/libraries/controlP5/reference/index.html]

ControlP5 cp5;
Numberbox nbxWidth, nbxHeight, nbxPosterize;
CheckBox cbxAutoHeight;

static final int fullHoverBounds = 20;

PImage input, output;
int offsetX = 0, offsetY = 0;
float zoom = 0, effectiveZoom = 1.0;

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
}

//The main algorithm where we extract the pixel art from the input image
void extract()
{
    input.loadPixels();

    int outputW = (int)nbxWidth.getValue();
    int outputH = (int)nbxHeight.getValue();

    int stepSizeX = input.width/outputW;
    int stepSizeY;

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
    output.filter(POSTERIZE, (int)nbxPosterize.getValue());
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

void mouseWheel(MouseEvent event)
{
    if(currScreen == "bothImg" && !(between(mouseX, width/2-225, width/2) && between(mouseY, height-155, height)))
    {
        float e = event.getCount();
        zoom += e;
        zoom = clamp(zoom, -28, 20);
        effectiveZoom = pow(0.8, zoom);
        // offsetX *= effectiveZoom;
        // offsetY *= effectiveZoom;

        if(zoom >= 0)
        {
            offsetX = 0;
            offsetY = 0;
        }
    }
}

void controlEvent(ControlEvent event)
{
    if(event.isFrom(nbxWidth) || event.isFrom(nbxHeight) || event.isFrom(nbxPosterize))
    {
        extract();
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

        if(mousePressed && !(between(mouseX, width/2-225, width/2) && between(mouseY, height-105, height)))
        {
            offsetX += mouseX - pmouseX;
            offsetY += mouseY - pmouseY;
        }

        //Draw input/output images
        clip(width/4, height/2, width/2, height);
        stroke(100);
        image(input, width/4 + offsetX, height/2 + offsetY, effectiveZoom*width/2, effectiveZoom*height/2);

        clip(3*width/4, height/2, width/2, height);
        image(output, 3*width/4 + offsetX, height/2 + offsetY, effectiveZoom*width/2, effectiveZoom*height/2);

        noClip();

        if(effectiveZoom > 300) //Draw pixel gridlines
        {

        }

        //Draw divider line
        stroke(255);
        line(width/2, 0, width/2, height);

        //Offset info
        textAlign(LEFT, CENTER);
        textSize(10);
        text("Offset: " + offsetX + ", " + offsetY + " | Zoom: " + zoom + " => " + effectiveZoom, width/2+20, height-20);

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