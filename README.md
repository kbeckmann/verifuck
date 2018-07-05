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

## Pipeline

I want to create a pipeline resembling https://en.wikipedia.org/wiki/Classic_RISC_pipeline. However I'll start with a non pipelined version.

All memory access takes 2 clock cycles: assigning address and ren/wen takes 1 cycle, then the sram takes one cycle to perform the read/write.

`prog_addr`: PC / Program Counter. Points to the instruction that will be fetched during IF.

`prog_rval`: Instruction. Current instruction that is being executed.

`data_addr`: The primary register. This is the data pointer that is manipulated with `>` and `<`.

`data_rval`: The data that was read at `data_addr`. Used as scratch register to perform addition or subtraction.

`stack_index`: The current stack pointer. The stack pointer is increased for each `[` and decreased whenever a loop finished with `]`.

`stack_rval`: Where to jump back to.

### IF: Instruction Fetch
Fetches the instruction at the Program Counter.

**Preconditions**:
- `prog_ren` is set to `1`
- `prog_addr` is set to a valid address

**Actions**:
- Increments `prog_addr` with `1`.

**Effects in the next stage**:
- `prog_rval` will be loaded with the instruction at `prog_addr`.

### ID: Instruction Decode
This stage is skipped since the instructions are so simple.

### EX: Execute
This stage executes the instruction stored in `prog_rval`.

**Preconditions**:
- `prog_rval` contains a valid instruction

**Actions**:
- Pending writes will be committed in this stage.
- In case of `>` and `<`:
  - `++data_addr;` or `--data_addr;`
- In case of `+`, `-`, `]`:
  - `data_ren = 1;`
- In case of `.` and `,`, stalls until uart is done.

**Effects in the next stage**:
- In case of `+`, `-` and `]`, data read will be pending.

### MEM: Memory access
This a buffer stage to allow the read to be completed in the next stage.

**Preconditions**:
- `data_ren == 1` and/or `stack_ren == 1` in case data should be read

**Actions**:
- None.

**Effects in the next stage**:
- In case of `+`, `-`, data read will be loaded in `data_rval`.
- In case of `]`, data read will be loaded in `stack_rval`.

### WB: Write Back
This stage prepares data that is to be written. The actual write occurs in the next stage.

**Preconditions**:
- In case of `+`, `-` valid data should be loaded in `data_rval`
- In case of `]` valid data should be loaded in `stack_rval`

**Actions**:
- In case of `+`:
  - `data_wval <= data_rval + 1;`
  - `data_wen <= 1;`
- In case of `-`:
  - `data_wval <= data_rval - 1;`
  - `data_wen <= 1;`
- In case of `]`:
  - Loop logic
    - `if (data_rval == 0) stack_index <= stack_index - 1; else prog_addr <= stack_rval;`

**Effects in the next stage**:
- In case of `+`, `-`, data will prepared to be written `*data_addr = data_wval;`.
- In case of `]`, data will be prepared to be written `*stack_addr = data_wval;`.
