.data
	msg_prompt: .asciiz "Input an integer: "
	msg_recursive: .asciiz "\nRecursive Result: "
	msg_iterative: .asciiz "\nIterative Result: "
.text
	
	#prompt for int
	la $a0, msg_prompt
	li $v0, 4
	syscall
	
	#read int 
	li $v0, 5 #read int service
	syscall #$v0 contains the int
	
	move $s0, $v0 #save N
	
	#RECURSIVE:
	#msg
	la $a0, msg_recursive
	li $v0, 4
	syscall
	#call
	move $a0, $s0 #N is arg for RECURSIVE function
	jal RECURSIVE #pass N in $a0, returns answer to $v0
	move $a0, $v0 #move answer to arg for print service
	li $v0, 1 #print int service
	syscall
	
	#ITERATIVE:
	#msg
	la $a0, msg_iterative
	li $v0, 4
	syscall
	#call
	move $a0, $s0 #N is arg for ITERATIVE function
	jal ITERATIVE #pass N in $a0, returns answer to $v0
	move $a0, $v0 #move answer to arg for print service
	li $v0, 1 #print int service
	syscall
	
	li $v0, 10 #Terminate
	syscall
	
	
	
	
RECURSIVE: #a0 = N | return to $v0 | worry about $ra and $s0
	#prologue
	addi $sp, $sp, -12 #Push activation frame (with two spaces)
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	#Check for Base Cases
	beq $a0, 2, R_ONE #check for 2
	beq $a0, 1, R_ONE #check for 1
	blez $a0, R_ZERO #check for 0
	
	#r(n-1)
		addi $a0, $a0, -1 # remove 1 for r(N - 1)
		move $s0, $a0 #copy N-1 to be saved across the function call
		jal RECURSIVE #else (>2) ... call r(n-1)
		move $s1, $v0 #save the return of r(N-1)

	#r(n-2)
		addi $s0, $s0, -1 # remove another 1 for r(n-2)
		move $a0, $s0 # move into arg position
		jal RECURSIVE #call r(n-2)

	#now v0 holds a value -- so does s1
		add $v0, $v0, $s1 #returns r(n-2)+r(n-1)
		j R_EPILOGUE

	R_ONE:
		li $v0, 1 #return 1
		j R_EPILOGUE
	R_ZERO:
		li $v0, 0 #return 0
	R_EPILOGUE:
	#epilogue
	lw $s1, 0($sp)
	lw $s0, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12 #pop activation frame
	
	jr $ra
	
ITERATIVE: #$a0 = N  | return to $v0
	#t0 = count
	#t1 = fib 1, initially
	#t2 = fib 2, initially
	#t3 = odd boolean
	li $t0, 2 #initilize count to 2 (we have fib 2)
	li $t1, 1 #init fib1 
	li $t2, 1 #init fib2
	li $t3, 1 #initilize bool to true (we start with fib 3 [odd])
	
	ble $a0, 2, I_TWOONEZERO #if N <= 2
		# N here is greather than two
	I_LOOP:	beqz $t3, I_EVEN
			#current fib we are computing is odd
			addi $t3, $t3, -1 #convert odd to FALSE
			add $t1, $t1, $t2 #add and store into odd fib
			j I_SKIPEVEN
		I_EVEN: #current fib we are computing is even
			addi $t3, $t3, 1 #convert odd to TRUE
			add $t2, $t1, $t2 #store into even fib
		I_SKIPEVEN:
		#add one to count
		addi $t0, $t0, 1 #count++
		bne $t0, $a0, I_LOOP #if the count does not equal N, loop again!
		#finished looping:
		bgt $t1, $t2, I_TONEBIGGER
			#$t2 has the larger value
			move $v0, $t2 #return the larger value (t2)
			j I_RETURN
		I_TONEBIGGER: #$t1 has the larger value
			move $v0, $t1 #return larger value (t1)
		
		I_RETURN: #return!
			jr $ra
	
	I_TWOONEZERO: #handle each base case 2, 1, or 0
		beqz $a0, I_ZERO
			li $v0, 1
			jr $ra
		I_ZERO:
			li $v0, 0
			jr $ra