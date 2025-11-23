################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Massah Arafeh, 1011325745
# Student 2: Zhihan(Hannah), 1010925037
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
    dark_black: .word 0x00000000 
    black: 		.word 0x001A1A1A        # black, used to check collisions + color of game field
    indigo:     .word 0x006F5CFF        # indigo/purple color, gem
    cyan:       .word 0x006FFFFF        # cyan/celeste color, bg
    white:      .word 0x00FFFFFF        # white color, misc

# Gem Colors:    
    gem_palette:
        .word 0x002A27CE        # penn blue/navy color
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
	
	game_grid: .space 1248     # game grid area
	
	field_x0: .word 4      # leftmost field tile in VRAM
    field_y0: .word 4      # topmost field tile in VRAM

    mark_grid:  .space 1248     # grid that the cells have been matched
    
    message_grid:  .space 4096 # grid for the message what to store in the grid
    
# Extra features (milestone 4,5):
    gravity_timer:          .word 0
    music_timer:            .word 0     # TODO change when implementing soundfx/theme music
    gameover_music_timer:   .word 4820 
    pause_recorder:         .word 0     # 1 = pause
    game_started:           .word 0     # haven't start: 0; start level: 1,2,3

##############################################################################
# Mutable Data
##############################################################################

# Active falling col:
    initial:        .word 552
    curr_colors:    .space 12       # because we are using 3 gems for each generated column
    
# Game state:
    score:          .word 0
    match_counter: .word 0 # count the total number of the cells matched

##############################################################################
# Registers
##############################################################################

    # s0 - ADDR_DSPL base
    # s1 - grid_w
    # s2 - grid_h
    # s3 - curr_pos
    # s4 - curr_x
    # s5 - curr_y (the top cell)
    

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
    jal init_message_grid # UPDATE
    jal init_game_field
    jal init_game_grid

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
# draw the (second) logic grid
#################################################################################

init_game_grid:
    la $t0, game_grid     # pointer to grid
    li $t1, 0
    li $t2, 312           # 13 * 24 = 312 tiles

init_grid_loop:
    beq $t2, $zero, init_grid_end
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    j init_grid_loop

init_grid_end:
    jr $ra

#################################################################################
# UPDATE
# initialize message_grid for pause
# using different int in present different message 
# (e.g. 1 means the cell for pause, 2 means the cell for game over, 3 means for both the cell for game over and pause)
#################################################################################
init_message_grid:
    la $t1, message_grid     # pointer to grid
    li $t3, 0 # t3 = row

init_message_grid_row_loop:
    bge $t3, 32, init_message_grid_end
    
    li $t4, 0 # t4 col
    
init_message_grid_col_loop:  
    bge  $t4, 32, init_message_grid_next_row
    bne  $t4, 25, init_message_grid_next_col  # next col if message_grid col is not 25

    # otherwise
    mul  $t5, $t3, 32
    add  $t5, $t5, $t4
    sll  $t5, $t5, 2

    # message_grid[index]
    addu $t5, $t1, $t5       # t5 = message_grid[index]
   
    # load 1
    li   $t7, 1
    sw   $t7, 0($t5)

init_message_grid_next_col:
    addi $t4, $t4, 1
    j    init_message_grid_col_loop

init_message_grid_next_row:
    addi $t3, $t3, 1
    j    init_message_grid_row_loop

init_message_grid_end:
    jr $ra
#################################################################################
# draw new column
#################################################################################
    
generate_new_column:
    move $t0, $s0     # base address 
    lw $t1, initial   # starter position offset
    
    la $a2, gem_palette     # gem array
    la $a3, curr_colors     # will store the 3 random colors in here
    
    # li $s3, 552             # tracking curr position
    li $s4, 6              # tracking curr_x
    li $s5, 0               # tracking curr_y
    
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
    li $v0, 33
    li $a0, 70        # pitch
    li $a1, 700       # duration
    li $a2, 89        # instrument
    li $a3, 127       # volume
    syscall
    
    li  $v0, 10
    syscall

#################################################################################
# Keyboard Input        s3 - curr_pos, s4 - x, s5- - y, a3 - curr_color
#################################################################################
    
keyboard_input:     # t0 = keyboard address
    lw $a0, 4($t0)  # load second word from keyboard (since the first word is the one that determines whether we are using the keyboard)
    beq $a0, 0x71, q_response     # Check if the key q was pressed
    
    la   $t2, game_started
    lw   $t3, 0($t2)
    beq  $t3, $zero, gravity_select_response   # game_started == 0: must to select the difficulty

    ###### game begin ########
    beq $a0, 0x70, pause_response # check if the key p was pressed

    # if it is pause
    lw  $t9, pause_recorder
    bne $t9, $zero, ignore_key_for_pause

    # otherwise 
    beq $a0, 0x61, move_left	# if the key a was pressed, move col left
	beq $a0, 0x64, move_right	# if the key d was pressed, move col right
	beq $a0, 0x73, move_down	# if the key s was pressed, move col down
	beq $a0, 0x77, rotate		# if the key w was pressed, rotate col (we dont need to check collisions for this, merely shuffle the order of colors.
	
	b game_loop                 # else go back
