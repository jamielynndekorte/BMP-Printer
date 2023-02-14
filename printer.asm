.data 
	filePrompt:	.asciiz "Please enter a filename: "
	fileError: 	.asciiz "File not found"
	firstTwoStr:	.asciiz "The first two characters: "
	fileSizeStr:	.asciiz "\nThe size of the BMP file (bytes): "
	addressStrtStr:	.asciiz "\nThe starting address of image data: "
	widthStr:	.asciiz "\nImage width (pixels): "
	heightStr:	.asciiz "\nImage height (pixels): "
	colorPlanesStr:	.asciiz "\nThe number of color planes: "
	bPPStr:		.asciiz	"\nThe number of bits per pixel: "
	compMethodStr:	.asciiz	"\nThe compression method: "
	sizeDataStr:	.asciiz "\nThe size of raw bitmap data (bytes): "
	horzResStr:	.asciiz "\nThe horizontal resolution (pixels/meter): "
	vertResStr:	.asciiz "\nThe vertical resolution (pixels/meter): "
	numColorStr:	.asciiz "\nThe number of colors in the color palette: "
	numColorUStr:	.asciiz "\nThe number of important colors used: "
	colorStr:	.asciiz "\nThe color at index "
	bgrStr:		.asciiz " (B G R): "
	
	
	fileName:	.space	50	# allocates space for filename
	firstTwo:	.space	2	# allocates space 
	.align 2			# aligns memory
	header:		.space	12	# allocates space for the header
	dibHeaderSize:	.space	4	# allocates space for the DIB header
	
.text
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, filePrompt	# Load address of string to print
	syscall			# Print "Please enter a filename: "
	addi $v0, $zero, 8 	# Syscall 8: Read string
	la $a0, fileName 	# Set the buffer
	addi $a1, $zero, 50 	# Set the maximum to 50 (size of the buffer)
	syscall			# Reads file name
	la $s0, fileName	# Loads address of fileName in $s0
	
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Open/Verify File~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

