.data
	fileName: .asciiz "calc_log.txt"
	
	input_prompt: .asciiz "Please insert your expression: \n"
	invalid_input: .asciiz "You inserted an invalid character in your expression \n"
	prompt_postfix: .asciiz "Postfix expression: "
	prompt_result: .asciiz "Result: "
	prompt_quit: .asciiz "Exitting the calculator..."
	stars: .asciiz "**************************************** \n"
	
	####
	debug: .asciiz "debug"
	####
	
	dot: .asciiz "."
	char0: .asciiz "0"
	newline: .asciiz "\n"
	negchar: .asciiz "-"
	
	# Constant
	converter: .word 1
	wordToConvert: .word 1
	
	const0: .double 0
	const1: .double 1
	const10: .double 10
	constNe1000000: .double -1000000
	character0: .double 48
	
	# Space for process
	stack: .space 800
	operator: .space 800
	postfix: .space 800
	int_stack: .space 800
	float_stack: .space 800
	input: .space 800
	
.text
start:
	# For log file
	li   $v0, 13       # system call for open file
  	la   $a0, fileName     # output file name
  	li   $a1, 1        # Open for writing (flags are 0: read, 1: write)
  	syscall            # open a file (file descriptor returned in $v0)
  	move $s2, $v0      # save the file descriptor 
main:
	#call input prompt
	li $v0, 4
	la $a0, stars
	syscall
	
	li $v0, 4
	la $a0, input_prompt
	syscall	
	
	# read input expression
	la $a0, input 
	addi $a1, $0, 100
	li $v0, 8 
	syscall
	
	# Write input to file log
	
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, stars($0)     
  	li   $a2, 42       
  	syscall           
	
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, input_prompt($0)     
  	li   $a2, 32       
  	syscall 
  	
  	li $t0,0	# t0 to track the string index
	li $t1,0	# t1 is the string[i]
  	
InputToLogFile:
	lb $t1, input($t0)
	
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, input($t0)     
  	li   $a2, 1       
  	syscall 
  	
	addi $t0,$t0,1
	
	beq $t1, '\n', EndITLF
	
	j InputToLogFile
EndITLF:
	
	 
  	
	# Status
	li $s7,0 		# Status 
				# 0 = initially receive nothing
				# 1 = receive number
				# 2 = receive operator
				# 3 = receive (
				# 4 = receive )
				# 5 = receive !
				# 6 = receive .s
				# 7 = receive M
	li $t0,0	# t0 to track the string index
	li $t1,0	# t1 is the string[i]
	li $t8,0	# t8 to track the postfix size
	li $t6,0	# t6 to track the operator stack index, t5 to help
	li $t5,0
	
	# CONSTANT
	l.d $f0,const0($0)           	# CONSTANTS	# f0 = 0	
	l.d $f2,const1($0)				# f2 = 1
	l.d $f4,const10($0)				# f4 = 10
	l.d $f6,constNe1000000($0)			# f6 = -1000000
	l.s $f31,converter($0)		# f31 is converter
	
	#Process the floatNums
	l.d $f20,const0($0)		# f20 to store number 
	l.d $f24,const1($0)		# f24 is divisor
					# f26 to store digits as double
					# f28 to store digits as float
					# f8 to load from postfix
	l.d $f22,character0($0)		# f22 is character 0
					# f16 is for operator[i]
	
String_Iterate:
	# t1 is string[i]
	lb $t1, input($t0)
	addi $t0,$t0,1  
	
	beq $t1, ' ',String_Iterate  # Skip a blank space ' '
	# End of string
	beq $t1, '\n', ExitString_Iterate
	
	# Quit program
	beq $t1, 'q',checkQuit
	
	# If not, convert t1 to double and store to f26
	# Convert t1 to float
	sw $t1, wordToConvert($0)
	l.s $f30, wordToConvert($0)
	div.s $f30,$f30,$f31
	cvt.d.s $f26,$f30      #f26 is double precision	
	
	
	# Read digits and fraction
	beq $t1, '0',readDigits
	beq $t1, '1',readDigits
	beq $t1, '2',readDigits
	beq $t1, '3',readDigits
	beq $t1, '4',readDigits
	beq $t1, '5',readDigits
	beq $t1, '6',readDigits
	beq $t1, '7',readDigits
	beq $t1, '8',readDigits
	beq $t1, '9',readDigits
	beq $t1, '.',readFractionPart
	
	# Read Operators
	
	beq $t1, '+',PlusMinus
	beq $t1, '-',PlusMinus
	beq $t1, '*',MulDiv
	beq $t1, '/',MulDiv
	beq $t1, '!',Factorization
	beq $t1, '^',Exponential
	
	beq $t1, '(', openBracket
	beq $t1, ')', closeBracket
	
	beq $t1,'M', receiveM
	
