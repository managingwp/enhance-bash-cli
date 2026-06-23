# AGENTS.md

## Development Workflow

* Don't create test files such as bash scripts or php scripts in the main codebase.
* **Auto-commit after every change.** After completing any code changes (fixes, features, refactors, etc.), automatically create a git commit with a descriptive message using conventional commit format (`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`). Do not wait for the user to ask — commit immediately after the changes are verified. Print the commit message when finishing the work.
* Search `doc/` folder before creating new documentation files to avoid duplicates.
* After completing code work, suggest testing methods for the change to complete.

## Enhance API

* The enhance api openapi document is in `doc/enhance-api.yaml`. Use it to generate code or documentation.