removeNewLineLoop:
	lb $t0, 0($s0)		# read character
	subiu $t0, $t0, 0x0A	# subtract newline
	addi $s0, $s0, 1	# increment pointer
	bnez $t0, removeNewLineLoop
	addi $s0, $s0, -1
	sb $zero, 0($s0)	# overwrite newline with null
	
	addi $v0, $zero, 13	# Syscall 13: Open file
	la $a0, fileName	# $a0 is the address of the filename
	add $a1, $zero, $zero	# $a1 = 0
	add $a2, $zero, $zero	# $a2 = 0
	syscall			# Open file
	add $s0, $zero, $v0	# Copy the file descriptor to $s0
	slt $t0, $s0, $zero	# Check if file descriptor is less than 0
	beqz $t0, goodFile	# Close the program if the file does not exist
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, fileError	# Load address of string to print
	syscall			# Print "File not found"
	j terminateProgram	# End program

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Read Header~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			
goodFile:
	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	la $a1, firstTwo	# $a1 is the address of a buffer
	addi $a2, $zero, 2	# $a2 is the number of bytes to read
	syscall			# Read first two bytes of file
	la $s1, firstTwo	# Set $s1 to the address of firstTwo
	
	lb $t0, 0($s1)		# get B from firstTwo
	sll $t0, $t0, 8		# move into position
	lb $t1, 1($s1)		# get M from firstTwo
	or $t0, $t0, $t1	# put into one variable
	bne $t0, 0x424D, terminateProgram	# Check to see if firstTwo are the letters BM
			
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, firstTwoStr	# Load address of string to print
	syscall			# Print "The first two characters: "
	
	addi $v0, $zero, 11	# Syscall 11: Print character
	lb $a0, 0($s1)		# $a0 is the first byte of firstTwo
	syscall			# Print a character
	lb $a0, 1($s1)		# $a0 is the second byte of firstTwo
	syscall			# Print a character
	
	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	la $a1, header		# $a1 is the address of a buffer
	addi $a2, $zero, 12	# $a2 is the number of bytes to read
	syscall			# Reads the header
	la $s1, header		# Set $s1 to the address of header
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, fileSizeStr	# Load address of string to print
	syscall			# Print "\nThe size of the BMP file (bytes): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 0($s1)		# $a0 is the 4-byte integer of the file size
	syscall			# Print the file size
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, addressStrtStr	# Load address of string to print
	syscall			# Print "\nThe starting address of image data: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 8($s1)		# $a0 is the 4-byte integer of the starting address of image data
	syscall			# Print the starting address of image data

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Read DIB Header~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	la $a1, dibHeaderSize	# $a1 is the address of a buffer
	addi $a2, $zero, 4	# $a2 is the number of bytes to read
	syscall			# Reads the DIB header size
	
	la $s1, dibHeaderSize	# Set $s1 to the address of dibHeaderSize
	lw $t0, 0($s1)		# Load the DIB header size into $t0
	addi $t0, $t0, -4	# Subtract 4 bytes that have already been read
	
	addi $v0, $zero, 9	# Syscall 9: Sbrk (allocate heap memory)
	add $a0, $t0, $zero	# $a0 contains the number of bytes in the DIB header
	syscall
	addi $s1, $v0, 0	# Moves address of allocated memory into $s1
	
	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	add $a1, $s1, $zero	# $a1 is the address the buffer
	add $a2, $zero, $t0	# $a2 is the number of bytes to read
	syscall			# Reads the DIB header
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, widthStr	# Load address of string to print
	syscall			# Print "\nImage width (pixels): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 0($s1)		# Load the image width from DIB header into $a0
	add $s5, $zero, $a0	# Store width in $s5
	syscall			# Print the image width
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, heightStr	# Load address of string to print
	syscall			# Print "\nImage height (pixels): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 4($s1)		# Load the image height from DIB header into $a0
	add $s6, $zero, $a0	# Store height in $s6
	syscall			# Print the image height
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, colorPlanesStr	# Load address of string to print
	syscall			# Print "\nThe number of color planes: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lh $a0, 8($s1)		# Load the number of color planes from DIB header into $a0
	syscall			# Print the number of color planes
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, bPPStr		# Load address of string to print
	syscall			# Print "\nThe number of bits per pixel: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lh $a0, 10($s1)		# Load the number of bpp from DIB header into $a0
	syscall			# Print the number of bpp
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, compMethodStr	# Load address of string to print
	syscall			# Print "\nThe compression method: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 12($s1)		# Load the compression method from DIB header into $a0
	syscall			# Print the compression method
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, sizeDataStr	# Load address of string to print
	syscall			# Print "\nThe size of raw bitmap data (bytes): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 16($s1)		# Load the size of raw bitmap data from DIB header into $a0
	add $t3, $zero, $a0	# Store the size of raw bitmap data in $t3
	syscall			# Print the size of raw bitmap data

	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, horzResStr	# Load address of string to print
	syscall			# Print "\nThe horizontal resolution (pixels/meter): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 20($s1)		# Load the horizontal resolution from DIB header into $a0
	syscall			# Print the horizontal resolution

	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, vertResStr	# Load address of string to print
	syscall			# Print "\nThe vertical resolution (pixels/meter): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 24($s1)		# Load the vertical resolution from DIB header into $a0
	syscall			# Print the vertical resolution

	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, numColorStr	# Load address of string to print
	syscall			# Print "\nThe number of colors in the color palette: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 28($s1)		# Load the number of colors in the color palette from DIB header into $a0
	addi $t1, $a0, 0	# Store the number of colors in the color palette in $t1
	syscall			# Print the number of colors in the color palette
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, numColorUStr	# Load address of string to print
	syscall			# Print "\nThe number of important colors used: "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lw $a0, 32($s1)		# Load the number of important colors used from DIB header into $a0
	syscall			# Print the number of important colors used

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Read Color Palette~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	sll $t2, $t1, 2		# multiplies the number of colors in the palette by 4 to get the number of bytes to read and stores it in $t2
	
	addi $v0, $zero, 9	# Syscall 9: Sbrk (allocate heap memory)
	add $a0, $t2, $zero	# $a0 contains the number of bytes in the color palette
	syscall
	addi $s2, $v0, 0	# Moves address of allocated memory into $s2
	
	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	add $a1, $s2, $zero	# $a1 is the address the buffer
	add $a2, $zero, $t2	# $a2 is the number of bytes to read
	syscall			# Reads the color palette
	
	addi $t4, $zero, 0	# Initialize counter
	
colorPaletteLoop:	

	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, colorStr	# Load address of string to print
	syscall			# Print "\nThe color at index : "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	add $a0, $t4, $zero	# Load the index into $a0
	syscall			# Print index
	
	addi $v0, $zero, 4	# Syscall 4: Print string
	la $a0, bgrStr		# Load address of string to print
	syscall			# Print " (B G R): "
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lbu $a0, 0($s2)		# Load the index into $a0
	syscall			# Print index
	
	addi $v0, $zero, 11	# Syscall 11: Print Character
	addi $a0, $zero, 0x20	# Load the space character into $a0
	syscall			# Print a space
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lbu $a0, 1($s2)		# Load the index into $a0
	syscall			# Print index
	
	addi $v0, $zero, 11	# Syscall 11: Print Character
	addi $a0, $zero, 0x20	# Load the space character into $a0
	syscall			# Print a space
	
	addi $v0, $zero, 1	# Syscall 1: Print Integer
	lbu $a0, 2($s2)		# Load the index into $a0
	syscall			# Print index
	
	addi $s2, $s2, 4	# increment address
	addi $t4, $t4, 1	# increment counter
	bne $t1, $t4, colorPaletteLoop	# get next color if not the end

	beqz $a0, noInvert	# check if white is at index 1
	addi $s3, $zero, 1	# if white is at index 1, set $s3 to invert black and white colors
	j printBitMap		# go to print bitmap
