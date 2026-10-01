// Shared geometry. Include from a configured entry script, not on its own.
// Boolean cutters overshoot only the through-cut axis; this is not fit allowance.
epsilon = 0.01;
curveSegments = 96;
function hingeLength(angle, radius) = 2*PI*radius*abs(angle)/360*bendAllowance;
function tabCount(span, length) = ceil(floor(span/length)/2);

module validateSettings()
{
    assert(outputMode == "cut" || outputMode == "flat" || outputMode == "preview",
           "outputMode must be cut, flat or preview");
    assert(slotRepeatMin > 0 && slotLengthMin > 0, "slot spacing must be positive");
    assert(slotWidth > 0 && slotWidth < slotRepeatMin, "slotWidth must be between 0 and slotRepeatMin");
    assert(slotLengthGap > 0, "slotLengthGap must be positive");
    assert(bendAllowance > 0, "bendAllowance must be positive");
    assert(jointClearance >= 0, "jointClearance must be nonnegative");
    assert(kerf >= 0 && kerf < slotWidth, "kerf must be nonnegative and less than slotWidth");
    assert(partGap > kerf, "partGap must exceed kerf");
    assert(explodeDistance >= 0, "explodeDistance must be nonnegative");
    assert(curveSegments >= 12 && curveSegments == floor(curveSegments), "curveSegments must be an integer >= 12");
    children();
}

module validateBox(height, width, depth, thickness, radius, tabLength)
{
    validateSettings()
    {
        assert(height > 0 && width > 0 && depth > 0 && thickness > 0, "box dimensions must be positive");
        assert(radius > 0 && 2*radius < min(width, depth), "cornerRadius must be positive and less than half width/depth");
        assert(tabLength > jointClearance, "tabLength must be positive and exceed jointClearance");
        assert(jointClearance < thickness, "jointClearance must be less than thickness");
        assert(height > 2*thickness + jointClearance, "height is too small for opposing joints");
        assert(min(width, depth)-2*radius >= tabLength + jointClearance,
               "straight walls are too short for the requested tabs and clearance");
        children();
    }
}

// Expand material by half the beam width: outer paths move out, holes move in.
// Apply exactly once, to cut output only. Flat/preview retain nominal geometry.
module cuttingProjection()
{
    if (kerf > 0)
        offset(delta=kerf/2) projection() children();
    else
        projection() children();
}

module livingHinge2D(panelLength, panelWidth, panelThickness)
{
    assert(panelLength >= 2*slotRepeatMin, "hinge is too short for a slot row; increase radius or reduce slotRepeatMin");
    assert(panelWidth > slotLengthGap && panelThickness > 0, "hinge width must exceed slotLengthGap and thickness must be positive");
    // A narrow hinge uses one column instead of dividing by zero.
    widthDiv = max(1, floor(panelWidth/slotLengthMin));
    noSlots = floor(panelLength/slotRepeatMin)-1;
    slotRepeat = panelWidth/widthDiv;
    slotLength = panelLength/(noSlots+1);
    assert(slotRepeat > slotLengthGap + kerf, "slotLengthGap/kerf leaves no usable hinge slot");
    difference()
    {
        cube([panelWidth, panelLength, panelThickness], true);
        translate([-panelWidth/2, -panelLength/2, -panelThickness/2-epsilon])
            for (column=[0:widthDiv-1], row=[1:noSlots])
                translate([column*slotRepeat + slotLengthGap*((column+row+1)%2),
                           row*slotLength-slotWidth/2, 0])
                    cube([slotRepeat-slotLengthGap, slotWidth, panelThickness+2*epsilon]);
    }
}

// Solid curved schematic: it deliberately omits the flat hinge's cut pattern.
// Signed angles choose direction; zero is rejected; +/-360 produces a ring.
module livingHinge3D(angle, radius, panelWidth, panelThickness)
{
    assert(angle != 0 && abs(angle) <= 360, "angle must be nonzero and within -360..360");
    assert(radius > 0 && panelWidth > 0 && panelThickness > 0, "curved hinge dimensions must be positive");
    translate([-(radius+panelThickness/2), -(radius+panelThickness/2), -panelWidth/2])
        rotate([0,0,angle < 0 ? angle : 0])
            rotate_extrude(angle=abs(angle), $fn=curveSegments)
                translate([radius,0]) square([panelThickness,panelWidth]);
}

// A folded lid cutter passes through local Y after rotation; flat cuts use Z.
module makeTabs(noTabs, tabLength, panelThickness, clearance=0, cutter=false, lidCutter=false)
{
    assert(noTabs >= 1 && noTabs == floor(noTabs), "panel is too short for any tabs");
    assert(tabLength > 0 && panelThickness > 0 && clearance >= 0, "tab dimensions must be positive");
    for (i=[-noTabs+1:2:noTabs-1])
        translate([i*tabLength,0,0])
            cube([tabLength+clearance, panelThickness+clearance+(lidCutter ? 2*epsilon : 0),
                  panelThickness+clearance+(cutter && !lidCutter ? 2*epsilon : 0)], true);
}

module tabPanel(panelHeight, panelWidth, panelThickness, tabLength, tabsOut=false, slotCutter=false)
{
    assert(panelHeight > 0 && panelWidth >= tabLength + jointClearance && panelThickness > 0,
           "panel dimensions are too small for tabs and clearance");
    noTabs = tabCount(panelWidth, tabLength);
    if (tabsOut)
        union()
        {
            cube([panelHeight, panelWidth, panelThickness], true);
            for (side=[-1,1])
                translate([side*(panelHeight+panelThickness)/2,0,0])
                    rotate([0,0,90])
                        makeTabs(noTabs, tabLength, panelThickness,
                                 slotCutter ? jointClearance : 0, slotCutter, slotCutter);
        }
    else
        difference()
        {
            cube([panelHeight, panelWidth, panelThickness], true);
            for (side=[-1,1])
                translate([side*(panelHeight-3*panelThickness)/2,0,0])
                    rotate([0,0,90])
                        makeTabs(noTabs, tabLength, panelThickness, jointClearance, true);
        }
}
