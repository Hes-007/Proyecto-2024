.section .data
input_file:     .asciz "input.txt"    // Nombre del archivo de entrada
output_file:    .asciz "output.txt"   // Nombre del archivo de salida
buffer:         .space 1024           // Espacio reservado para el buffer de 1024 bytes
numbers:        .space 400            // Espacio para 100 números (4 bytes cada uno)
num_buffer:     .space 16             // Espacio reservado para el buffer del número de 16 bytes
buffer_salida:  .space 256            // Espacio reservado para el buffer de salida

.section .text
.global _start

_start:
    // Abrir input.txt para lectura
    mov x0, #-100               // AT_FDCWD (directorio actual)
    ldr x1, =input_file         // Dirección del nombre del archivo
    mov x2, #0                  // O_RDONLY (modo de solo lectura)
    mov x8, #56                 // syscall: openat (abrir archivo)
    svc #0                      // Llamada al sistema
    cbz x0, error               // Si x0 es cero, saltar a error
    mov x9, x0                  // Guardar el descriptor de archivo en x9

    // Leer del archivo
    mov x0, x9                  // Descriptor de archivo en x0
    ldr x1, =buffer             // Dirección del buffer en x1
    mov x2, #1024               // Tamaño del buffer en x2
    mov x8, #63                 // syscall: read (leer archivo)
    svc #0                      // Llamada al sistema
    cbz x0, error               // Si x0 es cero, saltar a error
    mov x19, x0                 // Guardar el número de bytes leídos en x19

    // Inicializar variables
    mov x20, #0                 // Contador de números
    ldr x1, =buffer             // Dirección del buffer en x1
    ldr x2, =numbers            // Dirección del array de números en x2
    ldr x3, =num_buffer         // Dirección del buffer del número en x3
    mov x4, x3                  // Puntero actual para escribir el número

parse_loop:
    ldrb w5, [x1], #1           // Leer un byte del buffer y avanzar
    cmp w5, #','                // Comparar con ','
    b.eq parse_number           // Si es ',', parsear el número
    cmp w5, #0                  // Comparar con el fin de cadena '\0'
    b.eq parse_number           // Si es '\0', parsear el número
    strb w5, [x4], #1           // Guardar el byte en el buffer del número y avanzar
    b parse_loop                // Continuar el bucle

parse_number:
    mov w0, #0                  // Terminar la cadena del número con '\0'
    strb w0, [x4]
    
    // Convertir la cadena a número
    ldr x0, =num_buffer         // Dirección del buffer del número en x0
    bl atoi                     // Convertir cadena a número
    
    // Guardar el número en el array
    str w0, [x2], #4            // Guardar el número en el array y avanzar
    add x20, x20, #1            // Incrementar contador de números
    
    mov x4, x3                  // Restablecer el puntero del buffer del número
    cmp w5, #0                  // Comprobar si hemos llegado al final
    b.ne parse_loop             // Si no, continuar el bucle

    // Ordenar los números (usando bubble sort)
    mov x21, x20                // x21 = número de elementos
    sub x21, x21, #1            // x21 = número de elementos - 1
outer_loop:
    mov x22, #0                 // x22 = índice actual
    ldr x23, =numbers           // x23 = dirección base del array