noInvert:	
	add $s3, $zero, $zero	# set $s3 to zero
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Print Bitmap Data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printBitMap:
	addi $v0, $zero, 9	# Syscall 9: Sbrk (allocate heap memory)
	add $a0, $t3, $zero	# $a0 contains the number of bytes of raw bitmap data
	syscall
	addi $s4, $v0, 0	# Moves address of allocated memory into $s4
	
	addi $v0, $zero, 14	# Syscall 14: Read file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	add $a1, $s4, $zero	# $a1 is the address the buffer
	add $a2, $zero, $t3	# $a2 is the number of bytes to read
	syscall			# Reads the raw bitmap data
	
	add $a1, $zero, $s3	# put 0 or 1 into $a1 to/not to invert colors
	div  $t3, $s6		# divide size of bitmap data by image height to get bytes per row
	mflo $a2		# put number of bytes per row to $a2
	add $s7, $zero, $a2	# store number of bytes per row in $s7
	add $a0, $t3, $s4	# put address of bitmap data into $a0, plus the size of data to get to the end
	sub $a0, $a0, $a2	# move address of bitmap data to first row of the image (last row in the file) 
	add $s4, $a0, $zero	# store the address in $s4
	
	addi $sp, $sp, -4			# Store t registers needed
	sw $t3, 0($sp)				# "
	jal _printRow				# function to print a row
	lw $t3, 0($sp)				# restores t registers needed
	addi $sp, $sp, 4			# "
	
	sll $s7, $s7, 3				# multiply the number of bits per bits per row by 8
	sub $s4, $s4, $s7			# move address down 8 rows
	srl $s7, $s7, 3				# put number of bits per row back to normal
	
	srl $t0, $s6, 3				# divide the image height by 8 to get the height in bytes
	
	addi $t1, $zero, 1			# initialize a counter to count the number of rows printed
	
printLoop:
	add $a0, $s4, $zero			# put the new address into $a0
	add $a1, $s3, $zero			# put 0 or 1 into $a1 to/not to invert colors
	add $a2, $s7, $zero			# put the bytes per row into $a2
	
	addi $sp, $sp, -8			# Store t registers needed
	sw $t0, 0($sp)				# "
	sw $t1, 4($sp)				# "
	jal _printRow
	lw $t0, 0($sp)				# restores t registers needed
	lw $t1, 4($sp)				# "
	addi $sp, $sp, 8			# "
	
	addi $t1, $t1, 1			# increment counter
	beq $t0, $t1, printingComplete		# if all rows and columns have been printed, close file & terminate program
	
	sll $s7, $s7, 3				# multiply the number of bits per bits per row by 8
	sub $s4, $s4, $s7			# move address down 8 rows
	srl $s7, $s7, 3				# put number of bits per row back to normal
	
	j printLoop				# print the next row
	
printingComplete:
	addi $v0, $zero, 16	# Syscall 16: Close file
	add $a0, $zero, $s0	# $a0 is the file descriptor
	syscall			# Close file
	
terminateProgram:	
	addi $v0, $zero, 10	# Syscall 10: Exit
	syscall			# Terminate program
	
# _printRow
#   - loads and prints 8 columns of data
# Arguments:
#   - $a0: address of buffer containing bit map info
#   - $a1: whether or not to invert bits to correct for color
#   - $a2: how many bytes per row of pixel
# Return Value
#   - none	
	
_printRow:

	addi $sp, $sp, -32			# Store s registers used in function
	sw $s0, 0($sp)				# "
	sw $s1, 4($sp)				# "
	sw $s2, 8($sp)				# "
	sw $s3, 12($sp)				# "
	sw $s4, 16($sp)				# "
	sw $s5, 20($sp)				# "
	sw $s6, 24($sp)				# "
	sw $s7, 28($sp)				# "
	
	add $s0, $a0, $zero			# Put the address of the buffer in $s0
	add $s1, $a1, $zero			# Put whether or not to invert bits for color in $s1
	add $s2, $a2, $zero			# Put numbre of bytes per row of pixel in $s2
	add $s3, $zero, $zero			# Set $s3 to zero
	add $s4, $zero, $zero			# Set $s4 to zero
	add $s6, $zero, $s0			# Make a copy of the buffer address in $s6
	add $s7, $zero, $zero			# Set $s7 to zero
	
