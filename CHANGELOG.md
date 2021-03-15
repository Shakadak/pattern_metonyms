# Changelog

All notable changes to this project will be documented in this file. (Hopefully I won't forget much.)

## [Unreleased]

### Changed

- Implementation details, using new dependency

## [0.3.1] - 2021-03-11

### Changed

- Doc updated

### Added

- Anonymous functions can now be used with `view`

## [0.3.0] - 2020-12-18

### Changed

- Updated this changelog to try the format from [keep-a-changelog]
- Reworked `view` to handle remote calls, updated the doc accordingly

## [0.2.0] - 2020-12-18


### Changed

- Docs updated
- Reorganised the order of the patterns definitions, this allows to set the doc attribute for the version used by the programmer, and to hide the internal version used by `view`
- Added a vanilla definition for unidirectional pattern using a view, this permit to set a doc attribute usable by the programmer, improve discoverability, and signal with a better error message when the pattern is improperly used (from unknown definition to custom raise)
- Internal changes

### Added

- Guards can now be used with `view`

## [0.1.1] - 2020-12-04

### Fix

- `view/2` updated to use a unique variable before matching, avoiding repeated function call when it is the value to be matched on
- `pattern/1` : changed ast traversal from pre to post to avoid infinite loops during compilation (was present but forgotten in the changelog)

### Changed

- Docs updated

### Added

- Changelog creation

## [0.1.0] - 2020-12-03

### Added
* Base implementation

Changelog format inspired by [keep-a-changelog]

[keep-a-changelog]: https://github.com/olivierlacan/keep-a-changelog
[unreleased]: https://github.com/shakadak/pattern_metonyms/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/shakadak/pattern_metonyms/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/shakadak/pattern_metonyms/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/shakadak/pattern_metonyms/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/shakadak/pattern_metonyms/compare/b1810a9...v0.1.0