Invalid_input:
	li $v0, 4
	la $a0, newline
	syscall
	
	li $v0, 4
	la $a0, invalid_input
	syscall
	
	li $v0, 4
	la $a0, stars
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	# Write invalid output to file log
	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	la   $a1, newline    # address of buffer from which to write
  	li   $a2, 1      # length
  	syscall            # write to file
	
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, invalid_input   
  	li   $a2, 55      
  	syscall            
	
	li   $v0, 15       
  	move $a0, $s2       
  	la   $a1, stars   
  	li   $a2, 42      
  	syscall     
  	
  	li   $v0, 15       
  	move $a0, $s2       
  	la   $a1, newline   
  	li   $a2, 1      
  	syscall              
  	
  	# End write
	
	j main
	
checkQuit:
	lb $t1, input($t0)
	addi $t0,$t0,1
	bne $t1,'u',Invalid_input
	
	lb $t1, input($t0)
	addi $t0,$t0,1
	bne $t1,'i',Invalid_input
	
	lb $t1, input($t0)
	addi $t0,$t0,1
	bne $t1,'t',Invalid_input
	
	j QuitProgram
receiveM:
	beq $s7,1,Invalid_input
	beq $s7,4,Invalid_input
	beq $s7,5,Invalid_input
	beq $s7,6,Invalid_input
	beq $s7,7,Invalid_input
	li $s7,7
	add.d $f20,$f8,$f0
	
	j String_Iterate		
readDigits:
	beq $s7,4,Invalid_input
	beq $s7,5,Invalid_input
	
	sub.d $f26,$f26,$f22
	mul.d $f20,$f20,$f4
	add.d $f20,$f20,$f26
	
	li $s7,1
	j String_Iterate
	
readFractionPart:
	bne $s7,1,Invalid_input
	li $s7,6
	
	continueReadFr:
	lb $t1, input($t0)	#number after colon
  	
	beq $t1, '0',processRFP
	beq $t1, '1',processRFP
	beq $t1, '2',processRFP
	beq $t1, '3',processRFP
	beq $t1, '4',processRFP
	beq $t1, '5',processRFP
	beq $t1, '6',processRFP
	beq $t1, '7',processRFP
	beq $t1, '8',processRFP
	beq $t1, '9',processRFP
	beq $t1, '.', Invalid_input
	beq $t1, '(', Invalid_input
	
	j String_Iterate
	
	processRFP:
	li $s7,1
  	sub $t1,$t1,'0'
  	
	#convert t1 to double
	sw $t1, wordToConvert($0)
	l.s $f28, wordToConvert($0)
	div.s $f28,$f28,$f31
	cvt.d.s $f26,$f28
	
  	mul.d $f24,$f24,$f4
  	div.d $f26,$f26,$f24
  	add.d $f20,$f20,$f26
  	
  	addi $t0,$t0,1
  	j continueReadFr
	
PlusMinus:
	beq $s7,3,Invalid_input	# Wrong if before it is a operator or an open bracket
	beq $s7,2,Invalid_input
	beq $s7,0,Invalid_input	# Receive operator before any number		
	beq $s7,6,Invalid_input	# Wrong if before it is a .
	
	bne $s7,4, ggPluMi
	j wpPluMi
	ggPluMi:
		jal NumsToPostfix
	wpPluMi:
	li $s7,2
	
	SupportPlusMinus:
	beq $t6,0,inputOperator # If top of operator stack has nothing
	#Else Pop until the operator stack has nothing, because + - has the lowest priority :
	l.d $f16, operator($t5) # top of stack
	cvt.w.d $f28,$f16	
	mfc1.d $t7,$f28
	beq $t7,'(',inputOperator
	jal OpsToPostfix
	j SupportPlusMinus

MulDiv:
	beq $s7,3,Invalid_input	# Wrong if before it is a operator or an open bracket
	beq $s7,2,Invalid_input
	beq $s7,0,Invalid_input	# Receive operator before any number	
	beq $s7,6,Invalid_input	# Wrong if before it is a .
	
	bne $s7,4, ggMulDiv
	j wpMulDiv
	ggMulDiv:
		jal NumsToPostfix
	wpMulDiv:
	li $s7,2
	
	
	SupportMulDiv:
	beq $t6,0,inputOperator # If top of operator stack has nothing
	# Else pop until meet the lower priority operator
	l.d $f16, operator($t5) # top of stack
	cvt.w.d $f28,$f16	
	mfc1.d $t7,$f28
	beq $t7,'(',inputOperator	# If top is ( --> push into
	beq $t7,'+',inputOperator	# If top is a lower priority operator
	beq $t7,'-',inputOperator
	jal OpsToPostfix
	j SupportMulDiv
