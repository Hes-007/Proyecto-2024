// Sección de datos
.section .data
input:          .asciz "proyecto2/backend/presionbarometrica/temperatura.txt"      
output:         .asciz "proyecto2/backend/presionbarometrica/maximoOutput2.txt"   
data_buffer:    .space 256                
number_buffer:  .space 16                 
output_format:  .asciz "%d\n"             
newline_char:   .asciz "\n"               

.section .text
.global _start

_start:
    // Abrir input.txt para lectura
    mov x0, #-100               
    ldr x1, =input              
    mov x2, #0                  
    mov x8, #56                 
    svc #0                      
    cbz x0, handle_error        
    mov x20, x0                 

    // Leer del archivo
    mov x0, x20                
    ldr x1, =data_buffer        
    mov x2, #256                
    mov x8, #63                 
    svc #0                      
    cbz x0, handle_error       
    mov x21, x0                 

    // Calcular el máximo de los números en el CSV
    mov x22, #0                 
    ldr x1, =data_buffer        
    ldr x2, =number_buffer     
    mov x3, x2                  

process_loop:
    ldrb w4, [x1], #1           
    cmp w4, #','                
    b.eq process_number        

    cmp w4, #0                  
    beq process_number          
    strb w4, [x3], #1           
    b process_loop              

process_number:
    mov w0, #0                  
    strb w0, [x3]

    // Convertir la cadena a número
    ldr x0, =number_buffer      
    bl convert_string_to_int    

    // Evitar actualizar el máximo si el número es 0
    cbz x0, reset_number_buffer 

    // Comparar el número actual con el máximo
    cmp x0, x22                 
    csel x22, x0, x22, gt       

reset_number_buffer:
    // Restablecer el puntero del buffer del número
    ldr x3, =number_buffer
    cmp w4, #0                 
    beq finalize_processing
    b process_loop              

finalize_processing:
    // Convertir el máximo a cadena
    mov x0, x22                 
    ldr x1, =data_buffer        
    bl convert_int_to_string    

    // Abrir output.txt para escritura
    mov x0, #-100              
    ldr x1, =output             
    mov x2, #577                
    mov x3, #0644              
    mov x8, #56                 
    svc #0                      
    cbz x0, handle_error        
    mov x23, x0                 

    // Escribir el máximo en el archivo
    mov x0, x23                
    ldr x1, =data_buffer        
    bl write_buffer_to_file     

    // Cerrar los archivos
    mov x0, x20                 
    mov x8, #57                 
    svc #0                      

    mov x0, x23                
    mov x8, #57                 
    svc #0                     

    // Salir del programa
    mov x0, #0                  
    mov x8, #93                 
    svc #0                     

handle_error:
    // Manejar error y salir
    mov x0, #-1                 
    mov x8, #93                 
    svc #0                      

// Función convert_string_to_int (convertir cadena a número)

convert_string_to_int:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Inicialización
    mov x2, #0                  

string_to_int_loop:
    ldrb w3, [x0], #1          
    sub w3, w3, #'0'            
    cmp w3, #9                  
    bhi string_to_int_end       
    mov x4, #10
    mul x2, x2, x4              
    add x2, x2, x3              
    b string_to_int_loop        

string_to_int_end:
    mov x0, x2                  

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16    
    ret                         

// Función convert_int_to_string (convertir número a cadena)
convert_int_to_string:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Inicialización
    mov x2, #10                
    mov x3, x1                 
    mov x4, x0                  

int_to_string_loop:
    udiv x0, x4, x2             
    msub x5, x0, x2, x4         
    add x5, x5, #'0'            
    strb w5, [x3], #1          
    mov x4, x0                  
    cbz x0, int_to_string_end   

    b int_to_string_loop        
int_to_string_end:
    strb w0, [x3]              

    // Invertir la cadena en el buffer
    sub x3, x3, #1
    mov x4, x1                  
    mov x5, x3                  
reverse_string:
    ldrb w6, [x4]               
    ldrb w7, [x5]               
    strb w7, [x4]               
    strb w6, [x5]               
    add x4, x4, #1              
    sub x5, x5, #1              
    cmp x4, x5                  
    blo reverse_string          

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret                         

// Función write_buffer_to_file (escribir buffer en archivo)
write_buffer_to_file:
    // Guardar registros de retorno
    stp x29, x30, [sp, #-16]!   
    mov x29, sp                 

    // Calcular la longitud de la cadena
    mov x2, #0
calculate_length:
    ldrb w3, [x1, x2]           
    cbz w3, calculate_done      
    add x2, x2, #1              
    b calculate_length          

calculate_done:
    // Escribir la cadena
    mov x8, #64                
    svc #0                      

    // Restaurar registros de retorno
    ldp x29, x30, [sp], #16     
    ret   