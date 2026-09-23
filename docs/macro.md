# Understanding the macro

What the ROM array actually is, read off the netlist -- no simulator needed.

[<- back to the README](../README.md)

---

## Understanding the macro

### The cell array is a NAND chain

![Cell array](img/02-array-overview.png)

A bitline is not one transistor per row tied to ground -- it is every cell of
that column **in series**, from the bitline contact at the top down to a single
foot transistor at the bottom. There are two cell types:

```
one_cell   : X0 D G S gnd    -> drain and source are DIFFERENT nets = a real transistor
zero_cell  : X0 S G S gnd    -> drain and source are the SAME net   = a permanent short
```

| `rom_base_one_cell` | `rom_base_zero_cell` |
|---|---|
| ![one cell](img/03a-one-cell.png) | ![zero cell](img/03b-zero-cell.png) |

Every cell position holds a physical transistor. What programs the bit is
whether a metal strap shorts its source to its drain. **That strap is the
stored data** -- the via pattern you can see in the layout is the ROM contents.

![One column, cells abutted in series](img/04-column-strip.png)

### How a read works

During evaluate, **all wordlines stay HIGH except the selected one**, which is
driven LOW. So the chain conducts through dozens of pass transistors:

| cell in the selected row | when its wordline goes low | chain | bitline | read |
|---|---|---|---|---|
| `one_cell` (transistor) | turns **off** | broken | stays at VDD | **1** |
| `zero_cell` (strap) | strap does not care | conducts | discharges | **0** |

This is also why the macro is slow: the discharge current flows through ~80
series transistors, so the bitline behaves as a distributed RC line and the
delay grows roughly **quadratically** with the chain length.

You can read any column straight out of the netlist:

```
$ python3 scripts/rom_char/rom_explore.py wrom0 --col 236
== wrom0 column 236 -- bitline chain (top to bottom, 134 rows)
   1 = one_cell  (series NMOS, gate=wl) -> resistance in the chain
   0 = zero_cell (source/drain shorted) -> wire only

   r0    1010110101001111101100111111010111001001
   r40   1011110010111001101010010110100110011111
   r80   1000011110011100101010011111101001010100
   r120  11111011111101

   series NMOS count = 82  (real transistors in the discharge path)
```

The column with the most `one_cell`s is the slowest one, and characterization
runs on it. That choice is made by the tools, never by hand.

### The precharge phase, and why it is part of the answer

Nothing ever drives a bitline high in this macro. A read is a question about
charge that was put there in the previous half cycle, which is what makes the
array *precharged*, and it makes the length of that half cycle part of the
access time rather than a detail of the testbench.

One cycle has two phases, and the `precharge` net is what separates them. It
gates two devices at once:

| `clk0` | `precharge` net | precharge PMOS (top of the column) | foot NMOS (bottom of the chain) | the bitline |
|---|---|---|---|---|
| low | low | **on** -- pulls the bitline to VDD | **off** -- the chain is cut from ground | charges |
| high | high | off | **on** -- the chain reaches ground | discharges, or does not: that is the bit |

Both devices are driven by the same net on purpose: the foot transistor is
what keeps a short from VDD to ground through the chain while the bitline is
being charged. It is also why the foot is never one of the programmable cells
-- its gate is the `precharge` net, not a wordline, and
`gen_col_tb_parasitic.py` identifies it by that gate rather than by its
position.

**The chain's internal nodes never reach VDD.** They are charged from the
bitline *through the cells*, and every cell is an NMOS pass transistor, so
each one loses a threshold; the deeper the node, the lower it settles.
Measured at the end of a settled 100 ns precharge phase on wrom0 column 236 at
TT: bitline 1.799 V, first chain node 1.070 V, node 41 0.843 V, node 81
0.821 V -- and they keep creeping up as the phase is made longer, which is the
next paragraph.
There is no steady state in which the chain is simply "full".

So the longer the precharge phase lasts, the more charge the next read has to
remove, and the slower that read is:

| precharge phase | settled `t_dis_50` (wrom0, TT) |
|---|---|
| 25 ns | 6.96 ns |
| 50 ns | 9.54 ns |
| 100 ns | 11.59 ns |
| 200 ns | 12.96 ns |
| 1 us | 14.85 ns |

