.section .data
input_file:    .asciz "entrada.csv"   // Nombre del archivo de entrada
mode:          .asciz "r"             // Modo de apertura del archivo (lectura)
buffer:        .space 1024            // Espacio para leer el contenido del archivo
output_file:   .asciz "salida.txt"    // Nombre del archivo de salida
min_msg:       .asciz "Mínimo: %d\n"  // Mensaje para mostrar el mínimo
error_msg:     .asciz "Error al abrir el archivo\n" // Mensaje de error al abrir el archivo
.section .text
.global _start

.extern fopen
.extern fread
.extern fclose
.extern printf

_start:
    // Abrir el archivo de entrada
    ldr x0, =input_file    // Cargar la dirección del nombre del archivo de entrada
    ldr x1, =mode          // Cargar el modo de apertura del archivo
    bl fopen               // Llamar a la función fopen
    cbz x0, file_error     // Manejar el error si fopen devuelve 0
    mov x19, x0            // Guardar el puntero al archivo abierto en x19

    // Leer el archivo
    ldr x0, =buffer        // Cargar la dirección del buffer de lectura
    mov x1, 1              // Tamaño de lectura (1 byte)
    mov x2, 1024           // Número máximo de elementos a leer
    mov x3, x19            // Cargar el puntero al archivo en x3
    bl fread               // Llamar a la función fread

    // Cerrar el archivo de entrada
    mov x0, x19            // Cargar el puntero al archivo a cerrar
    bl fclose

    // Inicializar variables para encontrar el mínimo
    mov x20, 0x7FFFFFFFFFFFFFFF  // Inicializar con un valor alto para comparación (MAX_INT64)
    mov x21, 0                  // Variable para almacenar el mínimo encontrado

    // Obtener el buffer
    ldr x1, =buffer         // Cargar la dirección del buffer
    mov x3, 0               // Índice para recorrer el buffer

find_minimum:
    ldrb w2, [x1, x3]       // Leer el byte actual del buffer
    cmp w2, 0               // Comprobar el fin de archivo
    beq print_result        // Si es el fin de archivo, imprimir el mínimo encontrado
    
    cmp w2, 44              // Comparar con coma (',')
    beq next_char           // Si es una coma, ir al siguiente carácter
    
    sub w2, w2, 48          // Convertir el carácter ASCII a número
    uxtw x4, w2             // Extender w2 a un registro de 64 bits x4
    cmp x21, x4             // Comparar el mínimo actual con el número leído
    csel x21, x21, x4, lt   // Actualizar x21 si el número leído es menor
    
next_char:
    add x3, x3, 1           // Avanzar en el buffer
    b find_minimum          // Continuar buscando el mínimo

print_result:
    // Imprimir el mínimo encontrado
    ldr x0, =min_msg        // Cargar la dirección del mensaje de mínimo
    mov x1, x21             // Cargar el mínimo encontrado en x1
    bl printf               // Llamar a printf para imprimir el mínimo

    // Abrir el archivo de salida
    ldr x0, =output_file    // Cargar la dirección del nombre del archivo de salida
    ldr x1, =mode           // Cargar el modo de apertura del archivo (escritura)
    mov x2, 101             // Modo de creación y escritura
    mov x3, 0777            // Permisos del archivo
    bl fopen                // Llamar a la función fopen para abrir el archivo de salida
    cbz x0, file_error_out  // Manejar el error si fopen devuelve 0
    mov x19, x0             // Guardar el puntero al archivo de salida en x19

    // Convertir el mínimo a cadena ASCII y escribirlo en el archivo de salida
    ldr x0, =buffer         // Cargar la dirección del buffer con el mínimo convertido
    ldr x1, =output_file    // Cargar la dirección del nombre del archivo de salida
    mov x2, 12              // Tamaño de la cadena (suficiente para el mínimo)
    bl itoa                 // Llamar a la función itoa para convertir el mínimo a cadena ASCII

    // Escribir la cadena en el archivo de salida
    ldr x0, =buffer         // Cargar la dirección del buffer con la cadena convertida
    ldr x1, =output_file    // Cargar la dirección del nombre del archivo de salida
    mov x2, 12              // Tamaño de la cadena (suficiente para el mínimo)
    mov x3, x19             // Cargar el puntero al archivo de salida en x3
    bl fwrite               // Llamar a la función fwrite para escribir en el archivo

    // Cerrar el archivo de salida
    mov x0, x19             // Cargar el puntero al archivo de salida a cerrar
    bl fclose

    // Salir del programa
    mov x8, 93              // syscall: exit
    svc 0                   // Llamar al sistema para salir

file_error:
    ldr x0, =error_msg      // Cargar la dirección del mensaje de error de archivo
    bl printf               // Llamar a printf para imprimir el mensaje de error
    b exit_program          // Saltar a la salida del programa en caso de error

file_error_out:
    ldr x0, =error_msg      // Cargar la dirección del mensaje de error de archivo
    bl printf               // Llamar a printf para imprimir el mensaje de error
    b exit_program_out      // Saltar a la salida del programa en caso de error al escribir

// Función itoa (convertir número a cadena)
itoa:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   // Guardar x29 y x30 en la pila
    mov x29, sp                 // Actualizar el puntero de marco de pila

    // Inicialización
    mov x2, 0                   // Inicializar contador de caracteres

itoa_loop:
    udiv x1, x1, x8             // Dividir el número por 10
    msub x3, x1, x8, x1         // Calcular el dígito
    add x2, x2, 1               // Incrementar el contador de caracteres
    strb w3, [x0, x2]           // Almacenar el dígito convertido
    cmp x1, 0                   // Comprobar si se ha dividido todo
    b.ne itoa_loop              // Repetir el ciclo si no se ha dividido todo

    // Agregar el carácter de nueva línea al final
    mov w3, 10                  // Carácter de nueva línea
    strb w3, [x0, x2]           // Agregar nueva línea al final
    add x2, x2, 1               // Incrementar el contador de caracteres

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     // Restaurar x29 y x30 desde la pila
    ret                         // Retornar de la función

exit_program:
    // Salir del programa en caso de error
    mov x8, 93                  // syscall: exit
    svc 0                       // Llamar al sistema para salir

exit_program_out:
    // Salir del programa en caso de error al escribir
    mov x8, 93                  // syscall: exit
    svc 0                       // Llamar al sistema para salir