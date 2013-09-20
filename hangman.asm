.data
	word_array: 	.word		word0, word1, word2, word3, word4, word5, word6, word7, word8, word9
	
	word0: 		.asciiz  	"syscall"
	word1:		.asciiz		"binary"
	word2: 		.asciiz		"denormal"
	word3: 		.asciiz		"iteration"
	word4: 		.asciiz		"recursion"
	word5:		.asciiz		"immediate"
	word6:		.asciiz		"function"
	word7:		.asciiz		"instruction"
	word8:		.asciiz		"procedural"
	word9:		.asciiz		"algorithm"
	
	msg_toguess:	.asciiz		"\nThe word to guess is: "
	str_blank: 	.asciiz		"_ "
	str_space:	.asciiz		" "
	
	msg_prompt:	.asciiz		"\nEnter guess "
	colon:		.asciiz		" : "
	
	msg_winner: 	.asciiz		"\nCorrect! You WIN!"
	msg_loser: 	.asciiz		"\nSorry! You Lose!\nThe word was: "
	msg_again:	.asciiz		"\nPlay again? (Y or N)"
	
	miss_array:	.word 		miss1, miss2, miss3, miss4, miss5, miss6
	
	miss1:		.asciiz 	"\n---.\n|  o\n|\n|"
	miss2:		.asciiz 	"\n---.\n|  o\n|  |\n|"
	miss3:		.asciiz 	"\n---.\n|  o\n| /|\n|"
	miss4:		.asciiz 	"\n---.\n|  o\n| /|\\\n|"
	miss5:		.asciiz 	"\n---.\n|  o\n| /|\\\n| /"
	miss6:		.asciiz 	"\n---.\n|  o\n| /|\\\n| / \\"
	

	
	
	#	$s0 = the number of guesses
	#	$s1 = the number of misses
	#	$s2 = current word address
	#	$s3 = blank count
	#	$s4 = user char guess
	#	$s5 = consider_char boolean  #0=not found -- MISS #1=found and revealed!
	
.text
BEGIN:
#initialize certain registers back to zero if play 2x
xor $s0, $s0, $s0
xor $s1, $s1, $s1
xor $s2, $s2, $s2 #initilize the chosen-word-address field to 0
xor $s3, $s3, $s3
xor $s4, $s4, $s4 #initialize the user-char-guess field to 0
xor $s5, $s5, $s5
#empty other used reg
xor $v0, $v0, $v0
xor $a0, $a0, $a0
xor $a1, $a1, $a1
xor $t2, $t2, $t2


j MAIN #jump to very bottom of source

	
CHOOSE_WORD: 
#Prologue:
addi $sp, $sp, -4 #create space for RA
sw $ra, 0($sp)	#store RA from main

	#Call for a random number
	li $a0, 10 #upperbound of return
	jal RAND_MACHINE# $a0=upperBound| @returns:$v0=randNumber
	
	#Note: $v0 has the INDEX
	
	#multiply by four to get a multiplier for the memory location
	mul $v0, $v0, 4 #will give us memory offset (multiple of four)
	lw $s2, word_array($v0) #loads address [0x10010000+(the rand num * 4)] into s2
		
#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

BLANKS: #Note: consider_char and blanks is the same function (with different names)
CONSIDER_CHAR: 
#Prologue:
addi $sp, $sp, -4 #create space for RA
sw $ra, 0($sp)	#store RA from main

	xor $s5, $s5, $s5 #our found boolean -- initialize to 0
	xor $s3, $s3, $s3 #s3 will be our blank count -- initialize to 0 
	move $t2, $s2  #moves word address into temp
	
	#print message:
	la $a0, msg_toguess #"The word to guess is: "
	li $v0, 4 #print string service
	syscall
	
	#read char at address, if null: break
	blanks_LOOP: 		lb $t0, 0($t2) #load a char from the word 
				#one char from word is in $t0
				beq $t0, 0, blanks_END_LOOP #if null, break out of loop
				ble $t0, 90, blanks_reveal #if word-char is already a CAPITAL, then print it!
					beq $t0, $s4, blanks_newreveal #else if the word-char equals the user-char-guess
						addi $s3, $s3, 1 #increment our blank count
						la $a0, str_blank #"_ "
						xor $s5, $s5, 0 #boolean (not found
						j blanks_finally #jump over the reveal
				
			blanks_newreveal:	li $s5, 1 #boolean (found
						addi $t0, $t0, -32 #update bytecode to CAPITAL
						sb $t0, 0($t2)#update char in word to a Capital				
			blanks_reveal:		move $a0, $t0 #moves char into argument field
						li $v0, 11 #print char service
						syscall
						la $a0, str_space #" "  (load a space into memory to be printed in finally case)
			blanks_finally:	li $v0, 4 #print string service
					syscall #prints either "_ " or " " 
					addi $t2, $t2, 1 #temp-word address++
					j blanks_LOOP #loop back!
					
	blanks_END_LOOP: 
	jal CHECK_WIN 
	
