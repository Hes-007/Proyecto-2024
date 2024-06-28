.section .data
input_file:     .asciz "input.txt"    // Nombre del archivo de entrada
output_file:    .asciz "output.txt"   // Nombre del archivo de salida
buffer:         .space 256            // Espacio reservado para el buffer de 256 bytes
num_buffer:     .space 16             // Espacio reservado para el buffer del número de 16 bytes
format_sum:     .asciz "%d\n"         // Formato de salida para la suma
newline:        .asciz "\n"           // Cadena de nueva línea

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
    mov x2, #256                // Tamaño del buffer en x2
    mov x8, #63                 // syscall: read (leer archivo)
    svc #0                      // Llamada al sistema
    cbz x0, error               // Si x0 es cero, saltar a error
    mov x19, x0                 // Guardar el número de bytes leídos en x19

    // Calcular el máximo de los números en el CSV
    mov x20, #0                 // Inicializar el máximo en 0
    ldr x1, =buffer             // Dirección del buffer en x1
    ldr x3, =num_buffer         // Dirección del buffer del número en x3
    mov x4, x3                  // Puntero actual para escribir el número

parse_loop:
    ldrb w2, [x1], #1           // Leer un byte del buffer y avanzar
    cmp w2, #','                // Comparar con ','
    b.eq parse_number           // Si es ',', procesar el número

    cmp w2, #0                  // Comparar con el fin de cadena '\0'
    beq parse_number            // Si es '\0', procesar el número
    strb w2, [x4], #1           // Guardar el byte en el buffer del número y avanzar
    b parse_loop                // Continuar el bucle

parse_number:
    mov w0, #0                  // Terminar la cadena del número con '\0'
    strb w0, [x4]

    // Convertir la cadena a número
    ldr x0, =num_buffer         // Dirección del buffer del número en x0
    bl atoi                     // Convertir cadena a número

    // Evitar actualizar el máximo si el número es 0
    cbz x0, reset_buffer        // Si el número es 0, saltar a reset_buffer

    // Comparar el número actual con el máximo
    cmp x0, x20                 // Rn - Operand 2. Compare and update flags
    csel x20, x0, x20, gt       // Si x0 > x20, actualizar x20, si no, mantener x20

reset_buffer:
    // Restablecer el puntero del buffer del número
    ldr x4, =num_buffer
    cmp w2, #0                  // Si encontramos fin de cadena, salir
    beq parse_end
    b parse_loop                // Continuar el bucle

parse_end:
    // Convertir el máximo a cadena
    mov x0, x20                 // Pasa el máximo a x0
    ldr x1, =buffer             // Dirección del buffer en x1
    bl itoa                     // Llama a la función itoa

    // Abrir output.txt para escritura
    mov x0, #-100               // AT_FDCWD (directorio actual)
    ldr x1, =output_file        // Dirección del nombre del archivo
    mov x2, #577                // O_WRONLY | O_CREAT | O_TRUNC (modo escritura, crear archivo, truncar archivo)
    mov x3, #0644               // Permisos del archivo
    mov x8, #56                 // syscall: openat (abrir archivo)
    svc #0                      // Llamada al sistema
    cbz x0, error               // Si x0 es cero, saltar a error
    mov x10, x0                 // Guardar el descriptor de archivo en x10

    // Escribir el máximo en el archivo
    mov x0, x10                 // Descriptor de archivo en x0
    ldr x1, =buffer             // Dirección del buffer en x1
    bl write_string             // Llama a la función write_string

    // Cerrar los archivos
    mov x0, x9                  // Descriptor de input.txt en x0
    mov x8, #57                 // syscall: close (cerrar archivo)
    svc #0                      // Llamada al sistema

    mov x0, x10                 // Descriptor de output.txt en x0
    mov x8, #57                 // syscall: close (cerrar archivo)
    svc #0                      // Llamada al sistema

    // Salir del programa
    mov x0, #0                  // Código de salida en x0
    mov x8, #93                 // syscall: exit (salir del programa)
    svc #0                      // Llamada al sistema

error:
    // Manejar error y salir
    mov x0, #-1                 // Código de salida de error en x0
    mov x8, #93                 // syscall: exit (salir del programa)
    svc #0                      // Llamada al sistema

// Función atoi (convertir cadena a número)
atoi:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   // Guardar x29 y x30 en la pila
    mov x29, sp                 // Actualizar el puntero de marco de pila

    // Inicialización
    mov x2, #0                  // resultado = 0

atoi_loop:
    ldrb w3, [x0], #1           // Leer un byte de x0 y postincrementar
    sub w3, w3, #'0'            // Convertir carácter a dígito
    cmp w3, #9                  // Comparar si el dígito está en el rango 0-9
    bhi atoi_end                // Si no está en el rango, terminar
    mov x4, #10
    mul x2, x2, x4              // resultado *= 10
    add x2, x2, x3              // resultado += dígito
    b atoi_loop                 // Repetir el ciclo

atoi_end:
    mov x0, x2                  // Poner el resultado en x0

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     // Restaurar x29 y x30 desde la pila
    ret                         // Retornar de la función

// Función itoa (convertir número a cadena)
itoa:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   // Guardar x29 y x30 en la pila
    mov x29, sp                 // Actualizar el puntero de marco de pila

    // Inicialización
    mov x2, #10                 // base = 10
    mov x3, x1                  // Puntero de inicio del buffer
    mov x4, x0                  // Número original

itoa_loop:
    udiv x0, x4, x2             // x0 = x4 / 10
    msub x5, x0, x2, x4         // x5 = x4 - x0 * 10 (resto)
    add x5, x5, #'0'            // Convertir el dígito a carácter
    strb w5, [x3], #1           // Escribir el carácter en el buffer
    mov x4, x0                  // x4 = x0 (dividido por 10)
    cbz x0, itoa_end            // Si x0 es 0, terminar

    b itoa_loop                 // Repetir el ciclo

itoa_end:
    strb w0, [x3]               // Terminar cadena con '\0'

    // Invertir la cadena en el buffer
    sub x3, x3, #1
    mov x4, x1                  // Puntero al inicio del buffer
    mov x5, x3                  // Puntero al final del buffer
itoa_reverse:
    ldrb w6, [x4]               // Leer carácter del inicio
    ldrb w7, [x5]               // Leer carácter del final
    strb w7, [x4]               // Escribir carácter del final al inicio
    strb w6, [x5]               // Escribir carácter del inicio al final
    add x4, x4, #1              // Avanzar hacia adelante
    sub x5, x5, #1              // Retroceder hacia atrás
    cmp x4, x5                  // Comparar punteros
    blo itoa_reverse            // Repetir si no se cruzan

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     // Restaurar x29 y x30 desde la pila
    ret                         // Retornar de la función

// Función write_string (escribir cadena)
write_string:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   // Guardar x29 y x30 en la pila
    mov x29, sp                 // Actualizar el puntero de marco de pila

    // Calcular la longitud de la cadena
    mov x2, #0
strlen_loop:
    ldrb w3, [x1, x2]           // Leer byte desde x1 más offset x2
    cbz w3, strlen_done         // Si el byte es cero (fin de cadena), terminar
    add x2, x2, #1              // Incrementar la longitud
    b strlen_loop               // Repetir el ciclo

strlen_done:
    // Escribir la cadena
    mov x8, #64                 // syscall: write (escribir)
    svc #0                      // Llamada al sistema

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     // Restaurar x29 y x30 desde la pila
    ret                         // Retornar de la función