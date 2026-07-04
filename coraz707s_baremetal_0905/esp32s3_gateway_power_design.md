# ESP32-S3 Sensor / CAN Gateway — Power System Design Walkthrough

## 0. Scope and assumptions

No existing schematic or component list was provided, so this document works through the full requested methodology — power budget → sequencing analysis → regulator selection → BOM → pin-to-net table — on a representative, fully-specified example design. The method and worksheet below apply directly to a real project; just substitute your own component list and datasheet currents in Section 2.

**Baseline assumptions:**
- Single PCB, USB-C powered (5 V VBUS), no battery (noted as a future-expansion option in Section 8).
- All active parts run from 3.3 V (no 1.8 V or 5 V logic rails needed).
- "Rev A" = the design as given, with zero voltage regulation of its own (bare load components only).
- "Rev B" = Rev A plus the power-management components this document adds.
- Every current figure in Section 2 is traced to a manufacturer datasheet; figures that are vendor/module-class estimates rather than a single primary datasheet number are marked as such.

## 1. Baseline design (Rev A — no power management)

| Ref | Function | Interface | Notes |
|---|---|---|---|
| U1 | ESP32-S3-WROOM-1-N16R8 — MCU, Wi‑Fi/BLE, native USB | USB, I2C, SPI, GPIO | 16 MB flash + 8 MB octal PSRAM variant |
| U2 | BME280 — temperature / humidity / pressure sensor | I2C | 8-pin LGA |
| U3 | ICM-42688-P — 6-axis IMU (accel + gyro) | SPI | 14-pin LGA |
| U4 | SSD1306-based 128×64 OLED module | I2C | 4-pin module (VCC, GND, SCL, SDA); reset handled on-module |
| U5 | W25Q128JVSIQ — 128 Mbit SPI NOR flash | SPI | Data logging storage |
| U6 | SN65HVD230D — 3.3 V CAN transceiver | UART-style D/R + bus | For a field-bus / gateway function |
| J1 | USB-C receptacle | USB 2.0 + power | Power in, native-USB programming/console |
| J2 | microSD socket | SPI mode | Push-push, full-size |
| J3 | 2-pin terminal block | CANH / CANL | Field bus connector |
| SW1, SW2 | Tactile switches | GPIO | Reset (EN) and Boot (GPIO0) |
| D1, D2 | Status LEDs | GPIO / rail | Power-good and activity |

As given, U1's 3V3 pin, and every other part's VCC/VDD pin, would land on one bare "3V3" net with no regulator, no sequencing, and no protection — that's the gap this exercise fills.

## 2. Worst-case power consumption

| Ref | Rail | Condition (worst case) | Current | Source |
|---|---|---|---|---|
| U1 ESP32-S3-WROOM-1 | 3V3 | 802.11b Wi-Fi TX, 20.5 dBm, 100% duty | **355 mA** | Espressif module datasheet, Table 6-4 (Active-mode current) |
| U2 BME280 | 3V3 | Peak current during pressure conversion | **0.7 mA** | Bosch BME280 datasheet (714 µA peak, pressure measurement) |
| U3 ICM-42688-P | 3V3 | 6-axis low-noise mode | **≈1.0 mA** | TDK InvenSense datasheet (0.88 mA typical; rounded up for margin) |
| U4 OLED module (SSD1306, 128×64) | 3V3 | Charge pump + most pixels lit | **≈30 mA** | Representative module-level spec (varies by vendor/display content; not a single primary datasheet max) |
| U5 W25Q128JVSIQ | 3V3 | Page program / sector erase class current | **25 mA** | Winbond datasheet, ICC4 (max) |
| U6 SN65HVD230 | 3V3 | Dominant bus state, driving | **17 mA** | TI datasheet, ICC dominant (max) |
| J2 microSD | 3V3 | Active write | **≈100 mA** | Representative figure; individual cards vary roughly 40–200 mA |
| D1+D2 status LEDs | 3V3 | Both on, ~1.3 mA each (1 kΩ series, 3.3 V, Vf≈2 V) | **3 mA** | Design choice, not a datasheet figure |
| Misc. static bias | 3V3 | I2C pull-ups, GPIO0/EN pull-ups, CAN RS bias | **≈1 mA** | Estimate |
| **Total, all peaks coincident** | 3V3 | — | **≈533 mA / 1.76 W** | Arithmetic sum |