#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

WORD_RESET: #come here at the very end if player chooses to play again
#Prologue:
addi $sp, $sp, -4 #create space for RA
sw $ra, 0($sp)	#store RA from main

	word_LOOP: 	lb $t0, 0($s2) #load a char from the word 
			beq $t0, 0, word_END_LOOP #if null, break out of loop
				addi $t0, $t0, 32 #update bytecode to LowerCase
				sb $t0, 0($s2)#update char in word to a lower	
				addi $s2, $s2, 1 #addy++ (get next char in word)
				j word_LOOP #loop back!	
	word_END_LOOP: #do nothing

#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

CHECK_WIN:
#Prologue:
addi $sp, $sp, -4 #create space for RA
sw $ra, 0($sp)	#store RA from main
	bne $s3, $zero, win_not
	 # break outta the main loop!
	
	j win_win 
win_not: #just exit the function if no win
	
#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

ADD_MISS:
#Prologue:
addi $sp, $sp, -4
sw $ra, 0($sp)
	
	mul $t0, $s1, 4 #multiply the number of misses by four for the missarray effective address
	lw $a0, miss_array($t0) #draw the appropriate picture
	li $v0, 4 #print string service
	syscall
	
	addi $s1, $s1, 1 #add after so we can have  a 0
	
	bne $s1, 6, miss_continue
		j LOSE_LOSE
	miss_continue: #dont throw losing flag
	
#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

READ_CHAR:
#Prologue:
addi $sp, $sp, -4
sw $ra, 0($sp)

	### >>Prompt user for a guess:
	la $a0, msg_prompt
	li $v0, 4 #print string service
	syscall
	
	### >>Print number of guesses
	addi $s0, $s0, 1 #increment GuessNumber
	move $a0, $s0 #move number of guesses to be printed
	li $v0, 1 #print int service
	syscall
	move $s0, $a0 #move back
	
	### >>Print colon
	la $a0, colon
	li $v0, 4 #print string service
	syscall
	
	### <<Read user guess (single char):
	li $v0, 12 #read char service
	syscall
	
	#$v0 has the user char
	move $s4, $v0
	
	#s4 has user char
	
	#check if it is a lowercase
	bgt $s4, 90, readchar_else #90 is Z, do nothing if userchar is a lowercase letter
		addi $s4, $s4, 32 #add 32 to char to make it a lower!
	readchar_else: #else, do nothing!

#Epilogue:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
	
RAND_MACHINE: #		Accepts: $a0=upperBound, 	Returns: $v0=randNumber   (in range 1-$a0)
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



MAIN:
	jal CHOOSE_WORD #@returns: $s2 contains @ddress of chosen word, so does current_word
	jal BLANKS #outputs blanks
	main_loop:		
			jal READ_CHAR #saves user char guess to $s4 (as lower)
			jal CONSIDER_CHAR #runs thru the game logic
			bne $s5, $zero, main_charfound
				jal ADD_MISS
			main_charfound: #dont need to update misses
#### TODO TODO TODO -- CHECK WIN OR LOSE DURING THIS LOOP!
			j main_loop
	win_win: #we break out here if we win!
		la $a0, msg_winner
		li $v0, 4 #"print you win
		syscall 
		j play_again
	LOSE_LOSE: #we break here if we lose!
		la $a0, msg_loser
		li $v0, 4
		syscall
		la $a0, ($s2)
		li $v0, 4 #"print you lose
		syscall 
	play_again:
		la $a0, msg_again # "play again?"
		li $v0, 4
		syscall
	play_read:	
		li $v0, 12 #read char (Y or N)
		syscall
		bgt $v0, 90, play_getUpper #get upper if it is lower
	play_checkY:	bne $v0, 89, play_checkN		#check for y or n  /// end game if not Y
				jal WORD_RESET #will execute if Y
				j BEGIN
	
	play_checkN: beq $v0, 78, ENDGAME #if equals N, end the game
				j play_again	#otherwise go back to play prompt
	ENDGAME:li $v0, 10 #terminate!
		syscall
	play_getUpper: addi $v0, $v0, -32 #convert to upper
			j play_checkY
	
