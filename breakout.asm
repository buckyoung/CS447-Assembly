#Buck Young Project 2
#bcy3 -- cs447
#STATUS: Incomplete!

	#   color: 0=off, 1=red, 2=orange, 3=green

#s0 = paddle x
#s1 = ball x
#s2 = ball y
#s3 = ball direction (1234)  --->        10 A 11
#           				  D o B
#s4 = score				 00 C 01
#s5 = lives

.text

	#game init
	jal brick_rows_init
	li $s4, 0 #init score
	li $s5, 3 #init lives
	
	#live init
	turn_init:
		jal initialize_ball_and_paddle #returns X position of ball
		move $s1, $v0 #ball init X position
		li $s2, 45 #ball init Y position
		li $s0, 26 #paddle init X position
		li $s3, 01 #ball init direction (down and right)
		
	#loop until B is pressed
	b_loop:
		move $a0, $s0 #pass paddle x as arg
		jal update_paddle #move paddle one step (also checks for B)
		move $s0, $v0 #save paddle x
		
		beq $v1, 4242, game_loop #start the game if 4242 is returned
		
		li $v0, 32 #sleep
		li $a0, 50 #for 50 milliseconds
		syscall

		j b_loop
	
	game_loop:
		
		move $a0, $s1 #pass ball x as arg
		move $a1, $s2 #pass ball y as arg
		move $a2, $s3 #pass ball direction as arg
		move $a3, $s4 #pass score
		jal update_ball #move ball one step     will return ballx= -1 if OUT 
		move $s1, $v0 #save ball x
		move $s2, $v1 #save ball y
		move $s3, $a0 #save ball direction
		move $s4, $a1 #save score
		
		beq $s3, -1, gl_lose_life
		
		move $a0, $s0 #pass paddle x as arg
		jal update_paddle #move paddle one step
		move $s0, $v0 #save paddle x
		
		#sleep
		li $v0, 32 #sleep
		li $a0, 60 #	? milliseconds ####################
		syscall
		j game_loop
		
	gl_lose_life:
		addi $s5, $s5, -1 #decrement lives
		#turn off ball
		move $a0, $s1
		move $a1, $s2
		li $a2, 0
		jal _setLED
		#turn off every LED in paddle row
		move $a0, $s0 #pass paddle x as arg
		jal clear_paddle
		
		bgtz $s5, turn_init
			move $a0, $s4 #move score to be printed
			li $v0, 1 #print int service
			syscall
			j terminate

update_bricks: #accepts: a0:x a1:y a2:color a3:score || returns v0, score
	#Prologue:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	
	li $s2, 0 #init s2
	move $s2, $a3
	
	beq $a2, 1, red
	beq $a2, 3, green
		j dbcp_exit #if not red or green, exit
		
	green: 
		addi $s2, $s2, 1 #add one to score 
	red: 
		addi $s2, $s2, 1 #add one to score
		#determine y values:
			andi $t1, $a1, 1
			#t1 will be 1 (odd) or 0 (even)
			beqz $t1, dbcp_t1ez
				#Y value is odd:
				addi $a1, $a1, -1 #start with one above
			dbcp_t1ez: #Y value is even:
				move $s1, $a1 #y val to destroy
		#determine x value
		dbcp_get_x:
			move $s0, $a0 #save x
			dbcp_get_x_loop:
			# find closest multiple of 4
			andi $t1, $s0, 3
			#t1 will be 000 or 100 (either is a multiple of 4
			
			beqz $t1, dbcp_turnblack
				#otherwise we are not at a multiple, lets subtract 1 and try again
				addi $s0, $s0, -1
				j dbcp_get_x_loop
		dbcp_turnblack:
		#now go thru and turn s0 - s0+3 at s1 and s2 black
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED # arguments: $a0 is x, $a1 is y, $a2 is color 
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
				#now add one to the y and subtract 3 from x
				addi $s0, $s0, -3
				addi $s1, $s1, 1
				#loop again
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED # arguments: $a0 is x, $a1 is y, $a2 is color 
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
				addi $s0, $s0, 1
				move $a0, $s0
				move $a1, $s1
				li $a2, 0
				jal _setLED
			
		
	dbcp_exit:
	move $v0, $s2
	
	#Epilogue:
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 16
	jr $ra

