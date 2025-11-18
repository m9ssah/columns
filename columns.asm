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
    black: 		.word 0x001A1A1A        # black, used to check collisions + color of game field
    indigo:     .word 0x00432AFF        # indigo/purple color, gem
    cyan:       .word 0x006FFFFF        # cyan/celeste color, bg
    white:      .word 0x00FFFFFF        # white color, misc

# Gem Colors:    
    gem_palette:
        .word 0x00111053        # penn blue/navy color
        .word 0x00F33F9C        # violet/pink
        .word 0x00FF7DFB        # pink
        .word 0x00FFA228        # orange
        .word 0x00F7D111        # mustard/yellow
        .word 0x003FFF85        # light green color
    
# Game Scene Constants:
	grid_w:     .word 13           # game field width
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
    initial:        .word 552
    curr_colors:    .space 12       # because we are using 3 gems for each generated column
    
# Game state:
    score:          .word 0
    jewels:         .word 0

##############################################################################
# Registers
##############################################################################

    # s0 - ADDR_DSPL
    # s1 - grid_w
    # s2 - grid_h
    # s3 - curr_pos
    # s4 - curr_x
    # s5 - curr_y
    

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
    
    jal init_board
    jal init_game_field
    jal generate_new_column
    j game_loop
    
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
    bgt $t2, 19, next_row
    
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
    jr $ra

#################################################################################
# initialize game field ONLY RUNS ONCE
#################################################################################

init_game_field:
    # starting from (5,5), we want to draw a 12x20 rectangle
    move $t0, $s0       # t0 address display, i dont think this is necessary
    addi $t2, $t0, 528  # initialize starting position
    
    lw $a0 grid_w       # width of field  (13)
    lw $a1 grid_h       # height of field (24)
    lw $a2, black       # initialize field color
    
    li $t3, 0           # loop variable

draw_game_field:
    beq $a1, $t3, game_field_end        # while t3 != 24:
    li $t4, 0                           # loop variable

draw_field_line:
    beq $a0, $t4, field_line_end        # while t4 != 13:
    sw $a2, 0($t2)
    addi $t2, $t2, 4                    # move to next row
    addi $t4, $t4, 1                    # t4++
    j draw_field_line

field_line_end:
    addi $t2, $t2, 76
    addi $t3, $t3, 1                    # t3++
    j draw_game_field
    
game_field_end:
    jr $ra

#################################################################################
# draw new column
#################################################################################
    
generate_new_column:
    move $t0, $s0     # base address 
    lw $t1, initial   # starter position offset
    
    la $a2, gem_palette     # gem array
    la $a3, curr_colors     # will store the 3 random colors in here
    
    li $s3, 552             # tracking curr position
    li $s4, 10              # tracking curr_x
    li $s5, 4               # tracking curr_y
    
    add $t1, $t0, $t1   # starting index to draw
    li $t3, 0   # loop var (0:2)
    
r_gen_loop:
    beq $t3, 3, gend_gen_loop
    li   $v0, 42                # random nummber generator function
    li   $a0, 0
    li   $a1, 6
    syscall                     # random index now in $a0
    
    sll $t6, $a0, 2
    add $t6, $t6, $a2
    lw $t8, 0($t6)              # load selected color word
    
    sll $t9, $t3, 2             # offset
    add $t9, $t9, $a3           # curr_colors + offset
    sw $t8, 0($t9)              # store color
    
    addi $t3, $t3, 1
    j r_gen_loop

gend_gen_loop:
    li $t3, 0                   # i = 0:3
    
draw_loop_top:
    beq $t3, 3, draw_loop_end   # exit when i == 3
    
    sll $t9, $t3, 2             # load curr_colors[i]
    add $t9, $t9, $a3
    lw $t8, 0($t9)             # load color from curr_colors[i]
    
    # compute vram address for curr gem
    move $t6, $t1           # start with base drawing position
    sll $t7, $t3, 7        # i * 128 (one row down per gem)
    add $t6, $t6, $t7      # final address
    
    # store gem color
    sw $t8, 0($t6)        # draw the gem
    
    addi $t3, $t3, 1
    j draw_loop_top

draw_loop_end:
    jr $ra
    
game_over:
    # TODO: implement

#################################################################################
# Keyboard Input        s3 - curr_pos, s4 - x, s5- - y, a3 - curr_color
#################################################################################
    