Factorization:
	beq $s7,3,Invalid_input	# Wrong if before it is a operator or an open bracket
	beq $s7,2,Invalid_input
	beq $s7,0,Invalid_input	# Receive operator before any number
	beq $s7,5,Invalid_input	# Wrong if before it is a ! or .
	beq $s7,6,Invalid_input
	
	c.lt.d $f20,$f0
	bc1t Invalid_input
	
	li $s7,5
	
	# Check if the previous number is integer ?
	cvt.w.d $f28,$f20	# f28 have the int value of f20
	cvt.d.w $f28,$f28
	c.eq.d $f28,$f20
	bc1t continueFac
	j Invalid_input
	
	continueFac:
	l.d $f28, const1($0)
	l.d $f14, const1($0)
	beginFacLoop:
	c.lt.d $f20,$f28
	bc1t endFacLoop
	mul.d $f14,$f14,$f28
	add.d $f28,$f28,$f2
	j beginFacLoop
	
	endFacLoop:
	#Store f20
	add.d $f20,$f0,$f14
	
	j String_Iterate
Exponential:
	beq $s7,3,Invalid_input	# Wrong if before it is a operator or an open bracket
	beq $s7,2,Invalid_input
	beq $s7,0,Invalid_input	# Receive operator before any number	
	beq $s7,6,Invalid_input	# Wrong if before it is a .
	
	# Check if previous is ) to avoid double NumsToPostFix
	bne $s7,4, ggExp
	j wpExp
	ggExp:
		jal NumsToPostfix
	wpExp:
	li $s7,2
	
	SupportExp:
	beq $t6,0,inputOperator # If top of operator stack has nothing
	# Else pop until meet the lower priority operator
	l.d $f16, operator($t5) # top of stack
	cvt.w.d $f28,$f16	
	mfc1.d $t7,$f28
	beq $t7,'(',inputOperator	# If top is ( --> push into
	beq $t7,'+',inputOperator	# If top is a lower priority operator
	beq $t7,'-',inputOperator
	beq $t7,'*',inputOperator	
	beq $t7,'/',inputOperator
	jal OpsToPostfix
	j SupportExp
	
inputOperator: 
	s.d  $f26,operator($t6)
	addi $t5,$t6,0
	addi $t6,$t6,8
	
	j String_Iterate
						
equalPriority: 		# Same operator priority
	jal OpsToPostfix
	j inputOperator
lowerPriority:		# Lower priority than top of operator stack, pop until op stack empty or meet lower priority
	jal OpsToPostfix

openBracket:
	beq $s7,1,Invalid_input		# Receive open bracket after a number or close bracket
	beq $s7,4,Invalid_input
	beq $s7,5,Invalid_input
	beq $s7,6,Invalid_input
	li $s7,3
	
	j inputOperator
closeBracket:
	beq $s7,0,Invalid_input
	beq $s7,2,Invalid_input
	beq $s7,3,Invalid_input
	beq $s7,6,Invalid_input
	
	bne $s7,4, ggCloseBracket
	j wpCloseBracket
	ggCloseBracket:
		jal NumsToPostfix
	wpCloseBracket:
	
	li $s7,4
	
	l.d $f16, operator($t5)
	cvt.w.d $f28,$f16
	mfc1 $t7,$f28
	
	beq $t7,'(',Invalid_input
	continueCloseBracket:
	beq $t6,0,Invalid_input		# Cant find a open bracket
	l.d $f16, operator($t5)
	cvt.w.d $f28,$f16
	mfc1 $t7,$f28
	beq $t7,'(',matchBracket
	jal OpsToPostfix	
	j continueCloseBracket
	
	matchBracket:
	addi $t5,$t5,-8
	addi $t6,$t6,-8
	j String_Iterate
	
	
NumsToPostfix:
	s.d  $f20,postfix($t8) 		# Store to postfix
	addi $t8,$t8,8
	
	l.d $f20, const0($0)		# Reset f20 to 0, f24 to 1
	l.d $f24, const1($0)			
	
	jr $ra
