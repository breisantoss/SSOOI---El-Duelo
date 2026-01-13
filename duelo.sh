#!/usr/bin/bash

CONFIG_FILE="config.cfg"
AWK="/usr/xpg4/bin/awk"
SED="/usr/xpg4/bin/sed"


readonly MAZO_BASE=(
	Espada_Corta
	Espada_Larga
	Espada_Larga
	Hacha
	Escudo_Basico
	Escudo_Basico
	Escudo_Reforzado
	Curacion
	Robo_Carta	
	Contraataque
)



if [ ! -f "$CONFIG_FILE" ]; then
	echo "ERROR: El fichero de configuracion '$CONFIG_FILE' no existe."
	exit 1
fi

if [ "$1" == "-g" ]; then
	echo "=================================="
	echo "			DATOS DEL GRUPO"
	echo "=================================="
	echo "	Breixo Callón Santos"
	echo "	DNI: 54505419L"
	echo "	brei@usal.es"
	echo ""
	echo "=========================================="
	echo "			CRITERIOS DE DESEMPATE"
	echo "=========================================="
	echo "	El método de desempate se aplica solo si la partida termina"
	echo "	con todos los jugadores vivos sin cartas en el mazo ni en la mano."
	echo ""
	echo "	1) En primer lugar, gana el jugador con mayor número de PV."
	echo "	2) Si existe empate en PV, gana quien haya jugado más cartas"
	echo "	   a lo largo de la partida (valor almacenado en CARTAS_JUGADAS)."
	echo "	3) Si todavía persiste el empate, gana el jugador con menor índice"
	echo "	   (es decir, el que jugaba antes en el orden de turnos)."
	echo ""
	echo "	Este criterio garantiza una resolución determinista y premia"
	echo "	tanto la supervivencia como la participación activa en el duelo."
	echo "=========================================="
	exit 0

elif [ -n "$1" ]; then
	echo "Uso correcto: $0 [-g]"
	exit 1
fi

function configuracion() {
	while true; do
		clear

		local jugadores=$(grep "^JUGADORES" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
		local pv=$(grep "^PV" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
		local estrategia=$(grep "^ESTRATEGIA" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
		local maximo=$(grep "^MAXIMO" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
		local log_file=$(grep "^LOG" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}')

		echo "========================================"
        echo "        PANEL DE CONFIGURACIÓN"
        echo "========================================"
        echo "1) Jugadores:          $jugadores (2-4)"
        echo "2) Puntos de Vida (PV):$pv (10-30)"
        echo "3) Estrategia IA:      $estrategia (0=Aleatoria, 1=Ofensiva, 2=Defensiva)"
        echo "4) PV para victoria:   $maximo (1-50, 0=desactivado)"
        echo "5) Fichero de Log:     $log_file"
        echo "========================================"
        echo "V) Volver al menú principal"
        echo "========================================"

        read -p "Introduce el número de la opción que deseas cambiar (o V para volver) >>> " choice

        case "$choice" in

        	1)
        		read -p "Nuevo número de jugadores (2-4): " nuevos_jugadores
        		if [[ "$nuevos_jugadores" -ge 2 && "$nuevos_jugadores" -le 4 ]]; then
        			"$SED" "s/^JUGADORES.*/JUGADORES=${nuevos_jugadores}/" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        			echo "GUARDADO!!!"
        		else
        			echo "ERROR: El número de jugadores debe estar entre 2 y 4."
        		fi
        		sleep 1
        		;;
        	2)
        		read -p "Nuevos puntos de vida (10-30): " nuevos_pv
        		if [[ "$nuevos_pv" -ge 10 && "$nuevos_pv" -le 30 ]]; then
        			"$SED" "s/^PV.*/PV=${nuevos_pv}/" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        			echo "Guardado!!!"
        		else
        			echo "ERROR: Los puntos de vida deben estar entre 10 y 30."
        		fi
        		sleep 1
        		;;
        	3)
        		read -p "Nueva estrategia (0, 1, 2): " nueva_estrategia
        		if [[ "$nueva_estrategia" == "0" || "$nueva_estrategia" == "1" || "$nueva_estrategia" == "2" ]]; then
        			"$SED" "s/^ESTRATEGIA.*/ESTRATEGIA=${nueva_estrategia}/" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        			echo "Guardado!!!"
        		else
        			echo "ERROR: La estrategia debe de ser 0, 1 o 2."
        		fi
        		sleep 1
        		;;
        	4)
        		read -p "Nuevos PV para victoria (1-50, 0 para desactivar): " nuevo_maximo
        		if [[ "$nuevo_maximo" -ge 0 && "$nuevo_maximo" -le 50 ]]; then
        			"$SED" "s/^MAXIMO.*/MAXIMO=${nuevo_maximo}/" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        			echo "Guardado!!!"
        		else
        			echo "ERROR: El valor debe estar entre 0 y 50."
        		fi
        		sleep 1
        		;;
        	5)
        		read -p "Nueva ruta para el fichero de log: " nuevo_log
        		if [ -n "$nuevo_log" ]; then
        			local dir=$(dirname "$nuevo_log")
        			if [ ! -d "$dir" ]; then
        				read -p "El directorio '$dir' no existe. ¿Quieres crearlo? (s/n): " crear_dir
        				if [[ "$crear_dir" == "s" || "$crear_dir" == "S" ]]; then
        					mkdir -p "$dir"
        				fi
        			fi
        			"$SED" "s|^LOG.*|LOG=${nuevo_log}|" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        			echo "Guardado!!!"
        		else
        			echo "ERROR: La ruta no puede estar vacía."
        		fi
        		sleep 1
        		;;
        	[vV])
        		return
        		;;
        	*)
        		echo "Opción no valida. Intentalo de nuevo."
        		sleep 1
        		;;
        esac
    done
}

