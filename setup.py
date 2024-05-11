import sys
import tkinter as tk
from PIL import Image, ImageTk
import subprocess
import os

#Recibir una variable del bash anterior
#aurhelper = sys.argv[1]
aurhelper = "yay"

def ejecutar_scripts():
    # Obtener los scripts seleccionados
    scripts_seleccionados = [script_nombre for script_nombre, var in zip(scripts, lista_scripts) if var.get() == 1]

    # Ejecutar cada script seleccionado
    for script_nombre in scripts_seleccionados:
        ruta_script = f"./scripts/{script_nombre}.sh"  # Ruta al script bash
        subprocess.run(["bash", ruta_script, aurhelper])

def al_cerrar():
    # Comando a ejecutar al cerrar el programa
    print("Cerrando programa...")
    # Agrega aquí el comando que deseas ejecutar
    subprocess.run([aurhelper, "-Scc", "--noconfirm"]) # Limpiar el directorio de instalacion y la cache de AUR
    ventana.destroy()  # Cerrar la ventana

# Actualizar repositorios del aurhelper
subprocess.run([aurhelper, "-Sy"])

# Crear ventana principal
ventana = tk.Tk()
ventana.title("Instalador de scripts")

# Asociar función al evento de cerrar la ventana
ventana.protocol("WM_DELETE_WINDOW", al_cerrar)

# Marco para la lista de paquetes
frame_paquetes = tk.Frame(ventana)
frame_paquetes.pack(fill=tk.BOTH, expand=True)

# Lista de scripts disponibles
scripts = []
lista_imagenes = []  # Lista para mantener referencias a las imágenes
with open('scripts.txt', 'r') as archivo_txt:
    for linea in archivo_txt:
        script_nombre = linea.strip()  # Eliminar espacios en blanco al principio y al final
        scripts.append(script_nombre)

# Cargar e insertar el logo y la casilla de verificación para cada script
icons_path = "./icons/"
lista_scripts = []
for script in scripts:
    var = tk.IntVar()
    icon_path = os.path.join(icons_path, f"{script}.png")
    if os.path.exists(icon_path):
        logo = Image.open(icon_path)
        logo = logo.resize((30, 30))  # Ajustar el tamaño del logo al mismo que el de las letras
        logo = ImageTk.PhotoImage(logo)
        lista_imagenes.append(logo)  # Mantenemos una referencia a la imagen

        # Contenedor para el logo y la casilla de verificación
        frame_contenedor = tk.Frame(frame_paquetes)
        frame_contenedor.pack(side=tk.TOP, padx=10, pady=5) # Alineamos el contenedor al centro con un poco de espacio

        etiqueta_logo = tk.Label(frame_contenedor, image=logo, text=script, compound="left")
        etiqueta_logo.pack(side=tk.LEFT, anchor=tk.W) # Alineamos el logo y el texto a la izquierda
        chk = tk.Checkbutton(frame_contenedor, variable=var)
        chk.pack(side=tk.LEFT, anchor=tk.W) # Alineamos la casilla a la izquierda, alineada con el texto
        lista_scripts.append(var)

# Botón para ejecutar los scripts seleccionados
boton_ejecutar = tk.Button(ventana, text="Ejecutar scripts seleccionados", command=ejecutar_scripts)
boton_ejecutar.pack(fill=tk.X)

# Ejecutar la aplicación
ventana.mainloop()
