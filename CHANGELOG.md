# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.5.1]] - 2019-02-28

### Added

- Add a Changelog.
- Add Makefile target to better clean up the project.

### Changed

- Use ShipStation's version of the TeamCIty SDK by default.
- Mark the API Key as sensitive information.
- Increase test timeout.
- Configure the test TeamCity Docker container to run with the option `rest.listSecureProperties=true`.

### Fixed

- Fix Octopus Push Package step `additional_command_line_arguments` option.

## [[0.4.0-64-0.5.0]] - 2019-02-26

### Fixed

- Fix incorrect buld step ordering. Merged [upstream fix](https://github.com/cvbarros/terraform-provider-teamcity/commit/958e0fec92a1bf2f6a1a59f4bf38f54cc08854cb).

## [0.4.0]

Base upstream version.

[//]: # (Release links)
[0.4.0]: https://github.com/shipstation/terraform-provider-teamcity/releases/tag/0.4.0
[0.4.0-64-0.5.0]: https://github.com/shipstation/terraform-provider-teamcity/releases/tag/0.4.0-64-0.5.0
[0.5.1]: https://github.com/shipstation/terraform-provider-teamcity/releases/tag/0.5.1

[//]: # (Issue/PR links)