ignore_key_for_pause:
    b game_loop

gravity_select_response:
  beq $a0, 0x31, general_gravity_setting1   # '1'
  beq $a0, 0x32, general_gravity_setting2    # '2'
  beq $a0, 0x33, general_gravity_setting3   # '3'

  #  else go back
  b  game_loop

pause_response:
    la  $t0, pause_recorder
    lw  $t1, 0($t0)      # t1 = pause_recorder
    beq $t1, $zero, set_pause # if pause_recorder = 0, change to 1 (pause) 

    # if pause_recorder = 1, change to 0, continue the game
    sw  $zero, 0($t0)
    jal hide_pause_message # UPDATE
    j   game_loop

set_pause:
    li  $t1, 1 
    sw  $t1, 0($t0) # pause_recorder change to 1
    jal display_pause_message # UPDATE
    j   game_loop

q_response:
	li $v0, 10      # quit gracefully
	syscall

move_left:
    li $v0,31
    li $a0,64       # pitch
    li $a1,300     # duration
    li $a2,4       # instrument
    li $a3,80     # vol
    syscall

    jal check_a     # check for collision
    li $a1, -1      # desired shift value (x-direction)
    li $a2, 0       # desired shift value (y-direciton)
    jal update_column
    jal check_lock
    j game_loop

move_right:
    li $v0,31
    li $a0,64       # pitch
    li $a1,300     # duration
    li $a2,4       # instrument
    li $a3,80     # vol
    syscall
    
    jal check_d     # check for collision
    li $a1, 1      # desired shift value (x-direciton)
    li $a2, 0       # desired shift value (y-direciton)
    jal update_column
    jal check_lock
    j game_loop
    
move_down:
    # if paused, don't move
    lw  $t9, pause_recorder
    bne $t9, $zero, ignore_key_for_pause

    # move down
    jal check_s     # check for collision
    li $a1, 0   # desired shift value (x-direciton)
    li $a2, 1   # desired shift value (y-direciton)
    jal update_column
    jal check_lock
    j game_loop

rotate:
    li $v0,31
    li $a0,60       # pitch
    li $a1,400      # duration
    li $a2,4        # instrument
    li $a3,80      # volume
    syscall

    jal rotate_colors
    # compute v-ram address:
    move $t0, $s0       # display address
    la $a3, curr_colors # colors array
    lw $t6, field_x0
    lw $t7, field_y0
    
    add $t4, $s4, $t6         # screen_x = grid_x + field_x0
    add $t5, $s5, $t7         # screen_y = grid_y + field_y0
    
    sll $t4, $t4, 2
    sll $t5, $t5, 7
    # s3 = offset of top cell
    add $s3, $t4, $t5       # error? debuged?
    add $t0, $s3, $s0
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
    # compute v-ram:
    lw $t6, field_x0
    lw $t7, field_y0
    
    add $t4, $s4, $t6      # screen_x = grid_x + field_x0
    add $t5, $s5, $t7      # screen_y = grid_y + field_y0
    
    sll $t4, $t4, 2        # x * 4
    sll $t5, $t5, 7        # y * 128
    
    add $s3, $t4, $t5
    add $t0, $s3, $s0      # VRAM = base + offset
    
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
    lw $t6, field_x0
    lw $t7, field_y0
    
    add $t4, $s4, $t6      # screen_x = grid_x + field_x0
    add $t5, $s5, $t7      # screen_y = grid_y + field_y0
    
    sll $t4, $t4, 2        # x * 4
    sll $t5, $t5, 7        # y * 128
    
    add $s3, $t4, $t5
    add $t0, $s3, $s0      # VRAM = base + offset
    
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

# check if the column can move left
check_a:
    move $t4, $s4
    move $t5, $s5
    beq $t4, $zero, no_left     # misc
    
    addi $t4, $t4, -1
    li $t3, 0
    
    left_loop_start:
    beq $t3, 3, ok_left
    add $a1, $t5, $t3       # load y
    move $a0, $t4            # load x
    
    # call read grid (to identify the coordinate we must check)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal read_grid
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    bne $v0, $zero, no_left
    
    addi $t3, $t3, 1        # loop var
    j left_loop_start

ok_left:
    jr $ra

no_left:
    j game_loop

