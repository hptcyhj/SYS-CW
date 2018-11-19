        .data
buffer1:.space 256
buffer2:.space 256
msg1:   .asciiz "Please enter an integer (x): "
msg2:   .asciiz "Please enter an integer (y): "
msg3:   .asciiz "The input is invalid!"
msg4:   .asciiz "The result is overflow!"
nl:     .asciiz "\n"
        .text
        .globl main

# helper function - init()
init:   # $a0 = the address of buffer, $a1 = length of the buffer
        li $t0, 0              # $t0 saves the counter

loop1:  beq   $t0, $a1, exit1  # test whether reach the end of the buffer
        sb    $zero, 0($a0)    # initialize the current byte
        addiu $a0, $a0, 1      # move to the next byte
        addiu $t0, $t0, 1      # add the counter
        j    loop1

exit1:  j    $ra

# helper function - isdigit()
isdigit: # $v0 = 1 if $a0 saves a digit, otherwise $v0 = 0.
        li  $v0, 1
        li  $t0, 48            # if a char is a digit, then its value is between 48 and 57
        li  $t1, 57
        blt $a0, $t0, cont
        bgt $a0, $t1, cont
        j   $ra

cont:   li  $v0, 0
        j   $ra

# helper function - atoi()
atoi:   # $a0 = buffer, $v0 saves the return number.
        li   $t0, 10           # $t0 saves the ascii code of "\n", and the base 10
        li   $v0, 0            # $v0 saves the result

loop2:  lbu   $t1, 0($a0)      # $t1 saves the current digit
        beq   $t1, $t0, exit2  # test whether arrive the end
        addiu $t1, $t1, -48    # $t1 saves the actual value of that digit
        mul   $v0, $v0, $t0    # multiply the base 10
        addu  $v0, $v0, $t1    # add the product to $v0
        addiu $a0, $a0, 1      # move to the next char
        j     loop2

exit2:  j    $ra

main:
        la   $a0, msg1          # prompt user enter the value of x
        li   $v0, 4             # print_string
        syscall

        # user may enter some invalid input, so here we read a string instead of a number.
        # First, we need to initialize the buffer.

        la  $a0, buffer1        # $a0 saves the address of buffer1
        li  $a1, 256            # $a1 saves the length of buffer1
        jal init

        # Now we can read the input.
        la  $a0, buffer1        # $a0 saves the address of buffer1
        li  $a1, 256            # $a1 saves the length of buffer1
        li  $v0, 8              # read_string
        syscall

# since the valid input should be an integer, any character that is not a digit would make the whole input, except a "+" or "-" symbol at the beginning, which show the number is positive or negative.

        # Now we test whether the first char is "+" or "-"
        la   $s0, buffer1       # $s0 saves the address of buffer1
        lbu  $t0, 0($s0)        # $t0 saves the first char
        li   $t1, 43            # $t1 saves the ascii code of "+"
        beq  $t0, $t1, posi
        li   $t1, 45            # $t1 saves the ascii code of "-"
        beq  $t0, $t1, nega
        li   $s2, 1             # $s2 = 1 when the value have no sign (positive)
        j    nosign

posi:   li   $s2, 1             # $s2 = 1 when the value is positive
        addiu $s0, $s0, 1       # increment the address of buffer1
        j    nosign

nega:   li    $s2, -1           # $s2 = -1 when the value is negative
        addiu $s0, $s0, 1       # increment the address of buffer1
        j     nosign

nosign: # check each char is a digit before arriving "\n"
        addu $s1, $s0, $zero    # backup the current address        
        li   $s3, 10            # $s3 saves the ascii code of "\n"  

loop3:  lbu   $a0, 0($s0)       # $a0 saves the current char
        beq   $a0, $s3, exit3   # test whether arriving the end of string
        jal   isdigit
        beq   $v0, $zero, error # if the char is not a digit, error happens
        addiu $s0, $s0, 1       # increment the address of buffer
        j     loop3

error:  # this case is for invalid input
        la   $a0, msg3          # prompt the input is invalid
        li   $v0, 4             # print_string
        syscall

        li   $v0, 10            # exit
        syscall

exit3:  # Now we need to convert valid input into an integer
        addu $a0, $s1, $zero    # $a0 saves the address of buffer
        jal  atoi

        addu $s4, $v0, $zero    # $s4 saves the converted value
        mult $s4, $s2           # correct the value with its sign
        mflo $s4                # $s4 saves the corrected value

