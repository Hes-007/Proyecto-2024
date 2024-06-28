.global _start

.data
input: .asciz "calidad_buena.csv"
output: .asciz "resultado_calidad_buena.txt"

.bss
buffer: .skip 1024

.text
_start:
    // Abrir el archivo de entrada
    mov x0, -100
    ldr x1, =input
    mov x2, 0
    mov x8, 56
    svc 0
    mov x9, x0

    // Leer el archivo de entrada
    mov x0, x9
    ldr x1, =buffer
    mov x2, 1024
    mov x8, 63
    svc 0

    // Inicializar variables
    mov x3, 0        // Índice para recorrer el buffer
    mov x4, 0        // Variable para almacenar el mínimo encontrado
    mov x5, 0x7FFFFFFFFFFFFFFF // Valor inicial alto para comparación

    // Encontrar el valor mínimo en el archivo
find_minimum:
    ldr x1, =buffer
    ldrb w6, [x1, x3]
    cmp w6, 44        // Coma en ASCII
    beq compare_value
    cmp w6, 0         // Fin de archivo
    beq print_result

    sub w6, w6, 48    // Convertir dígito ASCII a valor numérico
    mov x7, 10        // Base 10 para multiplicar

    // Acumular el número
    mul x4, x4, x7
    uxtw x6, w6       // Extender el valor de 8 bits a 64 bits
    add x4, x4, x6    // Sumar el dígito al valor acumulado

    add x3, x3, 1     // Avanzar en el buffer
    b find_minimum

compare_value:
    cmp x4, x5        // Comparar con el valor actual mínimo
    bge reset_value   // Saltar si no es menor
    mov x5, x4        // Actualizar el valor mínimo encontrado

reset_value:
    mov x4, 0         // Reiniciar valor acumulado
    add x3, x3, 1     // Avanzar en el buffer
    b find_minimum

print_result:
    // Convertir el valor mínimo a cadena ASCII en numstr
    ldr x0, =numstr
    mov x1, x5        // Valor mínimo a convertir
    mov x2, 10        // Base 10
    mov x3, 0         // Índice de cadena ASCII
    mov x11, 0        // Longitud de cadena

getsize:
    udiv x4, x1, x2   // Dividir por 10
    add x3, x3, 1     // Incrementar longitud de cadena
    cmp x4, 0         // Comprobar si se ha dividido todo
    bne getsize

    add x0, x0, x3    // Ajustar puntero al final de la cadena
    mov w6, 10        // Carácter de nueva línea
    strb w6, [x0]     // Agregar nueva línea al final
    sub x0, x0, 1     // Retroceder para almacenar el número
    add x3, x3, 1     // Incrementar longitud de cadena
    mov x4, x1        // Restaurar valor mínimo
    mov x5, 0         // Contador de dígitos

getdigits:
    udiv x6, x4, x2   // Dividir por 10
    msub x7, x6, x2, x4 // Obtener el dígito
    add x5, x5, 1     // Incrementar contador de dígitos
    strb w7, [x0]     // Almacenar dígito convertido
    sub x0, x0, 1     // Retroceder en la cadena
    mov x4, x6        // Actualizar valor para dividir
    cmp x4, 0         // Comprobar si se han convertido todos los dígitos
    bne getdigits
    add x0, x0, 1     // Avanzar puntero

// Imprimir el resultado en el archivo de salida
print:
    mov x0, -100
    ldr x1, =output
    mov x2, 101       // Modo de creación y escritura
    mov x3, 0777      // Permisos del archivo
    mov x8, 56        // syscall: openat
    svc 0
    mov x9, x0        // Guardar el descriptor de archivo

    mov x0, x9        // Descriptor de archivo
    ldr x1, =numstr   // Dirección de la cadena a imprimir
    mov x2, x11       // Longitud de la cadena
    mov x8, 64        // syscall: write
    svc 0

    // Cerrar el archivo de salida
    mov x0, x9        // Descriptor de archivo
    mov x8, 57        // syscall: close
    svc 0

    // Salir del programa
exit:
    mov x0, 0
    mov x8, 93        // syscall: exit
    svc 0

.data
numstr: .space 20    // Espacio para la cadena ASCII
