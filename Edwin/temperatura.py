# Prueba conexion con front y assembnler
from flask import Flask, jsonify
from flask_cors import CORS
import time 
import os
import subprocess

app = Flask(__name__)
CORS(app)

contadorTemperatura = 0
temperature_rounded = 0

try:
    from smbus2 import SMBus
except ImportError:
    from smbus import SMBus
from bmp280 import BMP280

print("Iniciando el sensor BMP280 para medir temperatura \n")


def escribir_archivo(temperature_rounded):
    print("Se crea el archivo vacio")
    global contadorTemperatura
    file_path = 'proyecto2/backend/presionbarometrica/temperatura.txt'
    try:
        # Limpiar el archivo si contadorViento es 0 y el archivo existe
        if contadorTemperatura == 0 and os.path.exists(file_path):
            with open(file_path, 'w') as file:
                file.truncate(0)
            print("Se limpio el archivo")

        # Escribir la temperatura en el archivo
        with open(file_path, 'a') as file:
            if contadorTemperatura > 0:
                file.write(',')
            file.write(f"{temperature_rounded}")
    except Exception as e:
        print(f"Error al escribir en el archivo: {e}")

def actualizar_archivo(temperature_rounded):
    file_path = 'proyecto2/backend/presionbarometrica/temperatura.txt'
    try:
        with open(file_path, 'r+') as file:
            data = file.read().strip()  # Leer y eliminar espacios en blanco al inicio y final
            temperaturas = data.split(',')
            if temperaturas[-1] == '':
                temperaturas.pop()  # Eliminar elemento vacio si existe

            # Agregar nueva velocidad y limitar a 10 elementos
            temperaturas.append(str(temperature_rounded))
            if len(temperaturas) > 70:
                temperaturas.pop(0)  # Eliminar el primer elemento si hay mas de 10

            # Rebobinar el archivo y escribir los datos actualizados
            file.seek(0)
            file.write(','.join(temperaturas))
            file.truncate()
    except Exception as e:
        print(f"Error al actualizar el archivo: {e}")

def execucatePromedio2(): 
    print("exceutePromedio")
    try: 
      with open('proyecto2/backend/presionbarometrica/promedio_temperatura.txt', 'w') as f: 
         subprocess.run(['stdbuf','-oL', 'proyecto2/backend/presionbarometrica/promedio2'], stdout=f)  
    except Exception as e:
        print(f"Error al obtener el promedio: {e}")



def ejecutarMaximo2():
    print('Suma!')
    try: 
        print("exucteMaximo")
        subprocess.run(['proyecto2/backend/presionbarometrica/maximo'])
        print("Ejecutado maximo")
    except Exception as e:
        print(f"Error al obtener el maximo: {e}")

def ejecutarMinimo2():
    print('Suma!')
    try: 
        print("exucteMinimo")
        subprocess.run(['proyecto2/backend/presionbarometrica/minimo'])
        print("Minimo ejecutado")
    except Exception as e:
        print(f"Error al obtener el minimo: {e}")

def ejecutarMeMod2():
    print('Media,Moda!')
    try: 
        print("executeMedMOd")
        subprocess.run(['proyecto2/backend/presionbarometrica/entero'])
        print("Ejecutado medMOd")
    except Exception as e:
        print(f"Error al obtener el medo: {e}")





def leerMinimo2(): 
    path = "proyecto2/backend/presionbarometrica/outputMinimo2.txt"
    with open(path, 'r') as file:
        lineas = file.readlines()
        if lineas:  # Verifica si hay l�neas en el archivo
            minimo = lineas[0].strip()  # Lee la primera l�nea y elimina espacios en blanco
            return minimo  # Devuelve el valor le�do
        else:
            return 0  # Devuelve None si el archivo est� vac�o
    
def leerMaximo2(): 
    path = "proyecto2/backend/velocidadviento/maximoOutput2.txt"
    with open(path, 'r') as file:
        lineas = file.readlines()
        if lineas:  # Verifica si hay l�neas en el archivo
            maximo = lineas[0].strip()  # Lee la primera l�nea y elimina espacios en blanco
            return maximo  # Devuelve el valor le�do
        else:
            return 0  # Devuelve None si el archivo est� vac�o
def leerMedMod2(): 
    path = "proyecto2/backend/velocidadviento/outputMedMod2.txt"
    try:
        with open(path, 'r') as file:
            datos = file.read().strip()
        lista = [int(num) for num in datos.split(',')]
        
        # Aseg�rate de que la lista tenga al menos dos elementos
        if len(lista) < 2:
            raise ValueError("El archivo no contiene suficientes datos.")
        
        variable1 = lista[0]
        variable2 = lista[1]

        return variable1, variable2

    except FileNotFoundError:
        print(f"El archivo en la ruta {path} no se encontr�.")
        return 0, 0
    except ValueError as ve:
        print(f"Error al procesar los datos: {ve}")
        return 0, 0



#@app.route('/presionbarometrica', methods=['GET'])
def temperatura():
    global temperature_rounded,contadorTemperatura
    print("Iniciando las mediciones de temperatura")
    # Iniciamos la comunicación con el sensor BMP280
    bus = SMBus(1)
    bmp280 = BMP280(i2c_dev=bus)

    # Tomamos una medición de presión
    temperature = bmp280.get_temperature()
    temperature_rounded = round(temperature)  # Redondeamos a número entero
    print(f"Temperatura actual: {temperature_rounded} *C")

    if contadorTemperatura <= 70: 
        escribir_archivo(int(temperature_rounded))
    else:
        print("Eliminar el primer valor y agregar nuevo valor de ultimo")
        print("mayor a 20 ")
        actualizar_archivo(int(temperature_rounded))
    contadorTemperatura  +=1
    print("Contador Presion: ", contadorTemperatura)

    #return jsonify({"velocidad": pressure_rounded}), 200
    return temperature_rounded

def leer_datos_temp():
    path = "proyecto2/backend/presionbarometrica/promedio_temperatura.txt"
    with open(path, 'r') as file:
        lineas = file.readlines()
        
    conteo2 = 0
    promedio2 = 0

    for linea in lineas:
        if linea.startswith("Conteo: "):
            conteo2 = int(linea.split(":")[1].strip())
        elif linea.startswith("Promedio: "):
            promedio2 = float(linea.split(":")[1].strip())

    return conteo2, promedio2




"""import time

try:
    from smbus2 import SMBus
except ImportError:
    from smbus import SMBus
from bmp280 import BMP280

print("Iniciando las mediciones de presión")

def termometro():
    # Iniciamos la comunicación con el sensor BMP280
    bus = SMBus(1)
    bmp280 = BMP280(i2c_dev=bus)

    # Iniciamos las lecturas, descartando el primer valor de calibración
    #temperature = bmp280.get_temperature()
    #print("Comienzo de lectura en 2 segundos")
    #time.sleep(2)

    # Creamos o limpiamos el archivo CSV antes de empezar a escribir
    with open("temperatura.csv", "w") as temperature_file:
        pass

    # Tomamos una medición de la temperatura 
    temperature = bmp280.get_temperature()
    temperature_rounded = round(temperature)  # Redondeamos a numero entero
    print(f"Temperatura actual: {temperature_rounded} *C")

    # Abrimos el archivo en modo append y escribimos la presion seguida de una coma
    with open("temperatura.csv", "a") as temperature_file:
        temperature_file.write(f"{temperature_rounded},") 

    return temperature_rounded 
"""

