# Completing Your Ethernet Switch Board in KiCad PCBnew
### A step-by-step guide from "placed" to "manufacturable"

Board: 130 x 85 mm, 2-layer (F.Cu/B.Cu), 160 footprints, built around a Lattice iCE40UP5K
FPGA (U1), a Realtek RTL8305NB 5-port switch (U5), 4x LAN RJ45 jacks (J6–J9) + 1x
PoE uplink RJ45 (J10), a CP2102N USB-to-serial bridge (U12) behind USB-C (J1), and a
PoE power path (U6 PD controller → U7 isolated DC/DC → U8/U9 power-OR → 3 LDOs).

---

## Part 0 — Before you touch anything: verify the netlist

This file's pads carry net *names* (e.g. `(net "GND")`) but the board has **no net-code
table** and **no routed tracks/vias/zones** yet. That's normal for a board that has only
just been placed from the schematic. The first thing to do once it's open in PCBnew:

1. **Tools → Update PCB from Schematic (F8)** — even if you don't think anything
   changed, run this once. It rebuilds the net table cleanly and makes sure every pad's
   ratsnest (the thin white "wants to connect" lines) is correct before you start moving
   parts or routing.
2. Turn on the ratsnest if it isn't already: **View → Show Ratsnest**, and set
   **Preferences → PCB Editor → Display Options → Ratsnest → "Curved"** or "straight" to
   whichever you find easier to read.

---

## Part 1 — Fix the two real placement problems

I checked every footprint's **courtyard** (the F.CrtYd keep-out outline KiCad draws
around each part — this is the standard way to detect physical collisions) against every
other footprint and against the board edge. Two conflicts came up:

### 1. CRITICAL — U7 (TEN20-4811WIN DC/DC converter) sits on top of ~15 other parts

U7 is a potted 2"x1" (50.8 x 25.4 mm) through-hole power module. At its current position
`(at 92 33 90)` its courtyard footprint spans roughly **X: 56–107 mm, Y: 23–48 mm** —
and that rectangle physically overlaps:

- **U5**, the RTL8305NB Ethernet switch chip itself (almost entirely covered)
- U8, U9 (power-OR ideal-diode ICs), U10 (3.3 V LDO)
- C5–C10 (FPGA bypass caps), C26, C27, C28, C29, C30
- D6, D7, R42, R54, R58, R59, R60

Since U7's part number and net (`OUT_5V`, fed from the PoE rectifier) are electrically
correct for this board, this looks like a part that was never actually placed — it's most
likely sitting near its "just imported from schematic" position rather than a deliberate
location.

**Fix:** the only fully open area on the whole board large enough for U7's footprint is
the gap between the two DIP switches (SW1/SW2) and the PoE section below them:
**move U7 to approximately X = 112 mm, Y = 28 mm, keep rotation at 90°.**
I verified this position has zero courtyard overlap with any other part and stays fully
inside the board outline (with ~2 mm clearance on every side).

### 2. MODERATE — J2 (SPI-flash programming header) sits on top of SW10 (tactile switch)

J2's pins (`+3V3, FLASH_CLK, FLASH_DI, FLASH_DO, FLASH_CS`) belong to the SPI-flash
programming header for U2, while SW10 belongs to the 8-button keypad matrix read through
the PCA9701 I/O expander (U4) — two unrelated nets that simply happen to sit in the same
spot: `(at 15 17 90)` for J2 directly overlaps SW10 at `(at 3.683 17.05 180)`.

