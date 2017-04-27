# Sample NES project for Self Conference 2017

This is a basic but fully-working NES game written in 6502 assembly. Feel free to use it as a starting point for your own explorations!

## Tools used

- [cc65 compiler suite](http://cc65.github.io/cc65/) (`ca65` assembler, `ld65` linker)
- [NES Screen Tool](https://shiru.untergrund.net/software.shtml) (graphics)
- [FCEUX](http://www.fceux.com/web/download.html) Win32 (debugging)

## Building and running

First, assemble the source:
```ca65 src/main.asm -I src -g -o main.o```

Next, link the resulting object file and CHR data:
```ld65 main.o -C nes.cfg -o selfconf.nes```

Open the resulting .nes file with any NES emulator (FCEUX, Nestopia, etc.).

## Credits

This project based on `nrom-template` (https://github.com/pinobatch/nrom-template) by Damian Yerrick:

> Copyright 2011-2016 Damian Yerrick
>
> Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved in all source code copies. This file is offered as-is, without any warranty.
