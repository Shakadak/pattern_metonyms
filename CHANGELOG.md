# Changelog

All notable changes to this project will be documented in this file. (Hopefully I won't forget much.)

## [0.8.0] - 2022-06-21

### Added

- Added `PatternMetonyms.matchv?/2` as an equivalent to `match?/2`.

### Changed

- Doc improvements.

## [0.7.0] - 2022-06-20

### Added

- Added `PatternMetonyms.fit/2` as an equivalent to `=/2`.
- Added `PatternMetonyms.fit/1` to convert `=/2` to `PatternMetonyms.fit/2` within the do block.

## [0.6.1] - 2022-05-17

### Added

- Now handling equality patterns.

## [0.6.0] - 2021-11-03

### Added

- `PatternMetonyms.view/2` can now use any function in guards, as long as they return `true`.
- Added `PatternMetonyms.defv/2` to define named functions capable of the same things as `PatternMetonyms.view/2`.
- Added `PatternMetonyms.fnv/1` do defined anonymous functions capable of the same things as `PatternMetonyms.view/2`.

## [0.5.0] - 2021-10-20

### Changed

- Implicitly replace patterns defined using no args with patterns defined using an empty list of args.
- Improved the localisation of the pattern mentioned in the error message for patterns that can only be used inside `PatternMetonyms.view/2`.
- Breaking : require parentheses on raw views used with `PatternMetonyms.view/2`, and in views used with `PatternMetonyms.pattern/1`.
- Reworked `PatternMetonyms.view/2` to handle nested pattern usage

## [0.4.0] - 2021-05-14

### Changed

- Implementation details, using new dependency: Circe.
- Doc updated.

## [0.3.1] - 2021-03-11

### Changed

- Doc updated.

### Added

- Anonymous functions can now be used with `PatternMetonyms.view/2`.

## [0.3.0] - 2020-12-18

### Changed

- Updated this changelog to try the format from [keep-a-changelog].
- Reworked `PatternMetonyms.view/2` to handle remote calls, updated the doc accordingly.

## [0.2.0] - 2020-12-18


### Changed

- Docs updated.
- Reorganised the order of the patterns definitions, this allows to set the doc attribute for the version used by the programmer, and to hide the internal version used by `PatternMetonyms.view/2`.
- Added a vanilla definition for unidirectional pattern using a view, this permits setting a doc attribute usable by the programmer, improves discoverability, and signal with a better error message when the pattern is improperly used (from unknown definition to custom raise).
- Internal changes.

### Added

- Guards can now be used with `PatternMetonyms.view/2`.

## [0.1.1] - 2020-12-04

### Fix

- `PatternMetonyms.view/2` updated to use a unique variable before matching, avoiding repeated function call when it is the value to be matched on.
- `PatternMetonyms.pattern/1` : changed ast traversal from pre to post to avoid infinite loops during compilation (was present but forgotten in the changelog).

### Changed

- Docs updated.

### Added

- Changelog creation.

## [0.1.0] - 2020-12-03

### Added
* Base implementation.

Changelog format inspired by [keep-a-changelog].

[keep-a-changelog]: https://github.com/olivierlacan/keep-a-changelog
[unreleased]: https://github.com/shakadak/pattern_metonyms/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/shakadak/pattern_metonyms/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/shakadak/pattern_metonyms/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/shakadak/pattern_metonyms/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/shakadak/pattern_metonyms/compare/b1810a9...v0.1.0
