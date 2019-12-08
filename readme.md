AOM Random Maps
===============

Random map scripts for Age of Mythology.

### Installation

Scripts for any random maps that you want to try (both the `xml` and `xs` files) should be installed into the `/rm2/versionX/` directory (where X is your latest version).

The `cof89_lib.xs` file is a library that is used by all random maps and should also be installed into the same location.

Append the contents of the `en-language.txt` file to the existing file in the `/language/en/` directory.

### Notes on XS

For those unfamiliar, this is basically C++ but with some mandatory syntax (eg: _for_ loops);

```
// This Works
for(x = 1; < cNumberPlayers)

// This Errors
for(x = 1; x < cNumberPlayers; x ++)
```

See [this post](http://aom.heavengames.com/cgi-bin/forums/display.cgi?action=ct&f=19,26905,0,10) for more information.