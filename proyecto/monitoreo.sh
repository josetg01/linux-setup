#!/bin/bash

# Definir el archivo de log
LOG_FILE="/var/log/monitorizacion.log"

# Obtener los 5 procesos que más consumen CPU y memoria
echo "----- Procesos que más consumen recursos -----" >> $LOG_FILE
ps aux --sort=-%cpu | head -n 6 >> $LOG_FILE
ps aux --sort=-%mem | head -n 6 >> $LOG_FILE

# Comprobar el espacio en disco
echo "----- Espacio en Disco -----" >> $LOG_FILE
df -h | grep -E '^/dev' | while read line; do
    partition=$(echo $line | awk '{print $1}')
    available=$(echo $line | awk '{print $4}')
    if [[ "${available%?}" -lt 10 ]]; then
        echo "ALERTA: La partición $partition tiene menos de 10% de espacio libre." >> $LOG_FILE
    fi
done

# Revisión de los logs del sistema para errores
echo "----- Revisión de logs -----" >> $LOG_FILE
echo "Errores en syslog:" >> $LOG_FILE
grep -i "error" /var/log/syslog | tail -n 10 >> $LOG_FILE
echo "Errores en dmesg:" >> $LOG_FILE
dmesg | grep -i "error" | tail -n 10 >> $LOG_FILE

# Guardar en el log de monitorización
logger -t monitorizacion "Script de supervisión ejecutado a $(date)" 