OpsToPostfix:
	sub.d $f16,$f6,$f16		# Encode operator, make there char value to become < -90.000
	s.d $f16,postfix($t8)
	addi $t8,$t8,8
	addi $t5,$t5,-8			# Decrease index of top operator stack
	addi $t6,$t6,-8
	jr $ra
ExitString_Iterate:  
	beq $s7,2,Invalid_input		# End with an operator or open bracket
	beq $s7,3,Invalid_input		
	beq $s7,6,Invalid_input		# End with .
	beq $s7,0,Invalid_input		# Input nothing
	
	# If end with a ), not need to NumsToPostFix
	bne $s7,4, ggExit
	j wpExit
	ggExit:
		jal NumsToPostfix
	wpExit:
	li $s7,0
	j popAll
	
popAll:
	beq $t6,0,finishScan		# When operator stack is empt
	l.d $f16,operator($t5)	
	jal OpsToPostfix
	j popAll
finishScan: 
	# Print postfix prompt
	li $v0, 4
	la $a0, prompt_postfix
	syscall
	li $t4,0	#Set postfix offset to 0
	
printPost:
	beq $t4,$t8,finishPrint	# If offset == current index
	l.d $f8,postfix($t4) 	# Load value of current Postfix to f8
	addi $t4,$t4,8
	
	c.lt.d $f8,$f6
	bc1t printOps		# If current postfix value is an operator
	#Else:
	li $v0,3
	add.d $f12,$f8,$f0
	syscall
	
	li $v0, 11
	li $a0, ' '
	syscall
	
	j printPost
	
	printOps:
	sub.d $f8,$f6,$f8		# Decode operator
	
	cvt.w.d $f8,$f8		# Convert to integer and store to t9
	mfc1.d  $t9, $f8
	
	li $v0, 11
	addi $a0, $t9,0
	syscall
	
	li $v0, 11
	li $a0, ' '
	syscall
	
	j printPost
finishPrint:
# Calculate
	li $t4,0	#Set postfix offset to 0
	li $t3,0 	#Stack offset
	
calPost:
	beq $t4,$t8,printResult
	l.d $f8,postfix($t4) 	# Load value of current Postfix to f8
	addi $t4,$t4,8
	
	c.lt.d $f8,$f6		# if current index is an operator -> pop 2 numbers to cal
	bc1t process
	#Else then $f8 is a number
	s.d $f8,stack($t3)
	addi $t3,$t3,8
	j calPost
	
	process:
	sub.d $f8,$f6,$f8		# Decode operator
	
	cvt.w.d $f8,$f8		# Convert to integer and store to t9
	mfc1.d $t9, $f8
	
	beq $t9,43,plus
	beq $t9,45,minus
	beq $t9,42,multiply
	beq $t9,47,divide
	beq $t9,94,exp
	plus:
		sub $t3,$t3,8		# Pop 2 numbers
		l.d $f12,stack($t3)	# B
		sub $t3,$t3,8
		l.d $f10,stack($t3)	# A
					
		add.d $f14,$f10,$f12	# plus
		
		s.d $f14,stack($t3)	# Push again to stack
		addi $t3,$t3,8
		
		j calPost
	minus:
		sub $t3,$t3,8		# Pop 2 numbers
		l.d $f12,stack($t3)	# B
		sub $t3,$t3,8
		l.d $f10,stack($t3)	# A
					
		sub.d $f14,$f10,$f12	# minus
		
		s.d $f14,stack($t3)	# Push again to stack
		addi $t3,$t3,8
		
		j calPost
	multiply:
		sub $t3,$t3,8		# Pop 2 numbers
		l.d $f12,stack($t3)	# B
		sub $t3,$t3,8
		l.d $f10,stack($t3)	# A
					
		mul.d $f14,$f10,$f12	# multiply
		
		s.d $f14,stack($t3)	# Push again to stack
		addi $t3,$t3,8
		
		j calPost
	divide:
		sub $t3,$t3,8		# Pop 2 numbers
		l.d $f12,stack($t3)	# B
		sub $t3,$t3,8
		l.d $f10,stack($t3)	# A
					
		div.d $f14,$f10,$f12	# div
		
		s.d $f14,stack($t3)	# Push again to stack
		addi $t3,$t3,8
		
		j calPost
		
	exp:
		sub $t3,$t3,8		# Pop 2 numbers
		l.d $f12,stack($t3)	# B
		
		# Check if B is a integer
		cvt.w.d $f10,$f12	# f10 have the int value of f12\
		mfc1.d $s5,$f10
		bltz $s5, Invalid_input
		
		cvt.d.w $f10,$f10
		c.eq.d $f10,$f12
	
		bc1t continueExp
		j Invalid_input
			
		continueExp:	
		sub $t3,$t3,8
		l.d $f10,stack($t3)	# A
		
		li $t2,0
		l.d $f14,const1($0)
		
		startExpLoop:
		addi $t2,$t2,1
		mul.d  $f14,$f14,$f10
		beq $t2,$s5,endExpLoop
		j startExpLoop
		
		endExpLoop:
		s.d $f14,stack($t3)	# Push again to stack
		addi $t3,$t3,8
		j calPost
