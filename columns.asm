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
	grid_w:     .word 12           # game field width
	grid_h:     .word 24           # game field height
	
	unit_size:  .word 8            # gem size
    dspl_width: .word 256
	dspl_height:.word 256

	frame_cols: .word 18
	frame_rows: .word 30
	
	frame_x0:   .word 4        # offsets
	frame_y0:   .word 132  
    
    
# Extra features (milestone 4,5):
    gravity_timer:   .word 0     # TODO change when implementing gravity
    music_timer:     .word 0     # TODO change when implementing soundfx/theme music


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
# Registers
##############################################################################

    # s0 - ADDR_DSPL
    # s1 - grid_w
    # s2 - grid_h
    

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game
    
main:       # Initialize the game
    lw $s0, ADDR_DSPL       # display  base address = s0
    
    lw $s1, grid_w          # game field width = s1
    lw $s2, grid_h          # game field height = s2
    
    lw $s3, frame_cols         
    lw $s4, frame_rows
    
    jal init_board
    
#################################################################################
# initialize board frame (checkered 1x1 alternating color squares) ONLY RUNS ONCE
#################################################################################

init_board:
    move $t0, $s0      # $t0 = base address of display
    lw $a0, cyan           # color A (cyan)
    lw $a1, indigo         # color B (indigo)

    li $t1, 1              # tile_row = 1..30

row_loop:
    bgt $t1, 30, init_board_end
    li $t2, 1              # tile_col = 1..18

col_loop:
    bgt $t2, 18, next_row
    
    # determines which color is next (to achieve checkered look)
    add  $t3, $t1, $t2     # sum of row and col
    andi $t3, $t3, 1       # get least significant bit
    beq  $t3, $zero, use_cyan
    move $t6, $a1          # use indigo
    j color_selected

use_cyan:
    move $t6, $a0          # use cyan
    
color_selected:
    # calculate
    # pixel_y = tile_row * 128
    # pixel_x = tile_col * 4
    
    sll $t7, $t1, 7        # converting to correct index (y)
    sll $t8, $t2, 2        # basically converting to correct index (x)

    # calculate offset:
    add $t7, $t7, $t8      # y  = y + x
    
    add $t9, $t0, $t7      # $t9 = starting address of tile (y)
    
    # now fill the tile with the selected color
    li $s7, 0              # pixel_row = 0 to 7

tile_row_loop:
    li $t5, 1
    beq $s7, $t5, tile_done
    li $s6, 0              # pixel_col = 0 to 7

tile_col_loop:
    li $t5, 1
    beq $s6, $t5, tile_next_row
    
    sw $t6, 0($t9)         # store color at current pixel
    addi $t9, $t9, 4       # move to next pixel (right)
    addi $s6, $s6, 1
    j tile_col_loop

tile_next_row:
    li $t5, 128
    add $t9, $t9, $t5
    addi $s7, $s7, 1
    j tile_row_loop
    
tile_done:
    addi $t2, $t2, 1       # next tile column
    j col_loop

next_row:
    addi $t1, $t1, 1       # next tile row
    j row_loop

init_board_end:
    j init_game_field       # questionable, probably wrong TODO Check if this is ok

#################################################################################
# initialize game field ONLY RUNS ONCE
#################################################################################

init_game_field:
    # starting from (5,5), we want to draw a 12x20 rectangle
    move $t0, $s0       # t0 address display, i dont think this is necessary\
    addi $t2, $t0, 528  # initialize starting position
    
    lw $a0 grid_w       # width of field  (12)
    lw $a1 grid_h       # height of field (24)
    lw $a2, black       # initialize field color
    
    li $t3, 0           # loop variable

draw_game_field:
    beq $a1, $t3, game_field_end        # while t3 != 24:
    li $t4, 0                           # loop variable

draw_field_line:
    beq $a0, $t4, field_line_end        # while t4 != 12:
    sw $a2, 0($t2)
    addi $t2, $t2, 4                    # move to next row
    addi $t4, $t4, 1                    # t4++
    j draw_field_line

field_line_end:
    addi $t2, $t2, 80
    addi $t3, $t3, 1                    # t3++
    j draw_game_field
    
game_field_end:
    li $v0, 10
    syscall


    
game_loop:
    # 1a. Check if key has been pressed
    # lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    # lw $t8, 0($t0)                  # Load first word from keyboard
    # beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    # j game_loop