function jugar() {
    local TPO_INICIO=$SECONDS

    local JUGADORES=$(grep "^JUGADORES" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
    local PV_INICIAL=$(grep "^PV" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
    local ESTRATEGIA=$(grep "^ESTRATEGIA" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
    local MAXIMO=$(grep "^MAXIMO" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}' | tr -d ' ')
    local LOG_FILE=$(grep "^LOG" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}')


    echo "--- DEBUG: INICIANDO PARTIDA ---"
    echo "JUGADORES LEÍDOS: '$JUGADORES'"
    echo "PV_INICIAL LEÍDOS: '$PV_INICIAL'"
    echo "ESTRATEGIA LEÍDA: '$ESTRATEGIA'"
    echo "-----------------------------------"
    echo "Pulsa una tecla para empezar..."
    read -n 1


    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
    	mkdir -p "$log_dir"
    fi
    if [ ! -f "$LOG_FILE" ]; then
    	echo "FECHA|HORA|TPO|JUGADORES|PV|ESTRATEGIA|PMAXIMO|GANADOR|P1|P2|P3|P4|TCZ|TCM|TCJ" > "$LOG_FILE"
    fi


    declare -a ESTADO_JUGADOR
    declare -a PV
    declare -a ESCUDO
    declare -a CONTRAATAQUE
    declare -a CARTAS_JUGADAS

    for (( j=0; j<JUGADORES; j++ )); do
	jugador_num=$((j+1))

    	eval "MAZO_${j}=(\"\${MAZO_BASE[@]}\")"
    	_barajar_mazo "$j"

    	eval "MANO_${j}=()"
    	for ((c=0; c<5; c++)); do
        	_jugar_robar_carta "$j"
	done

    	PV[$j]=$PV_INICIAL
    	ESTADO_JUGADOR[$j]="VIVO"
    	ESCUDO[$j]=0
    	CONTRAATAQUE[$j]=0
    	CARTAS_JUGADAS[$j]=0
    done

    for (( j=JUGADORES; j<4; j++ )); do
        PV[$j]="-"
    done

    local ganador="0"
    local ronda=1
    
    while true; do

        for (( j=0; j<JUGADORES; j++ )); do
            jugador_num=$((j+1))
            
            if [ "${ESTADO_JUGADOR[$j]}" == "MUERTO" ]; then
                continue 
            fi

            _jugar_mostrar_tablero $j $ronda "$JUGADORES" "${PV[@]}"

            if [ $j -eq 0 ]; then
                _jugar_turno_humano $j $JUGADORES
            else
                _jugar_turno_ia $j $JUGADORES $ESTRATEGIA
            fi

            ganador=$(_jugar_comprobar_fin $JUGADORES $MAXIMO)
            if [ "$ganador" != "0" ]; then
                break 2 
            fi

        done 

        ((ronda++))

    done

    clear
    echo "========================================"
    echo "         FIN DE LA PARTIDA"
    echo "========================================"
    echo "¡El jugador $ganador GANA EL DUELO!"
    echo ""
    echo "--- Puntuaciones Finales ---"
    for (( j=0; j<JUGADORES; j++ )); do
    	jugador_num=$((j+1))
        eval "local mazo_len=\${#MAZO_${j}[@]}"
        eval "local mano_len=\${#MANO_${j}[@]}"
        echo "Jugador $jugador_num (PV: ${PV[$j]}) | Mazo: $mazo_len | Mano: $mano_len"
    done
    echo "========================================"

    local TPO=$(( SECONDS - TPO_INICIO ))

    _jugar_guardar_log "$TPO" "$JUGADORES" "$PV_INICIAL" "$ESTRATEGIA" "$MAXIMO" "$LOG_FILE" "$ganador"

}



 function _jugar_mostrar_tablero() {
    local j_actual=$1
    local ronda=$2
    local num_jugadores=$3
    local -a pvs=("${PV[@]}")

    clear
    echo "=========================== EL DUELO (Ronda $ronda) ============================"
    echo ""

    for (( jj=0; jj<num_jugadores; jj++ )); do
        local jugador_num=$((jj+1))
        eval "local mazo_len=\${#MAZO_${jj}[@]}"
        eval "local mano_len=\${#MANO_${jj}[@]}"

        if [ "${ESTADO_JUGADOR[$jj]}" == "MUERTO" ]; then
            printf "Jugador %-2s [%-6s]\n" "$jugador_num" "MUERTO"
            continue
        fi

        local linea
        linea=$(printf "Jugador %-2s [%-4s] | PV: %-2s | Mazo: %-2s | Mano: %-2s" \
            "$jugador_num" "${ESTADO_JUGADOR[$jj]}" "${pvs[$jj]}" "$mazo_len" "$mano_len")

        if [ "${ESCUDO[$jj]}" -gt 0 ]; then
            linea+=" | Escudo: ${ESCUDO[$jj]}"
        fi

        if [ "${CONTRAATAQUE[$jj]}" -eq 1 ]; then
            linea+=" | CTRATQ: ACTIVO"
        else
            linea+=" | CTRATQ: INACTIVO"
        fi

        echo "$linea"
    done

    echo ""
    echo "---------------------------------------------------------------------------"
    echo ">>> Turno del Jugador $((j_actual+1)) <<<"
}


function _jugar_robar_carta() {
    local j=$1
    eval "local mazo_len=\${#MAZO_${j}[@]}"

    if (( mazo_len == 0 )); then
        echo "El Jugador $((j+1)) no puede robar, su mazo está vacío."
        return 1
    fi

    eval "local carta=\${MAZO_${j}[0]}"
    eval "MANO_${j}+=(\"\$carta\")"
    eval "MAZO_${j}=(\"\${MAZO_${j}[@]:1}\")"
}

function _barajar_mazo() {
    local j=$1
    eval "local -a tmp=(\"\${MAZO_${j}[@]}\")"
    local i rand t
    for (( i=${#tmp[@]}-1; i>0; i-- )); do
    	rand=$(( RANDOM % (i+1) ))
        t=${tmp[i]}
        tmp[i]=${tmp[rand]}
        tmp[rand]=$t
    done
    eval "MAZO_${j}=(\"\${tmp[@]}\")"
}

function _jugar_aplicar_efecto() {
    local origen=$1
    local objetivo=$2
    local carta="$3"
    
    local dano=0
    local curacion=0

    case "$carta" in
	    Espada_Corta)     dano=2 ;;
	    Espada_Larga)     dano=4 ;;
	    Hacha)            dano=6 ;;

	    Escudo_Basico)
		ESCUDO[$origen]=4
		echo "¡El Jugador $((origen+1)) activa un Escudo basico (bloquea 4)!"
		sleep 1
		;;
	    Escudo_Reforzado)
		ESCUDO[$origen]=6
		echo "¡El Jugador $((origen+1)) activa un Escudo reforzado (bloquea 6)!"
		sleep 1
		;;

	    Curacion)
		curacion=3
		PV[$origen]=$(( ${PV[$origen]} + curacion ))
		echo "¡El Jugador $((origen+1)) se cura $curacion PV!"
		sleep 1
		;;
	    Robo_Carta)
		echo "¡El Jugador $((origen+1)) roba una carta extra!"
		sleep 1
		_jugar_robar_carta "$origen"
		;;
	    Contraataque)
		CONTRAATAQUE[$origen]=1
		echo "¡El Jugador $((origen+1)) prepara un Contraataque!"
		sleep 1
		;;
    esac


    if [ $dano -gt 0 ]; then
        echo "¡Jugador $((origen+1)) ataca a Jugador $((objetivo+1)) con ${carta//_/ } ($dano de daño)!"
        sleep 1
        
        if [ ${CONTRAATAQUE[$objetivo]} -eq 1 ]; then
            local dano_devuelto=$(( $dano / 2 ))
            PV[$origen]=$(( ${PV[$origen]} - $dano_devuelto ))
            echo "¡...pero el Jugador $objetivo CONTRAATACA! Jugador $((origen+1)) recibe $dano_devuelto de daño."
            sleep 1
            CONTRAATAQUE[$objetivo]=0 
            if [ ${PV[$origen]} -le 0 ]; then
                PV[$origen]=0
                ESTADO_JUGADOR[$origen]="MUERTO"
                echo "¡El Jugador $((origen+1)) ha caído!"
                sleep 1
            fi
        fi
        
        if [ ${ESCUDO[$objetivo]} -gt 0 ]; then
            local bloqueo=${ESCUDO[$objetivo]}
            echo "¡...pero el Jugador $((objetivo+1)) tiene un escudo de $bloqueo!"
            sleep 1
            if [ $dano -le $bloqueo ]; then
                echo "¡El ataque es bloqueado completamente!"
                sleep 1
                dano=0
            else
                dano=$(( $dano - $bloqueo ))
                echo "El escudo absorbe $bloqueo de daño. El daño restante es $dano."
                sleep 1
            fi
            ESCUDO[$objetivo]=0 
        fi
        
        PV[$objetivo]=$(( ${PV[$objetivo]} - $dano ))
        if [ $dano -gt 0 ]; then
             echo "¡El Jugador $((origen+1)) recibe $dano de daño! PV restantes: ${PV[$objetivo]}"
             sleep 1
        fi

        if [ ${PV[$objetivo]} -le 0 ]; then
            PV[$objetivo]=0
            ESTADO_JUGADOR[$objetivo]="MUERTO"
            echo "¡El Jugador $((objetivo+1)) ha caído!"
        fi
    fi
}

