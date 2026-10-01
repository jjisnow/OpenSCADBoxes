# Changelog

## Unreleased

- Default every entry script to direct 2D export; add cut/flat/preview modes.
- Consolidate hinges, tab patterns, validation and cutting projection in one library.
- Keep a slot column on narrow hinges and reject undersized/invalid patterns.
- Replace pie subtraction with signed rotate-extrude bends, including full circles.
- Attach final split-wall panels using their actual length for unequal width/depth.
- Use calculated part bounds for separated cutting layouts at different box heights.
- Expose joint clearance, kerf, bend allowance, part spacing and preview spacing.
- Generate oversized lids with one smooth rounded outline instead of overlapping primitives.
- Keep lid slot centres at nominal wall positions when changing clearance.
- Use through-cut Boolean overshoot and remove redundant off-panel hinge cutters.
- Add geometry regression tests, export/calibration instructions and provenance.
- Record unresolved upstream licensing without inventing a redistribution grant.

Old exports are not byte-for-byte compatible: layouts, curve resolution, the PI
approximation and joint clearance have changed. Re-export designs and calibrate
fit and bend settings before a production cut.