**Fix:** slide J2 to the right along its own row — **X = 21.5 mm, Y = 17 mm, same 90°
rotation.** This clears SW10 by ~1 mm and doesn't touch the neighboring J3/J4/J5 headers
(they sit ~2.5 mm further down, so there's no new conflict).

Both fixes are shown in the attached before/after diagram — red/orange = conflicts,
green = the two parts after being moved, gray-green = everything else (untouched).

### 3. Worth double-checking, but probably intentional

A few connectors' courtyards extend past the board edge:

| Ref | Extends past edge by |
|---|---|
| J1 (USB-C receptacle) | ~1.2 mm past the top edge |
| J6–J9 (RJ45 LAN jacks) | ~3.7 mm past the bottom edge |
| J10 (RJ45 PoE jack) | ~3.8 mm past the bottom edge |

This is standard for edge-launch connectors — the jack/plug opening is meant to sit at or
past the board edge so it lines up with a panel or enclosure cutout. I'm flagging it, not
fixing it: just confirm these overhang amounts match your enclosure/panel drawing before
you finalize the board outline.

### 4. Two housekeeping notes for later

- **No mounting holes** exist anywhere on the board yet — add at least 2–4 before you
  finish (Part 9 below).
- Because the pad `net` entries are missing their numeric net-codes, if the ratsnest
  looks wrong or empty when you first open the file, that's the file format issue —
  running **Update PCB from Schematic** (Part 0) resolves it.

---

## Part 2 — How to actually move U7 and J2 in PCBnew

1. Click on the part (or type its reference in **Edit → Find**, hit Enter, and it'll be
   selected/centered).
2. Press **M** (Move) — *not* G (Drag), since Drag would try to drag any already-routed
   traces with it, and you have none yet, but M is the right habit going forward.
3. Type the target coordinates directly: with the part picked up, press **Space** or just
   start typing — or simpler, after placing it roughly by eye, open its **Properties**
   (double-click the part, or right-click → Properties) and type the exact X/Y position
   into the Position fields, and confirm the Orientation field still reads the original
   rotation (90° for both U7 and J2).
4. Left-click to drop it, or press **Enter** to confirm the position dialog.
5. Turn on **View → Courtyards** (or the courtyard-collision indicator in the top
   toolbar) so overlapping courtyards highlight in bright red/purple as you drag — this
   is the live version of the check I did offline, and it'll warn you immediately if a
   new position collides with something else.

---

## Part 3 — Confirm placement is clean: run the DRC

**Inspect → Design Rules Checker** (or the DRC icon in the top toolbar).

- Click **Run DRC**.
- In KiCad 10 you'll see violations grouped by type. At this stage (nothing routed yet)
  you're only checking for **"Courtyard overlap"** type errors — click through the list
  and confirm the U7/J2 conflicts are gone and no new ones appeared.
- Ignore "unconnected items" (missing ratsnest) warnings for now — that's expected until
  you route.
- Re-run DRC after any placement change; it's free and fast, so get in the habit of
  running it constantly rather than saving it for the end.

---

## Part 4 — Set up board design rules (before routing)

Open **File → Board Setup** (or the Board Setup icon).

### Physical stackup
Go to the **Physical Stackup** page and confirm 2 copper layers (F.Cu/B.Cu), 1.6 mm
overall thickness — this already matches the file. If your fab has a specific stackup
(core thickness, copper weight), enter it here now; it feeds directly into KiCad 10's
built-in impedance calculator, which you'll want for the Ethernet differential pairs.

### Design Rules → Constraints
Set your board-wide minimums to match what your fab can actually build (check their
capability page first) — typical values for a hobby-tier 2-layer board:
- Minimum track width: 0.15–0.2 mm
- Minimum clearance: 0.15–0.2 mm
- Minimum via diameter / drill: 0.6 mm / 0.3 mm
- Minimum annular ring: 0.13–0.15 mm

KiCad 10 added a **graphical rule editor** here — you can also add custom rules (e.g.
"increase clearance near the RJ45 jacks for isolation") without hand-writing rule syntax.

### Net Classes
Still in Board Setup, go to **Net Classes**. Create at least these three:

| Class | Suggested track width | Suggested clearance | Assign by pattern |
|---|---|---|---|
| Default | 0.2 mm | 0.2 mm | (everything else) |
| Power | 0.4–0.6 mm (or wider — see Part 5) | 0.2 mm | `GND`, `+3V3`, `OUT_5V`, `DUT_RTL_*`, `POE_*`, `PD_NEG` |
| Ethernet_Diff | matched to 100 Ω differential (see Part 7) | 0.2 mm | `ETH_P*`, `ETH_T*`, `ETH_R*` |

You can assign nets to a class either by typing wildcard **patterns** directly in this
table, or via **Inspect → Net Inspector**, where you can multi-select nets by name and
right-click → "Assign netclass."

---

## Part 5 — Route power first

Power nets are the least sensitive to routing order and length, so get them out of the
way first while the board is still uncluttered. Priority order:

1. **GND** — don't hand-route this. You'll pour it as a copper zone in Part 8; for now
   just route any GND pads that specifically need a direct stitch (e.g. thermal pad vias
   under U1/U5's exposed pads).
2. **48 V PoE input path**: J10 center-taps → D8/D9 (bridge rectifiers) → U6
   (TPS2375-1 PD controller) → U7 (`OUT_5V`) → U8/U9 (power-OR) → the LDOs. This carries
   the most current on the board (up to ~0.5 A depending on your PoE class), so route it
   noticeably wider than your default track width — 0.5–0.8 mm is a reasonable start;
   check U6/U7's datasheets for actual current and use KiCad's built-in **Track Width
   from current** calculator (right-click a track while routing → "Current" or use
   **Tools → Calculator Tools → Track Width**) to size it properly.
3. **+3V3 / RTL_1V2 / DUT_RTL_3V3** and the other regulator outputs — route at your Power
   net class width from each LDO to its respective load cluster (FPGA, switch IC, flash).
4. Use **X** (Add Track) for all of these; hold the routed net's ratsnest line as your
   guide — it disappears once a net is fully connected.

---

## Part 6 — Route the low-speed / control signals

Everything that isn't power or Ethernet: SPI flash bus (`FLASH_CLK/DI/DO/CS`) between U1
and U2, I2C or SPI to the PCA9701 expanders (U3, U4) for the switch/button matrix,
`RTL_MDC/MDIO` management bus from U1 to U5, `RTL_RESETB` and the strap pins, the LED
control lines, USB D+/D- from J1 to U12, and the crystal (Y1) connections.

- Route these with plain **X** (Add Track) at your Default net class width.
- Keep the USB D+/D- pair (J1 ↔ U12/D2) reasonably tight and matched-length if you want
  to be thorough — USB2 full/high-speed also wants ~90 Ω differential — but at these low
  data rates on a short board trace, "roughly equal length, routed together" is normally
  good enough for a hobby-tier design.
- Keep the crystal (Y1) traces to U1 as short and direct as practical, and avoid routing
  other signals directly underneath/parallel to them.

---

## Part 7 — Route the Ethernet differential pairs

This is the part of the board where routing style actually matters electrically. Each of
the 5 RJ45 ports connects to U5 (RTL8305NB) with **two differential pairs** — confirmed
directly from the netlist:

| Port | RJ45 | TX pair | RX pair |
|---|---|---|---|
| 0 | J6 | `ETH_P0_TXOP` / `ETH_P0_TXON` | `ETH_P0_RXIP` / `ETH_P0_RXIN` |
| 1 | J7 | `ETH_P1_TXOP` / `ETH_P1_TXON` | `ETH_P1_RXIP` / `ETH_P1_RXIN` |
| 2 | J8 | `ETH_P2_TXOP` / `ETH_P2_TXON` | `ETH_P2_RXIP` / `ETH_P2_RXIN` |
| 3 | J9 | `ETH_P3_TXOP` / `ETH_P3_TXON` | `ETH_P3_RXIP` / `ETH_P3_RXIN` |
| 4 (PoE uplink) | J10 | `ETH_TP` / `ETH_TN` | `ETH_RP` / `ETH_RN` |

The RJ45 jacks (Amphenol RJMG1BD3B8K1ANR / Abracon ARJP11A) have **integrated
magnetics**, so these pairs run straight from U5's pins to the jack with nothing in
between — good, one less thing to route around.

### How to route them
1. First, in **Board Setup → Design Rules → Net Classes**, use the PCB Calculator
   (**Tools → Calculator Tools → Track Width**, or the standalone PCB Calculator app) to
   work out the trace width and pair gap that gives ~100 Ω differential impedance for
   your actual stackup (copper weight, dielectric height, dielectric constant from your
   fab). Enter those numbers as the Ethernet_Diff net class's track width / diff-pair
   gap.
2. Select both nets of a pair at once (click one ratsnest line, Ctrl+click the other, or
   select the two pads) and press **6** (Add Differential Pair) instead of X.
3. Route both traces together, length-matched within the pair (KiCad shows a live length
   readout and lets you add a small trombone/accordion tuning pattern with **5** if one
   leg needs to catch up — aim for well under 1 mm skew, which is easy at 100 Mbps).
4. Keep each pair's two traces the same distance apart the whole way (don't let them
   spread out and pinch back together) and keep them away from noisy nets like switching
   power traces.
5. KiCad 10 also introduced **time-domain tuning** (propagation-delay based instead of
   pure physical length) via Tuning Profiles in Board Setup → Net Classes. For 10/100
   Ethernet on a short board like this, plain length-domain matching is entirely
   sufficient — you can ignore that feature unless you want to explore it.
6. Repeat for all 5 ports (10 pairs total). Do this after the low-speed routing so the
   board is less cluttered, but before the ground pour.

---

## Part 8 — Pour ground copper on both layers

1. **Place → Zone** (or the zone tool icon), draw a zone covering roughly the whole
   board on **F.Cu**, assign it to net **GND**, and repeat on **B.Cu**.
2. Set the zone's clearance and thermal-relief settings in the zone properties dialog
   (defaults are fine for a first pass).
3. **Right-click → Fill All Zones** (or the fill icon) to pour the copper.
4. Add a handful of stitching **vias** connected to GND scattered around the board — near
   the RJ45 jacks and around U5/U1 especially — to tie the top and bottom ground pours
   together and give return-current paths a shortcut between layers.
5. Re-fill zones any time you move a track afterward; stale fills are a common source of
   confusing DRC results.

---

## Part 9 — Final checks before you're "done"

- **Run DRC one more time** (Inspect → Design Rules Checker) — target zero errors. Pay
  attention to clearance violations near the RJ45 jacks especially, since PoE boards
  often want extra creepage/clearance around the high-voltage side; KiCad 10's DRC can
  route "creepage" checks around holes automatically if you've defined that rule.
- **Ratsnest should show zero unrouted nets.**
- Add **2–4 mounting holes** (footprint library: `MountingHole:MountingHole_3.2mm_M3` or
  similar) near the board corners — there are currently none on this board.
- Check silkscreen doesn't overlap pads or overlap between adjacent parts — easiest way
  is **View → 3D Viewer (Alt+3)** and a visual sweep, plus **Inspect → Footprint
  checker** for individual parts.
- Double check the J1/J6–J10 edge overhangs (Part 1, item 3) against your enclosure
  drawing now that the layout is final.

---

## Part 10 — Generate manufacturing files

**File → Fabrication Outputs** gives you each of these individually, or use
**File → Plot** for full control:
- **Gerbers** (one per layer you need: F.Cu, B.Cu, F.SilkS, B.SilkS, F.Mask, B.Mask,
  Edge.Cuts)
- **Drill files** (Excellon format, PTH + NPTH)
- Optionally a **Gerber job file** (already enabled in this board's plot settings) which
  many fabs can auto-import to configure your order
- A **pick-and-place (position) file** if you're having it assembled
  (**File → Fabrication Outputs → Component Placement**)
- A **BOM** (Bill of Materials) if your fab/assembler needs one —
  **Tools → Generate Bill of Materials**

Most fabs (JLCPCB, PCBWay, OSH Park, etc.) publish exact Gerber/drill settings they
want — check their site before exporting so you don't have to redo it.

---

## Note-1. When do you need a via?

**The core rule on a 2-layer board**:
a via is needed any time a trace has to switch from F.Cu to B.Cu — because something is physically in the way on the layer you're on, or because you need a return path to the ground pour on the other side.

---

Concretely, that happens when:
- Another trace or pad blocks the direct path on your current layer and there's no way to route around it — hop to the other layer, go under/over, hop back.
- Escaping a dense part — fanning pins out from a fine-pitch IC often requires alternating layers pin-by-pin.
- Thermal/ground pads under QFN packages — this board has two: U5's footprint (`QFN-48-1EP_6x6mm_P0.4mm_..._ThermalVias`) already has a via array built into the library part, so nothing to do there. U1's footprint (`QFN-48-1EP_7x7mm_P0.5mm_EP5.6x5.6mm`) does not — no `ThermalVias` in the name — so you'll want to manually drop a small via grid (5–9 vias, 0.3mm drill) under U1's exposed pad yourself, or swap to a _ThermalVias variant of that footprint if one exists in your library.
- GND stitching — scattered vias tying the F.Cu and B.Cu ground pours together, especially near the RJ45 jacks and around U1/U5, so return current has a short path back regardless of which layer a signal routed on.
- A differential pair needs to change layers — via both legs at the same physical point (mirror the via placement), not one leg only, or you'll blow the pair's length/skew match.

One beginner mix-up to avoid: a THT part's own hole (like U7's leads) already connects F.Cu and B.Cu — that's not a via, it's a component pad, and it doesn't help you route other nets through it.

---

## Note-2. Footprints needing different clearance

- Yes — two spots, in opposite directions.
- Needs tighter clearance to be routable at all: I pulled the actual pad geometry —

| Part | Pitch | Pad width | Copper-to-copper gap |
|---|---|---|---|
| U5 (RTL8305NB, QFN-48) | 0.4mm | 0.2mm | 0.2mm |
| U1 (iCE40UP5K, QFN-48) | 0.5mm | 0.25mm | 0.25mm |
| U12 (CP2102N, QFN-28) | 0.5mm | 0.25mm | 0.25mm |

- U5 is the tight one. If you set a board-wide default clearance above 0.2mm anywhere (easy to do — e.g. 0.25mm "for comfortable hand-soldering margin"), DRC will throw violations on every adjacent pad pair under U5. The clean fix isn't to loosen the whole board — it's Board Setup → Design Rules → Custom Rules, add a rule scoped to that footprint (`condition: A.insideFootprint('U5')` or similar) with a smaller clearance (0.15mm or whatever your fab's actual minimum is), and keep the board-wide default looser everywhere else.
- Needs wider clearance for safety, not routability: the raw 48V PoE path — J10's center-tap pins → D8/D9 (the two `DF01S` bridge rectifiers) → D7 (the TVS clamp) → into U6 and only U6's/U7's primary-side pins. Everything downstream of U7's transformer (its `OUT_5V` output and onward) is isolated, safe extra-low-voltage. I'm not going to invent a specific clearance number here — the correct creepage/clearance depends on your magjack's isolation rating and which safety standard you're targeting (IEC 62368-1, altitude/pollution-degree assumptions) — but the mechanism is the same custom-rule tool: define a net class or rule area covering that "hot" cluster and give it wider clearance than the board default, rather than relying on one blanket number for the whole board.
- No footprint in the file currently has a pad-level clearance override — both of these need a rule you add.

---

## Note-3. Freerouting

Freerouting works with KiCad 10 through the standard Specctra exchange: File → Export → Specctra DSN, open that `.dsn` in Freerouting (standalone app, or the plugin installed via the Plugin & Content Manager which adds an autorouter button right in PCBnew), autoroute, export a `.ses` session file, then File → Import → Specctra Session back into KiCad. Net class track widths/clearances travel with the DSN export, so get those right before exporting (see #2) — a clearance that's wrong for U5 will make Freerouting produce garbage or fail right there.

---

What to finish manually and lock before handing off to Freerouting:

1. Placement, fully final — including the U7/J2 moves from before. Freerouting routes to wherever parts currently sit; moving anything after routing invalidates the routes.
2. Power, by hand — especially the 48V PoE path and the 5V/regulator distribution. Autorouters size traces off the net class default width, not actual current — they won't know U7's output needs a wider trace than a GPIO signal does.
3. The 10 Ethernet differential pairs, by hand (or at minimum their escape from U5's 0.4mm-pitch pins) — Freerouting does recognize diff pairs via matching net-name suffixes, but tight, impedance-controlled length-matching and the dense QFN fan-out are exactly where autorouters produce the worst results. Route these yourself, then lock the tracks (select → right-click → Lock, or Ctrl+L) so Freerouting treats them as fixed obstacles instead of ripping them up.
4. Leave the low-speed stuff for Freerouting — SPI flash, I2C/GPIO to the PCA9701 expanders, MDC/MDIO, LEDs, USB D+/D-. This is exactly the kind of routing an autorouter is good at and where it'll save you real time.
5. Don't pour the ground zones yet — do that after import, since the DSN exchange doesn't carry zone fills anyway.

After importing the `.ses`, run Route → Cleanup Tracks and Vias to tidy up 90° corners and redundant vias Freerouting tends to leave behind, then DRC, then pour the ground copper as the last step.