# check if the column can move right
check_d:
    move $t4, $s4
    move $t5, $s5
    lw   $t0, grid_w
    addi $t0, $t0, -1       # t0 = grid_w - 1
    beq  $t4, $t0, no_right
    
    addi $t4, $t4, 1
    li $t3, 0
    
    right_loop_start:
    beq $t3, 3, ok_right
    add $a1, $t5, $t3       # load y
    move $a0, $t4            # load x
    
    # call read grid (to identify the coordinate we must check)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal read_grid
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    bne $v0, $zero, no_right
    
    addi $t3, $t3, 1        # loop var
    j right_loop_start

ok_right:
    jr $ra

no_right:
    j game_loop
    
# check if the column can move down
check_s:        # no need for loop, we only cheeck very last block of curr col
    move $t4, $s4
    move $t5, $s5

    lw   $t0, grid_h
    addi $t0, $t0, -3
    beq  $t5, $t0, no_down
    
    addi $a1, $t5, 3       # load y
    move $a0, $t4      # load x
    
    # call read grid (to identify the coordinate we must check)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal read_grid
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    lw $t1, black
    bne $v0, $zero, no_down

    jr $ra
    
no_down:
    jal check_lock
    j game_loop


#################################################################################
# Check if the column is landed (and then lock the landed column by calling lock_landed_column)
#################################################################################
check_lock:   # checks whether we should freeze curr column and begin generating a new one
###
#  (s4 = x, s5 = y) 
# Check_lock
#   1. landed to the frame
#   2. landed to another column
###

    # bottom_row = s5 + 2
    move $t0, $s5
    addi $t0, $t0, 2          # t0 = bottom_row

    # grid_h 
    addi $t1, $s2, -1         # t1 = grid_h - 1 is the lowest row

    # case 1: the lowest row landed
    beq  $t0, $t1, lock_landed_column

    # case 2: landed on another column
    addi $t2, $t0, 1          # t2 = row_below = bottom_row + 1

    # game_grid[row_below][s4]
    la   $t3, game_grid       # t3 = game_grid base_address 
    mul  $t4, $t2, $s1        # t4 = row_below * grid_w
    add  $t4, $t4, $s4        # t4 = row_below * grid_w + col
    sll  $t4, $t4, 2          # * 4 Byte (1 word = 4 Byte)
    add  $t3, $t3, $t4        # t3 = base_address + game_grid[row_below][col]*4
    lw   $t5, 0($t3)          # t5 = the content for game_grid[row_below][col]*4

    # check if it is landed
    beq  $t5, $zero, check_lock_return # conti
    
    lw   $t6, black
    beq  $t5, $t6, check_lock_return #conti

    # otherwise landed
    j lock_landed_column

check_lock_return: # return to next line(j game loop)
    jr   $ra

#################################################################################
# After checking landing
#################################################################################
lock_landed_column: #after landand, we need 
#1)clocked 
#2)clock the column(write into the game_grid) 
#3)check the game over 
#4)matching and cancelling 
#5)generate the new column


    #write the current column into the game_grid
    jal  lock_column

    # matching and cancelling
    jal match_and_fall

    # game over
    jal check_game_over

    #create new column
    jal  generate_new_column
    j game_loop


#################################################################################
# write the current column into the game_grid
#   curr_colors[0] = top color
#   curr_colors[1] = mid color
#   curr_colors[2] = bottom color
#################################################################################
lock_column:
    li $v0,31
    li $a0,76         # F#5
    li $a1,500        # long soft decay
    li $a2,98         # Crystal FX (perfect match)
    li $a3,100
    syscall
    
    la  $t0, curr_colors   # t0 curr_colors base
    la  $t1, game_grid     # t1 game_grid base
    li  $t2, 0             # initialize i = 0 (for index i = 0,1,2)

lock_column_loop:
    beq $t2, 3, lock_column_done # for i = 0,1,2

    # row = s5 + i
    addu $t3, $s5, $t2     # t3 = row (y)
    # col = s4
    move $t4, $s4          # t4 = col (x)

    # get curr_colors[i]
    sll  $t5, $t2, 2       # i * 4 word offset
    addu $t6, $t0, $t5     # address = curr_colors base + offset
    lw   $t7, 0($t6)       # t7 = curr_colors[i] (color)

    # game_grid[row][col] address：
    # index = row * grid_w + col
    mul  $t8, $t3, $s1     # t8 = row * grid_w
    add  $t8, $t8, $t4     # t8 = row * grid_w + col
    sll  $t8, $t8, 2       # *4 byte 
    addu $t9, $t1, $t8     # t9 = game_grid_base + offset

    # stote color into curr_color[i]
    sw   $t7, 0($t9)

    # i++
    addi $t2, $t2, 1
    j    lock_column_loop

