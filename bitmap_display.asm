##############################################################################
# Example: Displaying Pixels
#
# This file demonstrates how to draw pixels with different colours to the
# bitmap display.
##############################################################################

######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################
    .data
ADDR_DSPL:
    .word 0x10008000

    .text
	.globl main

main:
    li $t1, 0xff0000        # $t1 = red
    li $t2, 0x00ff00        # $t2 = green
    li $t3, 0x0000ff        # $t3 = blue

    lw $t0, ADDR_DSPL       # $t0 = base address for display
    sw $t1, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $t2, 4($t0)          # paint the second unit on the first row green
    sw $t3, 132($t0)        # paint the first unit on the second row blue
exit:
    li $v0, 10              # terminate the program gracefully
    syscall

add $t4, $t1, $t2 # make yellow out of red and green.
sw $t4, 8( $t0 ) # paint the next unit yellow
add $t5, $t1, $t3 # make magenta out of red and blue.
sw $t5, 12( $t0 ) # paint the next unit yellow
add $t6, $t2, $t3 # make cyan out of green and blue.
sw $t6, 256( $t0 ) # paint the next unit yellow
add $t7, $t1, $t6 # make white out of red and cyan.
sw $t7, 384( $t0 ) # paint the next unit yellow
# initialize registers $a0, $a1 and $a2
addi $a0, $zero, 11 # set X coordinate to 11
addi $a1, $zero, 3 # set Y coordinate to 3
addi $a2, $zero, 7 # set line length to 7
jal draw_line # call the line drawing code.
addi $a0, $zero, 2 # set X coordinate to 2
addi $a1, $zero, 18 # set Y coordinate to 18
addi $a2, $zero, 5 # set line length to 5
jal draw_line # call the line drawing code.
addi $a0, $zero, 19 # set X coordinate to 19
addi $a1, $zero, 16 # set Y coordinate to 16
addi $a2, $zero, 4 # set rectangle width to 4
addi $a3, $zero, 12 # set rectangle height to 12
jal draw_rect # call the rectangle drawing code.
li $v0, 10 # terminate the program gracefully
syscall
## The draw_line function
## - Draws a horizontal line from a given X and Y coordinate
#
# $a0 = the x coordinate of the line
# $a1 = the y coordinate of the line
# $a2 = the length of the line
# $t1 = the colour for this line (red)
# $t0 = the top left corner of the bitmap display
# $t2 = the starting location for the line.
# $t3 = location for line drawing to stop.
draw_line:
sll $a0, $a0, 2 # multiply the X coordinate by 4 to get the horizontal
offset
add $t2, $t0, $a0 # add this horizontal offset to $t0, store the result in
$t2
sll $a1, $a1, 7 # multiply the Y coordinate by 128 to get the vertical
offset
add $t2, $t2, $a1 # add this vertical offset to $t2
# Make a loop to draw a line.
sll $a2, $a2, 2 # calculate the difference between the starting value for
$t2 and the end value.
add $t3, $t2, $a2 # set stopping location for $t2
line_loop_start:
beq $t2, $t3, line_loop_end # check if $t0 has reached the final location of the
line
sw $t1, 0( $t2 ) # paint the current pixel red
addi $t2, $t2, 4 # move $t0 to the next pixel in the row.
j line_loop_start # jump to the start of the loop
line_loop_end:
jr $ra # return to the calling program.
## The draw_rect function
## - Draws a rectangle at a given X and Y coordinate
#
# $a0 = the x coordinate of the line
# $a1 = the y coordinate of the line
# $a2 = the width of the rectangle
# $a3 = the height of the rectangle
draw_rect:
# no registers to initialize (use $a3 as the loop variable)
rect_loop_start:
beq $a3, $zero, rect_loop_end # test if the stopping condition has been satisfied
addi $sp, $sp, -4 # move the stack pointer to an empty location
sw $ra, 0($sp) # push $ra onto the stack
addi $sp, $sp, -4 # move the stack pointer to an empty location
sw $a0, 0($sp) # push $a0 onto the stack
addi $sp, $sp, -4 # move the stack pointer to an empty location
sw $a1, 0($sp) # push $a1 onto the stack
addi $sp, $sp, -4 # move the stack pointer to an empty location
sw $a2, 0($sp) # push $a2 onto the stack
jal draw_line # call the draw_line function.
lw $a2, 0($sp) # pop $a2 from the stack
addi $sp, $sp, 4 # move the stack pointer to the top stack element
lw $a1, 0($sp) # pop $a1 from the stack
addi $sp, $sp, 4 # move the stack pointer to the top stack element
lw $a0, 0($sp) # pop $a0 from the stack
addi $sp, $sp, 4 # move the stack pointer to the top stack element
lw $ra, 0($sp) # pop $ra from the stack
addi $sp, $sp, 4 # move the stack pointer to the top stack element
addi $a1, $a1, 1 # move the Y coordinate down one row in the bitmap
addi $a3, $a3, -1 # decrement loop variable $a3 by 1
j rect_loop_start # jump to the top of the loop.
rect_loop_end:
jr $ra # return to the calling program.