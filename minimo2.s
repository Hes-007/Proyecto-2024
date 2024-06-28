// Bubble sort implementation in ARM64 v8 assembly language

.data
input: .asciz "input.txt"
output: .asciz "output.txt"
arr: .space 40 // assume 10 elements, each 4 bytes
buffer: .space 40 // buffer for reading input file

.text
_start:
    // Open input file
    mov x0, -100
    ldr x1, =input
    mov x2, 0
    mov x8, 56
    svc 0
    mov x9, x0

    // Read input file into buffer
    mov x0, x9
    ldr x1, =buffer
    mov x2, 40
    mov x8, 63
    svc 0

    // Close input file
    mov x0, x9
    mov x8, 57
    svc 0

    // Parse input buffer into array
    mov x0, #0 // index
    mov x1, #0 // value
parse_loop:
    ldrb w2, [buffer, x0]
    cmp w2, #44 // comma
    beq parse_next
    cmp w2, #0 // end of string
    beq parse_done
    mul x1, x1, 10
    add x1, x1, w2 - '0'
    add x0, x0, 1
    b parse_loop

parse_next:
    str x1, [arr, x0, lsl #2]
    mov x1, #0
    add x0, x0, 1
    b parse_loop

parse_done:
    // Set up bubble sort
    mov x0, #10 // array size
    mov x1, #0 // index
    mov x2, #0 // swap flag

loop:
    // Load current element and next element
    ldr x3, [arr, x1, lsl #2]
    ldr x4, [arr, x1, lsl #2, #4]

    // Compare elements
    cmp x3, x4
    bgt swap

    // No swap needed, increment index
    add x1, x1, 1
    cmp x1, x0
    blt loop

    // Check if any swaps were made
    cmp x2, #0
    beq done

    // Reset index and swap flag
    mov x1, #0
    mov x2, #0
    b loop

swap:
    // Swap elements
    str x4, [arr, x1, lsl #2]
    str x3, [arr, x1, lsl #2, #4]

    // Set swap flag
    mov x2, #1

    // Increment index
    add x1, x1, 1
    cmp x1, x0
    blt loop

done:
    // Open output file
    mov x0, -100
    ldr x1, =output
    mov x2, 101
    mov x3, 0777
    mov x8, 56
    svc 0
    mov x9, x0

    // Write sorted array to output file
    mov x0, x9
    ldr x1, =arr
    mov x2, 40
    mov x8, 64
    svc 0

    // Close output file
    mov x0, x9
    mov x8, 57
    svc 0

    // Exit
    mov x0, #0
    mov x8, #93
    svc #0
