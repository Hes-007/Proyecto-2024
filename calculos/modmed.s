.global _start

.bss
cadena: .space 20, 0 
counter: .skip 100
n:       .word 0 
buffer:  .space 1024
list:    .skip 10000

.data
filename:   .asciz "input.txt"
output:     .asciz "output.txt"
error_file: .asciz "Error al abrir el archivo\n"

.text
_start:

    b read_information
close:
    mov x0, 0           // return vale
    mov x8, 93          // exit
    svc 0               // syscall



// Función read_points: lee los puntos del archivo 


read_information:
    // open file
    mov x0, -100        // open
    ldr x1, =filename   // filename address
    mov x2, 0           // O_RDONLY 
    mov x8, 56          // openat
    svc #0              // syscall
    mov x9, x0          // store file descriptor

    cmp x0, 0
    b.lt error_open

    // read file
    mov x0, x9          // file descriptor
    ldr x1, =buffer     // buffer address
    mov x2, 1024        // size address
    mov x8, 63          // read
    svc 0               // syscall

    bl add_list

s_list:
    ldr x0, =list
    ldr x1, =n
    ldr x1, [x1]

    bl sort

    ldr x0, =list
    ldr x1, =n
    ldr x1, [x1]

c_mode:
    bl calculate_mode
    mov x17, x2
    ldr x0, =list
    ldr x1, =n
    ldr x1, [x1]

    bl calculate_median

    // close file
    mov x0, x9          // file descriptor
    mov x8, 57          // close
    svc 0               // syscall

    ldr x0, =cadena
    mov x2, 10
    mov x4, x17
    mov x3, 0
    bl contar_digitos
    mov x4, x11
    bl contar_digitos

    add x3, x3, 1
    // mov x10, x3
    // mov x14, x3
    mov x18, x3
    mov w7, 10
    strb w7,[x0,x3]
    sub x3, x3, 1

    mov x1, x17
    bl itoa

    mov w7, 44
    strb w7,[x0,x3]
    sub x3, x3, 1

    mov x4, 0
    mov x5, 0
    mov x1, x11
    bl itoa

    ldr x1, =cadena   // load cadena
    mov x0, 1
    mov x8, 64        // Número de syscall para write.
    mov x2, 20        // Número de bytes a escribir.
    svc 0             // Invoca la syscall.

    bl save_output
    ret

error_open:
    mov x0, 1
    ldr x1, =error_file
    mov x2, 26
    mov x8, 64
    svc #0
no_error:
    ret


// Función add_points: añade los puntos al array 


add_list:
    ldr x1, =buffer
    ldr x7 , =list
    mov x0, 0
    mov x2, 10
    mov x3, 0
    mov x4, 0
    mov x6, 0

    add_lopp:
        ldrb w3, [x1]
        cmp w3, 0
        beq end_add_points2
        cmp w3, 44
        beq end_add_points
        sub w3, w3, 48
        uxtb x3, w3
        mul x0, x0, x2
        add x0, x0, x3
        add x1, x1, 1
        b add_lopp
    
    end_add_points:
        add x1, x1, 1
        ldrb w5, [x1]
        mov w3, w5
    end_add_points2:
        mov w5, w3
        str x0, [x7]
        add x7, x7, 8
        mov x0, 0
        mov x3, 0
        cmp w5, 0
        add x6, x6, 1
        cmp w5, 0
        bne add_lopp
    save1:
        ldr x1, =n
        str x6, [x1]
        ret


// Función sort: ordena los puntos del archivo 

sort:
    mov x2, 0
    mov x3, 0
    
for1:
    sub x5, x1, 1
    cmp x3, x5
    bge end_sort
    add x4, x3, 1

    for2:
        cmp x4, x1
        bge jump1
        lsl x19, x3, 3
        lsl x20, x4, 3
        add x19, x19, x0
        add x20, x20, x0
        ldr x21, [x19]
        ldr x22, [x20]
        cmp x21, x22
        ble jump_exchange
        ldr x23, [x19]
        ldr x24, [x20]
        str x24, [x19]
        str x23, [x20]

