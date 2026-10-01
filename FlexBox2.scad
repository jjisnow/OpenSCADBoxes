// Dimensions in millimetres. See README.md for export and calibration.
height = 30; width = 100; depth = 60;
thickness = 2.7; cornerRadius = 10; tabLength = 10;
slotRepeatMin = 2; slotLengthMin = 20; slotLengthGap = 2; slotWidth = 0.2;
bendAllowance = 1.02;
// Total extra width of a mating slot; independent of kerf compensation.
jointClearance = 0.1;
kerf = 0;
partGap = 3;
explodeDistance = 10;
outputMode = "cut"; // [cut,flat,preview]
include <lib/common.scad>

validateBox(height, width, depth, thickness, cornerRadius, tabLength)
    assert((width-2*cornerRadius)/2 >= tabLength+jointClearance, "split wall is too short for tabs")
    if (outputMode == "cut")
        cuttingProjection() makeBox(true);
    else if (outputMode == "flat")
        makeBox(true);
    else
        makeBox(false);

// Flat layout uses nominal bounds, leaving partGap before kerf compensation.
// Folded parts are schematic; explodeDistance controls inspection spacing.
module makeBox(flat)
{
    if (flat)
    {
        union()
        {
            translate([0, width+4*thickness+partGap, (height+thickness)/2])
                boxLid(height, width, depth, thickness, cornerRadius);

            translate([0, 0, (height+thickness)/2])
                boxLid(height, width, depth, thickness, cornerRadius);

            translate([depth/2+2*thickness+partGap+height/2+thickness, 0, 0])
                boxSide2D(height, depth, width, thickness, cornerRadius, true);
        }
    }
    else
    {
        boxSide3D(height, width, depth, thickness, cornerRadius, true);

        translate([0,0,-explodeDistance])
            boxLid(height, width, depth, thickness, cornerRadius);

        translate([0,0,height +explodeDistance])
            boxLid(height, width, depth, thickness, cornerRadius);
    }
}

module boxLid(height, width, depth, thickness, cornerRadius)
{
    difference()
    {
        translate([0, 0, -(height+thickness)/2])
            roundedRectangle(width+(thickness*2), depth+(thickness*2), thickness, cornerRadius);

        boxSide3D(height, width, depth, thickness, cornerRadius, true, true);
    }
}

// Preserve the original oversized envelope, using a true rounded outline.
module roundedRectangle(panelWidth, panelDepth, panelThickness, radius)
{
    cornerX = panelDepth/2-radius;
    cornerY = panelWidth/2-radius;
    linear_extrude(height=panelThickness, center=true)
        hull()
            for (x=[-cornerX,cornerX], y=[-cornerY,cornerY])
                translate([x,y]) circle(r=radius+panelThickness, $fn=curveSegments);
}

module boxSide3D(height, width, depth, thickness, cornerRadius, tabsOut, slotCutter=false)
{
    faceWidth1 = depth-(2*cornerRadius);
    faceWidth2 = width-(2*cornerRadius);
    faceHeight = height;

    translate([(faceWidth1+thickness)/2 + cornerRadius,0,0])
    {
        translate([0,(faceWidth2+thickness)/2 + cornerRadius,0])
            livingHinge3D(90, cornerRadius, faceHeight, thickness);

        translate([0, -(faceWidth2+thickness)/2 - cornerRadius,0])
            rotate([0,0,-90])
                livingHinge3D(90, cornerRadius, faceHeight, thickness);

        rotate([0,90,0])
            tabPanel(faceHeight, faceWidth2, thickness, tabLength, tabsOut, slotCutter);
    }

    translate([-(faceWidth1+thickness)/2 - cornerRadius,0,0])
    rotate([0,0,180])
    {
        translate([0,(faceWidth2+thickness)/2 + cornerRadius,0])
            livingHinge3D(90, cornerRadius, faceHeight, thickness);

        translate([0, -(faceWidth2+thickness)/2 - cornerRadius,0])
            rotate([0,0,-90])
                livingHinge3D(90, cornerRadius, faceHeight, thickness);

        //Make 2 half panels for the final side
        translate([0,faceWidth2/4,0])
        rotate([0,90,0])
            tabPanel(faceHeight, faceWidth2/2, thickness, tabLength, tabsOut, slotCutter);

        translate([0,-faceWidth2/4,0])
        rotate([0,90,0])
            tabPanel(faceHeight, faceWidth2/2, thickness, tabLength, tabsOut, slotCutter);
    }

    rotate([-90,90,0])
    {
        translate([0,0,(faceWidth2+thickness)/2 + cornerRadius])
            tabPanel(faceHeight, faceWidth1, thickness, tabLength, tabsOut, slotCutter);

        translate([0,0,-(faceWidth2+thickness)/2 - cornerRadius])
            tabPanel(faceHeight, faceWidth1, thickness, tabLength, tabsOut, slotCutter);
    }
}

module boxSide2D(height, width, depth, thickness, cornerRadius, tabsOut)
{
    faceWidth1 = depth-2*cornerRadius;
    union()
    {
        tabPanel(height, faceWidth1, thickness, tabLength, tabsOut);
        boxPart2D(height, width, depth, thickness, cornerRadius, tabsOut);

        mirror([0,1,0])
            boxPart2D(height, width, depth, thickness, cornerRadius, tabsOut);
    }
}

module boxPart2D(height, width, depth, thickness, cornerRadius, tabsOut)
{
    faceWidth1 = depth-(2*cornerRadius);
    faceWidth2 = width-(2*cornerRadius);
    hingeLength1 = hingeLength(90, cornerRadius);

    translate([0,(faceWidth1 + hingeLength1)/2,0])
    {
        livingHinge2D(hingeLength1, height, thickness);

        translate([0,(hingeLength1 + faceWidth2)/2,0])
        {
            tabPanel(height, faceWidth2, thickness, tabLength, tabsOut);

            translate([0,(hingeLength1 + faceWidth2)/2,0])
            {
                livingHinge2D(hingeLength1, height, thickness);

                translate([0,(hingeLength1 + faceWidth1/2)/2,0])
                    tabPanel(height, faceWidth1/2, thickness, tabLength, tabsOut);
            }
        }
    }
}