keyboard_input:     # t0 = keyboard address
    lw $a0, 4($t0)  # load second word from keyboard (since the first word is the one that determines whether we are using the keyboard)
    
    beq $a0, 0x71, q_response     # Check if the key q was pressed
    beq $a0, 0x61, move_left	# if the key a was pressed, move col left
	beq $a0, 0x64, move_right	# if the key d was pressed, move col right
	beq $a0, 0x73, move_down	# if the key s was pressed, move col down
	beq $a0, 0x77, rotate		# if the key w was pressed, rotate col (we dont need to check collisions for this, merely shuffle the order of colors.
	
	b game_loop                 # else go back

q_response:
	li $v0, 10      # quit gracefully
	syscall

move_left:
    # jal check_a     # check for collision
    
    li $a1, -1      # desired shift value (x-direction)
    li $a2, 0       # desired shift value (y-direciton)
    jal update_column
    jal check_frozen
    j game_loop

move_right:
    # jal check_d     # check for collision
    
    li $a1, 1      # desired shift value (x-direciton)
    li $a2, 0       # desired shift value (y-direciton)
    jal update_column
    jal check_frozen
    j game_loop
    
move_down:
    # jal check_s     # check for collision
    
    li $a1, 0   # desired shift value (x-direciton)
    li $a2, 1   # desired shift value (y-direciton)
    jal update_column
    jal check_frozen
    j game_loop

rotate:
    jal rotate_colors
    
    # compute v-ram address:
    move $t0, $s0       # display address
    la $a3, curr_colors # colors array
    move $t4, $s4
    move $t5, $s5
    sll $t4, $t4, 2
    sll $t5, $t5, 7
    add $s3, $t4, $t5   # curr v-ram address
    add $t0, $s3, $t0   # to draw
    li $t6, 0           # loop var
    
    rotate_start:
        beq $t6, 3, rotate_end
        sll $t9, $t6, 2     # load curr_colors[i]
        add $t9, $t9, $a3
        lw $t8, 0($t9)
        sw $t8, 0($t0)      # draw gem 
        addi $t0, $t0, 128  # move to next block
        addi $t6, $t6, 1
        j rotate_start
        
    rotate_end:
        j game_loop

################################################################################
# rotate_colors helper
################################################################################
rotate_colors:
    la $t0, curr_colors
    
    lw $t1, 0($t0)   # top
    lw $t2, 4($t0)   # mid
    lw $t3, 8($t0)   # bottom

    sw $t2, 0($t0)   # new top
    sw $t3, 4($t0)   # new mid
    sw $t1, 8($t0)   # new bottom

    jr $ra

#################################################################################
# Update + Clear
#################################################################################
update_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_column
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    move $t0, $s0   # address display
    # update curr position:
    add $s4, $s4, $a1   
    add $s5, $s5, $a2
    #compute v-ram:
    move $t4, $s4
    move $t5, $s5
    
    sll $t4, $t4, 2
    sll $t5, $t5, 7
    add $s3, $t4, $t5   # curr v-ram address
    add $t0, $s3, $t0   # to draw
    
    la $a3, curr_colors # colors array
    li $t3, 0           # loop var
    
update_column_loop:
    beq $t3, 3, update_column_end
    
    sll $t9, $t3, 2     # load curr_colors[i]
    add $t9, $t9, $a3
    lw $t8, 0($t9)
    sw $t8, 0($t0)      # draw gem 
    addi $t0, $t0, 128  # move to next block
    addi $t3, $t3, 1    # increment loop var
    j update_column_loop

update_column_end:
    jr $ra

clear_column:       # overwrite curr column by recoloring it to black
    move $t0, $s0       # address display
    #compute v-ram:
    move $t4, $s4
    move $t5, $s5
    
    sll $t4, $t4, 2
    sll $t5, $t5, 7
    add $s3, $t4, $t5   # curr v-ram address
    
    add $t0, $s3, $t0   # to draw
    lw $t2, black       # load black color
    li $t3, 0           # loop var
    
clear_column_start:
    beq $t3, 3, clear_column_end
    sw $t2, 0($t0)      # color block in black
    addi $t0, $t0, 128
    addi $t3, $t3, 1
    j clear_column_start

clear_column_end:
    jr $ra
    
#################################################################################
# Collision Detection
#################################################################################
    
check_a:

check_d:

check_s:

check_frozen:   # checks whether we should freeze curr column and begin generating a new one

    
    
#################################################################################
# game loop
#################################################################################

game_loop:
    # 1a. Check if key has been pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
	li $v0, 32
    li $a0, 5000
    # 5. Go back to Step 1
    j game_loop