################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Massah Arafeh, 1011325745
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
    .data
##############################################################################
# Immutable Data
##############################################################################
# Address of the bitmap display
    ADDR_DSPL:  .word 0x10008000
# Address of the keyboard
    ADDR_KBRD:  .word 0xffff0000
    
# Colors:
    black: 		.word 0x00000000        # black, misc
    blue:       .word 0x000E2258        # penn blue/navy color, bg
    indigo:     .word 0x00432AFF        # indigo/purple color, gem
    violet:     .word 0x00FF76E6        # violet/pink, gen
    mustard:    .word 0x00FFD767        # mustard/yellow, gem
    green:      .word 0x0086FA9F        # light green color, gem
    cyan:       .word 0x009EE6E6        # cyan/celeste color, bg
    white:      .word 0x00FFFFFF        # white color, misc
    
# Game Scene Constants:
	grid_w:     .word 13           # game field width
	grid_h:     .word 24           # game field height
	
	unit_size:  .word 8            # gem size
    dspl_width: .word 256
	dspl_height:.word 256

	t_border:   .word 3             # top  border
    
    
# Extra features (milestone 4,5):
    gravity_time:   .word 0     # TODO change when implementing gravity
    
    music_timer:    .word 0     # TODO change when implementing soundfx/theme music


##############################################################################
# Mutable Data
##############################################################################

# Active falling col:
    curr_x:         .word 0
    curr_y:         .word 0
    curr_colors:    
    
# Game state:
    score:          .word 0
    jewels:         .word 0


##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game
    
main:       # Initialize the game
    
    
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
