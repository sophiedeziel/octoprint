## [Unreleased]

## [0.1.0] - 2026-11-16

Initial release. Targets OctoPrint 1.11.x and Ruby 3.3+.

- Covers the OctoPrint REST API: files, job, printer, printer profiles, slicing, connection, languages, logs, timelapse, access control (users, groups, permissions, login/logout), settings, system commands, wizard, util, and server version/information.
- Supports one global client or several clients for multiple printers, with configurable timeouts.
- Maps HTTP errors to specific exception classes, including `TimeoutError` and `ConnectionError`.
- Ships RBI files so Sorbet users get types for the gem.