function _jugar_turno_humano() {
    local j=$1
    local num_jugadores=$2
    
    eval "local -a mano=(\${MANO_${j}[@]})"
    echo "Tu mano:"
    for (( i=0; i<${#mano[@]}; i++ )); do
        echo "  $((i+1))) ${mano[$i]//_/ }"
    done

    local eleccion_carta
    while true; do
        read -p "Elige una carta para jugar (1-${#mano[@]}): " eleccion_carta
        if [[ "$eleccion_carta" -ge 1 && "$eleccion_carta" -le ${#mano[@]} ]]; then
            break
        else
            echo "Selección no válida."
        fi
    done
    
    local carta_jugada="${mano[$((eleccion_carta-1))]}"
    
    local objetivo=$j
    if [[ "$carta_jugada" == Espada_Corta || "$carta_jugada" == Espada_Larga || "$carta_jugada" == Hacha ]]; then
        echo "Elige un objetivo:"
        for (( k=0; k<num_jugadores; k++ )); do
    		if [ $k -ne $j ] && [ "${ESTADO_JUGADOR[$k]}" == "VIVO" ]; then
        		echo "  $((k+1))) Jugador $((k+1)) (PV: ${PV[$k]})"
    		fi
	done

        
        while true; do
            read -p "Elige un jugador objetivo: " objetivo
            objetivo=$((objetivo-1))
            
            if [[ "$objetivo" -ge 0 && "$objetivo" -lt $num_jugadores && $objetivo -ne $j && "${ESTADO_JUGADOR[$objetivo]}" == "VIVO" ]]; then
                break
            else
                echo "Objetivo no válido."
            fi
        done
    fi

    echo "Juegas '${carta_jugada//_/ }'..."
    sleep 1
    eval "MANO_${j}=(\"\${MANO_${j}[@]:0:$((eleccion_carta-1))}\" \"\${MANO_${j}[@]:$((eleccion_carta))}\")"
    CARTAS_JUGADAS[$j]=$(( ${CARTAS_JUGADAS[$j]} + 1 ))

    _jugar_aplicar_efecto $j $objetivo "$carta_jugada"
    
    _jugar_robar_carta $j
    
    sleep 2 
}

function _jugar_turno_ia() {
    local j=$1
    local num_jugadores=$2
    local estrategia=$3
    
    echo "El Jugador $((j+1)) (IA) está pensando..."
    sleep 1
    
    eval "local -a mano=(\${MANO_${j}[@]})"

    if [ ${#mano[@]} -eq 0 ]; then
    	echo "El Jugador $((j+1)) (IA) no tiene cartas. Roba una y pasa turno."
    	_jugar_robar_carta "$j"
    	return
    fi

local eleccion_carta=-1

    
    if [ $estrategia -eq 0 ]; then
        eleccion_carta=$(( $RANDOM % ${#mano[@]} ))
    
    elif [ $estrategia -eq 1 ]; then
        local mejor_ataque=-1
        local idx_ataque=-1
        for (( i=0; i<${#mano[@]}; i++ )); do
            local dano=0
            [[ "${mano[$i]}" == "Espada_Corta" ]] && dano=2
            [[ "${mano[$i]}" == "Espada_Larga" ]] && dano=4
            [[ "${mano[$i]}" == "Hacha" ]] && dano=6
            if [ $dano -gt $mejor_ataque ]; then
                mejor_ataque=$dano
                idx_ataque=$i
            fi
        done
        
        if [ $idx_ataque -ne -1 ]; then
            eleccion_carta=$idx_ataque 
        else
            eleccion_carta=$(( $RANDOM % ${#mano[@]} ))
        fi
    
    
    elif [ $estrategia -eq 2 ]; then
        local idx_defensa=-1
        for (( i=0; i<${#mano[@]}; i++ )); do
            if [[ "${mano[$i]}" == Escudo_Basico || "${mano[$i]}" == Escudo_Reforzado || "${mano[$i]}" == Curacion || "${mano[$i]}" == Contraataque ]]; then
                idx_defensa=$i
                break 
            fi
        done
        
        if [ $idx_defensa -ne -1 ]; then
            eleccion_carta=$idx_defensa
        else
            eleccion_carta=$(( $RANDOM % ${#mano[@]} )) 
        fi
    fi
    
    local carta_jugada="${mano[$eleccion_carta]}"
    
    local objetivo=$j 
    if [[ "$carta_jugada" == *"Espada"* || "$carta_jugada" == "Hacha" ]]; then
        local -a posibles_objetivos=()
        for (( kk=0; kk<num_jugadores; kk++ )); do
            if [ $kk -ne $j ] && [ "${ESTADO_JUGADOR[$kk]}" == "VIVO" ]; then
               	posibles_objetivos+=($kk)
    	    fi
	done

        if [ ${#posibles_objetivos[@]} -gt 0 ]; then
            if [ $estrategia -eq 1 ]; then
                objetivo=${posibles_objetivos[0]}
                local max_pv=0
                for k in "${posibles_objetivos[@]}"; do
                    if [ ${PV[$k]} -gt $max_pv ]; then
                        max_pv=${PV[$k]}
                        objetivo=$k
                    fi
                done
            else
                objetivo=${posibles_objetivos[$(( $RANDOM % ${#posibles_objetivos[@]} ))]}
            fi
        else
            objetivo=$j 
        fi
    fi

    echo "El Jugador $((j+1)) (IA) juega '${carta_jugada//_/ }'..."
    sleep 1
    eval "MANO_${j}=(\"\${MANO_${j}[@]:0:$((eleccion_carta))}\" \"\${MANO_${j}[@]:$((eleccion_carta+1))}\")"
    CARTAS_JUGADAS[$j]=$(( ${CARTAS_JUGADAS[$j]} + 1 ))

    _jugar_aplicar_efecto $j $objetivo "$carta_jugada"
    
    _jugar_robar_carta $j
    
    sleep 2 
}

function _jugar_comprobar_fin() {
    local num_jugadores=$1
    local max_pv_victoria=$2
    
    local jugadores_vivos=0
    local ultimo_jugador_vivo=0      
    local ganador_por_pv_max=0       
    local mazos_vacios=1             
    
    for (( jj=0; jj<num_jugadores; jj++ )); do
        if [ "${ESTADO_JUGADOR[$jj]}" == "VIVO" ]; then
            jugadores_vivos=$((jugadores_vivos + 1))
            ultimo_jugador_vivo=$((jj+1))  
        fi

        if [ "$max_pv_victoria" -gt 0 ] && [ "${PV[$jj]}" -ge "$max_pv_victoria" ]; then
            ganador_por_pv_max=$((jj+1))   
        fi

        eval "local mazo_len=\${#MAZO_${jj}[@]}"
        eval "local mano_len=\${#MANO_${jj}[@]}"
	if [ "$mazo_len" -gt 0 ] || [ "$mano_len" -gt 0 ]; then
    		mazos_vacios=0
	fi
    done

    if [ "$jugadores_vivos" -eq 1 ]; then
        echo "$ultimo_jugador_vivo"   
        return
    fi

    if [ "$ganador_por_pv_max" -ne 0 ]; then
        echo "$ganador_por_pv_max"    
        return
    fi

    if [ "$mazos_vacios" -eq 1 ]; then
    	local pv_max_final=-1
    	local -a candidatos=()
    	for (( jj=0; jj<num_jugadores; jj++ )); do
    	    if [ "${ESTADO_JUGADOR[$jj]}" == "VIVO" ]; then
    	        if [ "${PV[$jj]}" -gt "$pv_max_final" ]; then
    	            pv_max_final=${PV[$jj]}
    	            candidatos=($jj)
    	        elif [ "${PV[$jj]}" -eq "$pv_max_final" ]; then
    	            candidatos+=($jj)
    	        fi
    	    fi
    	done
	
    	if [ ${#candidatos[@]} -eq 1 ]; then
    	    echo "$((candidatos[0]+1))"
    	    return
    	fi
	
    	local mejor_cj=-1
    	local -a candidatos_cj=()
    	for idx in "${candidatos[@]}"; do
    	    if [ ${CARTAS_JUGADAS[$idx]} -gt "$mejor_cj" ]; then
    	        mejor_cj=${CARTAS_JUGADAS[$idx]}
    	        candidatos_cj=("$idx")
    	    elif [ ${CARTAS_JUGADAS[$idx]} -eq "$mejor_cj" ]; then
    	        candidatos_cj+=("$idx")
    	    fi
    	done
	
    	if [ ${#candidatos_cj[@]} -eq 1 ]; then
    	    echo "$((candidatos_cj[0]+1))"
    	    return
    	fi
	
    	echo "$((candidatos_cj[0]+1))"
    	return
    fi	
	
	
    echo "0"  
}

function _jugar_guardar_log() {
  local tpo="$1"
  local jugadores="$2"
  local pv_init="$3"
  local estrategia="$4"
  local pmaximo="$5"
  local log_file="$6"
  local ganador="$7"

  local fecha hora
  fecha=$(date +%d%m%y)
  hora=$(date +%H%M%S)

  mkdir -p "$(dirname "$log_file")"

  if [ ! -f "$log_file" ]; then
    echo "FECHA|HORA|TPO|JUGADORES|PV|ESTRATEGIA|PMAXIMO|GANADOR|P1|P2|P3|P4|TCZ|TCM|TCJ" > "$log_file"
  fi

  local tcz=0 tcm=0 tcj=0
  for (( jj=0; jj<jugadores; jj++ )); do
    eval "tcz=\$(( tcz + \${#MAZO_${jj}[@]} ))"
    eval "tcm=\$(( tcm + \${#MANO_${jj}[@]} ))"
    tcj=$(( tcj + ${CARTAS_JUGADAS[$jj]} ))
  done

  
  local p1="${PV[0]}" p2="${PV[1]}" p3="${PV[2]}" p4="${PV[3]}"

  echo "$fecha|$hora|$tpo|$jugadores|$pv_init|$estrategia|$pmaximo|$ganador|$p1|$p2|$p3|$p4|$tcz|$tcm|$tcj" >> "$log_file"
}


function estadisticas() {
    local LOG_FILE
    LOG_FILE=$(grep "^LOG" "$CONFIG_FILE" | "$AWK" -F'=' '{print $2}')

    clear
    echo "============================= ESTADÍSTICAS ============================="

    if [[ -z "$LOG_FILE" ]]; then
        echo "No se ha configurado el fichero de log en $CONFIG_FILE."
        read -n 1 -s -r -p "Pulsa una tecla para volver..."
        return
    fi
    if [[ ! -r "$LOG_FILE" ]]; then
        echo "No puedo leer el fichero de log: $LOG_FILE"
        read -n 1 -s -r -p "Pulsa una tecla para volver..."
        return
    fi

    local PARTIDAS
    PARTIDAS=$("$AWK" -F'|' 'NR>1 && $0!=""{c++} END{print c+0}' "$LOG_FILE")
    if (( PARTIDAS == 0 )); then
        echo "No hay partidas registradas en el log."
        read -n 1 -s -r -p "Pulsa una tecla para volver..."
        return
    fi

    local TPO_MEDIO TPO_MIN TPO_MAX
    TPO_MEDIO=$("$AWK" -F'|' 'NR>1 && $0!=""{sum+=$3;n++} END{if(n) printf "%.2f", sum/n; else print 0}' "$LOG_FILE")
    TPO_MIN=$("$AWK" -F'|' 'NR>1 && $0!=""{if(min==""||$3<min) min=$3} END{print min+0}' "$LOG_FILE")
    TPO_MAX=$("$AWK" -F'|' 'NR>1 && $0!=""{if(max==""||$3>max) max=$3} END{print max+0}' "$LOG_FILE")

    local W1 W2 W3 W4
    read -r W1 W2 W3 W4 < <(
        "$AWK" -F'|' 'NR>1 && $0!=""{ if($8 ~ /^[1-4]$/) w[$8]++ } END{ for(i=1;i<=4;i++) printf "%d ", (w[i]?w[i]:0) }' "$LOG_FILE"
    )

    local P1 P2 P3 P4
    P1=$("$AWK" -v w="$W1" -v n="$PARTIDAS" 'BEGIN{printf "%.2f", (n?100*w/n:0)}')
    P2=$("$AWK" -v w="$W2" -v n="$PARTIDAS" 'BEGIN{printf "%.2f", (n?100*w/n:0)}')
    P3=$("$AWK" -v w="$W3" -v n="$PARTIDAS" 'BEGIN{printf "%.2f", (n?100*w/n:0)}')
    P4=$("$AWK" -v w="$W4" -v n="$PARTIDAS" 'BEGIN{printf "%.2f", (n?100*w/n:0)}')

    local PV_MAX_GLOBAL
    PV_MAX_GLOBAL=$("$AWK" -F'|' 'NR>1 && $0!=""{for(i=9;i<=12;i++) if($i ~ /^[0-9]+$/ && $i>max) max=$i} END{print (max==""?0:max)}' "$LOG_FILE")

    local PV1_MED PV2_MED PV3_MED PV4_MED
    read -r PV1_MED PV2_MED PV3_MED PV4_MED < <(
        "$AWK" -F'|' '
            NR>1 && $0!=""{
                for(i=9;i<=12;i++){
                    if($i ~ /^[0-9]+$/){ sum[i]+=$i; cnt[i]++ }
                }
            }
            END{
                for(i=9;i<=12;i++){
                    if(cnt[i]) printf "%.2f ", sum[i]/cnt[i]; else printf "0.00 "
                }
            }' "$LOG_FILE"
    )

    local TCZ_MED TCM_MED TCJ_MED
    read -r TCZ_MED TCM_MED TCJ_MED < <(
        "$AWK" -F'|' 'NR>1 && $0!=""{sz+=$13; sm+=$14; sj+=$15; n++} END{
            if(n) printf "%.2f %.2f %.2f", sz/n, sm/n, sj/n; else print "0 0 0"
        }' "$LOG_FILE"
    )

    local E0 E1 E2
    read -r E0 E1 E2 < <(
        "$AWK" -F'|' 'NR>1 && $0!=""{ if($6 ~ /^[0-2]$/) e[$6]++ } END{ for(i=0;i<=2;i++) printf "%d ", (e[i]?e[i]:0) }' "$LOG_FILE"
    )

    local LINEA_MIN
    LINEA_MIN=$("$AWK" -F'|' 'NR==2 && $0!=""{min=$3; l=$0} NR>2 && $0!=""{if($3<min){min=$3; l=$0}} END{print l}' "$LOG_FILE")

    local LINEA_PV_MAX
    LINEA_PV_MAX=$("$AWK" -F'|' '
        NR==2 && $0!=""{
            maxpv=0
            for(i=9;i<=12;i++) if($i ~ /^[0-9]+$/ && $i>maxpv) maxpv=$i
            best=$0
        }
        NR>2 && $0!=""{
            cur=0
            for(i=9;i<=12;i++) if($i ~ /^[0-9]+$/ && $i>cur) cur=$i
            if(cur>maxpv){ maxpv=cur; best=$0 }
        }
        END{print best}
    ' "$LOG_FILE")

    local EMPATES
    EMPATES=$("$AWK" -F'|' '
        NR>1 && $0!=""{
            maxpv=-1; c=0
            for(i=9;i<=12;i++){
                if($i ~ /^[0-9]+$/){
                    if($i>maxpv){ maxpv=$i; c=1 }
                    else if($i==maxpv){ c++ }
                }
            }
            if(c>=2){ print "  " $0 }
        }
    ' "$LOG_FILE")

    echo ""
    echo "Archivo de log: $LOG_FILE"
    echo "Partidas registradas: $PARTIDAS"
    echo "Tiempo (s):   media=$TPO_MEDIO   min=$TPO_MIN   max=$TPO_MAX"
    echo ""
    echo "Victorias:"
    printf "  Jugador 1: %3d  (%6s%%)\n" "$W1" "$P1"
    printf "  Jugador 2: %3d  (%6s%%)\n" "$W2" "$P2"
    printf "  Jugador 3: %3d  (%6s%%)\n" "$W3" "$P3"
    printf "  Jugador 4: %3d  (%6s%%)\n" "$W4" "$P4"
    echo ""
    echo "PV final medio por jugador:"
    printf "  P1: %6s   P2: %6s   P3: %6s   P4: %6s\n" "$PV1_MED" "$PV2_MED" "$PV3_MED" "$PV4_MED"
    echo "PV final máximo observado: $PV_MAX_GLOBAL"
    echo ""
    echo "Cartas (medias por partida):"
    echo "  TCZ (mazos): $TCZ_MED    TCM (manos): $TCM_MED    TCJ (jugadas): $TCJ_MED"
    echo ""
    echo "Estrategias usadas (0=Aleatoria, 1=Ofensiva, 2=Defensiva):"
    echo "  E0: $E0    E1: $E1    E2: $E2"

    echo ""
    echo "Partida más corta (línea completa):"
    echo "  $LINEA_MIN"

    echo ""
    echo "Partida con mayor PV final observado (línea completa):"
    echo "  $LINEA_PV_MAX"

    echo ""
    echo "Partidas con empate (mismo PV máximo en varios jugadores):"
    if [[ -n "$EMPATES" ]]; then
        echo "$EMPATES"
    else
        echo "  (No se han registrado empates)"
    fi

    echo "==========================================================================="
    read -n 1 -s -r -p "Pulsa una tecla para volver al menú..."
}


while true; do

	clear

	echo "=========================="
	echo "			MENU"
	echo "=========================="
	echo "C) CONFIGURACION"
	echo "J) JUGAR"
	echo "E) ESTADISTICAS"
	echo "S) SALIR"
	read -r -p "Introduzca una opcion >>> " OPCION

	case "$OPCION" in
		C|c)
			configuracion	
			;;
		J|j)
			jugar			
			;;
		E|e)
			estadisticas	
			;;
		S|s)
			echo "Saliendo del juego..."
			exit 0			
			;;
		*)
			echo "Opción no válida. Intentelo de nuevo"
			;;
	esac

	read -n 1 -s -r -p "Pulse una tecla para continuar"
	echo ""				

done