**Why sum every peak arithmetically:** for sizing a regulator's current *rating* (as opposed to sizing bulk capacitance for a single transient), the conservative approach assumes the worst case can coincide — e.g. a Wi-Fi TX burst landing during an SD-card log write. It's unlikely, but the regulator should never brown out if it happens.

**Design margin:** applying a standard 30% margin, 533 mA × 1.3 ≈ **693 mA** — call it a 700 mA design target for the always-on rail.

**Regulator sizing check (Section 4):**
- U7 (buck, always-on 3V3_A) carries the *entire* 533 mA worst case → a 3 A part runs at ~18% of rating.
- U8 (load switch, 3V3_B) carries everything *except* the ESP32-S3 itself: 0.7+1.0+30+25+17+100+3+1 ≈ **178 mA** → a 2 A part runs at ~9% of rating.

Both parts have generous headroom — chosen more for their sequencing/inrush-control features (Section 4) than for raw current capacity, which also keeps both running cool and efficient well below saturation.

## 3. Reset / enable / similar signals — power-up sequencing

| Signal | Owner | Type | Role |
|---|---|---|---|
| EN | U1 ESP32-S3-WROOM-1 | Active-high chip enable | Holds the MCU in reset until 3V3_A is stable; released by an RC delay |
| GPIO0 | U1 | Boot-mode strap | Must be high (normal boot) or low (download mode) at the moment EN releases |
| IO4 (PERIPH_EN) | U1 → U8 | GPIO output → load-switch input | Firmware-controlled: brings up the peripheral rail only after boot |
| ON | U8 TPS22918 | Active-high switch enable | Driven by IO4; gates 3V3_B |
| CT | U8 | Rise-time control | Sets a controlled (non-instant) ramp on 3V3_B to limit inrush into OLED/flash/IMU bulk capacitance |
| QOD | U8 | Quick output discharge | Actively discharges 3V3_B when disabled, instead of leaving it floating — matters for clean power-down and for safely power-cycling a "stuck" sensor |
| RS | U6 SN65HVD230 | Slope/standby select | Tied through a resistor for slope-controlled (lower-EMI) operation; pulling it high would put the transceiver into a low-current standby, an option for future firmware-controlled power saving |

### Sequence, in order

1. **VBUS present.** USB-C 5 V appears at J1. U7's EN pin is pulled up directly from VBUS (always enabled whenever powered).
2. **3V3_A regulates.** U7 ramps the always-on rail with its own internal fixed soft-start, reaching regulation in about 1 ms.
3. **U1's EN releases.** A 10 kΩ / 1 µF RC network on EN (plus SW1 for a manual reset button) delays chip enable by roughly 10 ms after 3V3_A is up — this is Espressif's own recommended practice, not a custom addition: the module datasheet explicitly calls for an RC delay circuit on EN for stable power-up.
4. **GPIO0 is already valid.** Its pull-up sits on the same rail (3V3_A) as EN, so it's stable well before EN crosses its threshold — normal boot proceeds unless SW2 is held to force download mode.
5. **ESP32-S3 boots** (ROM loader → 2nd-stage bootloader → application), typically on the order of 100–300 ms to reach application code.
6. **Firmware asserts IO4** only after basic init (clocks, watchdog) — this is the actual "power-up sequencing" decision point, made in software rather than hardware, which is what lets the MCU also power-cycle the peripheral rail later if a sensor locks up.
7. **U8 turns on** with a controlled rise time (set by the CT capacitor) rather than a hard step, limiting inrush into the OLED's charge-pump capacitors, the flash, the IMU, and the CAN transceiver's bulk decoupling.
8. **Firmware waits before first access.** The binding constraints from each peripheral's own power-up spec: BME280 needs its internal POR to settle (~2 ms), the ICM-42688-P's accelerometer needs 10 ms from sleep to valid data, the SSD1306 module needs its on-board POR/charge-pump to stabilize (driver libraries typically allow ~100 ms), and a microSD card needs ≥1 ms of stable power plus 74 SPI clocks with CS held high before CMD0. A single ~100 ms firmware delay after asserting IO4 satisfies all of them.
9. **Peripheral buses initialize:** I2C (BME280, OLED), SPI with three independent chip selects (flash, SD, IMU), and the CAN controller/transceiver.

