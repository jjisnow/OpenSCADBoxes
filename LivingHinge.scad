// Standalone hinge coupon. All dimensions in millimetres.
hingeHeight = 50;
angle = 90;
radius = 10;
thickness = 2.7;
slotRepeatMin = 2; slotLengthMin = 25; slotLengthGap = 2; slotWidth = 0.2;
bendAllowance = 1.2;
jointClearance = 0;
kerf = 0;
partGap = 3;
explodeDistance = 10;
outputMode = "cut"; // [cut,flat,preview]
include <lib/common.scad>

validateSettings()
{
    assert(angle != 0 && abs(angle) <= 360, "angle must be nonzero and within -360..360");
    assert(radius > 0 && thickness > 0 && hingeHeight > 0, "hinge dimensions must be positive");
    if (outputMode == "cut")
        cuttingProjection() livingHinge2D(hingeLength(angle, radius), hingeHeight, thickness);
    else if (outputMode == "flat")
        livingHinge2D(hingeLength(angle, radius), hingeHeight, thickness);
    else
        livingHinge3D(angle, radius, hingeHeight, thickness);
}
