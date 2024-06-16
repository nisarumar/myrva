## My RISCV Implementation

- Currently it is WIP. A core implementation with RV32I is somewhat done.
- AXI Master and Slave logic is written
- SRAM inference logic is added for RTL simulation

### todo
- [ ] Complete test benches for AXI slave and AXI master
- [ ] Develop AXI slave SRAM interface with a test bench
- [ ] Develop logic for interconnect and connect AXI master core and AXI slave sram
- [ ] Add Debug, flushing, and CSR logic to the core
- [ ] Add UART master to the interconnect
- [ ] Add instruction and data caches