**Power-down note:** QOD ensures 3V3_B discharges cleanly rather than floating (which would otherwise leave indeterminate levels on I2C/SPI lines). ESP32-S3's own internal brownout detector resets the chip if 3V3_A droops — a reasonable safety net without adding a dedicated supervisor IC for this rail count.

## 4. Power architecture (Rev B — added components)

**Why a buck + load switch instead of one PMIC:** at two rails with modest current, a small integrated PMIC (e.g. a TI TPS6508x-class part) would add I2C configuration overhead and BOM cost without buying much — the same job is done here by two simple, second-sourceable, well-documented parts. If a future revision adds more rails (e.g. a separate 1.8 V domain for a higher-speed peripheral), that's the point where a sequencing-capable PMIC starts to earn its complexity.

**U7 — TPS563201 (3 A synchronous buck, SOT-23-6 "DDC" package)**
Pinout: 1=GND, 2=SW, 3=VIN, 4=VFB, 5=EN, 6=VBST (confirmed against TI's datasheet pin diagram).
- VIN = VBUS (5 V), EN pulled to VIN through a 100 kΩ resistor (always enabled when powered).
- Feedback divider for ~3.3 V out: R1 = 100 kΩ, R2 = 30.1 kΩ (1%) → Vout = 0.768 V × (1 + 100/30.1) ≈ 3.32 V, using the device's ~0.768 V feedback reference.
- L1 = 2.2 µH shielded power inductor (≥3 A saturation current), Cin = 10 µF X7R, Cout = 22 µF X7R, Cboot = 100 nF — representative values consistent with TI's typical application circuit for this device class; fine-tune with TI's design procedure for final layout.
- Internal fixed soft-start ≈ 1.0 ms.

**U8 — TPS22918 (2 A load switch, adjustable rise time + quick output discharge, SOT-23-6)**
Pinout: 1=VIN, 2=GND, 3=ON, 4=CT, 5=QOD, 6=VOUT (confirmed against TI's datasheet pin diagram).
- VIN = 3V3_A, VOUT = 3V3_B, ON driven from U1 IO4.
- CT = 1 nF ceramic sets a controlled turn-on ramp.
- QOD tied directly to VOUT, using the device's internal pull-down for quick discharge on disable (no external resistor needed).
- Cin (VIN bypass) = 1 µF, Cout (VOUT bulk) = 10 µF.

**Supporting network on U1**
- R4 = 10 kΩ (3V3_A → EN), C4 = 1 µF (EN → GND): ~10 ms power-on delay, per Espressif's own reference design guidance.
- SW1: EN → GND, momentary (manual reset).
- R5 = 10 kΩ (3V3_A → GPIO0): boot-mode pull-up.
- SW2: GPIO0 → GND, momentary (download-mode entry).

**USB-C sink configuration (J1)**
- R7, R8 = 5.1 kΩ from CC1/CC2 to GND — standard configuration advertising a default-current USB Type-C sink (no PD negotiation needed for this load).
- At ~533 mA worst-case output and ~90% buck efficiency, input draw is roughly 533 mA × 3.3 V / (0.90 × 5 V) ≈ **390 mA** from VBUS — comfortably inside a standard 5 V/900 mA–1.5 A USB-C source budget.

## 5. Bill of materials

| Ref Des | Qty | Value / Part Number | Description | KiCad library reference | Notes |
|---|---|---|---|---|---|
| U1 | 1 | ESP32-S3-WROOM-1-N16R8 | MCU + Wi-Fi/BLE module, 16 MB flash, 8 MB PSRAM | `RF_Module:ESP32-S3-WROOM-1` — confirmed present in both the mainline kicad-symbols repo and Espressif's official PCM-distributed library | Native USB on IO19/IO20 |
| U2 | 1 | BME280 | Humidity/pressure/temperature sensor, 8-pin LGA | Verify in your `Sensor_Humidity`/`Sensor_Pressure` library version — commonly sourced as a vendor/Ultra Librarian symbol if not present | I2C addr 0x76/0x77 |
| U3 | 1 | ICM-42688-P | 6-axis IMU, 14-pin LGA | Verify — TDK/InvenSense provides an Ultra Librarian export if not in your base library | SPI, CS + INT1 used |
| U4 | 1 | Generic SSD1306 128×64 I2C OLED module | 4-pin display module | Model as a 4-pin connector/generic display symbol | On-board reset/POR |
| U5 | 1 | W25Q128JVSIQ | 128 Mbit SPI NOR flash, SOIC-8 | `Memory_Flash:W25Q128` — commonly included; verify version | Data logging |
| U6 | 1 | SN65HVD230D | 3.3 V CAN transceiver, SOIC-8 | `Interface_CAN_LIN:SN65HVD230` — commonly included; verify version | RS via R6 |
| U7 | 1 | TPS563201DDCR | 3 A synchronous buck converter, SOT-23-6 | Verify in `Regulator_Switching`; otherwise use TI's Ultra Librarian/SnapEDA export | Always-on 3V3_A |
| U8 | 1 | TPS22918DBVR | 2 A load switch, adj. rise time + QOD, SOT-23-6 | Verify in `Power_Management`; otherwise use TI's Ultra Librarian/SnapEDA export | Switched 3V3_B |
| J1 | 1 | USB-C receptacle, 16-pin (e.g. GCT USB4105) | Power + native USB data | `Connector:USB_C_Receptacle_USB2.0_16P` | 5 V in |
| J2 | 1 | microSD socket, push-push | e.g. Molex 104031-0811 | `Connector_Card:microSD` | SPI mode |
| J3 | 1 | 2-pin terminal block, 3.5 mm pitch | CANH/CANL field connector | `Connector_Terminal_Block:*` | — |
| SW1, SW2 | 2 | 6 mm tactile switch, SMD | Reset (EN) and Boot (GPIO0) | `Button_Switch_SMD:*` | — |
| D1, D2 | 2 | 0603 LED | Power-good, activity indicator | `LED_SMD:LED_0603` | — |
| L1 | 1 | 2.2 µH, ≥3 A sat. current | Shielded power inductor | `Inductor_SMD:*` | Buck output inductor |
| R1 | 1 | 100 kΩ, 1% | FB divider top | `Resistor_SMD:R_0603` | U7 |
| R2 | 1 | 30.1 kΩ, 1% | FB divider bottom | `Resistor_SMD:R_0603` | U7 |
| R3 | 1 | 100 kΩ | EN pull-up (buck) | `Resistor_SMD:R_0603` | VBUS → U7 EN |
| R4 | 1 | 10 kΩ | EN pull-up (MCU) | `Resistor_SMD:R_0603` | 3V3_A → U1 EN |
| R5 | 1 | 10 kΩ | GPIO0 pull-up | `Resistor_SMD:R_0603` | 3V3_A → U1 IO0 |
| R6 | 1 | 10 kΩ | CAN RS slope-control | `Resistor_SMD:R_0603` | U6 RS → GND |
| R7, R8 | 2 | 5.1 kΩ | USB-C CC pulldowns | `Resistor_SMD:R_0603` | J1 CC1/CC2 → GND |
| R9, R10 | 2 | 1 kΩ | LED series resistors | `Resistor_SMD:R_0603` | D1, D2 |
| R11, R12 | 2 | 4.7 kΩ | I2C pull-ups (SDA, SCL) | `Resistor_SMD:R_0603` | On 3V3_B |
| R13 | 1 | 120 Ω | CAN bus termination (populate only at a bus end — solder-jumper selectable) | `Resistor_SMD:R_0805` | Across CANH/CANL |
| C1 | 1 | 10 µF, X7R, ≥16 V | Buck input cap | `Capacitor_SMD:C_0805` | U7 VIN |
| C2 | 1 | 22 µF, X7R, ≥10 V | Buck output cap | `Capacitor_SMD:C_0805` | U7 → 3V3_A |
| C3 | 1 | 100 nF | Buck bootstrap cap | `Capacitor_SMD:C_0402` | U7 VBST |
| C4 | 1 | 1 µF | EN delay cap (MCU) | `Capacitor_SMD:C_0603` | U1 EN → GND |
| C5 | 1 | 1 nF | Load-switch rise-time cap | `Capacitor_SMD:C_0402` | U8 CT → GND |
| C6 | 1 | 1 µF | Load-switch input bypass | `Capacitor_SMD:C_0603` | U8 VIN |
| C7 | 1 | 10 µF | Load-switch output bulk cap | `Capacitor_SMD:C_0805` | U8 VOUT / 3V3_B |
| C8 | 1 | 10 µF | Bulk decoupling at U1's 3V3 pin | `Capacitor_SMD:C_0805` | Per Espressif reference design |
| C9–C14 | 6 | 100 nF | Per-IC decoupling (U1, U2, U3, U4, U5, U6) | `Capacitor_SMD:C_0402` | One per power pin |

## 6. Pin-to-net table

Scoped to power, control, and bus-level pins — exhaustive NC/reserved-pin listings for the LGA parts (e.g. IMU `CLKIN`, `RESV`) are left to the schematic capture step and noted here only where they need a specific tie-off.

**Power input & regulation**

| Ref-Pin | Net |
|---|---|
| J1.VBUS (A4/A9/B4/B9) | VBUS |
| J1.GND (A1/B1/A12/B12) | GND |
| J1.CC1 (A5) | CC1 |
| J1.CC2 (B5) | CC2 |
| R7.1 – R7.2 | CC1 – GND |
| R8.1 – R8.2 | CC2 – GND |
| J1.D+ (A6/B6) | USB_DP |
| J1.D− (A7/B7) | USB_DM |
| U7.3 (VIN) | VBUS |
| U7.1 (GND) | GND |
| U7.2 (SW) | SW_NODE |
| U7.6 (VBST) | VBST_NODE |
| C3.1 – C3.2 | VBST_NODE – SW_NODE |
| L1.1 – L1.2 | SW_NODE – 3V3_A |
| C1.1 – C1.2 | VBUS – GND |
| C2.1 – C2.2 | 3V3_A – GND |
| U7.4 (VFB) | FB_NODE |
| R1.1 – R1.2 | 3V3_A – FB_NODE |
| R2.1 – R2.2 | FB_NODE – GND |
| U7.5 (EN) | EN_BUCK |
| R3.1 – R3.2 | VBUS – EN_BUCK |

**Peripheral-rail switch**

| Ref-Pin | Net |
|---|---|
| U8.1 (VIN) | 3V3_A |
| U8.2 (GND) | GND |
| U8.3 (ON) | PERIPH_EN |
| U8.4 (CT) | LSW_CT |
| C5.1 – C5.2 | LSW_CT – GND |
| U8.5 (QOD) | 3V3_B |
| U8.6 (VOUT) | 3V3_B |
| C6.1 – C6.2 | 3V3_A – GND |
| C7.1 – C7.2 | 3V3_B – GND |

**MCU core, boot control, and USB**

| Ref-Pin | Net |
|---|---|
| U1.3V3 | 3V3_A |
| U1.GND | GND |
| U1.EN | ESP_EN |
| R4.1 – R4.2 | 3V3_A – ESP_EN |
| C4.1 – C4.2 | ESP_EN – GND |
| SW1.1 – SW1.2 | ESP_EN – GND |
| U1.IO0 | GPIO0_BOOT |
| R5.1 – R5.2 | 3V3_A – GPIO0_BOOT |
| SW2.1 – SW2.2 | GPIO0_BOOT – GND |
| U1.IO19 | USB_DM |
| U1.IO20 | USB_DP |
| U1.IO4 | PERIPH_EN |
| C8.1 – C8.2 | 3V3_A – GND |

**I2C bus (BME280, OLED)**

| Ref-Pin | Net |
|---|---|
| U1.IO8 | I2C_SDA |
| U1.IO9 | I2C_SCL |
| R11.1 – R11.2 | 3V3_B – I2C_SDA |
| R12.1 – R12.2 | 3V3_B – I2C_SCL |
| U2.VDD, U2.VDDIO | 3V3_B |
| U2.GND | GND |
| U2.SCK | I2C_SCL |
| U2.SDI | I2C_SDA |
| U2.CSB | 3V3_B (tied high → I2C mode) |
| U2.SDO | GND (sets addr 0x76) |
| U4.VCC | 3V3_B |
| U4.GND | GND |
| U4.SCL | I2C_SCL |
| U4.SDA | I2C_SDA |

**SPI bus (flash, microSD, IMU — shared clock/data, independent chip selects)**

| Ref-Pin | Net |
|---|---|
| U1.IO11 | SPI_MOSI |
| U1.IO12 | SPI_SCK |
| U1.IO13 | SPI_MISO |
| U1.IO10 | SPI_CS_FLASH |
| U1.IO14 | SPI_CS_SD |
| U1.IO21 | SPI_CS_IMU |
| U5.VCC | 3V3_B |
| U5.GND | GND |
| U5.CS | SPI_CS_FLASH |
| U5.CLK | SPI_SCK |
| U5.DI | SPI_MOSI |
| U5.DO | SPI_MISO |
| U5.WP# | 3V3_B (write-protect disabled) |
| U5.HOLD#/RESET# | 3V3_B (hold disabled) |
| J2.VDD | 3V3_B |
| J2.GND | GND |
| J2.CS | SPI_CS_SD |
| J2.CLK | SPI_SCK |
| J2.DI | SPI_MOSI |
| J2.DO | SPI_MISO |
| U3.VDD, U3.VDDIO | 3V3_B |
| U3.GND | GND |
| U3.CS | SPI_CS_IMU |
| U3.SCLK | SPI_SCK |
| U3.SDI | SPI_MOSI |
| U3.SDO | SPI_MISO |
| U3.INT1 | IMU_INT (→ U1.IO6, optional) |

**CAN bus**

| Ref-Pin | Net |
|---|---|
| U1.IO17 | CAN_TX |
| U1.IO18 | CAN_RX |
| U6.VCC | 3V3_B |
| U6.GND | GND |
| U6.D | CAN_TX |
| U6.R | CAN_RX |
| U6.RS | CAN_RS |
| R6.1 – R6.2 | CAN_RS – GND |
| U6.VREF | NC |
| U6.CANH | J3.1 |
| U6.CANL | J3.2 |
| R13.1 – R13.2 | J3.1 – J3.2 (populate only at a bus end) |

**Indicators**

| Ref-Pin | Net |
|---|---|
| D1.anode | 3V3_A (via R9) |
| R9.1 – R9.2 | 3V3_A – D1.anode |
| D1.cathode | GND |
| D2.anode | 3V3_A (via R10) |
| R10.1 – R10.2 | 3V3_A – D2.anode |
| D2.cathode | U1.IO5 (LED2_CTRL, GPIO sinks to light) |

## 7. KiCad library notes

Confirmed directly against current vendor/KiCad documentation:
- **ESP32-S3-WROOM-1**: symbol and footprint exist both in the mainline `kicad-symbols`/`kicad-footprints` repositories (merged into `RF_Module`) and in Espressif's own official library, distributed through KiCad's Plugin and Content Manager.
- **TPS563201 / TPS22918**: exact pinouts above were pulled from TI's datasheets directly; presence in the base `Regulator_Switching`/`Power_Management` libraries varies by KiCad version — both are available as vendor-verified exports (TI provides Ultra Librarian/SnapEDA symbols) if not already installed.
- **SN65HVD230 / W25Q128**: common parts in `Interface_CAN_LIN` and `Memory_Flash` respectively in most KiCad releases; worth a quick check in your installed version before relying on it.
- **BME280 / ICM-42688-P**: less consistently included in default sensor libraries; plan to pull a manufacturer-provided symbol (Bosch and TDK both publish CAD exports) if your library doesn't already have one.
- Passives, connectors, switches, and LEDs (R, C, L, `Connector`, `Connector_Card`, `Button_Switch_SMD`, `LED_SMD`) are standard KiCad `Device`/`Connector` library content in every recent release.

## 8. Suggested next steps

- If you have a real BOM in mind, send it over and Section 2's worksheet drops in directly — same method, your numbers.
- Battery operation would add one part (a Li-ion charger such as MCP73831) ahead of U7, with U7 fed from the battery/USB OR-ed input rather than USB alone.
- If a third rail is ever needed, that's the natural point to replace U7+U8 with a small I2C-sequenced PMIC instead of adding a third discrete regulator.