lock_column_done:
    jr   $ra

#################################################################################
# function: match anc cancellling
#################################################################################
match_and_fall:
    # store the return address
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

match_and_fall_loop:
    # 1. clear mark_grid
    jal clear_mark_grid

    # 2. find matches and mark them
    jal find_matches        # v0 = then number of cells matched this group
    
    #TODO scoring system

    beq  $v0, $zero, match_and_fall_end   # no match: the loop ends

    # 2.1
    jal flashing
    

    # 3. remove all cancelled cells from the game_grid
    jal remove_marked_cells

    # 4. gravity
    jal grid_gravity

    # 5. redraw the game_grid
    # jal redraw_grid

    # loop again
    j   match_and_fall_loop

match_and_fall_end:
    # jamp back to return address
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


#################################################################################
# clear_mark_grid
#################################################################################
clear_mark_grid:
    la  $t0, mark_grid # t0 = mark_grid base address
    li  $t1, 312     # counter

clear_mark_loop:
    beq $t1, $zero, clear_mark_done
    sw  $zero, 0($t0)        # mark_grid[i] = 0
    addi $t0, $t0, 4         # t0 = next word
    addi $t1, $t1, -1
    j   clear_mark_loop

clear_mark_done:
    jr  $ra # finishing clear_mark_done

#################################################################################
# find_matches
# v0 = the number of the marked cells
# s1 = grid_w, s2 = grid_h
#################################################################################
find_matches:
    addi $sp, $sp, -8
    
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)

    li   $v0, 0              # v0 = number of the marked cell
    la   $s0, game_grid      # s0 = game_grid base
    la   $t7, mark_grid      # t7 = mark_grid base

    li   $t0, 0              # t0 = row0
    
# structure:
# for (row = 0; row < grid_h; row++) {
#    for (col = 0; col < grid_w; col++) {
#        color = game_grid[row][col];
#        if (color == 0) continue;
fm_row_loop:
    bge  $t0, $s2, find_matches_end   # end when row >= grid_h
    li   $t1, 0              # t1 = col0

fm_col_loop:
    bge  $t1, $s1, fm_next_row   # change to next col when col >= grid_w

    # t3 = color at game_grid[row][col] 
    mul  $t2, $t0, $s1           # t2 = row * grid_w
    add  $t2, $t2, $t1           # t2 = row * grid_w + col
    sll  $t2, $t2, 2             # t2 = index * 4
    addu $t3, $s0, $t2           # t3 = game_grid[row][col] address
    lw   $t3, 0($t3)             # t3 = color at game_grid[row][col]

    beq  $t3, $zero, fm_next_col    # if 0: next col
    lw   $t9, black
    beq  $t3, $t9, fm_next_col      # if black: next col

    ########################################################################
    # horizontal (row, col), (row, col+1), (row, col+2)
    ########################################################################
    addi $t4, $t1, 2
    bge  $t4, $s1, match_vertical   # col+2 >= grid_w exceed

    # 2nd： (row, col+1)
    addi $t4, $t1, 1                # sec_col = col+1
    
    mul  $t5, $t0, $s1
    add  $t5, $t5, $t4
    sll  $t5, $t5, 2
    addu $t5, $s0, $t5
    lw   $t5, 0($t5)                # $t5 = color2
    bne  $t5, $t3, match_vertical

    # 3rd： (row, col+2)
    addi $t4, $t1, 2                # third_col = col+2
    
    mul  $t6, $t0, $s1
    add  $t6, $t6, $t4
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)                # t6 = color3
    bne  $t6, $t3, match_vertical

    # otherwise 3 matches
    # mark (row, col) on mark_grid
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8              # t9 = mark_grid base + offset
    lw   $t6, 0($t9)                # t6 = color1
    
    bne  $t6, $zero, fm_mark_h2     # if match, mark(row, col) in the mark_grid. skip the repeat counting if it is marked before
    #
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1 # if match, v0++

# mark (row, col+1)
fm_mark_h2:
    addi $t4, $t1, 1
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t4
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_h3
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1
    
# mark (row, col+2)
fm_mark_h3:
    addi $t4, $t1, 2
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t4
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, match_vertical
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

match_vertical:

    ########################################################################
    # 2. vertical (row, col), (row+1, col), (row+2, col)
    ########################################################################
    addi $t4, $t0, 2
    bge  $t4, $s2, match_dignonal    # row+2 >= grid_h 

    # 2nd： (row+1, col)
    addi $t4, $t0, 1
    mul  $t5, $t4, $s1
    add  $t5, $t5, $t1
    sll  $t5, $t5, 2
    addu $t5, $s0, $t5
    lw   $t5, 0($t5)
    bne  $t5, $t3, match_dignonal

    # third： (row+2, col)
    addi $t4, $t0, 2
    mul  $t6, $t4, $s1
    add  $t6, $t6, $t1
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)
    bne  $t6, $t3, match_dignonal

    # mark (row, col)
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_v2
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

