.section .data
input_file:    .asciz "input.txt"
mode:          .asciz "r"
output_file:   .asciz "output.txt"    // Nombre del archivo de salida
write_mode:    .asciz "w"             // Modo de apertura del archivo de salida (escritura)
buffer:        .space 1000
result_msg:    .asciz "Suma total: %d\n"
actual_msg:    .asciz "Actual: %d\n"
next_msg:      .asciz "Siguiente: %d\n"
count_msg:     .asciz "Cantidad de números: %d\n"
prom_msg:      .asciz "Promedio: %.2f\n"
error_msg:     .asciz "Error al abrir el archivo\n"
write_error_msg: .asciz "Error al escribir el archivo\n"  // Mensaje de error al escribir

.section .text
.global _start

.extern fopen
.extern fread
.extern fclose
.extern fprintf

_start:
    // Abrir el archivo de entrada
    ldr x0, =input_file  
    ldr x1, =mode        
    bl fopen             
    cbz x0, file_error   
    mov x19, x0          

    // Leer el archivo
    ldr x0, =buffer      
    mov x1, 1            
    mov x2, 1000         
    mov x3, x19          
    bl fread             

    // Cerrar el archivo de entrada
    mov x0, x19          
    bl fclose            

    // Inicializar variables
    mov x20, #0          
    mov x27, #1          

    // Obtener el buffer
    ldr x1, =buffer      

parse_loop:
    ldrb w2, [x1], #1    
    cmp w2, #','         
    beq parse_next       

    cmp w2, #0           
    beq parse_end        

    cbnz w2, parse_number

parse_number:
    sub x1, x1, #1       
    mov x0, x1           
    bl atoi              

    mov x21, x0          

    mov x22, x1          

    ldr x0, =actual_msg  
    mov x1, x21          
    bl printf            

    mov x1, x22          

    add x20, x20, x21    
    ldr x0, =buffer      
    mov x1, x22          

    add x1, x1, #1       

    ldrb w2, [x1], #1    
    cmp w2, #0           
    beq parse_end        

    cmp w2, #','         
    beq parse_next       

    cbnz w2, parse_number

parse_next:
    add x27, x27, #1     
    cbz x1, parse_end    
    b parse_loop         

parse_end:
    ldr x0, =result_msg  
    mov x1, x20          
    bl printf            

    ldr x0, =count_msg   
    mov x1, x27          
    bl printf            

    fmov d0, x20         
    fmov d2, x27         
    fdiv d0, d0, d2      

    ldr x0, =prom_msg    
    fmov s0, d0          
    bl printf            

    // Guardar el promedio en archivo de salida
    ldr x0, =output_file  
    ldr x1, =write_mode   
    bl fopen              
    cbz x0, write_error   
    mov x19, x0           

    // Escribir el promedio
    ldr x0, =prom_msg     
    fmov w1, s0           
    mov x2, x19           
    bl fprintf            

    // Cerrar el archivo de salida
    mov x0, x19           
    bl fclose             

    // Salir del programa
    mov x8, 93           
    svc 0                

file_error:
    ldr x0, =error_msg   
    bl printf            
    b parse_end

write_error:
    ldr x0, =write_error_msg   
    bl printf            
    b parse_end

// Función atoi (convertir cadena a número)
atoi:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Inicialización
    mov x2, #0                  

atoi_loop:
    ldrb w3, [x0], #1           
    sub w3, w3, #'0'            
    cmp w3, #9                  
    bhi atoi_end                
    mov x4, #10
    mul x2, x2, x4              
    add x2, x2, x3              
    b atoi_loop                 

atoi_end:
    mov x0, x2                  

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret                 