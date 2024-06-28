.global _start

.data
input: .asciz "entrada.csv"           
output: .asciz "salida.txt" 

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

    // Escribir el contenido del buffer en la salida estándar
    mov x0, 1         
    ldr x1, =buffer   
    mov x2, 1024      
    mov x8, 64        
    svc 0             

    // Inicializar variables
    mov x3, 0         
    mov x4, 0        
    mov x5, 0x7FFFFFFFFFFFFFFF 

    // Cerrar el archivo de entrada
    mov x0, x9        
    mov x8, 57        
    svc 0             

    // Encontrar el valor mínimo en el archivo
find_minimum:
    ldr x1, =buffer    
    ldrb w6, [x1, x3]  
    cmp w6, 44         
    beq compare_value  
    cmp w6, 0          
    beq load_data     

    sub w6, w6, 48     
    mov x5, 10         

    // Acumular el número
    mul x4, x4, x5     
    add x4, x4, w6     

    add x3, x3, 1      
    b find_minimum     

compare_value:
    cmp x4, x5        
    bge reset_value  
    mov x5, x4       
reset_value:
    mov x4, 0         
    add x3, x3, 1     
    b find_minimum    

load_data:
    // Convertir el valor mínimo a cadena ASCII
    ldr x0, =numstr   
    mov x1, x5        
    mov x2, 10        
    mov x3, 0         
    mov x11, 0        

getsize:
    udiv x4, x1, x2   
    add x3, x3, 1     
    cmp x4, 0         
    bne getsize       

    add x0, x0, x3    
    mov w6, 10        
    strb w6, [x0]     
    sub x0, x0, 1     
    add x3, x3, 1     
    mov x4, x1        

getdigits:
    udiv x6, x4, x2   
    msub x7, x6, x2, x4 
    add x7, x7, 48    
    strb w7, [x0]     
    sub x0, x0, 1     
    mov x4, x6        
    cmp x4, 0         
    bne getdigits     
    add x0, x0, 1     

// Imprimir el resultado en el archivo de salida
print:
    mov x0, -100      
    ldr x1, =output   
    mov x2, 101       
    mov x3, 0777      
    mov x8, 56       
    svc 0             
    mov x9, x0        

    mov x0, x9        
    ldr x1, =numstr   
    mov x2, x3        
    mov x8, 64        
    svc 0             

    // Cerrar el archivo de salida
    mov x0, x9        
    mov x8, 57        
    svc 0             

    // Salir del programa
exit:
    mov x0, 0         
    mov x8, 93        
    svc 0             

.data
numstr: .space 20    
                