printResult:
	li $v0, 4
	la $a0, newline
	syscall
	
	li $v0, 4
	la $a0, prompt_result
	syscall
	
	
	li $v0,3
	l.d $f12,stack($0)
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	li $v0, 4
	la $a0, stars
	syscall
	
	
	li $v0, 4
	la $a0, newline
	syscall
	
	l.d $f8,stack($0)	# For M
	
	# Output result in log file
	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	la   $a1, newline  # address of buffer from which to write
  	li   $a2, 1        # hardcoded buffer length
  	syscall            # write to file
  	
  	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, prompt_result  
  	li   $a2, 8       
  	syscall
  	
	c.lt.d $f8,$f0
	bc1t negaNums
	
	posiNums:
  	mov.d $f0,$f8
  	j continueOutputtoFile
  	
	negaNums:
	# Output the - sign first
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, negchar  
  	li   $a2, 1       
  	syscall
  	
  	# convert to positive
  	abs.d $f0,$f8
  	
	continueOutputtoFile:
	cvt.w.d $f2,$f0
  	mfc1 $t0,$f2
  	cvt.d.w $f2,$f2
  	li $t9,10
  	
  	li $t3,0
  	beq $t0,0,exitIntHandle
	
  	intLoop:
  	beq $t0,0, printInt
  	div $t0,$t9
  	mflo $t0
  	mfhi $t1
  	addi $t1,$t1,'0'
  	sb $t1,int_stack($t3)
  	addi $t3,$t3,1
  	j intLoop
  	
  	printInt:
  	beq $t3,0,FloatHandle
  	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	addi $t3,$t3,-1
  	la   $a1, int_stack($t3)   # address of buffer from which to write
  	li   $a2, 1       # hardcoded buffer length
  	syscall            # write to file
  	j printInt
  	
  	exitIntHandle:
  	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	la   $a1, char0($0)   # address of buffer from which to write
  	li   $a2, 1        # hardcoded buffer length
  	syscall            # write to file
  	
  	FloatHandle:
  	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	la   $a1, dot      # address of buffer from which to write
  	li   $a2, 1        # hardcoded buffer length
  	syscall            # write to file
  	
  	sub.d $f0,$f0,$f2
	li $t3,0
	li $t4,0
	l.d $f4,const0($0)
	l.d $f6,const10($0)
	
	c.eq.d $f0,$f4
	bc1t exitFloatHandle
	floatLoop:
	beq $t3,16,printFloat
	c.eq.d $f0,$f4
	bc1t printFloat
	mul.d $f0,$f0,$f6
	
	cvt.w.d $f2,$f0
	mfc1 $t9, $f2
	addi $t9,$t9,'0'
	sb $t9,float_stack($t3)
	cvt.d.w $f2,$f2
	sub.d $f0,$f0,$f2
	addi $t3,$t3,1
	j floatLoop
	
	printFloat:
	beq $t4,$t3,Quit
	li   $v0, 15       
  	move $a0, $s2     
  	la   $a1, float_stack($t4)  
  	addi $t4,$t4,1 
  	li   $a2, 1       
  	syscall            
	
	j printFloat
  	exitFloatHandle:
  	li   $v0, 15       # system call for write to file
  	move $a0, $s2      # file descriptor 
  	la   $a1, char0($0)   # address of buffer from which to write
  	li   $a2, 1       # hardcoded buffer length
  	syscall            # write to file
  	
	Quit:
	
	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, newline  
  	li   $a2, 1        
  	syscall	
  	
  	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, stars    
  	li   $a2, 42       
  	syscall
  	
  	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, newline  
  	li   $a2, 1        
  	syscall
	
	j main	

QuitProgram:
  	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, newline    
  	li   $a2, 1       
  	syscall
  	
  	li   $v0, 15       
  	move $a0, $s2      
  	la   $a1, prompt_quit($0)     
  	li   $a2, 26       
  	syscall 
  	
	li $v0, 4
	la $a0, prompt_quit
	syscall
