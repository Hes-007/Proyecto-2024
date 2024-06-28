// Sección de datos
.section .data
input:           .asciz "input.txt"    
output:          .asciz "output.txt"  
data_buffer:     .space 256            
temp_buffer:     .space 16             
output_format:   .asciz "%d\n"         
newline_str:     .asciz "\n"           

// Sección de código
.section .text
.global _start

_start:

    // Abrir archivo de entrada
    mov x0, #-100               
    ldr x1, =input              
    mov x2, #0                  
    mov x8, #56                 
    svc #0                     
    cbz x0, exit_with_error     
    mov x10, x0                 

    // Leer del archivo
    mov x0, x10                
    ldr x1, =data_buffer        
    mov x2, #256                
    mov x8, #63                 
    svc #0                      
    cbz x0, exit_with_error    
    mov x11, x0                

    // Encontrar el valor mínimo
    mov x12, #0xFFFFFFFF        
    ldr x1, =data_buffer        
    ldr x2, =temp_buffer        
    mov x3, x2                  

process_buffer:
    ldrb w4, [x1], #1          
    cmp w4, #','                
    b.eq process_number         

    cmp w4, #0                 
    beq process_number          
    strb w4, [x3], #1           
    b process_buffer           

process_number:
    mov w0, #0                  
    strb w0, [x3]

    // Convertir la cadena a número
    ldr x0, =temp_buffer        
    bl string_to_int           

    // Evitar actualizar el mínimo si el número es 0
    cbz x0, reset_temp_buffer   

    // Comparar el número actual con el mínimo
    cmp x0, x12                 
    csel x12, x0, x12, lt       

reset_temp_buffer:
    // Restablecer el puntero del buffer temporal
    ldr x3, =temp_buffer
    cmp w4, #0                 
    beq write_output
    b process_buffer           

write_output:
    // Convertir el mínimo a cadena
    mov x0, x12                 
    ldr x1, =data_buffer       
    bl int_to_string            

    // Abrir archivo de salida
    mov x0, #-100               
    ldr x1, =output    
    mov x2, #577                
    mov x3, #0644               
    mov x8, #56                 
    svc #0                      
    cbz x0, exit_with_error     
    mov x13, x0                 

    // Escribir el mínimo en el archivo
    mov x0, x13                 
    ldr x1, =data_buffer        
    bl write_to_file            
    // Cerrar los archivos
    mov x0, x10                
    mov x8, #57                 
    svc #0                      

    mov x0, x13                 
    mov x8, #57                 
    svc #0                      

    // Salir del programa
    mov x0, #0                  
    mov x8, #93                 
    svc #0                      

exit_with_error:
    // Manejar error y salir
    mov x0, #-1                 
    mov x8, #93                 
    svc #0                     

// Función string_to_int (convertir cadena a número)
string_to_int:

    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Inicialización
    mov x2, #0                  

string_loop:
    ldrb w3, [x0], #1           
    sub w3, w3, #'0'            
    cmp w3, #9                  
    bhi string_end              
    mov x4, #10
    mul x2, x2, x4              
    add x2, x2, x3              
    b string_loop               

string_end:
    mov x0, x2                  
    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret                         

// Función int_to_string (convertir número a cadena)

int_to_string:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Inicialización
    mov x2, #10                
    mov x3, x1                  
    mov x4, x0                  

itoa_loop:
    udiv x0, x4, x2             
    msub x5, x0, x2, x4        
    add x5, x5, #'0'            
    strb w5, [x3], #1          
    mov x4, x0                 
    cbz x0, itoa_end            

    b itoa_loop                 

itoa_end:
    strb w0, [x3]               

    // Invertir la cadena en el buffer
    sub x1, x3, x1              
    mov x5, x1                  
    mov x1, x3                  
    ldr x6, =data_buffer        
    ldr x7, =data_buffer + 256  

reverse_string:
    sub x1, x1, #1              
    ldrb w0, [x1]               
    strb w0, [x6], #1           
    cmp x6, x1                  
    b.cc reverse_string         

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret                         

// Función write_to_file (escribe la cadena en el archivo de salida)

write_to_file:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                

    // Inicialización
    mov x2, x5                 

    mov x8, #64                 
    svc #0                     

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret                        