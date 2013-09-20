#		PROJECT: 	step3: 1 random, 1-10
#		AUTHOR: 	Buck Young  -  -  bcy3
#		STATUS: 	COMPLETE : Functions as expected

# it will generate a random number between 1 and 10

.data
	#
	msg_welcome:	.asciiz "I have a secret number from 1-10, can you guess it?\n"
	msg_guess:	.asciiz "Guess: "
	#
	hint_higher:	.asciiz "Higher!\n"
	hint_lower:	.asciiz "Lower!\n"
	#
	msg_win:	.asciiz "Correct! You win!"

.text
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
# seeding done --- get the number:
##############################################################################

# generate 1 random integer in the range [1-10] from the 
# seeded generator (whose id is 1)

li	$a0, 1		# as said, this id is the same as random generator id
li	$a1, 10		# upper bound of the range not inclusive ..... range is [0-9]
li	$v0, 42		# random int in range, service
syscall

# $a0 now holds the random number
# lets add 1 to make the range [1-10]
addi	$a0, $a0, 1

# $a0 still has the random number, lets put it in s6
move $s6, $a0
##############################################################################
# got number -- Secret Number is in $s6
############################################################################## 

##############################################################################
# start program:
##############################################################################
	#	>I have a secret number ... can you guess it? [newline]
	la 	$a0, msg_welcome
	li 	$v0, 4 			#print string sevice, 4
	syscall
	
USERGUESS: #start of loop!
	#	>Guess: [wait for user input]
	la 	$a0, msg_guess
	li 	$v0, 4 			#print string sevice, 4
	syscall
	#	>User input [will be placed in $v0]
	li	$v0, 5			#read int service, 5
	syscall
	#	[move users input to a better position -- $s7!]
	move 	$s7, $v0
	###############################################################################################
	################### USERS GUESS IS STORED IN:					###############
	##########################################     	  $ s 7    		#######################
	#############    (and the computers secret number is in $s6				#######
	###############################################################################################
	
	#	[compare] 	$s6:Secret    	$s7:userGuess
	#if equal, jump to winner, else compare and loop back to guess again
	beq	$s6, $s7, WINNER
	#else:
	# figure if higher or lower
	blt 	$s6, $s7, LOWER
	
	#############################
	#####	default CASE    #####
#default, HIGHER:
	# Print "HIGHER!"
	la 	$a0, hint_higher
	li 	$v0, 4 			#print string sevice, 4
	syscall
	# loop back to get another guess
	j USERGUESS
	####	END default	#####
	#############################


	#############################
	#####	LOWER CASE	#####
LOWER:
	# Print "LOWER!"
	la 	$a0, hint_lower
	li 	$v0, 4 			#print string sevice, 4
	syscall
	# loop back to get another guess
	j USERGUESS
	####	END LOWER	#####
	#############################
	
	
	
	#############################
	#####	WINNER CASE	#####
WINNER:
	# Print "YOU WIN!"
	la 	$a0, msg_win
	li 	$v0, 4 			#print string sevice, 4
	syscall
	# Terminate the progam: EXIT:
	li $v0, 10
	syscall
	####	END WINNER 	#####
	#############################
	