# Now we should read the value of y. Before doing this, let me explain my optimization for this question first.
# This formula in the question can be simplified into this: (x + 3y - 3)^2.
# It is obvious that the result would be greater than or equal to zero no matter the value of x or y is.
# Since the question ask us to do signed 32-bit arithmetic, the maximum value can be stored is 2**31 - 1. So (x + 3y - 3)^2 should be <= 2**31 - 1.
# After simplifying this inequation, we can get the valid range of (x + 3y). When we find the value of (x + 3y) is beyond the valid range, we can directly conclude that the result will be overflow.

        la   $a0, msg2          # prompt user enter the value of y
        li   $v0, 4             # print_string
        syscall

        # user may enter some invalid input, so here we read a string instead of a number.
        # First, we need to initialize the buffer.

        la  $a0, buffer2        # $a0 saves the address of buffer2
        li  $a1, 256            # $a1 saves the length of buffer2
        jal init

        # Now we can read the input.
        la  $a0, buffer2        # $a0 saves the address of buffer2
        li  $a1, 256            # $a1 saves the length of buffer2
        li  $v0, 8              # read_string
        syscall

# since the valid input should be an integer, any character that is not a digit would make the whole input, except a "+" or "-" symbol at the beginning, which show the number is positive or negative.

        # Now we test whether the first char is "+" or "-"
        la   $s0, buffer2       # $s0 saves the address of buffer2
        lbu  $t0, 0($s0)        # $t0 saves the first char
        li   $t1, 43            # $t1 saves the ascii code of "+"
        beq  $t0, $t1, posi2
        li   $t1, 45            # $t1 saves the ascii code of "-"
        beq  $t0, $t1, nega2
        li   $s2, 1             # $s2 = 1 when the value have no sign (positive)
        j    nosign2

posi2:  li   $s2, 1             # $s2 = 1 when the value is positive
        addiu $s0, $s0, 1       # increment the address of buffer2
        j    nosign2

nega2:  li   $s2, -1            # $s2 = -1 when the value is negative
        addiu $s0, $s0, 1       # increment the address of buffer2
        j    nosign2

nosign2: # check each char is a digit before arriving "\n"
        addu $s1, $s0, $zero    # backup the current address        
        li   $s3, 10            # $s3 saves the ascii code of "\n"  

loop4:  lbu  $a0, 0($s0)        # $a0 saves the current char
        beq  $a0, $s3, exit4    # test whether arriving the end of string
        jal  isdigit
        beq  $v0, $zero, error  # if the char is not a digit, error happens
        addiu $s0, $s0, 1       # increment the address of buffer
        j    loop4

exit4:  # Now we need to convert valid input into an integer
        addu $a0, $s1, $zero    # $a0 saves the address of buffer
        jal  atoi

        addu $s5, $v0, $zero    # $s5 saves the converted value
        mult $s5, $s2           # correct the value with its sign
        mflo $s5                # $s5 saves the corrected value

# Now we have finished handling input, $s4 = x, $s5 = y.
# Now we start doing the computation.
# First we compute 3 * y. If y is positive, the maximum value of 3y is 2**31 - 1. If y is negative, the minimum value of 3y is -2**31.

        blt  $s5, $zero, neg3   # test whether y is negative
        li   $t0, 715827882     # the maximum value can be stored in y without overflow
        bgt  $s5, $t0, overf
        j    l1

neg3:   li   $t0, -715827882    # the minimum value can be stored in y without overflow
        blt  $s5, $t0, overf
        j    l1

l1:     li   $t0, 3             # calculate 3 * y
        mult $s5, $t0
        mflo $s5                # $s5 = 3y

# Now we compute x + 3y.

        addu $t0, $s4, $s5      # $t0 = x + 3y
        xor  $t1, $s4, $s5      # use xor to detect whether x and 3y have same sign
        blt  $t1, $zero, l2     # if $t1 < 0, x and 3y have different signs, overflow cannot happens
        
        xor  $t1, $t0, $s4      # test whether the signs of sum and x are the same
        blt  $t1, $zero, overf  # if the signs of sum and x are different, overflow must happen

# As the previous explanation, we can directly check the valid range of (x + 3y) to know, whether the final result will be overflow.
# After simplifying the previous inequation, the range is -46337 <= (x + 3y) <= 46343.

l2:     addu $s0, $t0, $zero    # $s0 = x + 3y
        li   $t0, -46337        # the minimum valid value of (x + 3y)
        blt  $s0, $t0, overf

        li   $t0, 46343         # the maximum valid value of (x + 3y)
        bgt  $s0, $t0, overf

# During the rest of the program, we don't need to detect overflow anymore.

        addiu $s0, $s0, -3      # $s0 = x + 3y - 3
        mult  $s0, $s0
        mflo  $s0               # $s0 = (x + 3y - 3)^2

        addu $a0, $s0, $zero    # $a0 = (x + 3y - 3)^2
        li   $v0, 1             # print_int
        syscall

        li   $v0, 10            # exit
        syscall

overf:  la   $a0, msg4          # prompt the result is overflow
        li   $v0, 4             # print_string
        syscall

        li   $v0, 10            # exit
        syscall