fm_mark_v2:
    # mark (row+1, col)
    addi $t4, $t0, 1
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_v3
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

# mark (row+2, col)
fm_mark_v3:
    addi $t4, $t0, 2
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, match_dignonal
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

match_dignonal:

    ########################################################################
    # 3. dignal ↘ (row, col), (row+1, col+1), (row+2, col+2)
    ########################################################################
    addi $t4, $t0, 2
    bge  $t4, $s2, match_dignonal_up   # row+2 exceed
    addi $t4, $t1, 2
    bge  $t4, $s1, match_dignonal_up   # col+2 exceed

    # second： (row+1, col+1)
    addi $t4, $t0, 1
    addi $t5, $t1, 1
    mul  $t6, $t4, $s1
    add  $t6, $t6, $t5
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)
    bne  $t6, $t3, match_dignonal_up

    # 3rd： (row+2, col+2)
    addi $t4, $t0, 2
    addi $t5, $t1, 2
    mul  $t6, $t4, $s1
    add  $t6, $t6, $t5
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)
    bne  $t6, $t3, match_dignonal_up

    # mark (row, col)
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_dd2
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

# mark (row+1, col+1)
fm_mark_dd2:
    addi $t4, $t0, 1
    addi $t5, $t1, 1
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t5
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_dd3
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

# mark (row+2, col+2)
fm_mark_dd3:
    addi $t4, $t0, 2
    addi $t5, $t1, 2
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t5
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, match_dignonal_up
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

match_dignonal_up:

    ########################################################################
    # 4. dignonal ↗ (row, col), (row-1, col+1), (row-2, col+2)
    ########################################################################
    addi $t4, $t0, -2
    bltz $t4, fm_after_diag_up        # row-2 < 0 exceed 
    addi $t4, $t1, 2
    bge  $t4, $s1, fm_after_diag_up   # col+2 >= grid_w exceed

    # 2nd： (row-1, col+1)
    addi $t4, $t0, -1
    addi $t5, $t1, 1
    mul  $t6, $t4, $s1
    add  $t6, $t6, $t5
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)
    bne  $t6, $t3, fm_after_diag_up

    # 3rd： (row-2, col+2)
    addi $t4, $t0, -2
    addi $t5, $t1, 2
    mul  $t6, $t4, $s1
    add  $t6, $t6, $t5
    sll  $t6, $t6, 2
    addu $t6, $s0, $t6
    lw   $t6, 0($t6)
    bne  $t6, $t3, fm_after_diag_up

    # mark (row, col)
    mul  $t8, $t0, $s1
    add  $t8, $t8, $t1
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_du2
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

# mark (row-1, col+1)
fm_mark_du2:
    addi $t4, $t0, -1
    addi $t5, $t1, 1
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t5
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_mark_du3
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

# mark (row-2, col+2)
fm_mark_du3:
    addi $t4, $t0, -2
    addi $t5, $t1, 2
    mul  $t8, $t4, $s1
    add  $t8, $t8, $t5
    sll  $t8, $t8, 2
    addu $t9, $t7, $t8
    lw   $t6, 0($t9)
    bne  $t6, $zero, fm_after_diag_up
    li   $t6, 1
    sw   $t6, 0($t9)
    addi $v0, $v0, 1

fm_after_diag_up:

fm_next_col:
    addi $t1, $t1, 1  # col = col + 1
    j    fm_col_loop

fm_next_row:
    addi $t0, $t0, 1 # row = row + 1
    j    fm_row_loop

find_matches_end:
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

#################################################################################
# flashing
#################################################################################
flashing:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # make all marked cells white
    jal  flash_set_white

    # delay
    li  $v0, 32 # call sleep syscall
    li  $a0, 450 # sleep 17 ms
    syscall

    # jump to remove the matched cells
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
#################################################################################
# flash_set_white
# set all matched cells white
#################################################################################
flash_set_white:
    la   $t0, mark_grid      # t0 = mark_grid base 
    lw   $t1, field_x0       # t1 = field_x0
    lw   $t2, field_y0       # t2 = field_y0
    li   $t3, 0              # row = 0

fsw_row_loop:

    li $v0,31
    li $a0,55         # pitch
    li $a1,300        # duration
    li $a2,89         # instrument
    li $a3,125         # volume
    syscall

    bge  $t3, $s2, fsw_done

    li   $t4, 0              # col = 0

