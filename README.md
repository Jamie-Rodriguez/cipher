Cipher Suite
============

The output of an exercise in learning how various ciphers work; an application that has the ability to encode/decode a text message using various ciphers.

Current ciphers supported:

- Caesar cipher
- Vigenère cipher

Getting Started
===============

First build the app:

```shell
make
```

An executable named `cipher` will be created in the `bin/` directory.

From there, use the help command to see the list of options available.

```shell
cipher --help
```

Tests
=====

Build the tests with

```shell
make test
```

An executable named `run-tests` will be created in the `bin/` directory.

Run the tests by executing `run-tests`

```shell
run-tests
```

Static Analysis
---------------

Static analysis can be run on the codebase using [Cppcheck](https://cppcheck.sourceforge.io/) and/or [Infer](https://fbinfer.com/).

I've made Makefile rules to run these tools with some suitable arguments.

```shell
make check-cppcheck
```

```shell
make check-infer
```

To-Do
=====

- [ ] Make Caesar & Vigenère ciphers able to work with a provided custom alphabet
- [ ] Add *autokey* mode to Vigenère cipher
- [ ] Add Vigenère cipher variation: *Variant Beaufort*
- [ ] Add ability to read/write input/output files
- [ ] Start finding ways to create a tool to help decipher Vigenère ciphers
