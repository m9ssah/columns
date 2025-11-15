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
	grid_w:     .word 12           # game field width TODO fix these
	grid_h:     .word 24           # game field height
	
	unit_size:  .word 8            # gem size
    dspl_width: .word 256
	dspl_height:.word 256

	frame_cols: .word 18       # TODO: fix these
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
    
    lw  $s3, frame_cols
    lw  $s4, frame_rows
    
    lw  $s5, frame_x0
    lw  $s6, frame_y0
    
    jal init_border      # initialize game border
    jal init_field      # initialize game field
    jal draw_field      # draw the game field (checker board?)
    
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
    j game_loop
    
    
init_border:
    move $t0, $s0       # display base

    move $t1, $s3       # t1 = frame col
    move $t2, $s4       # t2 = frame rows
    move $t3, $s5       # t3 = frame_x0
    move $t4, $s6       # t4 = frame_y0
    
    # colors
    lw $t5, cyan
    lw $t6, indigo
    
    # row index 
    li  $s7, 0

border_row_loop:
    bge $s7, $t2, border_done       # stop when i == frame_rows 


border_done:



init_field:


draw_field:


draw_line:
    sll $a0, $a0, 2         # multiply the X coordinate by 4 to get the horizontal offset
    add $t2, $t0, $a0       # add this horizontal offset to $t0, store the result in $t2
    sll $a1, $a1, 7         # multiply the Y coordinate by 128 to get the vertical offset
    add $t2, $t2, $a1       # add this vertical offset to $t2
    
    # Make a loop to draw a line.
    sll $a2, $a2, 2         # calculate the difference between the starting value for $t2 and the end value.
    add $t3, $t2, $a2       # set stopping location for $t2
    line_loop_start:
    beq $t2, $t3, line_loop_end  # check if $t0 has reached the final location of the line
    sw $t1, 0( $t2 )        # paint the current pixel red
    addi $t2, $t2, 4        # move $t0 to the next pixel in the row.
    j line_loop_start            # jump to the start of the loop
    line_loop_end:
    jr $ra                  # return to the calling program.


##  - Draws a rectangle at a given X and Y coordinate 

# $a0 = the x coordinate of the line
# $a1 = the y coordinate of the line
# $a2 = the width of the rectangle
# $a3 = the height of the rectangle
draw_rect:
# no registers to initialize (use $a3 as the loop variable)
rect_loop_start:
    beq $a3, $zero, rect_loop_end   # test if the stopping condition has been satisfied
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $ra, 0($sp)                  # push $ra onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a0, 0($sp)                  # push $a0 onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a1, 0($sp)                  # push $a1 onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a2, 0($sp)                  # push $a2 onto the stack
    
    jal draw_line                   # call the draw_line function.
    
    lw $a2, 0($sp)                  # pop $a2 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $a1, 0($sp)                  # pop $a1 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $a0, 0($sp)                  # pop $a0 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $ra, 0($sp)                  # pop $ra from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    addi $a1, $a1, 1                # move the Y coordinate down one row in the bitmap
    addi $a3, $a3, -1               # decrement loop variable $a3 by 1
    j rect_loop_start               # jump to the top of the loop.
    rect_loop_end:
    jr $ra                          # return to the calling program.

draw_square:
    lw $t1, 0($sp)      # ccolor from caller
    addi $a2, $zero, 1  # width = 1
    addi $a3, $zero, 1  # height = 1
    
    jal draw_line
    jr $ra
    