fsw_col_loop:
    bge  $t4, $s1, fsw_next_row

    # index = row * grid_w + col
    mul  $t5, $t3, $s1
    add  $t5, $t5, $t4
    sll  $t5, $t5, 2         # *4

    # mark_grid[index]
    addu $t5, $t0, $t5       # mark_grid[index]
    lw   $t6, 0($t5)
    beq  $t6, $zero, fsw_next_col  # next col if mark_grid[i] = 0

    # VRAM address
    # screen_x = col + field_x0
    # screen_y = row + field_y0
    move $t7, $t4
    add  $t7, $t7, $t1     # screen_x

    move $t8, $t3
    add  $t8, $t8, $t2     # screen_y

    sll  $t7, $t7, 2       # x * 4
    sll  $t8, $t8, 7       # y * 128

    add  $t9, $s0, $t7
    add  $t9, $t9, $t8    # t9 = VRAM address

    # load white
    lw   $t5, white
    sw   $t5, 0($t9)

    # test function: counter++
    la $t7, match_counter
    lw $t8, 0($t7)
    addi $t8, $t8, 1
    sw $t8, 0($t7)

fsw_next_col:
    addi $t4, $t4, 1
    j    fsw_col_loop

fsw_next_row:
    addi $t3, $t3, 1
    j    fsw_row_loop

fsw_done:
    jr   $ra


#################################################################################
# apply_gravity
# for each col in game_grid:
# - if the 
# -refilling 0 
#################################################################################
apply_gravity:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    la   $t0, game_grid     # t0 = game_grid base address
    li   $t3, 0             # t3 = col = 0

# for(i = 0; i < grid_w; i++)
#  for
gravity_col_loop:
    bge  $t3, $s1, gravity_done   # if col >= grid_w，end loop

    # write_row = grid_h - 1
    addi $t4, $s2, -1       # t4 = write_row

    # read_row = grid_h - 1
    addi $t5, $s2, -1       # t5 = read_row

gravity_read_loop:
    bltz $t5, gravity_fill_zeros  # finishing and then clear all cells above the top cells in each col

    # game_grid[read_row][col]
    mul  $t6, $t5, $s1      # t6 = read_row * grid_w
    add  $t6, $t6, $t3      # t6 += col
    sll  $t6, $t6, 2        # t6 *= 4
    addu $t7, $t0, $t6      # t7 = game_grid[read_row][col]
    lw   $t8, 0($t7)        # t8 = color at game_grid[read_row][col]

    beq  $t8, $zero, gravity_next_read   # if color is 0, read next col

    # otherwise: write the read row color into the write row 
    mul  $t9, $t4, $s1      # t9 = write_row * grid_w
    add  $t9, $t9, $t3      # t9 += col
    sll  $t9, $t9, 2
    addu $t9, $t0, $t9      # t9 = game_grid[write_row][col]
    sw   $t8, 0($t9)        # load read row color into game_grid[write_row][col]

    # if write row is not read row, clear read row
    bne  $t4, $t5, gravity_clear_old
    
    j    gravity_after_write

gravity_clear_old:
    sw   $zero, 0($t7)      # clear

gravity_after_write:
    addi $t4, $t4, -1       # write_row--

gravity_next_read:
    addi $t5, $t5, -1       # read_row--
    j    gravity_read_loop

# reclearning (useless...?)
gravity_fill_zeros:
gravity_zero_loop:
    bltz $t4, gravity_next_col   # write_row < 0: next col

    mul  $t6, $t4, $s1
    add  $t6, $t6, $t3
    sll  $t6, $t6, 2
    addu $t7, $t0, $t6
    sw   $zero, 0($t7)
    addi $t4, $t4, -1      # row--
    j    gravity_zero_loop

gravity_next_col:
    addi $t3, $t3, 1       # col++
    j    gravity_col_loop

gravity_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

#################################################################################
# grid_gravity
# After removing the matched cells
#################################################################################
grid_gravity:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # 1. apply gravity on the game_grid
    jal  apply_gravity

    # 2. update the screen based on the new game_grid
    jal  redraw_grid

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

#################################################################################
# remove_marked_cells
#################################################################################
# if the marked_gird is 1, game_grid changes to 0
# if the marked_grid is 0, conti
remove_marked_cells:
    la  $t0, game_grid      # t0 = game_grid base address
    la  $t1, mark_grid      # t1 = mark_grid base address
    li  $t2, 312            

erase_mark_loop:
    beq $t2, $zero, erase_mark_done

    lw  $t3, 0($t1)         # t3 = mark_grid[i]
    beq $t3, $zero, erase_mark_skip

    sw  $zero, 0($t0)       # game_grid[i] = 0

