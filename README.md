# ice40_lib

This is a Verilog library made specifically for Lattice iCE40HX/LX devices.

It contains random bits and bytes that I needed or wanted.

Most of the modules are generic Verilog files that will work with any FPGAs, but some use specific iCE40 primitives for certain reasons. All design choices were made with iCE40 family in mind (such as utilization of 4kb RAM cells).

Files prefixed with "tb_" are testbenches and run in Icarus Verilog, like so:

`iverilog tb_xxx.v && ./a.out`



## Disclaimer

No guarantees, you are the user and you are responsible for everything.
