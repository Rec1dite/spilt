class Camera
{
    int startX, startY;
    int posX, posY;
    int camW, camH;
    float zoom = 0, effectiveZoom = 1.0;

    Camera(int x, int y, int w, int h)
    {
        this.startX = x;
        this.startY = y;
        this.posX = x;
        this.posY = y;
        this.camW = w;
        this.camH = h;
    }

    //Render an image at (0, 0) relative to the position and zoom of the camera
    //imgW/imgH is the size to rescale the image to
    //x/y is the top left pixel at which to render the whole camera view
    void render(PImage img, int imgW, int imgH, int x, int y)
    {
        // image(input, width/4 + offsetX, height/2 + offsetY, effectiveZoom*width/2, effectiveZoom*height/2);
        // image(input, offsetX, offsetY, effectiveZoom*width/2, effectiveZoom*hwRatio*width/2);
        // image(output, 3*width/4 + offsetX, height/2 + offsetY, effectiveZoom*width/2, effectiveZoom*height/2);
        imageMode(CORNER);
        clip(x, y, camW, camH);

        imageMode(CENTER);

        pushMatrix();
            translate(x+camW/2, y+camH/2); //Offset relative to cam center
                scale(effectiveZoom); //Perform camera transformations
                translate(posX, posY); //Undo
            translate(-x-camW/2, -y-camH/2); //Un-offset relative to cam TL corner

        image(img, x, y, imgW, imgH);

        popMatrix();

        final int crosshairSize = 10;
        stroke(255);
        line(x+camW/2, y+camH/2-crosshairSize, x+camW/2, y+camH/2+crosshairSize);
        line(x+camW/2-crosshairSize, y+camH/2, x+camW/2 + crosshairSize, y+camH/2);
    }

    void move(int dx, int dy)
    {
        this.posX += dx/effectiveZoom;
        this.posY += dy/effectiveZoom;
    }

    String getCamData()
    {
        return "Pos: " + posX + ", " + posY + " | Zoom: " + zoom + " => " + effectiveZoom;
    }

    void onZoom(float e)
    {
        zoom += e;
        zoom = clamp(zoom, -28, 20);
        effectiveZoom = pow(0.8, zoom);
        // offsetX *= effectiveZoom;
        // offsetY *= effectiveZoom;

        // if(zoom >= 0)
        // {
            // posX = startX;
            // posY = startY;
        // }
    }
}