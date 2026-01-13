# El Duelo - Juego de Cartas en Bash - Práctica de Sistemas Operativos (USAL)

Este repositorio contiene la implementación del juego "El Duelo", un script en Bash que simula una batalla estratégica por turnos. [cite_start]El proyecto ha sido desarrollado siguiendo estrictos requisitos de entorno UNIX/Solaris[cite: 2, 5].

## Descripción

El juego enfrenta a un jugador humano contra hasta 3 inteligencias artificiales (IA). [cite_start]El objetivo es sobrevivir como el último jugador en pie o alcanzar la puntuación máxima establecida en la configuración[cite: 30, 56, 61].

El sistema incluye:
* [cite_start]**Gestión de Logs:** Auditoría completa de cada partida en ficheros de texto[cite: 73].
* [cite_start]**Estadísticas:** Análisis de victorias, tiempos y estrategias[cite: 91].
* [cite_start]**Configuración en caliente:** Modificación de parámetros sin editar código[cite: 19].

## Requisitos Técnicos

 **Importante:** Este script está diseñado para ejecutarse en entornos **Solaris/Encina**. Hace uso de rutas absolutas estándar XPG4:
* Shell: `/usr/bin/bash`
* [cite_start]Awk: `/usr/xpg4/bin/awk` [cite: 5]
* [cite_start]Sed: `/usr/xpg4/bin/sed` [cite: 5]

> Si deseas ejecutarlo en Linux (Ubuntu/Debian), debes editar las primeras líneas de `duelo.sh` para usar `/usr/bin/awk` y `/usr/bin/sed`.

## Instrucciones de Uso

### 1. Preparación
Otorga permisos de ejecución al script:
```bash
chmod +x duelo.sh