jump_exchange:
    add x4, x4, 1
    b for2

jump1:
    add x3, x3, 1
    b for1

end_sort:
    ret


// Función mode: calcula la moda de los puntos 

calculate_mode:
    mov x2, 0 // mode
    mov x3, 0 // max_frecuency

    mov x4, 0 // current frecuency

    mov x6, 0 // index
    mov x7, 1 // index of the mode
    for_mode:
        cmp x7, x1
        bge end_mode

        lsl x19, x6, 3
        lsl x20, x7, 3

        add x19, x19, x0
        add x20, x20, x0

        ldr x21, [x19]  // data[i-1]
        ldr x22, [x20]  // data[i]

    if_mode:
        cmp x22, x21
        bne else_mode

        add x4, x4, 1
        add x7, x7, 1
        add x6, x6, 1
        b for_mode

    else_mode:
        cmp x4, x3
        bgt update_mode
        mov x4, 1
        add x7, x7, 1
        add x6, x6, 1
        b for_mode
    
    update_mode:
        mov x3, x4
        mov x2, x21
        mov x4, 1
        add x7, x7, 1
        add x6, x6, 1
        b for_mode
    
    end_mode:
        cmp x4, x3
        bgt save_mode
        ret
    
    save_mode:
        mov x2, x21
        ret

calculate_median:
    mov x7, 2
    udiv x8, x1, x7  // x8 = n // 2
    ands x9, x8, 1   // x9 = n % 2
    
    bne even_median
    lsl x10, x8, 3
    add x10, x10, x0

    ldr x11, [x10] // x11 = data[n/2]
    ret

even_median:
    lsl x10, x8, 3
    add x10, x10, x0

    ldr x11, [x10] // x11 = data[n/2]
    ldr x12, [x10, 8] // x12 = data[n/2 + 1]
    add x11, x11, x12
    udiv x11, x11,x7
    ret


// Función calcular_digitos: cuenta los digitos 


contar_digitos:
    bucle_dig:
        sdiv x4, x4, x2  // divide X4 por la bsea (10) y guarda el cociente en x4 y el resto en x5
        add x3, x3, 1    // incrementa el contador de digitos
        cmp x4, 0        // compara x4 con 0
        bne bucle_dig        // si x4 no es 0, salta a bucle
    ret   


// Función itoa: convierte un entero a string


itoa:
    bucle_itoa:
        udiv x4, x1, x2       // divide X1 por la base (10) y guarda el cociente en x4 
        msub x5, x4, x2, x1   // x5 = x1 - (x4 * x2)
        add x5, x5, 48        // convierte el resto en un caracter ascii
        strb w5, [x0, x3]     // guarda el caracter en la cadena con el offset x3
        sub x3, x3, 1         // decrementa el contador de digitos
        mov x1,x4             // x1 = x4
        cmp x1, 0             // compara x1 con 0
        bne bucle_itoa            // si x1 no es 0, salta a bucle2
    ret

save_output:
    mov x0, -100      // Descriptor de archivo (-100 indica que se abrirá un nuevo archivo)
    ldr x1, =output // Carga la dirección de 'filename' en x1
    mov x2, 101       // Flags para abrir el archivo (O_WRONLY | O_CREAT)
    mov x3, 0777      // Permisos del archivo
    mov x8, 56        // syscall number para open
    svc 0             // Llamada al sistema para abrir el archivo

    mov x9, x0        // Guarda el descriptor de archivo en x9

    mov x0, x9        // Carga el descriptor de archivo en x0
    ldr x1, =cadena  // Carga la dirección de 'content' en x1
    mov x2, x18       // Carga el número de bytes leídos en x2
    mov x8, 64        // syscall number para write
    svc 0             // Llamada al sistema para escribir en el archivo

    mov x0, x9        // Carga el descriptor de archivo en x0
    mov x8, 57        // syscall number para close
    svc 0             // Llamada al sistema para cerrar el archivo

    mov x8, 93        // Número de syscall para exit.
    mov x0, 0        // Código de salida.
    svc 0             // Invoca la syscall.
    ret