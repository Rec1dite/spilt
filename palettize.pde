enum PalettizeMethod
{
    SimpleRandom,
    KMeans
}

color[] palettize(int numColors, PalettizeMethod method)
{
    if(numColors == 0) //Revert to unpalettized output
    {
        palettized = null;
        return new color[] {};
    }

    color[] newPalette = new color[] {};

    switch(method)
    {
        case SimpleRandom:
            newPalette = palettize_simpleRandom(numColors, output);
            break;
        case KMeans:
            newPalette = palettize_kMeans(numColors, output);
            break;
    }

    //Update palettized image with new palette
    if(newPalette.length > 0)
    {
        palettized = createImage(output.width, output.height, RGB);
        palettized.loadPixels();

        for(int x = 0; x < output.width; x++)
        for(int y = 0; y < output.height; y++)
        {
            //Find closest cluster point for each pixel
            color pix = output.pixels[x + y*output.width];
            color closestPaletteCol = newPalette[0];
            int closestPaletteColDist = sqColorDist_euclideanRGB(pix, closestPaletteCol);

            for(int p = 1; p < numColors; p++)
            {
                int dist = sqColorDist_euclideanRGB(pix, newPalette[p]);
                if(dist < closestPaletteColDist)
                {
                    closestPaletteCol = newPalette[p];
                    closestPaletteColDist = dist;
                }
            }

            palettized.pixels[x + y*output.width] = closestPaletteCol;
        }
        palettized.updatePixels();
    }

    return newPalette;
}

//Literally just picks random points on the image as the color palette
color[] palettize_simpleRandom(int numColors, PImage img)
{
    img.loadPixels();
    color[] paletteCols = new color[numColors];

    //Pick random points
    for(int c = 0; c < numColors; c++)
    {
        int randX = (int)random(img.width);
        int randY = (int)random(img.height);
        paletteCols[c] = img.pixels[randX + randY*img.width];
    }

    return paletteCols;
}

class LargeColor
{
    int r;
    int g;
    int b;

    LargeColor()
    {
        this.r = 0;
        this.g = 0;
        this.b = 0;
    }

    //Vector addition
    void add(color c)
    {
        this.r += ((c >> 16) & 0xFF);
        this.g += ((c >> 8) & 0xFF);
        this.b += (c & 0xFF);
    }
}

//Pick palette using k-Means clustering algorithm
color[] palettize_kMeans(int numColors, PImage img)
{
    final int numEpochs = 32;

    img.loadPixels();
    color[] clusterPoints = new color[numColors];

    //Pick random starting points
    for(int c = 0; c < numColors; c++)
    {
        int randX = (int)random(img.width);
        int randY = (int)random(img.height);
        clusterPoints[c] = img.pixels[randX + randY*img.width];
    }

    //Move cluster points towards their respective means each epoch
    for(int e = 0; e < numEpochs; e++) //Epoch
    {
        //Calculate the mean for each cluster
        LargeColor[] clusterTotals = new LargeColor[numColors];
        for(int c = 0; c < numColors; c++) { clusterTotals[c] = new LargeColor(); }
        int[] clusterSizes = new int[numColors];

        //Loop through image
        for(int x = 0; x < img.width; x++)
        for(int y = 0; y < img.height; y++)
        {
            //Find closest existing cluster point for this pixel
            color pix = img.pixels[x + y*img.width];

            int closestClusterPointIndex = 0;
            int closestClusterPointDist = sqColorDist_euclideanRGB(pix, clusterPoints[0]);

            for(int p = 1; p < numColors; p++)
            {
                int dist = sqColorDist_euclideanRGB(pix, clusterPoints[p]);
                if(dist < closestClusterPointDist)
                {
                    closestClusterPointIndex = p;
                    closestClusterPointDist = dist;
                }
            }

            //Add pixel to cluster
            clusterTotals[closestClusterPointIndex].add(pix);
            clusterSizes[closestClusterPointIndex]++;
        }

        //Update each cluster point to its respective mean
        for(int p = 0; p < numColors; p++)
        {
            if(clusterSizes[p] != 0)
            {
                clusterPoints[p] = color(
                    clusterTotals[p].r / clusterSizes[p],
                    clusterTotals[p].g / clusterSizes[p],
                    clusterTotals[p].b / clusterSizes[p]
                );
            }
        }
    }

    return clusterPoints;
}

//Returns the squared euclidean distance between two colors (in RGB space)
int sqColorDist_euclideanRGB(color a, color b)
{
    int dr =  ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
    int dg =  ((a >> 8) & 0xFF)  - ((b >> 8) & 0xFF);
    int db =  (a & 0xFF)         - (b & 0xFF);

    return dr*dr + dg*dg + db*db;
}

int sqColorDist_euclideanHSL(color a, color b)
{
    float dh = hue(a) - hue(b);
    float ds = saturation(a) - saturation(b);
    float db = brightness(a) - brightness(b);

    return (int)(dh*dh + ds*ds + db + db);
}