"""Render actual geometry; Python's standard library and OpenSCAD are sufficient."""
from pathlib import Path
import math
import os
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OPENSCAD = os.environ.get("OPENSCAD", "openscad")
NUMBER = r"[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?"


def polygons(svg):
    """Read OpenSCAD's polygon-only SVG output, preserving outer/hole winding."""
    result = []
    document = ET.fromstring(svg)
    for path in document.iter("{http://www.w3.org/2000/svg}path"):
        for loop in re.findall(r"M\s+(.*?)\s*[zZ]", path.attrib["d"], re.S):
            points = [tuple(map(float, pair)) for pair in
                      re.findall(f"({NUMBER}),({NUMBER})", loop)]
            if len(points) < 3:
                raise AssertionError("Degenerate SVG contour")
            area = sum(x*y2-x2*y for (x, y), (x2, y2) in
                       zip(points, points[1:]+points[:1]))/2
            bounds = (min(x for x, _ in points), min(y for _, y in points),
                      max(x for x, _ in points), max(y for _, y in points))
            result.append((area, bounds))
    if not result:
        raise AssertionError("SVG has no contours")
    return result


class GeometryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which(OPENSCAD):
            raise RuntimeError("OpenSCAD is required; put it on PATH or set OPENSCAD")
        cls.directory = tempfile.TemporaryDirectory(prefix="openscad-boxes-tests-")
        cls.addClassCleanup(cls.directory.cleanup)
        cls.counter = 0

    def render(self, model, extension="svg", invalid=None, **parameters):
        type(self).counter += 1
        target = Path(self.directory.name)/f"render-{self.counter}.{extension}"
        command = [OPENSCAD, "-o", str(target)]
        for key, value in parameters.items():
            literal = f'"{value}"' if isinstance(value, str) else str(value)
            command.extend(["-D", f"{key}={literal}"])
        process = subprocess.run(command+[str(ROOT/model)], capture_output=True,
                                 text=True, timeout=120)
        log = process.stdout+process.stderr
        if invalid:
            # Some OpenSCAD versions return zero even for bad geometry.
            self.assertIn("ERROR: Assertion", log, log)
            self.assertIn(invalid, log, log)
            self.assertFalse(target.exists() and target.stat().st_size > 0, log)
            return None
        self.assertEqual(process.returncode, 0, log)
        self.assertNotRegex(log, r"WARNING:|ERROR:|DEPRECATED:|\b(?:nan|inf)\b", log)
        self.assertTrue(target.is_file() and target.stat().st_size, log)
        return target.read_text()

    def assert_parts(self, svg, count):
        outlines = [bounds for area, bounds in polygons(svg) if area < 0]
        self.assertEqual(len(outlines), count, "Parts have merged or split")
        # These layouts deliberately use separate bounding boxes, not nesting.
        for index, (left, top, right, bottom) in enumerate(outlines):
            for left2, top2, right2, bottom2 in outlines[index+1:]:
                self.assertTrue(right < left2 or right2 < left or
                                bottom < top2 or bottom2 < top,
                                "Cut parts overlap or touch")

    def test_default_cut_exports(self):
        for name, count in [("LivingHinge.scad", 1), ("FlexBox1.scad", 2), ("FlexBox2.scad", 3)]:
            with self.subTest(model=name):
                self.assert_parts(self.render(name), count)

    def test_small_hinge_retains_slots(self):
        svg = self.render("LivingHinge.scad", hingeHeight=10)
        contours = polygons(svg)
        self.assert_parts(svg, 1)
        material_area = -sum(area for area, _ in contours)
        expected_blank_area = 10*2*math.pi*10*90/360*1.2
        self.assertLess(material_area, expected_blank_area-1)

    def test_tall_box_layout_and_other_aspect_ratios(self):
        for model, settings, count in [
            ("FlexBox2.scad", {"height": 100}, 3),
            ("FlexBox2.scad", {"width": 83, "depth": 67, "height": 55}, 3),
            ("FlexBox2.scad", {"width": 60, "depth": 120, "height": 10}, 3),
            ("FlexBox1.scad", {"width": 110, "depth": 75, "height": 60}, 2),
        ]:
            with self.subTest(model=model, settings=settings):
                self.assert_parts(self.render(model, **settings), count)

    def test_kerf_moves_outer_and_inner_boundaries(self):
        before = polygons(self.render("LivingHinge.scad"))
        after = polygons(self.render("LivingHinge.scad", kerf=0.1))
        self.assertEqual(len(before), len(after))
        outer_before = next(bounds for area, bounds in before if area < 0)
        outer_after = next(bounds for area, bounds in after if area < 0)
        for index, direction in enumerate([-1, -1, 1, 1]):
            self.assertAlmostEqual(outer_after[index]-outer_before[index], direction*0.05, delta=0.001)
        holes_before = sorted(bounds for area, bounds in before if area > 0)
        holes_after = sorted(bounds for area, bounds in after if area > 0)
        self.assertTrue(holes_before)
        for first, second in zip(holes_before, holes_after):
            self.assertAlmostEqual((first[3]-first[1])-(second[3]-second[1]), 0.1, delta=0.001)

    def test_kerf_preserves_separate_parts(self):
        for model, count in [("FlexBox1.scad", 2), ("FlexBox2.scad", 3)]:
            self.assert_parts(self.render(model, kerf=0.1, partGap=0.5), count)

    def test_clearance_expands_lid_holes_without_moving_centres(self):
        before = sorted(bounds for area, bounds in polygons(self.render("FlexBox2.scad", jointClearance=0)) if area > 0)
        after = sorted(bounds for area, bounds in polygons(self.render("FlexBox2.scad", jointClearance=0.3)) if area > 0)
        self.assertEqual(len(before), len(after))
        self.assertEqual(len(before), 24)
        for first, second in zip(before, after):
            for low, high in [(0, 2), (1, 3)]:
                self.assertAlmostEqual((second[low]+second[high])/2,
                                       (first[low]+first[high])/2, delta=0.001)
                self.assertAlmostEqual((second[high]-second[low])-
                                       (first[high]-first[low]), 0.3, delta=0.001)

    def test_flat_and_preview_stl_exports(self):
        for model in ["LivingHinge.scad", "FlexBox1.scad", "FlexBox2.scad"]:
            for mode in ["flat", "preview"]:
                with self.subTest(model=model, mode=mode):
                    self.assertIn("facet normal", self.render(model, "stl", outputMode=mode))

    def test_full_circle_and_signed_angles(self):
        for angle in [90, -90, 180, 270, 360, -360]:
            with self.subTest(angle=angle):
                self.assertIn("facet normal", self.render("LivingHinge.scad", "stl", outputMode="preview", angle=angle))

    def test_invalid_parameters_fail_explicitly(self):
        cases = [
            ("LivingHinge.scad", {"radius": 1}, "hinge is too short"),
            ("LivingHinge.scad", {"hingeHeight": 1}, "hinge width"),
            ("LivingHinge.scad", {"angle": 0}, "angle must be nonzero"),
            ("LivingHinge.scad", {"angle": 361}, "angle must be nonzero"),
            ("FlexBox2.scad", {"cornerRadius": 30}, "cornerRadius"),
            ("FlexBox2.scad", {"thickness": 0}, "box dimensions"),
            ("FlexBox2.scad", {"tabLength": 0}, "tabLength"),
            ("FlexBox2.scad", {"slotRepeatMin": 0}, "slot spacing"),
            ("FlexBox2.scad", {"slotLengthMin": 0}, "slot spacing"),
            ("FlexBox2.scad", {"slotLengthGap": 30}, "hinge width"),
            ("FlexBox2.scad", {"kerf": 0.2}, "kerf"),
            ("FlexBox2.scad", {"kerf": 0.1, "partGap": 0.1}, "partGap"),
            ("FlexBox1.scad", {"height": 10}, "rounded end tabs"),
            ("FlexBox1.scad", {"jointClearance": -1}, "jointClearance"),
            ("FlexBox1.scad", {"outputMode": "unknown"}, "outputMode"),
        ]
        for model, parameters, message in cases:
            with self.subTest(model=model, parameters=parameters):
                self.render(model, invalid=message, **parameters)


if __name__ == "__main__":
    unittest.main(verbosity=2)
