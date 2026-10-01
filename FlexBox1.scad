// Dimensions in millimetres. See README.md for export and calibration.
height = 40; width = 80; depth = 80;
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
    assert(height-2*cornerRadius >= tabLength+jointClearance, "height is too small for FlexBox1 rounded end tabs")
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
            translate([0, 0, 0])
                boxSide2D(width+(4*thickness), depth, height, thickness, cornerRadius, false);

            translate([(width+4*thickness)/2 + partGap + height/2 + thickness, 0, 0])
                boxSide2D(height, depth, width, thickness, cornerRadius, true);
        }
    }
    else
    {
        rotate([0,0,90])
        {
            translate([explodeDistance/2,0,0])
                boxSide3D(height, width, depth, thickness, cornerRadius, true);

            translate([-explodeDistance/2,0,0])
            rotate([90,0,180])
                boxSide3D(width+(4*thickness), height, depth, thickness,    cornerRadius, false);
        }
    }
}

module boxSide3D(height, width, depth, thickness, cornerRadius, tabsOut)
{
    faceWidth1 = depth-(2*cornerRadius);
    faceWidth2 = width-(2*cornerRadius);
    faceHeight = height;

    translate([(faceWidth1+thickness)/2 + cornerRadius,0,0])
    {
        translate([0,(faceWidth2+thickness)/2 + cornerRadius,0])
            livingHinge3D(90, cornerRadius, faceHeight, thickness);

            translate([0,-(faceWidth2+thickness)/2 + -cornerRadius,0])
            rotate([0,0,-90])
            livingHinge3D(90, cornerRadius, faceHeight, thickness);

        rotate([0,90,0])
            tabPanel(faceHeight, faceWidth2, thickness, tabLength, tabsOut);
    }

    rotate([-90,90,0])
    {
        translate([0,0,(faceWidth2+thickness)/2 + cornerRadius])
            boxEnd(faceHeight, faceWidth1, thickness, tabLength, cornerRadius, tabsOut);

        translate([0,0,-(faceWidth2+thickness)/2 - cornerRadius])
            boxEnd(faceHeight, faceWidth1, thickness, tabLength, cornerRadius, tabsOut);
    }
}

module boxSide2D(height, width, depth, thickness, cornerRadius, tabsOut)
{
    faceWidth1 = depth-(2*cornerRadius);
    faceWidth2 = width-(2*cornerRadius);
    hingeLength1 = hingeLength(90, cornerRadius);
    union()
    {
        tabPanel(height, faceWidth1, thickness, tabLength, tabsOut);

            translate([0,(faceWidth1 + hingeLength1)/2,0])
            {
                livingHinge2D(hingeLength1, height, thickness);

                translate([0,(hingeLength1 + faceWidth2)/2,0])
                    boxEnd(height, faceWidth2, thickness, tabLength, cornerRadius, tabsOut);
            }

        mirror([0,1,0])
            translate([0,(faceWidth1 + hingeLength1)/2,0])
            {
                livingHinge2D(hingeLength1, height, thickness);

                translate([0,(hingeLength1 + faceWidth2)/2,0])
                    boxEnd(height, faceWidth2, thickness, tabLength, cornerRadius, tabsOut);
            }
    }
}

module boxEnd(height, width, thickness, tabLength, cornerRadius, tabsOut)
{
    tabPanel(height, width, thickness, tabLength, tabsOut);

    translate([0,width/2,0])
        tabbedEnd( height, thickness, cornerRadius, tabsOut);
}


module tabbedEnd(panelWidth, panelThickness, radius, tabsOut)
{
    if (tabsOut)
        roundedEnd(panelWidth-(2*radius), panelThickness, radius, tabsOut);
    else
        roundedEnd(panelWidth-(2*radius)-(4*panelThickness), panelThickness, radius+(2*panelThickness), tabsOut);
}

module roundedEnd(faceWidth, panelThickness, radius, tabsOut)
{
    noTabs = tabCount(faceWidth, tabLength);

    if (tabsOut)
    {
        union()
        {
            translate([0,0,-panelThickness/2])
                roundedInsideEnd(faceWidth+(2*radius), panelThickness, radius);

            translate([0,radius+panelThickness/2,0])
                makeTabs(noTabs, tabLength, panelThickness);
        }
    }
    else
    {
        difference()
        {
            translate([0,0,-panelThickness/2])
                roundedInsideEnd(faceWidth+(2*radius), panelThickness, radius);

            translate([0,radius-(1.5*panelThickness),0])
                makeTabs(noTabs, tabLength, panelThickness, jointClearance, true);
        }
    }
}

module roundedInsideEnd(panelWidth, panelThickness, radius)
{
    sub = curveSegments;
    faceWidth = panelWidth - (2*radius);
    assert(faceWidth >= tabLength+jointClearance, "rounded end is too small for tabs");
    intersection()
    {
        translate([-panelWidth/2,0,0])
            cube([panelWidth, radius, panelThickness]);

        union()
        {
            translate([-faceWidth/2,0,0])
                cube([faceWidth, radius, panelThickness]);
            translate([-panelWidth/2 + radius,0,0])
                cylinder(r=radius, h=panelThickness, $fn=sub);
            translate([panelWidth/2 - radius,0,0])
                cylinder(r=radius, h=panelThickness, $fn=sub);
        }
    }
}
