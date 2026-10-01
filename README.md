# OpenSCADBoxes

Parametric laser-cut boxes with living hinges, based on the original designs by
Martin Raynsford (`msraynsford`). All dimensions are in **millimetres**.

| Script | Design | Cutting parts |
| --- | --- | --- |
| `LivingHinge.scad` | Hinge coupon for material/bend calibration | 1 |
| `FlexBox1.scad` | Two panels with perpendicular bends | 2 |
| `FlexBox2.scad` | Continuous wall strip and two oversized lids | 3 |

![Two-panel flex box](images/IMG_5071%20(Custom).JPG)
![Three-panel flex box](images/IMG_5342%20(Custom).JPG)

## Quick start

Install [OpenSCAD](https://openscad.org/downloads.html). The regression suite is
verified with OpenSCAD 2021.01. Download or clone the **whole repository**: the
entry scripts require `lib/common.scad` beside them.

1. Open a script and adjust the parameters at its top (or use the Customizer).
2. Leave `outputMode = "cut"` for the 2D cutting layout.
3. Render with **F6**, then choose **File → Export → Export as SVG** or DXF.
4. Import at 1:1 scale into the laser software and verify a known dimension.
   Cut outlines, including every hinge slot and joint hole; do not fill/engrave
   the filled areas of the SVG. Do not treat SVG stroke width as beam width.
5. Cut a hinge and joint sample in the intended material before a full box.

The default for all three scripts is now `cut`; FlexBox1 previously opened a
combined 3D display. Output mode is a parameter, so exporting needs no code edits.

### Command line

Run these commands from the repository directory:

```sh
openscad -o FlexBox1.svg FlexBox1.scad
openscad -o FlexBox2.dxf FlexBox2.scad
openscad -o custom.svg -D 'height=100' -D 'width=120' FlexBox2.scad
openscad -o preview.stl -D 'outputMode="preview"' FlexBox2.scad
openscad -o flat.stl -D 'outputMode="flat"' FlexBox1.scad
```

In Windows PowerShell, use OpenSCAD's console executable and escaped embedded
quotes for string parameters:

```powershell
& 'C:\Program Files\OpenSCAD\openscad.com' -o box.svg FlexBox2.scad
& 'C:\Program Files\OpenSCAD\openscad.com' -o flat.stl -D 'outputMode=\"flat\"' FlexBox1.scad
```

`cut` is 2D and exports to SVG/DXF; `flat` is a nominal 3D sheet layout;
`preview` shows folded parts. Preview bends are solid schematics without hinge
slits, and the default `explodeDistance=10` separates parts for inspection.
Set it to zero to bring the schematics together. These previews do not simulate
material deformation or certify physical fit. STL is for inspection, not the
laser cutting path. Kerf compensation applies only to `cut`.

## Parameters and calibration

| Parameter | Meaning |
| --- | --- |
| `height`, `width`, `depth` | Nominal dimensions used by the original design; not a guaranteed usable internal envelope |
| `thickness` | Measured sheet thickness, rather than its catalogue value |
| `cornerRadius` | Inner radius of the schematic bend |
| `tabLength` | Nominal tab width; complete tab patterns are centred on each straight edge |
| `slotRepeatMin` | Minimum spacing of slot rows across the bend length |
| `slotLengthMin` | Target minimum slot-column spacing along the hinge height; a narrow panel uses one column |
| `slotLengthGap` | Uncut bridge width between staggered slot segments |
| `slotWidth` | Nominal width of each rectangular slot |
| `bendAllowance` | Multiplier on ideal arc length; defaults are 1.02 for boxes and 1.2 for the coupon |
| `jointClearance` | Total extra width/length of mating slots; 0.1 mm for boxes, adjustable independently of kerf |
| `kerf` | Measured beam width; 0 disables compensation |
| `partGap` | Nominal separation of flat parts; must exceed kerf |
| `explodeDistance` | Preview separation; does not change cutting dimensions |
| `angle`, `radius`, `hingeHeight` | Standalone coupon parameters; signed, nonzero angle in −360…360 degrees |
| `curveSegments` | Shared curve resolution in `lib/common.scad`; integer ≥12, also overridable with `-D` |

Measure thickness and kerf on the actual sheet with the chosen laser settings.
With compensation enabled, the material outline expands by half the kerf:
outer toolpaths move out and hole toolpaths move in. Do **not** also apply kerf
compensation in the laser software. `jointClearance` remains the desired total
extra slot size after a correctly calibrated cut.

Kerf must be less than `slotWidth`, otherwise hinge slots disappear. If your
beam width is larger, increase the nominal slot width and recalibrate the hinge.
Changing slot pattern, sheet grain, thickness, material or bend allowance changes
bend behaviour. Test the coupon at the same bend radius and settings as the box;
copy its successful settings to the box, including `bendAllowance`.

The scripts reject nonpositive dimensions, impossible radii/tab patterns, and
hinges too short for even one row. Increase radius or reduce `slotRepeatMin`
when a hinge is too short. A small panel width no longer silently loses its slots.
FlexBox1 also needs room for its rounded end tabs, and FlexBox2 needs room for
tabs on each half of its split wall. Check OpenSCAD's console for assertions;
an exit code alone is insufficient on some versions.

The flat layout is a simple separated layout, not a sheet-packing optimiser.
Changing dimensions changes its size, but parts remain separate. The existing
`Pi Case 3.svg` is a legacy static drawing, not generated by these parameters.

## Development and regression checks

Python 3.9+ and OpenSCAD are sufficient; no Python packages are required:

```sh
python -m unittest discover -s tests -v
```

On Windows, use `py` instead of `python` if needed and set the console executable:

```powershell
$env:OPENSCAD = 'C:\Program Files\OpenSCAD\openscad.com'
py -m unittest discover -s tests -v
```

Tests render real SVG/STL outputs, reject warnings, check separate part outlines,
verify slots on small coupons, measure kerf and clearance changes, exercise
signed/full-circle bends, and require explicit failure for invalid inputs.
Temporary outputs are removed automatically. Run the suite before submitting a
change; keep shared hinges, tab patterns and validation in `lib/common.scad`.
No automatic GitHub Actions workflow is added; tests can run locally without CI
minutes. Physical cutting and bending still require material-specific trials.

## Origin and licensing

The original design process is described in the
[Instructables article](https://www.instructables.com/id/Laser-Cut-Parametric-Flex-Box-Generators/).
This repository descends from [daci6920/OpenSCADBoxes](https://github.com/daci6920/OpenSCADBoxes).
The original project promoted the vanillabox laser cutter; that historical shop
is not a dependency or an installation requirement.

Neither the source repository nor this fork declares a licence. See
[LICENSE.md](LICENSE.md) for the explicit status and the remaining permissions
needed before offering a redistribution licence.