update_ball: #$a0 and $a1 is ball x and y . $a2: direction $a3: score|| returns v0 and v1, new ball x and y AND $a0: direction $a1: score
	#Prologue:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	move $s0, $a0 #save ball x		s0
	move $s1, $a1 #save ball y		s1
	move $s2, $a2 #save ball direction	s2
	move $s3, $a3 #save score
	
	#TODO: check for collisions (update ball direction)
		#update ball direction if needed
		#update brick if needed
		#can compare to paddle x if physics
		
	####COLLISION CHECK (direction update)############# 
	
	#first check for screen edges:
	bne $s0, 0, col_b1 #if ball x is at left-edge
		addi $s2, $s2, 1 #switch from left to right
		j col_edge_break
col_b1:	bne $s0, 63, col_b2 #if ball x is at right-edge
		addi $s2, $s2, -1 #switch from right to left
		j col_edge_break
col_b2:	bne $s1, 0, col_b3 #if ball y is at top-edge
		addi $s2, $s2, -10 #switch from up to down
		j col_edge_break
col_b3:	blt $s1, 60, col_edge_break #if ball y is near bottom
		LOSTLIFE: 	li $s2, -1
				j ball_exit
	col_edge_break:
	#next, check for objects:
	#check direction -- check up/down first
	bge $s2, 10, colcheck_up #if direction is 10 or 11
	blt $s2, 10, colcheck_down #if direction is 00 or 01
	
	colcheck_up:
		#check ball y-1 for collision
		move $a0, $s0 #move ball x to arg
		addi $a1, $s1, -1 #ball y-1 (1 above ball) to arg
		jal _getLED
		beqz $v0, col_branchLR   #if the LED is not blank then there is a collision there
			addi $s2, $s2, -10 #switch from up to down (-10)
			#try to remove brick
			move $a0, $s0
			addi $a1, $s1, -1
			move $a2, $v0
			move $a3, $s3
			jal update_bricks
			move $s3, $v0
		j col_branchLR #break
	colcheck_down:
		#check ball y+1 for collision
		move $a0, $s0 #move ball x to arg
		addi $a1, $s1, 1 #ball y+1 (1 below ball) to arg
#TODO: must check for bottom of screen ***and kill the ball***
		jal _getLED
		beqz $v0, col_branchLR   #if the LED is not blank then there is a collision there
			addi $s2, $s2, 10 #switch from down to up (+10)
			#try to remove brick
			move $a0, $s0
			addi $a1, $s1, 1
			move $a2, $v0
			move $a3, $s3
			jal update_bricks
			move $s3, $v0
		j col_branchLR #break
	col_branchLR: #check left/right
		andi $t0, $s2, 1 #t0 will be 0 if direction is left and 1 if direction is right
		beq $t0, 0, colcheck_left
		beq $t0, 1, colcheck_right
	colcheck_right:
		#check ball x+1 for collision
		move $a1, $s1 #move ball y to arg
		addi $a0, $s0, 1 #ball x+1 (1 to right of ball) to arg
#TODO: must check for RIGHT of screen
		jal _getLED
		beqz $v0, col_break   #if the LED is not blank then there is a collision there
			addi $s2, $s2, -1 #switch from right to left (-1)
			#try to remove brick
			move $a1, $s1
			addi $a0, $s0, 1
			move $a2, $v0
			move $a3, $s3
			jal update_bricks
			move $s3, $v0
		j col_break #break
	colcheck_left:
		#check ball x-1 for collision
		move $a1, $s1 #move ball y to arg
		addi $a0, $s0, -1 #ball x-1 (1 to left of ball) to arg
