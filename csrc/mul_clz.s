.global _start

.data
    data_1: .word 0x12345678
    data_2: .word 0xffffdddd
    mask_1: .word 0x55555555
    mask_2: .word 0x33333333
    mask_3: .word 0x0f0f0f0f

    str_cycle:     .string "cycle count: "
    endl:     .string "\n"
    buffer:     .byte 0, 0, 0, 0
.text
    
main:
    jal get_cycles
    addi sp, sp, -4
	sw a0, 0(sp)
    
    lw s0, data_1   #s0 = A
    lw s1, data_2   #s1 = B
    
    addi a0, s0, 0    
    jal ra, CLZ
    addi t5, a0, 0    #A's CLZ ->  t5
    addi a0, s1, 0
    jal ra, CLZ
    addi t6, a0, 0    #B's CLZ ->  t6
    slt t0, t5, t6 # if A's zero less than B's, t0=1
    addi a0, zero, 32
    bne t0, zero, start_mul
    addi t0, s0, 0
    addi s0, s1, 0
    addi s1, t0, 0
    addi t6, t5, 0
    
start_mul:
    #reset
    sub a0, a0, t6
    addi t0, zero, 0
    addi t1, zero, 0
    addi t2, zero, 0    
    addi s2, zero, 0        #s2: high 32 of number
    addi s3, zero, 0        #s3: low 32 of number
    addi s4, zero, 0        #used to check how many bit should shift   

int_mul:
    slt t1, s4, a0
    beq t1, zero, exit
    srl t0, s1, s4
    andi t0, t0, 0x00000001        #check B's rightest bit
    beq t0, zero, skip            #if(rightest bit is zero) jump
    sll s5,s0,s4                    #s0 is A,S5 the low bit i want
    addi t2, zero, 32
    sub t2, t2, s4
    srl s6, s0, t2             #s0 is A, S6 the high bit i want
    add s7, s3, s5             #s7 is 32_low + low bit i want
    jal overflow_detect_function
    
no_overflow:
    add s2, s2, s6
    jal skip
    
skip:
    addi s4, s4 ,1
    jal int_mul

overflow_detect_function:
    sltu t3, s7, s3
    addi s3, s7, 0
    beq t3, zero, no_overflow
    # if not jump  -->  overflow
    add s2, s2, s6
    addi s2, s2, 1
    addi s4, s4 ,1
    jal int_mul

CLZ:
    #a0: the num(x) you want to count CLZ
    #t0: shifted x
    addi a0, zero, 1
    srl t0, a0, a0    # t0 = x >> 1
    or a0, a0, t0     # x |= x >> 1
    addi a0, zero, 2
    srl t0, a0, a0    # t0 = x >> 2
    or a0, a0, t0     # x |= x >> 2
    addi a0, zero, 4
    srl t0, a0, a0    # t0 = x >> 4
    or a0, a0, t0     # x |= x >> 4
    addi a0, zero, 8
    srl t0, a0, a0    # t0 = x >> 8
    or a0, a0, t0     # x |= x >> 8
    addi a0, zero, 16
    srl t0, a0, a0    # t0 = x >> 16
    or a0, a0, t0     # x |= x >> 16

    #start_mask

    lw t2, mask_1
    addi a0, zero, 1
    srl t0, a0, a0    # t0 = x >> 1
    and t1, t0, t2    # t1 = (x >> 1) & mask1
    sub a0, a0, t1    # x -= ((x >> 1) & mask1)
    lw t2, mask_2     # load mask2 to t2
    addi a0, zero, 2
    srl t0, a0, a0    # t0 = x >> 2
    and t1, t0, t2    # (x >> 2) & mask2
    and a0, a0, t2    # x & mask2
    add a0, t1, a0    # ((x >> 2) & mask2) + (x & mask2)
    addi a0, zero, 4
    srl t0, a0, a0    # t0 = x >> 4
    add a0, a0, t0    # x + (x >> 4)
    lw t2, mask_3      # load mask3 to t2
    and a0, a0, t2    # ((x >> 4) + x) & mask4
    addi a0, zero, 8
    srl t0, a0, a0    # t0 = x >> 8
    add a0, a0, t0    # x += (x >> 8)
    addi a0, zero, 16
    srl t0, a0, a0    # t0 = x >> 16
    add a0, a0, t0    # x += (x >> 16)
    andi t0, a0, 0x3f # t0 = x & 0x3f
    addi a0, zero, 32         # a0 = 32
    sub a0, a0, t0    # 32 - (x & 0x3f)
    ret
get_cycles:
    csrr a1, cycleh
    csrr a0, cycle
    csrr a2, cycleh
    bne a1, a2, get_cycles
    ret
exit:
    addi a7, zero, 10

    addi a7, zero, 64	
    addi a0, zero, 1            
    la a1, str_cycle
    addi a2, zero, 13
    ecall
    jal get_cycles
    lw t0, 0(sp)    # t0 = pre cycle
    sub a0, a0, t0    # a0 = new cycle
    addi sp, sp, 4
    addi a1, zero, 4
    jal print_ascii
    mv t0, a0
    addi a0, zero, 1
    la a1, buffer
    addi a2, zero, 4
    addi a7, zero, 64
    ecall

    addi a7, zero, 64
    addi a0, zero, 1
    la a1, endl
    addi a2, zero, 2
    ecall
    addi a7, zero, 93    # "exit" syscall
    add a0, x0, 0       # Use 0 return code
    ecall
print_ascii:
    mv t0, a0     # load integer
    addi t1, zero, 0      # t1 = quotient
    addi t2, zero, 0      # t2 = reminder
    addi t3, zero, 10     # t3 = divisor
    mv t4, a1     # t4 = count round
check_less_then_ten:
    bge t0, t3, divide
    mv t2, t0
    mv t0, t1    # t0 = quotient
    j to_ascii
divide:
    sub t0, t0, t3
    addi t1, t1, 1
    j check_less_then_ten
to_ascii:
    addi t2, t2, 48	# reminder to ascii
    la t5, buffer  # t5 = buffer addr
    addi t4, t4, -1
    add t5, t5, t4
    sb t2, 0(t5)
    # counter = 0 exit
    beqz t4, convert_loop_done
    addi t1, zero, 0 # refresh quotient
    j check_less_then_ten
convert_loop_done:
    ret