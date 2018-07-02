# Verifuck (WIP!)

Because why not?

Verifuck is a verilog implementation of Brainfuck. It reads a brainfuck program from SPI Flash and executes it. UART rx/tx is used for stdin/stdout.

## Features
- UART rx/tx
- Supports reading a program from SPI flash
- Built to run on the icestick (iCE40-HX1K-TQ144)

## Architecture

(far from true right now)
4kB program size
4kB data size (1024 32-bit words)


## Intructions
```
INCDP   ">" 3e
DECDP   "<" 3c
INCDATA "+" 2b
DECDATA "-" 2d
OUTONE  "." 2e
INONE   "," 2c
CONDJMP "[" 5b
JMPBACK "]" 5d
```
