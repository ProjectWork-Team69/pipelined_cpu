# Scenario 1: Back-to-Back Forwarding Test
#----------------------------------------------------
# PC Address | Hex Code   | Assembly
#----------------------------------------------------
0x00000000 | 0x06400093 | addi x1, x0, 100      # x1 = 100
0x00000004 | 0x00108133 | add  x2, x1, x1       # x2 = 200 (Tests MEM->EX forwarding for x1)
0x00000008 | 0x401101B3 | sub  x3, x2, x1       # x3 = 100 (Tests MEM->EX fwd for x2 and WB->EX for x1)

# Scenario 2: JALR Test
#----------------------------------------------------
0x0000000C | 0x00800213 | addi x4, x0, 8        # x4 = 8 (Base address for jump)
0x00000010 | 0x010202E7 | jalr x5, x4, 16       # Jump to addr 24 (8+16). Save PC+4 (0x14) to x5.
0x00000014 | 0x3E700313 | addi x6, x0, 999      # This instruction MUST be flushed.

# Scenario 3: Load-Use Stall + Branch Test
#----------------------------------------------------
0x00000018 | 0x000013B7 | lui  x7, 1            # x7 = 0x1000 (Memory address)
0x0000001C | 0x0033A023 | sw   x3, 0(x7)        # Store 100 into mem[4096]
0x00000020 | 0x0003A403 | lw   x8, 0(x7)        # Load 100 into x8
0x00000024 | 0xFFF40493 | addi x9, x8, -1       # Load-Use STALL. x9 = 99
0x00000028 | 0x00349463 | bne  x9, x3, 8        # Branch is TAKEN (99 != 100). Jumps to addr 0x30.
0x0000002C | 0x22B00513 | addi x10, x0, 555     # This instruction MUST be flushed.

# End of Program
#----------------------------------------------------
0x00000030 | 0x000285B3 | add  x11, x5, x0      # Branch lands here. x11 = 20 (from x5).
0x00000034 | 0x0000006F | jal  x0, 0            # Halt CPU in an infinite loop at this address.