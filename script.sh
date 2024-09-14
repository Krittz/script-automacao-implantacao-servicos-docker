#!/bin/bash
ERROR='\033[0;31m'
INPUT='\033[0;32m'
WARNING='\033[1;33m'
INFO='\033[0;33m'
SUCCESS='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
NL='\n'
BLINK='\033[5m'

# --->>> FUNÇÕES USUAIS <<<---
function check_docker_installed() {
    if ! command -v docker &>/dev/null; then

        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Docker não está instalado. ${NL}  Por favor, 
        instale antes de prosseguir"
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        sleep 1
        return 1
    fi
    return 0
}
function check_and_install_ufw() {
    if ! command -v ufw &>/dev/null; then
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O UFW não está instalado no seu sistema."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

        echo -ne " ${INPUT}➤➤➤${NC} Deseja instalar o UFW? (s/n) "
        read -r install_choice

        if [[ "$install_choice" == "s" || "$install_choice" == "S" ]]; then
            echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Instalando o 'ufw'...${NC}${BLUE} :::...${NC}"
            sudo apt update
            sudo apt install -y ufw
            if [ $? -eq 0 ]; then
                echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  'ufw' foi instalado com sucesso."
                echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

            else
                echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  Falha na instalação do 'ufw'."
                echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━┙${NC}${NL}"
                return 1
            fi
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O 'ufw' não será instalado. As funcionalidades de firewall não estarão disponíveis."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✨  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi
}
function check_container_name() {
    local container_name=$1
    if [ -z "$container_name" ]; then

        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Nome do container não pode ser vazio."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then

        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Nome [${container_name}] indisponível. Tente novamente"
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        return 1
    else
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Nome do container [${container_name}] está disponível."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        return 0
    fi
}
function check_and_suggest_port() {
    local port=$1
    local start_port=$2
    local end_port=$3

    if [ -z "$port" ]; then
        echo ""
        return 1
    fi

    if ss -tuln | grep -q ":${port}\b"; then
        for alt_port in $(seq $start_port $end_port); do
            if ! ss -tuln | grep -q ":${alt_port}\b"; then
                echo "$alt_port"
                return 0
            fi
        done
        echo ""
        return 1
    else
        echo "$port"
        return 0
    fi
}
function check_container_exists() {
    local container_name="$1"
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then
        return 0
    else
        return 1
    fi
}
function check_directory_exists() {
    local directory_path="$1"

    if [ -d "$directory_path" ]; then
        return 0
    else
        return 1
    fi
}
function is_valid_ip() {
    local ip=$1
    local valid_ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    [[ $ip =~ $valid_ip_regex ]]
}

# --->>> //FUNÇÕES USUAIS <<<---

