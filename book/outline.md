# Outline for my CLASH book

What I want to do with Clash, and why.

I have been working with Verilog for over 30 minutes now, and I already see ways
in which Haskell / Clash can improve things for me. 

For my job, I would like to be able to connect up N peripherals using an AXI
bus. The bus will need to have support for a "CPU" master from Vivado or
whataever, as well as a master from a peripheral / other peripherals.

This book (I'm using the term 'book' lightly here) will follow along as I
learn the Clash using the impressive "Retroclash" book by XXX. I will be using
Vivado 2024.2 (since that's the version I installed) as well as the Zybo Z7 z20
FPGA. 

The goal of Clash here in my opinion is NOT to replace Verilog. Verilog is Super
super cool and can produce really clean code that is compact blah blah blah the
goal is to allow ME a reasonable person to quickly connect Verilog modules. I
believe it should be simple to connect modules up. 

There are a number of people out there writing fantastic Verilog code, and we
should be able to leverage it. I'm looking at you ZipCPU Guy :) I sp

## FPGA in 202X

Linux is probably required. I'm sure this stuff is possible on Windows and Mac,
but why bother with that.

- TabbyCAD
- ZipCPU
- Verilator
- GTKWave

Adding Clash into the mix is pretty easy:

- Stack
- GHCUP

## Hardware for this book

- Zybo Z7 z20 Digilent FPGA
- PMODs ...
- VGA Compatible Display

## Software for this book

I won't go too much into installing the software - I assume that the reader will
be able to figure it out.

- GHCUP
- GHC
- Vivado
- Verilator?
    - GCC
    - Make
- GTKWave
- ZIPCpu Busses?

### Creating a Clash Project

This is my first deviation from the Retroclash book - creating a project. 

...

## Following Along with the Book

- Seven Segment
    - Registers
        - Register Learning / Exploration
- 10 Key

## Deviating from the Book

- Clash -> GTKWave
- Testing
- Blackbox 

## 