_printRowLoop:

	lb $t0, 0($s0)				# Put the first row in $t0
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t1, 0($s0)				# Put the second row in $t1
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t2, 0($s0)				# Put the third row in $t2
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t3, 0($s0)				# Put the fourth row in $t3
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t4, 0($s0)				# Put the fifth row in $t4
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t5, 0($s0)				# Put the sixth row in $t5
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t6, 0($s0)				# Put the seventh row in $t6
	sub $s0, $s0, $s2			# Increment address to next row
	lb $t7, 0($s0)				# Put the eigth row in $t7
	sub $s0, $s0, $s2			# Increment address to next row
	
	add $s3, $zero, $zero			# Reset $s3 to zero
	
_printSquareLoop:
	
	andi $s5, $t0, 0x0080			# Get MSB of $t0
	ori $t8, $s5, 0x00			# Put MSB in index 0 of $t8 to print 
	
	andi $s5, $t1, 0x0080			# Get MSB of $t1
	srl $s5, $s5, 1				# Put MSB in index 1 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t2, 0x0080			# Get MSB of $t2
	srl $s5, $s5, 2				# Put MSB in index 2 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t3, 0x0080			# Get MSB of $t3
	srl $s5, $s5, 3				# Put MSB in index 3 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t4, 0x0080			# Get MSB of $t4
	srl $s5, $s5, 4				# Put MSB in index 4 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t5, 0x0080			# Get MSB of $t5
	srl $s5, $s5, 5				# Put MSB in index 5 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t6, 0x0080			# Get MSB of $t6
	srl $s5, $s5, 6				# Put MSB in index 6 of $t8 to print 
	or $t8, $t8, $s5			# "
	
	andi $s5, $t7, 0x0080			# Get MSB of $t7
	srl $s5, $s5, 7				# Put MSB in index 7 of $t8 to print 
	or $t8, $t8, $s5			# "
	
_checkColor:
	beqz $s1, _printColumn			# If $s1 is 1, invert the colors
	xori $t8, $t8, 0xFF			# Inverts colors in $t8
_printColumn:
	addi $t9, $zero, 1 	# Set $t9 to 1 to print
wait: 	bne $t9, $zero, wait 	# Wait until $t9 is back to 0
	
	addi $s7, $s7, 1			# Add 1 to the pixel counter
	
	sll $t0, $t0, 1				# Shift rows over to next bit
	sll $t1, $t1, 1				# "
	sll $t2, $t2, 1				# "
	sll $t3, $t3, 1				# "
	sll $t4, $t4, 1				# "
	sll $t5, $t5, 1				# "
	sll $t6, $t6, 1				# "
	sll $t7, $t7, 1				# "
	
	addi $s3, $s3, 1			# Add 1 to column counter
	bne $s3, 8, _printSquareLoop		# After all 8 pixels were printed, go to next byte
	
	addi $s4, $s4, 1			# Add one to bytes counter
	beq $s4, $s2, _rowPrinted		# Check if the number of bytes printed is the number of bytes per row
	
	add $s0, $zero, $s6			# Reset the address of the row
	add $s0, $s0, $s4			# Moves the address to the next byte

	j _printRowLoop				# Prints another 8 by 8 square

_rowPrinted:	

	add $t8, $zero, $zero			# Resets $t8 to 0
	beqz $s1, _fillRowLoop			# Check if colors need to be inverted
	xori $t8, $t8, 0xFF			# Invert colors
_fillRowLoop:
	beq $s7, 480, _printRowDone	# when 480 pixels have been printed, the row is done
	addi $t9, $zero, 1 	# Set $t9 to 1 to print
wait1: 	bne $t9, $zero, wait1 	# Wait until $t9 is back to 0
	addi $s7, $s7, 1	# Add one to pixel counter
	j _fillRowLoop		# Return to top
	
_printRowDone:		
				
	lw $s0, 0($sp)				# restores s registers used in function
	lw $s1, 4($sp)				# "
	lw $s2, 8($sp)				# "
	lw $s3, 12($sp)				# "
	lw $s4, 16($sp)				# "
	lw $s5, 20($sp)				# "
	lw $s6, 24($sp)				# "
	lw $s7, 28($sp)				# "
	addi $sp, $sp, 32			# "
	
	jr $ra			# Return to caller
	