Monotonic and saturating. The worst case is therefore the **longest** precharge
-- a ROM that has been sitting idle with `clk0` parked low, whose chain has
filled asymptotically, and whose next read is the slowest read the macro can
perform. That is a real operating condition and it is the one the `.lib` has
to cover, so the column deck runs at `TCLK=2u`: a 1 us precharge phase, far
into the saturated region.

**And the first cycle is not a measurement.** The deck sets `.ic` on the
bitline only; with `uic` every internal chain node starts at 0 V and jumps
within picoseconds to a capacitive-divider level set by each cell's parasitic
C to vdd and to gnd. That level is *higher* than what conduction produces, and
the nodes cannot come back down -- during precharge the foot is off, so they
can only be charged, never discharged. A longer first precharge does not wash
it out: wrom0 reads 16.5035 ns on cycle 1 whether the first phase is 25 ns,
100 ns or 1 us, against 14.8495 ns settled at that same 1 us phase.

| | cycle 1 (capacitive divider) | settled |
|---|---|---|
| bitline | 1.8000 V | 1.7990 V |
| chain node 1 | 1.2623 V | 1.0696 V |
| chain node 41 | 1.1171 V | 0.8426 V |
| chain node 81 | 1.1082 V | 0.8201 V |

Cycle 1 is nearly flat; the settled state is a gradient built by conduction.
Every measurement in the column deck therefore sits on the third cycle, and
the deck also emits `t_dis_50_prev` -- the same measurement one cycle earlier
-- so that settling is *proven* rather than assumed. If the two differ by more
than 1% the generator says so and the number must not be used. This is the
same rule the energy decks apply with `q_c2` against `q_c3`; the timing deck
did not have it until 2026-09-20, and measured its first cycle. The effect on
the numbers it produces:

| corner | cycle 1 | settled, 1 us phase |
|---|---|---|
| tt | 16.5035 ns | 14.8495 ns |
| ss | 41.9709 ns | 36.0231 ns |
| ff | 8.9101 ns | 8.2893 ns |

The old values were pessimistic for `access`, which is the safe direction, but
they reached that margin through a state the circuit never occupies -- and for
`retain_rise`/`retain_fall`, which come from the same deck, the artefact
pointed the other way: retain is an *early* bound, and an unphysically slow
discharge makes the output look like it holds its previous value longer than
it really does, which is exactly what lets a hold violation pass unnoticed.

#### Does a chain that never reaches VDD cost noise margin?

It is the obvious next question, and the deck cannot answer it: every wordline
is held at DC VDD, so the only case it simulates is a read of **0**. On a read
of **1** the selected cell breaks the chain and the bitline has to *stay* high
while every still-conducting node above the break shares charge with it -- and
the deeper the selected row, the more nodes hang on the bitline. Measured by
hand on wrom0 column 236 at TT, pulsing one wordline low during evaluate:

| | selected row at the top | selected row at the bottom (81 cells still conducting) |
|---|---|---|
| `v(bl)` at 20 ns | 1.8163 V | 1.8415 V |
| `v(bl)` at 200 ns | 1.8141 V | 1.8230 V |
| `v(bl)` min over a 1 us evaluate | 1.8000 V | 1.7336 V |
| `v(bl_b)` max (inverter output) | 0.0000 V | 0.0000 V |

The 1 level holds. Two mechanisms protect it: each pass transistor cuts itself
off once its node is within a threshold of the bitline, so the chain cannot
drag the bitline down to its own level; and 41 kohm of chain resistance makes
the redistribution far slower than the access time. The partially charged
chain costs **speed on a read of 0, not level on a read of 1** -- and the
bitline itself is driven by the precharge PMOS directly, with no pass
transistor in the way, so its high level is full rail to begin with.

(The readings above VDD at 20 ns are the precharge edge coupling into the
bitline through the cell capacitances. It is the small bump visible at the
start of every discharge if you plot the deck.)

What this does *not* cover is neighbour-column coupling, which the column deck
does not carry at all -- see limitation 1 below.
