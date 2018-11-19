        .data
buffer: .space 256
msg1:   .asciiz "Please enter a non-negative number: "
msg2:   .asciiz "The input is invalid!"
fnum:   .float 0.5 0.000001 10.0
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

# helper function - isdigit()  This version is for float number.
isdigit: # $v0 = 1 if $a0 saves a digit, otherwise $v0 = 0.
        li  $v0, 1
        li  $t0, 48            # if a char is a digit, then its value is between 48 and 57
        li  $t1, 57
        blt $a0, $t0, cont
        bgt $a0, $t1, cont
        j   $ra

cont:   li  $t2, 46            # if a char is the decimal point, it is valid
        beq $a0, $t2, finish 
        li  $v0, 0
finish: j   $ra

# helper function - atoi()  This version is for float number.
atoi:   # $a0 = buffer, $v0 saves the return number.
        li   $t0, 10           # $t0 saves the ascii code of "\n", and the base 10
        li   $v0, 0            # $v0 saves the result
        li   $t2, 46           # $t2 saves the ascii code of "."

loop2:  lbu  $t1, 0($a0)       # $t1 saves the current digit
        beq  $t1, $t0, exit2   # test whether arrive the end
        beq  $t1, $t2, conti3
        addi $t1, $t1, -48     # $t1 saves the actual value of that digit
        mul  $v0, $v0, $t0     # multiply the base 10
        add  $v0, $v0, $t1     # add the product to $v0
conti3: addi $a0, $a0, 1       # move to the next char
        j    loop2

exit2:  j    $ra


main:
        la   $a0, msg1          # prompt user to enter a non-negative number
        li   $v0, 4             # print_string
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

# Now let me explain my method to deal with the input. First, I will check if the input is valid.
# If so, I first convert the string into an integer without the decimal point.
# Then, I move the integer into coprocessor 1, and change it into float-number representation.
# Finally, I put back the decimal point, divide the integer by 10 many times.



# since the valid input should be a non-negative number, any character that is not a digit would make the whole input, 
# except a "+" symbol at the beginning, which show the number is positive. 
# And a "." symbol is also valid, which stands for decimal point. 
# (however, "-" would be invalid, since the number should be non-negative)

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

        # Now we should test whether there are more than one decimal point, if so, it is also a invalid input.

exit3:  move $s0, $s1           # $s0 saves the address of buffer
        li   $t0, 46            # $t0 saves the ascii code of decimal point
        li   $t1, 0             # $t1 is the counter
        li   $t3, 10            # $t3 saves the ascii code of '\n'

loop4:  lbu  $t2, 0($s0)        # $t2 saves the current char
        beq  $t2, $t3, exit4    # test whether arriving the end of string
        bne  $t2, $t0, conti    # test whether this char is a decimal point
        addi $t1, $t1, 1        # increment the counter
conti:  addi $s0, $s0, 1        # move to the next char
        j    loop4

exit4:  li   $t0, 1             # if the input has more than one decimal point
        bgt  $t1, $t0, error    # jump to error
        beq  $t1, $zero, isint  # if the input has no decimal point ,jump to isint

        # Now we need to know how many digits are behind the decimal point.

        move $s0, $s1           # $s0 saves the address of buffer
        li   $t0, 46            # $t0 saves the ascii code of decimal point
        li   $t1, 0             # $t1 is the counter
        li   $t2, 10            # $t2 saves the ascii code of '\n'

loop5:  lbu  $t3, 0($s0)        # $t3 saves the current char
        beq  $t3, $t2, exit5    # test whether arriving the end of string
        addi $t1, $t1, 1        # increment the counter
        bne  $t3, $t0, conti2
        move $t4, $t1           # $t4 saves the index of decimal point
conti2: addi $s0, $s0, 1        # move to the next char
        j    loop5

exit5:  sub  $s2, $t1, $t4      # $s2 saves the length of the digits after decimal point
        
        # Now we should convert the string to a number
                
        move $a0, $s1           # $a0 saves the address of buffer
        jal  atoi

        mtc1 $v0, $f0           # $f0 saves the input value without decimal point
        cvt.s.w $f0, $f0        # change the value from int to float
        
        # Here we put the decimal point back

        li   $t0, 0             # $t0 is the counter
        la   $t1, fnum          # $t1 saves the address of fnum
        lwc1 $f1, 8($t1)        # $f1 = 10.0

loop6:  beq   $t0, $s2, exit6   # test counter < length
        div.s $f0, $f0, $f1     # $f0 = $f0 / 10.0
        addi  $t0, $t0, 1       # increment the counter
        j     loop6

        # Now we handle the case: the input is an integer.
isint:  move $a0, $s1           # $a0 saves the address of buffer
        jal  atoi

        mtc1 $v0, $f0           # $f0 saves the input value
        cvt.s.w $f0, $f0        # change the value from int to float

# We have finished dealing with the input, and the input value has been stored in $f0.
# Now we start to compute the square root.

exit6:  la    $s0, fnum         # $s0 saves the address of float numbers
        lwc1  $f2, 0($s0)       # $f2 = 0.5
        lwc1  $f3, 4($s0)       # $f3 = 0.000001
        mov.s $f4, $f0          # $f4 = n
        mul.s $f1, $f0, $f2     # $f1 = 0.5 * n      

loop:   sub.s  $f5, $f0, $f1    # $f4 = x0 - x1
        c.le.s $f5, $f3         # test whether (x0 - x1) < 0.000001
        bc1t   exit

        mov.s  $f0, $f1         # x0 = x1
        div.s  $f5, $f4, $f0    # $f5 = n / x0
        add.s  $f5, $f5, $f0    # $f5 = x0 + n / x0
        mul.s  $f5, $f5, $f2    # $f5 = 0.5 * (x0 + n / x0)
        mov.s  $f1, $f5         # x1 = 0.5 * (x0 + n / x0)
        j      loop

exit:   mov.s  $f12, $f1        # move the result to print
        li     $v0, 2           # print_float
        syscall

        li     $v0, 10          # exit
        syscall