# --->>> POSTGRESQL <<<---
function create_postgresql_container() {
    local container_name
    local db_user
    local db_password

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando PostgreSQL${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe a senha do usuário do banco de dados: "
        read -s db_password
        echo

        if [ -z "$db_password" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  A senha não pode ser vazia."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 5432 5432 5499); then

        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 5432 e 5499 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/Dockerfile-postgresql <<EOF
FROM postgres:latest
ENV POSTGRES_PASSWORD=$db_password
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"
    docker build -t postgresql-image -f configs/Dockerfile-postgresql .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:5432 postgresql-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Banco: ${BOLD}PostgreSQL${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}postgres${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

}
function restore_backup_postgresql() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup PostgreSQL${NC}${BLUE} :::...${NC}"

    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container PostgreSQL: "
        read container_name

        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome caminho do arquivo de backup(incluindo o nome do arquivo): "
        read backup_file_path

        if [ ! -f "$backup_file_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O arquivo de backup [${backup_file_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"
        docker start "$container_name"
        if [ $? -ne 0 ]; then

            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}VERIFICANDO SE O BANCO DE DADOS [${db_name}] EXISTE"
    echo -e "${BLUE}----------------------------------------------------${NC}${NL}"

    if ! docker exec "$container_name" psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O banco de dados [${db_name}] não existe."
        echo -e "  Criando banco de dados."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker exec "$container_name" psql -U postgres -c "CREATE DATABASE ${db_name};"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao criar o banco [${db_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}RESTAURANDO BACKUP DO BANCO DE DADOS [${db_name}]"
    echo -e "${BLUE}----------------------------------------------------${NC}${NL}"

    cat "$backup_file_path" | docker exec -i "$container_name" sh -c "exec psql -U postgres -d ${db_name}"

    if [ $? -eq 0 ]; then

        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup do banco [${db_name}] restaurado com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao restaurar o backup [${db_name}]"
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    sleep 0.3
    main_menu
}
function backup_postgresql() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Backup PostgreSQL${NC}${BLUE} :::...${NC}"

    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container PostgreSQL: "
        read container_name

        if [ -z "${container_name}" ]; then

            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados PostgreSQL: "
        read db_name

        if [ -z "$db_name" ]; then

            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo para salvar o backup (incluir nome do arquivo):"
        read backup_file_path

        local dir_path
        dir_path=$(dirname "$backup_file_path")

        if [ ! -d "$dir_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O diretório [${dir_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}CRIANDO BACKUP DO BANCO DE DADOS [${db_name}]"
    echo -e "----------------------------------------------------${NC}${NL}"

    docker exec "$container_name" sh -c "exec pg_dump -U postgres ${db_name}" >"$backup_file_path"

    if [ $? -eq 0 ]; then

        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup do banco de dados[${db_name}] criado com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar backup do banco de dados [${db_name}]"
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
    sleep 0.3
    main_menu
}
# --->>> //POSTGRESQL <<<---
# --->>> MARIADB <<<----
function create_mariadb_container() {
    local container_name
    local db_user
    local db_password

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando MariaDB${NC} ${BLUE}:::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "

        read container_name
        if check_container_name "$container_name"; then
            break
        fi
    done
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do usuário do banco de dados: "
        read db_user

        echo -ne " ${INPUT}➤➤➤${NC} Informe a senha do usuário do banco de dados: "
        read -s db_password
        echo

        if [ -z "$db_user" ] || [ -z "$db_password" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Usuário e senha não podem ser vazios."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 3306 e 3399 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/Dockerfile-mariadb <<EOF
FROM mariadb:latest
# Definir variáveis de ambiente para o MariaDB
ENV MARIADB_ROOT_PASSWORD=$db_password
ENV MARIADB_USER=$db_user
ENV MARIADB_PASSWORD=$db_password
# Expor a porta padrão do MariaDB
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t mariadb-image -f configs/Dockerfile-mariadb .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:3306 mariadb-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Banco: ${BOLD}MariaDB${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
function restore_backup_mariadb() {
    local container_name
    local backup_file_path
    local database_name

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup MariaDB${NC}${BLUE} :::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container MariaDB: "
        read container_name

        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados MariaDB: "
        read database_name

        if [ -z "${database_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo do arquivo de backup: "
        read backup_file_path

        if [ ! -f "$backup_file_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O arquivo de backup [${backup_file_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    if ! check_container_running "${container_name}"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}VERIFICANDO A EXISTÊNCIA DO BANCO DE DADOS [${database_name}] NO CONTAINER [${container_name}]"
    echo -e "${BLUE}----------------------------------------------------${NC}${NL}"

    db_exists=$(docker exec "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'SHOW DATABASES LIKE \"${database_name}\";'")
    if [ -z "$db_exists" ]; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O banco de dados [${database_name}] não existe."
        echo -e "  Criando o banco de dados..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker exec "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'CREATE DATABASE ${database_name};'"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao criar o banco de dados [${database_name}]."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}RESTAURANDO O BACKUP NO CONTAINER [${container_name}] NO BANCO DE DADOS [${database_name}]"
    echo -e "--------------------------------------------------------------------${NC}${NL}"

    docker exec -i "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} ${database_name}" <"$backup_file_path"

    if [ $? -eq 0 ]; then

        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup [${database_name}] restaurado com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao restaurar backup [${database_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

        return 1
    fi
    sleep 0.3
    main_menu
}
function backup_mariadb() {
    local container_name
    local db_name
    local backup_file_path
    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Backup MariaDB${NC}${BLUE} :::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container MariaDB: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados MariaDB: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo para salvar o backup (incluir o nome do arquivo): "
        read backup_file_path

        local dir_path
        dir_path=$(dirname "$backup_file_path")

        if [ ! -d "$dir_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O diretório [${dir_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker start "$container_name"
        if [ $? -ne 0 ]; then

            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD} CRIANDO BACKUP DO BANCO DE DADOS [${db_name}]"
    echo -e "----------------------------------------------------${NC}${NL}"

    docker exec "$container_name" sh -c "exec mariadb-dump -u root -p\${MARIADB_ROOT_PASSWORD} ${db_name}" >"$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup [${db_name}] criado com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar backup do banco de dados [${db_name}]"
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    sleep 0.3
    main_menu
}
# --->>> //MARIADB <<<---
# --->>> MYSQL <<<---
function create_mysql_container() {
    local container_name
    local db_user
    local db_password

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando MySQL${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do usuário do banco de dados: "
        read db_user

        echo -ne " ${INPUT}➤➤➤${NC} Informe a senha do usuário do banco de dados: "
        read -s db_password
        echo

        if [ -z "$db_user" ] || [ -z "$db_password" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Usuário e senha não podem ser vazios."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done
    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then

        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 3306 e 3399 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/Dockerfile-mysql <<EOF
FROM mysql:latest
# Definir variáveis de ambiente para o MySQL
ENV MYSQL_ROOT_PASSWORD=$db_password
ENV MYSQL_USER=$db_user
ENV MYSQL_PASSWORD=$db_password
# Expor a porta padrão do MySQL
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"
    docker build -t mysql-image -f configs/Dockerfile-mysql .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:3306 mysql-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Banco: ${BOLD}MySQL${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
function restore_backup_mysql() {
    local container_name
    local backup_file_path
    local database_name

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup${NC}${BLUE} :::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        if ! check_container_exists "$container_name"; then

            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados: "
        read database_name

        if [ -z "${database_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo do arquivo de backup: "
        read backup_file_path
        if [ ! -f "$backup_file_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O arquivo de backup [${backup_file_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi

        if ! check_directory_exists "$(dirname "$backup_file_path")"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Diretório [$(dirname "$backup_file_path")] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}VERIFICANDO A EXISTÊNCIA DO BANCO DE DADOS [${database_name}] NO CONTAINER [${container_name}]"
    echo -e "----------------------------------------------------------------------------------${NC}${NL}"

    db_exists=$(docker exec "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES LIKE \"${database_name}\";'")
    if [ -z "$db_exists" ]; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O banco de dados [${database_name}] não existe."
        echo -e "  Criando o banco de dados..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker exec "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE ${database_name};'"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "   Falha ao criar o banco de dados [${database_name}]."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}RESTAURANDO O BACKUP NO CONTAINER [${container_name}] NO BANCO DE DADOS [${database_name}]"
    echo -e "----------------------------------------------------------------------------------${NC}${NL}"
    docker exec -i "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} ${database_name}" <"$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup [${database_name}] restaurado em [${container_name}] com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "   Falha ao restaurar o banco de dados [${database_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    sleep 0.3
    main_menu
}
function backup_mysql() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criar Backup${NC}${BLUE} :::..."

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container MySQL: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        if ! check_container_exists "$container_name"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do banco de dados MySQL: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do banco de dados não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo para salvar o backup (incluir o nome do arquivo): "
        read backup_file_path

        if [ -z "$backup_file_path" ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Diretório [${backup_file_path}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        if ! check_directory_exists "$(dirname "$backup_file_path")"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Diretório [$(dirname "$backup_file_path")] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            continue
        fi

        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then

        echo -e "${NL}${INFO}┍━━ ℹ  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  O container [${container_name}] não está em execução."
        echo -e "  Iniciando container..."
        echo -e "${INFO}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ℹ  ━━━━━━━┙${NC}${NL}"

        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao iniciar o container [${container_name}]"
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    echo -e "${NL}${BLUE}${BOLD}CRIANDO BACKUP DO BANCO DE DADOS [${db_name}]"
    echo -e "-------------------------------------------${NC}${NL}"

    docker exec "$container_name" sh -c "exec mysqldump -u root -p\${MYSQL_ROOT_PASSWORD} ${db_name}" >"$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Backup do banco de dados [${db_name}] criado com sucesso."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar backup do banco de dados [${db_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

        return 1
    fi

    sleep 0.3
    main_menu
}
# --->>> // MYSQL <<<---

# --->>> APACHE2 <<<---
function apache_static_site() {
    local container_name
    local site_directory

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando Container Apache${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo do diretório da aplicação: "
        read site_directory

        if check_directory_exists "$site_directory"; then
            break
        else
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Diretório [${site_directory}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 8080 e 8099 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker run -d --name "$container_name" -p $suggested_port:80 -v "$site_directory":/usr/local/apache2/htdocs/ httpd:2.4

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Servidor: ${BOLD}Apache${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
function reverse_proxy_apache() {
    local container_name
    local upstream_url

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando container Apache (Proxy Reverso)${NC} ${BLUE}:::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    echo -ne " ${INPUT}➤➤➤${NC} Informe a URL do upstream da API (ex: http://endereco-da-api:porta): "
    read upstream_url

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 8080 e 8099 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/httpd.conf <<EOF
<VirtualHost *:80>
    ServerName localhost
    ProxyPreserveHost On
    ProxyPass / $upstream_url
    ProxyPassReverse / $upstream_url
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    cat >configs/Dockerfile-apache <<EOF
FROM debian:latest
MAINTAINER SeuNome "seuemail@example.com"
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \\
    && apt-get -y install apache2 \\
    && apt-get clean \\
    && a2enmod proxy \\
    && a2enmod proxy_http \\
    && a2enmod ssl \\
    && a2enmod rewrite \\
    && service apache2 stop
EXPOSE 80
VOLUME /etc/apache2/sites-available
COPY configs/httpd.conf /etc/apache2/sites-available/000-default.conf
CMD ["apachectl", "-D", "FOREGROUND"]
EOF
    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t apache-reverse-proxy -f configs/Dockerfile-apache .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 apache-reverse-proxy

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Proxy para: ${BOLD}$upstream_url${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
# --->>> // APACHE2 <<<---
# --->>> NGINX <<<---
function create_nginx_frontend_container() {
    local container_name
    local frontend_dir

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando Nginx para Frontend${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o caminho completo do diretório da aplicação: "
        read frontend_dir

        if check_directory_exists "$frontend_dir"; then
            break
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Diretório [${frontend_dir}] não existe."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8080 8099); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 8080 e 8099 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs
    cp -r "$frontend_dir" configs/frontend

    cat >configs/Dockerfile-frontend <<EOF
FROM nginx:latest
COPY frontend /usr/share/nginx/html
EXPOSE 80
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t frontend-image -f configs/Dockerfile-frontend configs

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 frontend-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Servidor: ${BOLD}NGINX${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}

function reverse_proxy_nginx() {
    local container_name
    local upstream_url
    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando container Nginx (Proxy Reverso)${NC} ${BLUE}:::...${NC}"
    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    echo -ne " ${INPUT}➤➤➤${NC} Informe a URL do upstream da API (ex: http://endereco-da-api:porta): "
    read upstream_url

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 8080 e 8099 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/nginx.conf <<EOF
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass $upstream_url;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
    cat >configs/Dockerfile-nginx <<EOF
FROM nginx:latest
COPY configs/nginx.conf /etc/nginx/nginx.conf
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t nginx-image -f configs/Dockerfile-nginx .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 nginx-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Proxy para: ${BOLD}$upstream_url${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
# --->>> //NGINX <<<---

# --->>> VSFTPD <<<---
function create_vsftpd_container() {
    local container_name
    local sftp_user
    local sftp_password

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando SFTP${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do usuário SFTP: "
        read sftp_user

        echo -ne " ${INPUT}➤➤➤${NC} Informe a senha do usuário SFTP: "
        read -s sftp_password
        echo

        if [ -n "$sftp_user" ] && [ -n "$sftp_password" ]; then
            break
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Usuário e senha não podem ser vazios."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 22 22 29); then

        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 22 e 29 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    cat >configs/Dockerfile-vsftpd <<EOF
FROM ubuntu:latest
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN mkdir /home/$sftp_user
RUN useradd -d /home/$sftp_user -s /bin/bash $sftp_user
RUN echo '$sftp_user:$sftp_password' | chpasswd
RUN chown -R $sftp_user:$sftp_user /home/$sftp_user
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t sftp-image -f configs/Dockerfile-vsftpd .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:22 sftp-image

    if [ $? -eq 0 ]; then

        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}SFTP: ${BOLD}VSFTPD${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$sftp_user${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
# --->>> //VSFTPD <<<---
# --->>> OpenSSH <<<---
function create_ssh_sftp_container() {
    local container_name
    local sftp_user
    local sftp_password

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando SFTP${NC} ${BLUE}:::...${NC}"
    while true; do

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do usuário SFTP: "
        read sftp_user

        echo -ne " ${INPUT}➤➤➤${NC} Informe a senha do usuário SFTP: "
        read -s sftp_password
        echo

        if [ -n "$sftp_user" ] && [ -n "$sftp_password" ]; then
            break
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Usuário e senha não podem ser vazios."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 2222 2299); then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Não foi possível criar o container."
        echo -e "  Todas as portas entre 2222 e 2299 estão ocupadas."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    mkdir -p configs

    echo "$sftp_user:$sftp_password:1001" >configs/users.conf

    cat >configs/sshd_config <<EOF
Subsystem sftp internal-sftp
Match User $sftp_user
    PasswordAuthentication yes
    ChrootDirectory /home/$sftp_user
    ForceCommand internal-sftp
    AllowTcpForwarding no
EOF

    cat >configs/Dockerfile-ssh <<EOF
FROM debian:latest
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && useradd -m cristian \
    && echo "cristian:calangos" | chpasswd \
    && chown root:root /home/cristian \
    && chmod 755 /home/cristian \
    && mkdir /home/cristian/upload \
    && chown cristian:cristian /home/cristian/upload \
    && echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

COPY configs/sshd_config /etc/ssh/sshd_config
VOLUME /home/cristian
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

    echo -e "${NL}${BLUE}${BOLD}CONSTRUINDO IMAGEM DOCKER"
    echo -e "-------------------------------------${NC}${NL}"

    docker build -t sftp-image -f configs/Dockerfile-ssh .

    if [ $? -ne 0 ]; then
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao construir a imagem Docker."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:22 \
        -v $(pwd)/configs/users.conf:/etc/sftp-users.conf \
        sftp-image

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e "  ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}SFTP: ${BOLD}OpenSSH${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e "  ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$sftp_user${NC}"
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao criar o container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
        return 1
    fi
}
# --->>> //OpenSSH <<<---

# --->>> Firewall <<<---
function firewall_ip() {
    local container_name
    local container_port
    local ip_address

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Configurar Firewall${NC} ${BLUE}:::...${NC}${NL}"

    ufw status | grep -q "Status: active"
    if [ $? -ne 0 ]; then
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Ufw não está ativado."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        echo -ne " ${INPUT}➤➤➤${NC} Deseja ativar o ufw? (s/n) "
        read -r enable_choice
        if [[ "$enable_choice" == "s" || "$enable_choice" == "S" ]]; then
            ufw enable
            if [ $? -eq 0 ]; then
                echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  Ufw foi ativado."
                echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
            else
                echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  Falha ao ativar o ufw."
                echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━┙${NC}${NL}"
                return 1
            fi
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O ufw não será ativado."
            echo -e "  As regras de firewall não serão aplicadas."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi

        if ! check_container_exists "$container_name"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe a porta exposta pelo container (ex: 80): "
        read container_port
        if [ -z "${container_port}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Porta do container não pode ser vazia."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o IP permitido para acessar o container: "
        read ip_address
        if [ -z "${ip_address}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  IP não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        elif ! is_valid_ip "$ip_address"; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  IP fornecido não é válido."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    ufw allow from "$ip_address" to any port "$container_port" proto tcp
    ufw deny "$container_port"/tcp

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Regras de firewall aplicadas para container [${container_name}]."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao aplicar regras no container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
    fi
}
function limit_connections() {
    local container_name
    local container_port
    local max_connections

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Limitar Conexões${NC} ${BLUE}:::...${NC}${NL}"

    ufw status | grep -q "Status: active"
    if [ $? -ne 0 ]; then
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Ufw não está ativado."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
        echo -ne " ${INPUT}➤➤➤${NC} Deseja ativar o ufw? (s/n) "
        read -r enable_choice
        if [[ "$enable_choice" == "s" || "$enable_choice" == "S" ]]; then
            ufw enable
            if [ $? -eq 0 ]; then
                echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  Ufw foi ativado."
                echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
            else
                echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
                echo -e "  Falha ao ativar o ufw."
                echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━┙${NC}${NL}"
                return 1
            fi
        else
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O ufw não será ativado."
            echo -e "  As regras de limitação de conexões não serão aplicadas."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            return 1
        fi
    fi

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do container: "
        read -r container_name
        if [ -z "${container_name}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Nome do container não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi

        if ! check_container_exists "$container_name"; then
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O container [${container_name}] não existe."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe a porta exposta pelo container (ex: 80): "
        read -r container_port
        if [ -z "${container_port}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Porta do container não pode ser vazia."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}➤➤➤${NC} Informe o número máximo de conexões permitidas (ex: 100): "
        read -r max_connections
        if [ -z "${max_connections}" ]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Número máximo de conexões não pode ser vazio."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        elif ! [[ "$max_connections" =~ ^[0-9]+$ ]]; then
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  O valor fornecido não é um número válido."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"

            continue
        fi
        break
    done

    ufw limit "$container_port"/tcp

    if [ $? -eq 0 ]; then
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Regras de limitação de conexões aplicadas para container [${container_name}]."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
    else
        eecho -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Falha ao aplicar regras no container [${container_name}]."
        echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
    fi
}

# --->>> //Firewall <<<---

# --->>> DOCKER <<<---
function docker_install() {
    echo ""
    if command -v docker &>/dev/null; then
        sleep 0.3
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Docker instalado."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        return
    else
        echo -e "${NL}${MAGENTA} ...::: ${NC}${BOLD}Instalação do Docker${NC} ${MAGENTA}:::...${NC}"
        echo -e "${NL}${BLUE}${BOLD} Atualizando Sistema"
        echo -e "----------------------------------------------------${NC}${NL}"

        apt update && apt upgrade -y
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao atualizar sistema."
            echo -e "  Verifique sua conexão com a internet."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            sleep 0.3
            return
        fi
        echo -e "${NL}${BLUE}${BOLD}INSTALANDO PACOTES NECESSÁRIOS"
        echo -e "-------------------------------------${NC}${NL}"

        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao instalar pacotes necessários."
            echo -e "  Verifique sua conexão com a internet."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            sleep 0.3
            return
        fi

        echo -e "${NL}${BLUE}${BOLD}ADICIONANDO CHAVE GPG DO REPOSITÓRIO DOCKER"
        echo -e "-----------------------------------------------${NC}${NL}"

        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao adicionar chave GPG."
            echo -e "  Verifique sua conexão com a internet."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            sleep 0.3
            return
        fi
        echo -e "${NL}${BLUE}${BOLD}ADICIONANDO REPOSITÓRIO DOCKER AO SISTEMA"
        echo -e "-----------------------------------------------${NC}${NL}"

        echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
        apt update

        echo -e "${NL}${BLUE}${BOLD}INSTALANDO DOCKER ENGINE"
        echo -e "--------------------------------------${NC}${NL}"

        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao instalar Docker Engine."
            echo -e "  Verifique sua conexão com a internet."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"
            sleep 0.3
            return
        fi

        echo -e "${NL}${BLUE}${BOLD}ADICIONANDO USUÁRIO AO GRUPO DOCKER"
        echo -e "--------------------------------------${NC}${NL}"

        echo -ne " ${INPUT}➤➤➤${NC} Informe o nome do usuário que utilizará o Docker: "
        read -r usr
        usermod -aG docker $usr
        chown $usr:docker /var/run/docker.sock
        /etc/init.d/docker restart
        docker --version
        if [ $? -eq 0 ]; then
            sleep 0.3
            echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Docker instalado."
            echo -e "${SUCCESS}┕━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
            sleep 0.3
        else
            sleep 0.3
            echo -e "${NL}${ERROR}┍━━ ✕  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Falha ao instalar o Docker."
            echo -e "  Verifique sua conexão com a internet."
            echo -e "${ERROR}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✕  ━━━━━━━┙${NC}${NL}"

            sleep 0.3
            return
        fi
    fi
}
function docker_uninstall() {
    check_docker_installed
    if [ $? -ne 0 ]; then
        sleep 0.3
        echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Docker desinstalado."
        echo -e "${SUCCESS}┕━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"
        sleep 0.3
        return
    fi
    echo -e "${NL}${BLUE}${BOLD}DESINSTALANDO O DOCKER "
    echo -e "--------------------------------${NC}${NL}"

    rm /usr/share/keyrings/docker-archive-keyring.gpg
    apt purge docker-ce docker-ce-cli containerd.io -y && apt autoremove -y
    apt clean
    groupdel docker
    sleep 0.3

    echo -e "${NL}${SUCCESS}┍━━ ✓  ━━━━━━━━━━━━━━━━━━━┑${NC}"
    echo -e "  Docker desinstalado."
    echo -e "${SUCCESS}┕━━━━━━━━━━━━━━ ✓  ━━━━━━━┙${NC}${NL}"

    sleep 0.3
}
# --->>> //DOCKER <<<---

# --->>> MENUS <<<---
function apache_menu() {

    echo -e "${NL}${BLUE}╔═════════════════════════════════════════╗"
    echo -e "║                 ${NC}${BOLD}APACHE ${NC}${BLUE}                 ║"
    echo -e "╠═════════════════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Hospedar um site estático   ${BLUE}      ║"
    echo -e "║${NC} [${INPUT}2${NC}] - Proxy reverso para APIs     ${BLUE}      ║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                      ${BLUE}      ║"
    echo -e "╚═════════════════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r web_option
    case $web_option in
    1)
        sleep 0.3
        apache_static_site
        ;;
    2)
        sleep 0.3
        reverse_proxy_apache
        ;;
    0)
        sleep 0.3
        clear
        web_server_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        apache_menu
        ;;
    esac

}
function nginx_menu() {
    echo -e "${NL}${BLUE}╔═════════════════════════════════════════╗"
    echo -e "║                 ${NC}${BOLD}NGINX  ${NC}${BLUE}                 ║"
    echo -e "╠═════════════════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Hospedar um site estático   ${BLUE}      ║"
    echo -e "║${NC} [${INPUT}2${NC}] - Proxy reverso para APIs     ${BLUE}      ║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                      ${BLUE}      ║"
    echo -e "╚═════════════════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r web_option
    case $web_option in
    1)
        sleep 0.3
        create_nginx_frontend_container
        ;;
    2)
        sleep 0.3
        reverse_proxy_nginx
        ;;
    0)
        sleep 0.3
        clear
        web_server_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        nginx_menu
        ;;
    esac

}
function web_server_menu() {
    check_docker_installed
    if [ $? -ne 0 ]; then
        sleep 0.3
        return
    fi
    echo -e "${NL}${BLUE}╔═════════════════════════════╗"
    echo -e "║          ${NC}${BOLD}WEB SERVERS${NC}${BLUE}        ║"
    echo -e "╠═════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Apache                ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - Nginx                 ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                ${BLUE}║"
    echo -e "╚═════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r server_option
    case $server_option in
    1)
        sleep 0.3
        apache_menu
        ;;
    2)
        sleep 0.3
        nginx_menu
        ;;
    0)
        sleep 0.3
        clear
        main_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        web_server_menu
        ;;
    esac
}
function mariadb_menu() {
    echo -e "${NL}${BLUE}╔════════════════════════════════════════════╗"
    echo -e "║                  ${NC}${BOLD}MARIADB${NC}${BLUE}                   ║"
    echo -e "╠════════════════════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}║"
    echo -e "║${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}║"
    echo -e "╚════════════════════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r mariadb_option
    case $mariadb_option in
    1)
        sleep 0.3
        create_mariadb_container
        ;;
    2)
        sleep 0.3
        restore_backup_mariadb
        ;;
    3)
        sleep 0.3
        backup_mariadb
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        mariadb_menu
        ;;

    esac
}
function mysql_menu() {
    echo -e "${NL}${BLUE}╔════════════════════════════════════════════╗"
    echo -e "║                    ${NC}${BOLD}MYSQL${NC}${BLUE}                   ║"
    echo -e "╠════════════════════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}║"
    echo -e "║${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}║"
    echo -e "╚════════════════════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r mysql_option
    case $mysql_option in
    1)
        sleep 0.3
        create_mysql_container
        ;;
    2)
        sleep 0.3
        restore_backup_mysql
        ;;
    3)
        sleep 0.3
        backup_mysql
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        mysql_menu
        ;;
    esac
}
function postgre_menu() {
    echo -e "${NL}${BLUE}╔════════════════════════════════════════════╗"
    echo -e "║              ${NC}${BOLD}PostgreSQL${NC}${BLUE}                    ║"
    echo -e "╠════════════════════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}║"
    echo -e "║${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}║"
    echo -e "╚════════════════════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r postgre_option
    case $postgre_option in
    1)
        sleep 0.3
        create_postgresql_container
        ;;
    2)
        sleep 0.3
        restore_backup_postgresql
        ;;
    3)
        sleep 0.3
        backup_postgresql
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        postgre_menu
        ;;
    esac
}
function sfpt_menu() {
    check_docker_installed
    if [ $? -ne 0 ]; then
        sleep 0.3
        return
    fi
    echo -e "${NL}${BLUE}╔═══════════════════════╗"
    echo -e "║     ${NC}${BOLD}SERVIDORES SFTP${NC}${BLUE}   ║"
    echo -e "╠═══════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - OpenSSH         ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - vsftpd          ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar          ${BLUE}║"
    echo -e "╚═══════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r server_option

    case $server_option in
    1)
        sleep 0.3
        create_ssh_sftp_container
        ;;
    2)
        sleep 0.3
        create_vsftpd_container
        ;;

    0)
        sleep 0.3
        main_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        sftp_menu
        ;;
    esac
}
function database_menu() {
    check_docker_installed
    if [ $? -ne 0 ]; then
        sleep 0.3
        return
    fi
    echo -e "${NL}${BLUE}╔═══════════════════════╗"
    echo -e "║    ${NC}${BOLD}BANCOS DE DADOS${NC}${BLUE}    ║"
    echo -e "╠═══════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - MySQL           ${BLUE}║"
    echo -e "║${NC} [${INPUT}2${NC}] - MariaDB         ${BLUE}║"
    echo -e "║${NC} [${INPUT}3${NC}] - PostgreSQL      ${BLUE}║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar          ${BLUE}║"
    echo -e "╚═══════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r database_option
    case $database_option in
    1)
        sleep 0.3
        mysql_menu
        ;;
    2)
        sleep 0.3
        mariadb_menu
        ;;
    3)
        sleep 0.3
        postgre_menu
        ;;
    0)
        sleep 0.3
        clear
        main_menu
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        database_menu
        ;;
    esac
}
function firewall_menu() {
    check_docker_installed
    if [ $? -ne 0 ]; then
        sleep 0.3
        return
    fi
    check_and_install_ufw
    if [ $? -ne 0 ]; then
        sleep 0.3
        return
    fi
    echo -e "${NL}${BLUE}╔═════════════════════════════╗"
    echo -e "║           ${NC}${BOLD}FIREWALL${NC}${BLUE}          ║"
    echo -e "╠═════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Configurar Firewall  ${BLUE} ║"
    echo -e "║${NC} [${INPUT}2${NC}] - Limitar conexões     ${BLUE} ║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar               ${BLUE} ║"
    echo -e "╚═════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r firewall_option
    case $firewall_option in
    1)
        sleep 0.3
        firewall_ip
        ;;
    2)
        sleep 0.3
        limit_connections
        ;;
    0)
        sleep 0.3
        return
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
        ;;
    esac
}
function docker_menu() {
    echo -e "${NL}${BLUE}╔══════════════════════════════╗"
    echo -e "║           ${NC}${BOLD}DOCKER${NC}${BLUE}             ║"
    echo -e "╠══════════════════════════════╣"
    echo -e "║${NC} [${INPUT}1${NC}] - Instalar             ${BLUE}  ║"
    echo -e "║${NC} [${INPUT}2${NC}] - Desinstalar          ${BLUE}  ║"
    echo -e "║${NC} [${INPUT}0${NC}] - Voltar               ${BLUE}  ║"
    echo -e "╚══════════════════════════════╝${NC}"
    echo -ne " ${INPUT}➤➤➤${NC} Selecione uma opção: "
    read -r docker_option
    case $docker_option in
    1)
        sleep 0.3
        docker_install
        ;;
    2)
        sleep 0.3
        docker_uninstall
        ;;
    0)
        sleep 0.3
        return
        ;;
    *)
        sleep 0.3
        echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
        echo -e "  Opção inválida."
        echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
        sleep 0.3
        main_menu
        ;;
    esac
}

function main_menu() {
    while true; do
        echo -e "${NL}${BLUE}╔══════════════════════════════╗"
        echo -e "║        ${NC}${BOLD}MENU PRINCIPAL        ${BLUE}║"
        echo -e "╠══════════════════════════════╣"
        echo -e "║${NC} [${INPUT}1${NC}] - Docker                 ${BLUE}║"
        echo -e "║${NC} [${INPUT}2${NC}] - Servidores Web         ${BLUE}║"
        echo -e "║${NC} [${INPUT}3${NC}] - Servidores SFTP        ${BLUE}║"
        echo -e "║${NC} [${INPUT}4${NC}] - Bancos de Dados        ${BLUE}║"
        echo -e "║${NC} [${INPUT}5${NC}] - Firewall               ${BLUE}║"
        echo -e "║${NC} [${INPUT}0${NC}] - Sair                   ${BLUE}║"
        echo -e "╚══════════════════════════════╝${NC}"
        echo -ne "${INPUT}➤➤➤${NC} Selecione uma opção: "
        read -r menu_option

        case $menu_option in

        1)
            sleep 0.3
            clear
            docker_menu
            ;;
        2)
            sleep 0.3
            clear
            web_server_menu
            ;;
        3)
            sleep 0.3
            clear
            sfpt_menu
            ;;
        4)
            sleep 0.3
            clear
            database_menu
            ;;
        5)
            sleep 0.3
            clear
            firewall_menu
            ;;
        0)
            echo -e "${NL}${MAGENTA}┍━━ 🖐  ━━━━━━━━━━━━┑${NC}"
            echo -e "    ENCERRANDO."
            echo -e "${MAGENTA}┕━━━━━━━━━━ 🖐  ━━━━┙${NC}${NL}"
            sleep 0.3
            exit 0
            ;;
        *)
            sleep 0.3
            echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━┑${NC}"
            echo -e "  Opção inválida."
            echo -e "${WARNING}┕━━━━━━━━━━━━━━━ ⚠  ━━━━┙${NC}${NL}"
            sleep 0.3
            main_menu
            ;;
        esac
    done
}
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${NL}${WARNING}┍━━ ⚠  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑${NC}"
    echo -e "  Por favor execute esse script como root!"
    echo -e "${WARNING}┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ⚠  ━━━━━━━┙${NC}${NL}"
    exit 1
