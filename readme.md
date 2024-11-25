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

## Resources

- [Clash.Prelude](https://hackage.haskell.org/package/clash-prelude-1.8.1)
- [Clash.Prelude : TopEntity](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Annotations-TopEntity.html)
- [Clash-lang Discourse Group](https://clash-lang.discourse.group/)
- [An Introduction to Type Level Programming](https://rebeccaskinner.net/posts/2021-08-25-introduction-to-type-level-programming.html)

# Projects

- [Learning / Work with Registers](./registers/readme.md)
