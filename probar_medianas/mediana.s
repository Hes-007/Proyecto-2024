// .data section declarations
input_file:     .asciz "input.txt"    // Input file name
output_file:    .asciz "output.txt"   // Output file name
buffer:         .space 256            // Buffer space for input
num_array:      .space 256            // Array to store numbers
num_elements:   .word 0               // Variable to store the number of elements
median_buffer:  .space 16             // Buffer for median number as string

// .text section
.global _start

_start:
    // Open input file for reading
    // Read numbers from file into num_array and store the count in num_elements

    // Sort num_array (implement sorting algorithm)

    // Calculate median
    ldr x0, =num_elements
    ldr x1, =num_array
    bl calculate_median

    // Convert median to string
    ldr x0, =median_buffer
    ldr x1, =num_array       // Assuming median is stored in num_array[num_elements / 2]
    ldr x2, [x0]             // Load the median value
    bl itoa                  // Convert integer to ASCII string

    // Open output file for writing
    // Write median_buffer to output file

    // Close files and exit

calculate_median:
    // Calculate the median
    ldr x2, [x0]             // Load num_elements
    cmp x2, #0               // Check if there are elements
    b.eq median_not_found

    // Check if num_elements is odd or even
    tst x2, #1               // Check if num_elements is odd
    b.ne median_even         // If odd, skip to median_odd

median_even:
    // Calculate median for even number of elements
    mov x3, x2               // x3 = num_elements
    sub x3, x3, #1           // x3 = num_elements - 1
    udiv x3, x3, #2          // x3 = (num_elements - 1) / 2
    ldr x1, [x1, x3, LSL #3] // Load num_array[x3]

    ret

median_odd:
    // Calculate median for odd number of elements
    mov x3, x2               // x3 = num_elements
    udiv x3, x3, #2          // x3 = num_elements / 2
    ldr x1, [x1, x3, LSL #3] // Load num_array[x3]

    ret

median_not_found:
    // Handle case where median cannot be found (optional)

    ret