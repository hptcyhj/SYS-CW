        .data
buffer1:.space 256
buffer2:.space 3
msg1:   .asciiz "Please enter a string: "
msg2:   .asciiz "Please enter a char: "
msg3:   .asciiz "not found"
msg4:   .asciiz "found at offset: "
        .text
        .globl main

# helper function - strchr
# To use strchr to find the length of a string, we call this function is this way:
# $a0 saves the address of the string, $a1 = 0, because the NULL's ascii value is 0.
# And the return value is the offset of NULL, which is the same as the length of the string. (if we consider '\n' belonging to the string)

strchr: # $a0 = the address of buffer, $a1 = target
        # $v0 = offset if the target can be found, otherwise -1

        li   $t0, 0             # $t0 saves the counter i
        
loop:   lbu  $t1, 0($a0)        # $t1 saves the current char
        beq  $t1, $a1, found    # test whether is the target
        beq  $t1, $zero, end    # test whether the end is reached
        addi $t0, $t0, 1        # increment the counter
        addi $a0, $a0, 1        # increment the address
        j    loop

found:  move $v0, $t0           # copy the offset to $v0
        j    $ra

end:    li   $v0, -1            # return -1 if cannot found target
        j    $ra


main:
        la   $a0, msg1          # prompt user to enter a string
        li   $v0, 4             # print_string
        syscall

        la   $a0, buffer1       # use buffer1 to store the string
        li   $a1, 256
        li   $v0, 8             # read_string
        syscall

        la   $a0, msg2          # prompt user to enter a char
        li   $v0, 4             # print_string
        syscall

        la   $a0, buffer2       # use buffer2 to store the char
        li   $a1, 3
        li   $v0, 8             # read_string
        syscall

        lbu  $a1, 0($a0)        # $a1 saves the char
        la   $a0, buffer1       # $a0 saves the address of buffer1
        jal  strchr

        li   $t0, -1            # the return value when not found
        beq  $v0, $t0, nofound  # test whether found the target
        move $s0, $v0           # $s0 saves the offset

        la   $a0, msg4          # prompt the offset of the target
        li   $v0, 4             # print_string
        syscall
        move $a0, $s0           # $a0 saves the offset
        li   $v0, 1             # print_int
        syscall

        li   $v0, 10            # exit
        syscall

nofound:
        la   $a0, msg3          # prompt not found the target
        li   $v0, 4             # print_string
        syscall

        li   $v0, 10            # exit
        syscall