inner_loop:
    ldr w24, [x23]              // Cargar número actual
    ldr w25, [x23, #4]          // Cargar siguiente número
    cmp w24, w25                // Comparar números
    b.le no_swap                // Si están en orden, no intercambiar
    str w25, [x23]              // Intercambiar números
    str w24, [x23, #4]
no_swap:
    add x23, x23, #4            // Avanzar al siguiente par
    add x22, x22, #1            // Incrementar índice
    cmp x22, x21                // Comparar con número de elementos - 1
    b.lt inner_loop             // Si no hemos terminado, continuar bucle interno
    subs x21, x21, #1           // Decrementar contador externo
    b.gt outer_loop             // Si no hemos terminado, continuar bucle externo

    // Calcular la mediana
    lsr x21, x20, #1            // x21 = x20 / 2 (índice medio)
    ldr x22, =numbers           // x22 = dirección base del array
    lsl x23, x21, #2            // x23 = x21 * 4 (offset en bytes)
    add x22, x22, x23           // x22 = dirección del elemento medio
    tst x20, #1                 // Comprobar si el número de elementos es impar
    b.ne odd_count              // Si es impar, saltar
    // Número par de elementos
    ldr w24, [x22, #-4]         // Cargar elemento (n/2 - 1)
    ldr w25, [x22]              // Cargar elemento (n/2)
    add w24, w24, w25           // Sumar los dos elementos
    lsr w24, w24, #1            // Dividir por 2 para obtener la mediana
    b calculate_done
odd_count:
    // Número impar de elementos
    ldr w24, [x22]              // Cargar elemento medio (mediana)
calculate_done:
    mov x20, x24                // Guardar la mediana en x20

    // Convertir la mediana a cadena
    mov x0, x20                 // Pasa la mediana a x0
    ldr x1, =buffer_salida      // Dirección del buffer de salida en x1
    bl itoa                     // Llama a la función itoa

    // Abrir output.txt para escritura
    mov x0, #-100               // AT_FDCWD (directorio actual)
    ldr x1, =output_file        // Dirección del nombre del archivo
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644               // Permisos de archivo (rw-r--r--)
    mov x8, #56                 // syscall: openat (abrir archivo)
    svc #0                      // Llamada al sistema
    cbz x0, error               // Si x0 es cero, saltar a error
    mov x9, x0                  // Guardar el descriptor de archivo en x9

    // Escribir la mediana en el archivo
    mov x0, x9                  // Descriptor de archivo en x0
    ldr x1, =buffer_salida      // Dirección del buffer de salida en x1
    bl strlen                   // Calcular la longitud de la cadena
    mov x2, x0                  // Longitud de la cadena en x2
    mov x8, #64                 // syscall: write (escribir archivo)
    svc #0                      // Llamada al sistema

    // Cerrar archivo de salida
    mov x0, x9                  // Descriptor de archivo en x0
    mov x8, #57                 // syscall: close (cerrar archivo)
    svc #0                      // Llamada al sistema

    // Salir del programa
    mov x8, #93                 // syscall: exit (salir)
    svc #0

error:
    mov x8, #93                 // syscall: exit (salir)
    svc #0

// atoi: Convertir cadena a número
atoi:
    mov x1, #0                  // Inicializa acumulador
atoi_loop:
    ldrb w2, [x0], #1           // Leer siguiente carácter y avanzar
    cmp w2, #0                  // Comparar con fin de cadena
    beq atoi_done               // Si es fin de cadena, termina
    sub w2, w2, #'0'            // Convertir carácter a dígito
    mul x1, x1, #10             // Desplazar dígitos a la izquierda
    add x1, x1, x2              // Añadir nuevo dígito
    b atoi_loop                 // Continuar bucle
atoi_done:
    mov x0, x1                  // Resultado en x0
    ret

// itoa: Convertir número a cadena
itoa:
    mov x2, x1                  // Guardar buffer de salida en x2
    mov x3, #10                 // Base 10
    mov x4, x0                  // Guardar número en x4
itoa_loop:
    udiv x5, x4, x3             // División entera: x5 = x4 / 10
    msub x6, x5, x3, x4         // Módulo: x6 = x4 - x5 * 10
    add x6, x6, #'0'            // Convertir dígito a carácter
    strb w6, [x2], #-1          // Escribir carácter en el buffer
    mov x4, x5                  // Actualizar número
    cbz x5, itoa_done           // Si x5 es cero, termina
    b itoa_loop                 // Continuar bucle
itoa_done:
    // Invertir cadena
    mov x0, x2                  // Puntero al final de la cadena
    mov x1, x2                  // Puntero al inicio de la cadena
    add x1, x1, #15             // Máximo 15 dígitos
    mov w2, #0                  // Inicializa longitud de cadena
itoa_reverse:
    ldrb w3, [x0]               // Leer carácter
    cmp w3, #0                  // Comparar con fin de cadena
    beq itoa_reverse_done       // Si es fin de cadena, termina
    strb w3, [x1], #-1          // Escribir carácter en buffer
    add x0, x0, #1              // Avanzar puntero
    add x2, x2, #1              // Incrementar longitud
    b itoa_reverse              // Continuar bucle
itoa_reverse_done:
    mov x0, x1                  // Puntero al inicio de la cadena invertida
    sub x0, x0, #1              // Ajustar al inicio real
    mov x1, x2                  // Longitud de cadena en x1
    ret

// strlen: Calcular la longitud de la cadena
strlen:
    mov x2, x0                  // Guardar puntero inicial en x2
strlen_loop:
    ldrb w1, [x0], #1           // Leer siguiente carácter y avanzar
    cbz w1, strlen_done         // Si es fin de cadena, termina
    b strlen_loop               // Continuar bucle
strlen_done:
    sub x0, x0, x2              // Calcular longitud
    ret