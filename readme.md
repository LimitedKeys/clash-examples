# Clash learning

## Create a New Project

From:  

    https://github.com/clash-lang/stack-templates

> stack new my-clash-project clash-lang/simple

Things I do to clean it up after project creation:

- Remove Test libraries from cabal file
- Remove `tests` 
- Remove `src\Example`
- Create a new source file directory / file
- Update cabal file to use the new source file path

To build:

> stack build

The initial build takes FOREVER.

# Projects

- [Learning / Work with Registers](./registers/readme.md)