fi
echo -e "${BLUE}:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e ":::                                                       :::"
echo -e ":::${NC}              ██╗███████╗████████╗███╗   ███╗          ${BLUE}:::"
echo -e ":::${NC}              ██║██╔════╝╚══██╔══╝████╗ ████║          ${BLUE}:::"
echo -e ":::${NC}              ██║█████╗     ██║   ██╔████╔██║          ${BLUE}:::"
echo -e ":::${NC}              ██║██╔══╝     ██║   ██║╚██╔╝██║          ${BLUE}:::"
echo -e ":::${NC}              ██║██║        ██║   ██║ ╚═╝ ██║          ${BLUE}:::"
echo -e ":::${NC}              ╚═╝╚═╝        ╚═╝   ╚═╝     ╚═╝          ${BLUE}:::"
echo -e ":::${NC}   Instituto Federal de Educação, Ciência e Tecnologia ${BLUE}:::"
echo -e ":::${NC}         do Triângulo Mineiro - Campus Paracatu        ${BLUE}:::"
echo -e ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::${NC}"
echo -e ""
echo -e "★ Autor:       Cristian Alves Silva"
echo -e "★ Orientador:  Prof. Dr. Claiton Luiz Soares"
echo -e "★ Curso:       Tecnologia em Análise e Desenvolvimento de Sistemas"
echo -e "★ Título:      Assistente de implantação de servidores em Docker"

main_menu