#TODO: must check for LEFT of screen
		jal _getLED
		beqz $v0, col_break   #if the LED is not blank then there is a collision there
			addi $s2, $s2, 1 #switch from left to right (+1)
			#try to remove brick
			move $a1, $s1
			addi $a0, $s0, -1
			move $a2, $v0
			move $a3, $s3
			jal update_bricks
			move $s3, $v0
		j col_break #break
	col_break:
	
	###### UPDATE BALL POSITION BASED ON DIRECTION (position update)#####
	#move based on direction
	#TURN x,y BLACK
	move $a0, $s0 #pass ball x
	move $a1, $s1 #pass ball y
	li $a2, 0 #black color
	jal _setLED
	#update --branch--
	beq $s2, 11, ub_upRight
	beq $s2, 01, ub_downRight
	beq $s2, 00, ub_downLeft
	beq $s2, 10, ub_upLeft
	ub_upRight:
		addi $s0, $s0, 1 #increment X (right)
		addi $s1, $s1, -1 #decrement Y (up)
		j ub_direction_continue #break
	ub_downRight:
		addi $s0, $s0, 1 #increment X (right)
		addi $s1, $s1, 1 #increment Y (down)
		j ub_direction_continue #break
	ub_downLeft:
		addi $s0, $s0, -1 #decrement X (left)
		addi $s1, $s1, 1 #increment Y (down)
		j ub_direction_continue #break
	ub_upLeft:
		addi $s0, $s0, -1 #decrement X (left)
		addi $s1, $s1, -1 #decrement Y (up)	
		j ub_direction_continue #break
	ub_direction_continue:
	#TURN x,y YELLOW
	move $a0, $s0 #pass ball x
	move $a1, $s1 #pass ball y
	li $a2, 2 #yellow color
	jal _setLED
	
	ball_exit:
	move $v0, $s0 #return ball x
	move $v1, $s1 #return ball y
	move $a0, $s2 #return ball direction
	move $a1, $s3 #return score
	
	#Epilogue:
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	jr $ra

update_paddle: #$a0, paddle x || $v0 (returns) new paddle x
	#Prologue:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
		move $s0, $a0 #move paddle x to saved location
		
		jal _getKeyPress
	#$v0 contains:
	#	0	No key pressed
	# 	0x42	Middle button pressed
	# 	0xE0	Up arrow 
	# 	0xE1	Down arrow 
	# 	0xE2	Left arrow 
	# 	0xE3 	Right arrow
	
		beq $v0, 0xE3, kpr_right #RIGHT
		beq $v0, 0xE2, kpr_left #LEFT
		beq $v0, 0x42, kpr_b	#0x42	Middle button pressed
			j kpr_exit #jump to exit if not right/left
		kpr_right:
			beq $s0, 54, kpr_exit #exit if all the way right
			#turn x to black:
				move $a0, $s0
				li $a1, 56 # known paddle y
				li $a2, 0 #black color
				jal _setLED
			addi $s0, $s0, 1 #increment x
			#turn x+9 to yellow
				addi $a0, $s0, 9 #add 9 to paddle x and save as arg
				li $a1, 56 # known paddle y
				li $a2, 2 #yellow color
				jal _setLED
			j kpr_exit #break
		kpr_left:
			beq $s0, 0, kpr_exit #exit if all the way left
			#turn x+9 to black
				addi $a0, $s0, 9 #add 9 to paddle x and save as arg
				li $a1, 56 # known paddle y
				li $a2, 0 #black color
				jal _setLED
			addi $s0, $s0, -1 #decrement x
			#turn x to yellow
				move $a0, $s0
				li $a1, 56 # known paddle y
				li $a2, 2 #yellow color
				jal _setLED
			j kpr_exit #break
		kpr_b:
			li $v1, 4242 #return to indicate gamestart
			j kpr_exit #break
		kpr_exit:
			move $v0, $s0 #return new paddle position
			
	#Epilogue:
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	

