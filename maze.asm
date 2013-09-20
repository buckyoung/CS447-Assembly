.data 

	maze: .word 	1,1,1,1,1,1,1,1,
			3,0,0,0,0,0,0,1,
			1,1,1,1,1,1,0,1,
			1,2,1,0,0,0,0,1,
			1,0,1,0,1,0,1,1,
			1,0,1,1,1,0,1,1,
			1,0,0,0,0,0,1,1,
			1,1,1,1,1,1,1,1
			
.text

#	s0 = hero x
#	s1 = hero y

	main:	
		jal draw_maze #draw the maze
		li $s0, 0 #initialize x for our hero 	
		li $s1, 1 #initialize y for our hero
		
		polling_loop:
		#get keypress
			jal _getKeyPress #returns to vo:
			#	0	No key pressed
			# 	0x42	Middle button pressed
			# 	0xE0	Up arrow 
			# 	0xE1	Down arrow 
			# 	0xE2	Left arrow 
			# 	0xE3 Right arrow
			blt $v0, 0x45, no_input #check if player inputted a useful value 
		#update player (redraw)
				move $a0, $s0 #pass hero x
				move $a1, $s1 #pass hero y
				move $a2, $v0 #pass direction as arg
				jal update_player
				move $s0, $v0 #set new hero x
				move $s1, $v1 #set new hero y
		#check for win
			bne $s0, 4242, no_input #jump to noinput if win condition is not met
				j terminate#otherwise we win!
			no_input:
		#sleep
			li $v0, 32 #sleep service
			li $a0, 200 # for 200 milliseconds
			syscall
		#loop again
			j polling_loop
		#END polling_loop
	#END main function
		
	update_player: #a0:x , a1:y , a2:keypress  || returns v0:newX , v1:newY , [v0 = 4242 if WIN]
		#prologue:
		addi $sp, $sp, -24
		sw $ra, 0($sp)
		sw $s0, 4($sp)
		sw $s1, 8($sp)
		sw $s2, 12($sp)
		sw $s3, 16($sp)
		sw $s4, 20($sp)
		
		#save arguments
		move $s0, $a0 #x
		move $s1, $a1 #y
		move $s2, $a2 #keypress
			#s3   new x
			#s4   new y
		#determine if on left edge
		#determine new x and y:
		beq $s2, 0xE0, up_UP
		beq $s2, 0xE1, up_DOWN
		beq $s2, 0xE2, up_LEFT
		beq $s2, 0xE3, up_RIGHT
		
		up_UP:
			move $s3, $s0 # same x
			addi $s4, $s1, -1 #up one Y
			j up_get_state
		up_DOWN:
			move $s3, $s0 # same x
			addi $s4, $s1, 1 #down one Y
			j up_get_state
		up_LEFT:
			addi $s3, $s0, -1 #left one x
			bltz $s3, up_exit_without_move #check for leaving the entrance
			move $s4, $s1 # same y
			j up_get_state
		up_RIGHT:
			addi $s3, $s0, 1 #right one x
			move $s4, $s1 # same y
			j up_get_state
		
		#determine state of new x and y
		up_get_state:
			move $a0, $s3 #pass new x
			move $a1, $s4 #pass new y
			jal _getLED
			#v0 has LED state
		beqz $v0, up_move #if it is zero, then move
			#else check for 2
			bne $v0, 2, up_exit_without_move #space is full, lets check if it is the treasure
				j up_exit_WIN #if it is 2
		# good to go! lets move!
			up_move:
			#turn off current xy
			move $a0, $s0
			move $a1, $s1
			li $a2, 0
			jal _setLED
			#turn on new xy
			move $a0, $s3
			move $a1, $s4
			li $a2, 3
			jal _setLED
			
			move $v0, $s3 #return new x
			move $v1, $s4 #return new y
			j up_epilogue
			
		up_exit_without_move: 
			move $v0, $s0 #return old x
			move $v1, $s1 #return old y
			j up_epilogue
		
		up_exit_WIN:
			li $v0, 4242 #yep its the treasure... pass win condition in v0! (4242)
			#turn off current xy
			move $a0, $s0
			move $a1, $s1
			li $a2, 0
			jal _setLED
			
		up_epilogue:
		#epilogue:
		lw $s4, 20($sp)
		lw $s3, 16($sp)
		lw $s2, 12($sp)
		lw $s1, 8($sp)
		lw $s0, 4($sp)
		lw $ra, 0($sp)
		addi $sp, $sp, 24
		jr $ra
	#END update_player function		
		

	draw_maze:
		#prologue:
		addi $sp, $sp, -16
		sw $ra, 0($sp)
		sw $s0, 4($sp)
		sw $s1, 8($sp)
		sw $s2, 12($sp)
		
		#init counters
		li $s0, 0 #x counter
		li $s1, 0 #y counter
		la $s2, maze #save the memory address of maze-array
		
		#start printing
		dm_printing_loop:
		move $a0, $s0 #x
		move $a1, $s1 #y
		lw $a2, 0($s2) #color
		jal _setLED
		#determine loop behavior
		addi $s2, $s2, 4 #advance to next element in array
		beq $s0, 7, dm_reset_x #if x = 7 then reset it (8x8 maze, starts at 0)
			addi $s0, $s0, 1 #else, if x < 8 #increment x
			j dm_printing_loop #loop back
		dm_reset_x: 
		beq $s1, 7, dm_finished #if y = 7 then we are done 
			li $s0, 0 #else, lets reset x
			addi $s1, $s1, 1 #and increment y
			j dm_printing_loop
			
		dm_finished: #fall off
		
		#epilogue:
		lw $s2, 12($sp)
		lw $s1, 8($sp)
		lw $s0, 4($sp)
		lw $ra, 0($sp)
		addi $sp, $sp, 16
		jr $ra
	#END draw_maze function

#TERMINATE	
terminate:
li $v0, 10
syscall
#/TERMINATE
	
	# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=orange, 3=green
	#
	# warning:   x, y and color are assumed to be legal values (0-63,0-63,0-3)
	# arguments: $a0 is x, $a1 is y, $a2 is color 
	# trashes:   $t0-$t3
	# returns:   none
	#
_setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008	# base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	jr	$ra



	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  warning:   x and y are assumed to be legal values (0-63,0-63)
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2, 3)
	#
_getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra


	# int _getKeyPress(void)
	#	returns the key last pressed, unless there is none
	#
	# trashes: $t0-$t1
	# returns in $v0:
	#	0	No key pressed
	# 	0x42	Middle button pressed
	# 	0xE0	Up arrow 
	# 	0xE1	Down arrow 
	# 	0xE2	Left arrow 
	# 	0xE3 Right arrow
	#
_getKeyPress:
	la	$t1, 0xffff0000			# status register
	li	$v0, 0				# default to no key pressed
	lw	$t0, 0($t1)			# load the status
	beq	$t0, $zero, _keypress_return	# no key pressed, return
	lw	$v0, 4($t1)			# read the key pressed
_keypress_return:
	jr $ra
