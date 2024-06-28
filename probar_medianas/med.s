// .data section
input_file:     .asciz "input.txt"
output_file:    .asciz "output.txt"
buffer:         .space 256
num_array:      .space 256
num_elements:   .word 0
median_buffer:  .space 16

// .text section
.global _start

_start:
    // Open input file for reading
    mov x0, #-100
    ldr x1, =input_file
    mov x2, #0x0    // O_RDONLY
    mov x8, #0x56   // openat syscall number
    svc #0
    cbz x0, error_open_input
    mov x9, x0      // Save file descriptor in x9

    // Read from input file
    mov x0, x9
    ldr x1, =buffer
    mov x2, #256
    mov x8, #0x3f   // read syscall number
    svc #0
    cbz x0, error_read_input
    mov x10, x0     // Save number of bytes read in x10

    // Parse numbers from buffer into num_array and count num_elements
    ldr x0, =buffer
    ldr x1, =num_array
    mov x2, x10     // Length of data read
    bl parse_numbers

    // Sort num_array (bubble sort)
    ldr x0, =num_elements
    ldr x1, =num_array
    bl bubble_sort

    // Calculate median
    ldr x0, =num_array
    ldr x1, =num_elements
    bl calculate_median

    // Convert median to string
    ldr x0, =median_buffer
    ldr x1, =num_array
    ldr x2, [x0]
    bl itoa

    // Open output file for writing
    mov x0, #-100
    ldr x1, =output_file
    mov x2, #0x577  // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0x1b4  // S_IRUSR | S_IWUSR
    mov x8, #0x56   // openat syscall number
    svc #0
    cbz x0, error_open_output
    mov x11, x0     // Save file descriptor in x11

    // Write median_buffer to output file
    mov x0, x11
    ldr x1, =median_buffer
    bl write_string

    // Close input and output files
    mov x0, x9
    mov x8, #0x38   // close syscall number
    svc #0

    mov x0, x11
    mov x8, #0x38   // close syscall number
    svc #0

    // Exit program
    mov x0, #0
    mov x8, #0x3f   // exit syscall number
    svc #0

error_open_input:
    // Handle error opening input file
    b exit_program

error_read_input:
    // Handle error reading input file
    b exit_program

error_open_output:
    // Handle error opening output file
    b exit_program

exit_program:
    // Exit program with error code
    mov x0, #-1
    mov x8, #0x3f   // exit syscall number
    svc #0

// Function to parse numbers from buffer into num_array and count num_elements
parse_numbers:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x3, #0      // Initialize num_elements
parse_loop:
    ldrb w2, [x0], #1
    cmp w2, #'0'
    b.lo skip_digit
    cmp w2, #'9'
    b.hi skip_digit

    strb w2, [x1], #1
    ldr x4, [x3]
    add x4, x4, #1
    str x4, [x3]

    jmp parse_loop

skip_digit:
    cbz w2, done_parse
    cmp w2, #','
    b.ne done_parse

    ldr x4, [x3]
    str x4, [x3]

done_parse:
    ldp x29, x30, [sp], #16
    ret

// Bubble Sort function
bubble_sort:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    ldr x5, [x0]    // x5 = num_array
    ldr x6, [x1]    // x6 = num_elements

    mov x8, #0      // swapped = 0

outer_loop:
    mov x9, #0      // i = 0
    mov x10, #0     // swapped = 0

inner_loop:
    cmp x9, x6      // if i >= num_elements
    b.ge outer_end

    ldr x11, [x5, x9, lsl #3]   // load num_array[i]
    ldr x12, [x5, x9, lsl #3]   // load num_array[i + 1]
    cmp x11, x12    // if num_array[i] <= num_array[i + 1]
    b.le no_swap

    str x12, [x5, x9, lsl #3]   // num_array[i] = num_array[i + 1]
    str x11, [x5, x9, lsl #3]   // num_array[i + 1] = num_array[i]

    mov x10, #1     // swapped = 1

no_swap:
    add x9, x9, #1  // i = i + 1
    b inner_loop

outer_end:
    cmp x10, #0     // if swapped == 0
    b.eq outer_end

    b outer_loop

    ldp x29, x30, [sp], #16
    ret

// Function to calculate median
calculate_median:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    ldr x5, [x0]    // x5 = num_array
    ldr x6, [x1]    // x6 = num_elements

    mov x7, x6      // x7 = num_elements
    mov x8, #2      // x8 = 2

    udiv x7, x7, x8 // x7 = num_elements / 2

    add x5, x5, x7, lsl #3 // x5 = num_array + num_elements / 2

    ldr x6, [x5]    // x6 = num_array[num_elements / 2]

    ldp x29, x30, [sp], #16
    ret

// Function to convert integer to string
itoa:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x2, #10     // base = 10
    mov x3, x1      // pointer to start of buffer

itoa_loop:
    udiv x1, x0, x2 // x1 = x0 / 10
    msub x4, x1, x2, x0 // x4 = x0 - x1 * 10 (remainder)
    add x4, x4, #'0' // convert digit to character
    strb w4, [x3], #1 // write character to buffer
    mov x0, x1      // x0 = x1 (divided by 10)
    cbz x1, itoa_end // if x1 is 0, end

    b itoa_loop     // repeat loop

itoa_end:
    strb w0, [x3]   // terminate string with '\0'

    sub x3, x3, #1  // reverse string in buffer
    mov x4, x1      // pointer to start of buffer
    mov x5, x3      // pointer to end of buffer

itoa_reverse:
    ldrb w6, [x4]   // read character from start
    ldrb w7, [x5]   // read character from end
    strb w7, [x4]   // write character from end to start
    strb w6, [x5]   // write character from start to end
    add x4, x4, #1  // move forward
    sub x5, x5, #1  // move backward
    cmp x4, x5      // compare pointers
    blo itoa_reverse // repeat if not crossed

    ldp x29, x30, [sp], #16
    ret

// Function to write string to file
write_string:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x2, #0      // calculate string length
write_string_len:
    ldrb w3, [x1], #1
    cbz w3, write_string_done
    add x2, x2, #1
    b write_string_len

write_string_done:
    mov x1, x0      // file descriptor
    mov x0, #1      // stdout
    mov x8, #0x40   // write syscall number
    svc #0

    ldp x29, x30, [sp], #16
    ret