erase_mark_skip:
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, -1
    j    erase_mark_loop

erase_mark_done:
    jr  $ra

#################################################################################
# redraw_grid
#################################################################################
redraw_grid:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    la   $t0, game_grid

    lw   $t3, field_x0
    lw   $t4, field_y0

    li   $t5, 0              # row = 0

redraw_row_loop:
    bge  $t5, $s2, redraw_done

    li   $t6, 0              # col = 0
    
redraw_col_loop:
    bge  $t6, $s1, redraw_next_row

    # indec = row * grid_w + col
    mul  $t7, $t5, $s1
    add  $t7, $t7, $t6
    sll  $t8, $t7, 2
    addu $t9, $t0, $t8       # t9 = game_grid[row][col]
    lw   $s7, 0($t9)         # s7 = color

    beq  $s7, $zero, redraw_use_black
    move $a0, $s7            # redraw the color
    j    redraw_have_color

redraw_use_black:
    lw   $a0, black

redraw_have_color:
    # screen_x = col + field_x0
    # screen_y = row + field_y0
    move $t7, $t6
    add  $t7, $t7, $t3       # screen_x
    move $t8, $t5
    add  $t8, $t8, $t4       # screen_y

    sll  $t7, $t7, 2         # x * 4
    sll  $t8, $t8, 7         # y * 128

    add  $t9, $s0, $t7
    add  $t9, $t9, $t8

    sw   $a0, 0($t9)

    addi $t6, $t6, 1
    j    redraw_col_loop

redraw_next_row:
    addi $t5, $t5, 1
    j    redraw_row_loop

redraw_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


#################################################################################
# check_game_over
# if no space to generate new column, game over
#################################################################################
check_game_over:
    la   $t0, game_grid     # t0 = game_grid base address
    lw   $t1, grid_w        # t1 = grid_w = 13

    li   $t3, 6             # generate at col x = 6
    li   $t4, 0             # i = row, for i = 0..2

check_game_loop:
    beq  $t4, 3, checkgame_safe    # if checking all cells

    # index = row * grid_w + col
    mul  $t5, $t4, $t1      # row * grid_w
    add  $t5, $t5, $t3      # + col
    sll  $t5, $t5, 2        # * 4 bytes
    addu $t6, $t0, $t5      # t6 = game_grid[row][col]

    lw   $t7, 0($t6)        # t7 = game_grid[row][col]
    bne  $t7, $zero, game_over   # if there is a cell is not free, game over

    addi $t4, $t4, 1
    j    check_game_loop

checkgame_safe:
    jr   $ra               # continue
    
#################################################################################
# general_gravity
#################################################################################
general_gravity:
    la   $t0, game_started
    lw   $t1, 0($t0)                         # $t1 = game_started(0,1,2,3)
    beq  $t1, $zero, general_gravity_return  # game_started == 0: no gravity(don't move)
    li   $2, 2
    li   $3, 3

    #otherwise: start
    beq  $t1, $zero, general_gravity_setting1
    beq  $t1, $2, general_gravity_setting2
    beq  $t1, $3, general_gravity_setting3
    
general_gravity_setting1:
    la  $t0, game_started
    li  $t1, 1
    sw  $t1, 0($t0)
    
    la   $t1, gravity_timer # t1 = the address of gravity_timer
    lw   $t2, 0($t1)        # t2 = gravity_timer's value
    addi $t2, $t2, 1        # gravity_timer++
    sw   $t2, 0($t1)        # update gravity_timer++ into gravity_timer

    # setting the frequency of frames to update
    li   $t3, 25

    # no enough frames: continue
    blt  $t2, $t3, general_gravity_return

    # update the counter 
    sw   $zero, 0($t1) 

    # column move down
    j    move_down   
general_gravity_setting2:
    la  $t0, game_started
    li  $t1, 2
    sw  $t1, 0($t0)
    
    la   $t1, gravity_timer # t1 = the address of gravity_timer
    lw   $t2, 0($t1)        # t2 = gravity_timer's value
    addi $t2, $t2, 1        # gravity_timer++
    sw   $t2, 0($t1)        # update gravity_timer++ into gravity_timer

    # setting the frequency of frames to update
    li   $t3, 13

    # no enough frames: continue
    blt  $t2, $t3, general_gravity_return

    # update the counter 
    sw   $zero, 0($t1) 

    # column move down
    j    move_down   
general_gravity_setting3:
    la  $t0, game_started
    li  $t1, 3
    sw  $t1, 0($t0)
    
    la   $t1, gravity_timer # t1 = the address of gravity_timer
    lw   $t2, 0($t1)        # t2 = gravity_timer's value
    addi $t2, $t2, 1        # gravity_timer++
    sw   $t2, 0($t1)        # update gravity_timer++ into gravity_timer

    # setting the frequency of frames to update
    li   $t3, 5

    # no enough frames: continue
    blt  $t2, $t3, general_gravity_return

    # update the counter 
    sw   $zero, 0($t1) 

    # column move down
    j    move_down   
