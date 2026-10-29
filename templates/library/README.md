# @NAME@

Arduino library made by `arduino-box new library @NAME@` (32_13_arduino): `library.properties`, `src/`,
`examples/basic/`, `keywords.txt`. Builds without installing it (the `--library` flag points at this folder):

```sh
arduino-box compile examples/basic nano --library "$PWD"     # any board alias or FQBN
arduino-box cli lib install --zip-path @NAME@.zip              # install a zip into user/libraries (needs enable_unsafe_install)
```

Before publishing: fill author/maintainer/url/sentence in `library.properties`, add a LICENSE, tag the version
(`arduino-lint` checks the layout for the Library Manager).
