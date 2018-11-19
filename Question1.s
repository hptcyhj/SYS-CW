        .data
buffer: .space 256
msg1:   .asciiz "Please enter a non-negative integer: "
msg2:   .asciiz "The input is invalid!"
msg3:   .asciiz "The result is overflow!"
        .text
        .globl main

# helper function - init()
init:   # $a0 = the address of buffer, $a1 = length of the buffer
        li $t0, 0              # $t0 saves the counter

loop1:  beq  $t0, $a1, exit1   # test whether reach the end of the buffer
        sb   $zero, 0($a0)     # initialize the current byte
        addi $a0, $a0, 1       # move to the next byte
        addi $t0, $t0, 1       # add the counter
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

loop2:  lbu  $t1, 0($a0)       # $t1 saves the current digit
        beq  $t1, $t0, exit2   # test whether arrive the end
        addi $t1, $t1, -48     # $t1 saves the actual value of that digit
        mul  $v0, $v0, $t0     # multiply the base 10
        add  $v0, $v0, $t1     # add the product to $v0
        addi $a0, $a0, 1       # move to the next char
        j    loop2

exit2:  j    $ra

main:   la  $a0, msg1          # prompt user to enter a non-negative integer
        li  $v0, 4             # print_string
        syscall
        
        # user may enter some invalid input, so here we read a string instead of a number.
        # First, we need to initialize the buffer.

        la  $a0, buffer        # $a0 saves the address of buffer
        li  $a1, 256           # $a1 saves the length of buffer
        jal init

        # Now we can read the input.
        la  $a0, buffer        # $a0 saves the address of buffer
        li  $a1, 256           # $a1 saves the length of buffer
        li  $v0, 8             # read_string
        syscall

# since the valid input should be a non-negative integer, any character that is not a digit would make the whole input, except a "+" symbol at the beginning, which show the number is positive. (however, "-" would be invalid, since the number should be non-negative)

        # Now we test whether the first char is "+"
        la   $s0, buffer        # $s0 saves the address of buffer
        lbu  $t0, 0($s0)        # $t0 saves the first char
        li   $t1, 43            # $t1 saves the ascii code of "+"
        bne  $t0, $t1, nosign

        addi $s0, $s0, 1        # if the first char is "+", we can simply ignore it

nosign: # check each char is a digit before arriving "\n"
        move $s1, $s0           # backup the current address        
        li   $s2, 10            # $s2 saves the ascii code of "\n"

loop3:  lbu  $a0, 0($s0)        # $a0 saves the current char
        beq  $a0, $s2, exit3    # test whether arriving the end of string
        jal  isdigit
        beq  $v0, $zero, error  # if the char is not a digit, error happens
        addi $s0, $s0, 1        # increment the address of buffer
        j    loop3

error:  # this case is for invalid input
        la   $a0, msg2          # prompt the input is invalid
        li   $v0, 4             # print_string
        syscall

        li   $v0, 10            # exit
        syscall

exit3:  # Now we need to convert valid input into an integer
        move $a0, $s1           # $a0 saves the address of buffer
        jal  atoi

        move $s0, $v0           # $s0 saves the converted value
        li   $t0, 12            # the max number can be computed
        bgt  $s0, $t0, overf    # test whether the result is overflow

# Here is the core code of factorial function.
        li   $s1, 1             # $s1 saves the result
        li   $t0, 1             # $t0 saves the counter

loop4:  bgt  $t0, $s0, exit4    # test whether i <= n
        mult $s1, $t0           # $Lo = f * i
        mflo $s1                # f = f * i
        addi $t0, $t0, 1        # i = i + 1
        j    loop4

exit4:  move $a0, $s1           # $a0 saves the result
        li   $v0, 1             # print_int
        syscall
        
        li   $v0, 10            # exit
        syscall

overf:  la   $a0, msg3          # prompt the result is overflow
        li   $v0, 4             # print_string
        syscall

        li   $v0, 10            # exit
        syscall