general_gravity_return:
    jr   $ra

#################################################################################
# Collision Detection   a0 = x, a1 = y
#################################################################################
read_grid:
    la  $t0, game_grid
    mul $t1, $a1, $s1        # y * grid_w
    add $t1, $t1, $a0        # y * grid_w + x
    sll $t1, $t1, 2
    add $t0, $t0, $t1
    lw  $v0, 0($t0)
    jr  $ra

#################################################################################
# UPDATE
# display_pause_message 
#################################################################################
# for i in 32:
  # for i in 32:
    # if message_grid[col][row] is not 0: display white
    # otherwise continue
display_pause_message:
    move $t0, $s0         # t0 = VRAM base
    la $t1, message_grid     # pointer to grid
    
    li $t3, 0          # t2 = row

dpm_row_loop:
    bge $t3, 32, dpm_done
    
    li $t4, 0 # t4 col
    
dpm_col_loop:
    bge  $t4, 32, dpm_next_row
    
    # index = row * grid_w + col
    mul  $t5, $t3, 32
    add  $t5, $t5, $t4
    sll  $t5, $t5, 2

    # message_grid[index]
    addu $t5, $t1, $t5       # message_grid[index]
    lw   $t6, 0($t5)
    beq  $t6, $zero, dpm_next_col  # next col if message_grid[i] = 0

    # otherwise
    # VRAM address
    # screen_x = col + field_x0
    # screen_y = row + field_y0
    move $t7, $t4
    move $t8, $t3

    sll  $t7, $t7, 2       # x * 4
    sll  $t8, $t8, 7       # y * 128

    add  $t9, $s0, $t7
    add  $t9, $t9, $t8    # t9 = VRAM address

    # load white
    lw   $t5, white
    sw   $t5, 0($t9)

dpm_next_col:
    addi $t4, $t4, 1
    j    dpm_col_loop

dpm_next_row:
    addi $t3, $t3, 1
    j    dpm_row_loop
 
dpm_done:
    jr   $ra
    
#################################################################################
# UPDATE
# hide_pause_message
# hide by refill black
#################################################################################
hide_pause_message:
    move $t0, $s0         # t0 = VRAM base
    la $t1, message_grid     # pointer to grid
    
    li $t3, 0          # t2 = row

hpm_row_loop:
    bge $t3, 32, hpm_done
    
    li $t4, 0 # t4 col
    
hpm_col_loop:
    bge  $t4, 32, hpm_next_row
    
    # index = row * grid_w + col
    mul  $t5, $t3, 32
    add  $t5, $t5, $t4
    sll  $t5, $t5, 2

    # message_grid[index]
    addu $t5, $t1, $t5       # message_grid[index]
    lw   $t6, 0($t5)
    beq  $t6, $zero, hpm_next_col  # next col if message_grid[i] = 0

    # otherwise
    # VRAM address
    # screen_x = col + field_x0
    # screen_y = row + field_y0
    move $t7, $t4
    move $t8, $t3

    sll  $t7, $t7, 2       # x * 4
    sll  $t8, $t8, 7       # y * 128

    add  $t9, $s0, $t7
    add  $t9, $t9, $t8    # t9 = VRAM address

    # load white
    lw   $t5, dark_black
    sw   $t5, 0($t9)

hpm_next_col:
    addi $t4, $t4, 1
    j    hpm_col_loop

hpm_next_row:
    addi $t3, $t3, 1
    j    hpm_row_loop
 
hpm_done:
    jr   $ra
    
    
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
	
	jal general_gravity

    # 4. Sleep ~60FPS
    li  $v0, 32 # call sleep syscall
    li  $a0, 17 # sleep 17 ms
    syscall
    
    #################################
    # test function: match number
    # ONLY UNCOMMENT WHEN TESTING
    # la   $t1, match_counter   # $t1 = match_counter address
    # lw   $a0, 0($t1)          # $a0 = match_counter value
    # li   $v0, 1               # syscall 1 = print integer
    # syscall                  
    # li   $v0, 11      # syscall 11 = print char
    # li   $a0, 10      # ASCII 10 = '\n'
    # syscall
    #################################
    
    # 5. Go back to Step 1
    j game_loop
#################################################################################
# Conversion:
# game_grid address = base + (row * grid_w + col) * 4
# VRAM address = base + (s4 + field_0) * 4 + (grid_y + field_y0) * 128
#################################################################################   
    