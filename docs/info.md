<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a hardware assistant designed for tabletop trading card games, such as Pokémon TCG, to replace physical damage counters and dice. The core logic is built around a 4-bit up/down counter to track damage and an 8-bit Linear Feedback Shift Register (LFSR) acting as a hardware pseudo-random number generator for coin flips.

The input buttons for adding and subtracting damage use edge-detection logic to ensure that holding a button down only registers as a single increment or decrement. The damage state is multiplexed to a 7-segment display decoder to show values from 0 to 9 (representing 0 to 90 damage). The LFSR continuously shifts at the clock frequency; when the coin flip input is active, the state of the first bit is routed to an LED, effectively capturing a random state upon release.

## How to test

Provide a clock signal and ensure the active-low reset is high (normal operation).

Toggle Input 0 high then low to add 10 damage. The 7-segment display will increment by 1 (up to a maximum of 9).

Toggle Input 1 high then low to subtract 10 damage. The display will decrement by 1 (down to a minimum of 0).

Hold Input 2 high to rapidly cycle the coin flip RNG. Release it to lock the result. The 8th output LED will illuminate for "Heads" or remain dark for "Tails", which is used for resolving status conditions like Sleep or Paralysis.

Toggle Input 3 high to instantly reset the damage counter back to 0.

## External hardware

No external hardware is required. The design is fully compatible with the standard Tiny Tapeout carrier board, utilizing the onboard 8-position DIP switch for inputs, the 7-segment display for damage tracking, and the standard output LEDs for the coin flip result.