initialize_ball_and_paddle:
	#Prologue:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)	

	#PADDLE: 10 yellow LEDs, Centered, 8 rows from bottom
	li $a0, 26		#set X 
	li $a1, 56		#set Y
	li $a2, 2 		#set paddle color (orange)
	paddle_init_loop:
		jal _setLED
		addi $a0, $a0, 1 #increment X value
		ble $a0, 35, paddle_init_loop #will ensure that we get a paddle of legth 10
	#BALL: Use randmachine to get random x Coordinate (0-31)
	li $a0, 31		#upperbound for randmachine
	jal RAND_MACHINE
	move $a0, $v0		#set X coord (v0 has random number)
	move $s0, $v0 	#save this coord as return for this initilize function
	li $a1, 45		#set Y -- this is 12 rows above paddle
	li $a2, 2		#set ball color (orange)
	jal _setLED
	
	
	move $v0, $s0 #now, lets place our ball x-coord in the return slot
	#Epilogue:
	lw $s0, 4($sp)	
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	
clear_paddle:
	#Prologue:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	#PADDLE: 10 yellow LEDs, Centered, 8 rows from bottom
	#a0 already contains paddle X value	
	addi $s0, $a0, 10 #add 10 to get end condition
	li $a1, 56		#set Y
	li $a2, 0		#set paddle color (black)
	cp_loop:
		jal _setLED
		addi $a0, $a0, 1 #increment X value
		ble $a0, $s0, cp_loop #will ensure that we get a paddle of length 10
	
	#Epilogue:
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	
brick_rows_init: #Turn on all LEDs from a0 to 63, pass: a1 is Y cord/ a2 is color
	#Prologue:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		
	#BRICKS: 16x4 brick-block ten from top
	#set to red
	li $a2, 3 		#set green (red for rows 10, 11, 14, 15)
	#fill all rows in both reds
	li $a0, 0		#set X 
	li $a1, 10 		#set Y 10 from top
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 11
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 14
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 15
	jal brick_cols_init_loop
	#change to green
	li $a2, 1 		#red, rows 12, 13, 16, 17
	#fill all rows in both greens
	li $a0, 0
	li $a1, 12
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 13
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 16
	jal brick_cols_init_loop
	li $a0, 0
	li $a1, 17
	jal brick_cols_init_loop
	
	j brick_cols_exit
	
	brick_cols_init_loop: #INNER CLASS
			#Prologue:
			addi $sp, $sp, -4
			sw $ra, 0($sp)
		bcil_innerLoop:
		jal _setLED
		addi $a0, $a0, 1 #increment X
		ble $a0, 63, bcil_innerLoop
			#Epilogue:
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
		
	brick_cols_exit:
	#Epilogue:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
terminate:
	li $v0, 10		#terminate the program
	syscall
	
##################################		GIVEN		##################################

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

	
RAND_MACHINE: #		Accepts: $a0=upperBound, 	Returns: $v0=randNumber   (in range 0-$a0)
#Prologue:
addi $sp, $sp, -8
sw $ra, 0($sp)	
sw $a0, 4($sp) #Saves the upperbound-argument for later

##############################################################################
# seed the random number generator
##############################################################################
# get the time
li	$v0, 30		# get time in milliseconds (as a 64-bit value)
syscall

move	$t0, $a0	# save the lower 32-bits of time
# seed the random generator (just once)
li	$a0, 1		# random generator id (will be used later)
move 	$a1, $t0	# seed from time
li	$v0, 40		# seed random number generator syscall
syscall
##############################################################################
# seeding done # Generate random number, store in $a0
##############################################################################
li	$a0, 1		# as said, this id is the same as random generator id
lw 	$a1, 4($sp)	# loads the upperbound from the stack
li	$v0, 42		# random int in range, service
syscall
#Note: range is from 0 - (n-1)
# $a0 now holds the random number
move 	$v0, $a0 #move to return location

#Epilogue:
#note, the other value which we added has been used within the function
lw $ra, 0($sp)
addi $sp, $sp, 8
jr $ra
##################################	(END RAND MACHINE)	###############
