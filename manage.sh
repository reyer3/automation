#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funcion de ayuda
show_help() {
    echo "Uso: ./manage.sh [comando] [servicio]"
    echo ""
    echo "Comandos:"
    echo "  start     - Inicia los servicios"
    echo "  stop      - Detiene los servicios"
    echo "  restart   - Reinicia los servicios"
    echo "  logs      - Muestra los logs"
    echo "  setup     - Configura el entorno inicial"
    echo ""
    echo "Servicios:"
    echo "  all       - Todos los servicios"
    echo "  shared    - Servicios compartidos (Traefik, PostgreSQL, Redis)"
    echo "  n8n       - Servicio N8N"
    echo "  chat      - Servicio Chatwoot"
}

# Funcion para generar variables de entorno
generate_env_vars() {
    # Generar y almacenar todas las variables primero
    DOMAIN_NAME="mibot.cl"
    DATA_FOLDER="/opt/mibot"
    SSL_EMAIL="ricardo@onbotgo.cl"
    AUTOMATION_DOMAIN="automation.${DOMAIN_NAME}"
    EVOLUTION_DOMAIN="evolution.${DOMAIN_NAME}"
    CHAT_DOMAIN="chat-automation.${DOMAIN_NAME}"
    
    # Generar passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
    N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)
    SECRET_KEY_BASE=$(openssl rand -base64 64)
    TRAEFIK_AUTH=$(cat ./shared/traefik_users)

    # Generar shared/.env
    echo "Generando shared/.env..."
    {
        echo "# Configuracion General"
        echo "DOMAIN_NAME=${DOMAIN_NAME}"
        echo "DATA_FOLDER=${DATA_FOLDER}"
        echo "SSL_EMAIL=${SSL_EMAIL}"
        echo
        echo "# Dominios"
        echo "AUTOMATION_DOMAIN=${AUTOMATION_DOMAIN}"
        echo "EVOLUTION_DOMAIN=${EVOLUTION_DOMAIN}"
        echo "CHAT_DOMAIN=${CHAT_DOMAIN}"
        echo
        echo "# PostgreSQL"
        echo "POSTGRES_USER=postgres"
        echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
        echo "POSTGRES_DB=postgres"
        echo "POSTGRES_MULTIPLE_DATABASES=n8n,chatwoot"
        echo
        echo "# Redis"
        echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
        echo
        echo "# Traefik Dashboard"
        echo "TRAEFIK_DASHBOARD_AUTH=${TRAEFIK_AUTH}"
    } > ./shared/.env

    # Generar n8n/.env
    echo "Generando n8n/.env..."
    {
        echo "# N8N Configuracion"
        echo "N8N_PORT=5678"
        echo "N8N_PROTOCOL=https"
        echo "N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}"
        echo "GENERIC_TIMEZONE=America/Santiago"
        echo
        echo "# N8N Autenticacion"
        echo "N8N_BASIC_AUTH_ACTIVE=true"
        echo "N8N_BASIC_AUTH_USER=admin"
        echo "N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}"
        echo
        echo "# Base de datos"
        echo "POSTGRES_DB=n8n"
        echo "POSTGRES_USER=n8n"
        echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
        echo
        echo "# Redis"
        echo "REDIS_USER=default"
        echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
    } > ./n8n/.env

    # Generar chat/.env
    echo "Generando chat/.env..."
    {
        echo "# Chatwoot Configuracion"
        echo "SECRET_KEY_BASE=${SECRET_KEY_BASE}"
        echo "RAILS_ENV=production"
        echo "NODE_ENV=production"
        echo "INSTALLATION_ENV=docker"
        echo
        echo "# Base de datos"
        echo "POSTGRES_HOST=postgres"
        echo "POSTGRES_USERNAME=chatwoot"
        echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
        echo "POSTGRES_DB=chatwoot"
        echo
        echo "# Redis"
        echo "REDIS_URL=redis://redis:6379"
        echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
        echo
        echo "# Email (Configurar segun necesidades)"
        echo "SMTP_DOMAIN=mibot.cl"
        echo "SMTP_ADDRESS=smtp.gmail.com"
        echo "SMTP_PORT=587"
        echo "SMTP_USERNAME=your_email@mibot.cl"
        echo "SMTP_PASSWORD=your_email_password"
        echo "SMTP_AUTHENTICATION=plain"
        echo "SMTP_ENABLE_STARTTLS_AUTO=true"
        echo "DEFAULT_MAILER_FROM_EMAIL=your_email@mibot.cl"
        echo
        echo "# Storage"
        echo "ACTIVE_STORAGE_SERVICE=local"
        echo "RAILS_MAX_THREADS=5"
        echo
        echo "# Otros"
        echo "ENABLE_ACCOUNT_SIGNUP=false"
        echo "FORCE_SSL=true"
    } > ./chat/.env

    echo "Archivos .env generados exitosamente"
}

# Funcion de setup
setup() {
    echo -e "${BLUE}Iniciando setup de MiBot Infrastructure...${NC}"

    # Crear directorios necesarios
    echo -e "${GREEN}Creando directorios...${NC}"
    sudo mkdir -p /opt/mibot/{postgresql,redis,letsencrypt,.n8n,n8n-files,chatwoot/storage}
    sudo chown -R $USER:$USER /opt/mibot
    chmod -R 755 /opt/mibot

    # Asegurar permisos del script de inicializacion de PostgreSQL
    echo -e "${GREEN}Configurando permisos de scripts...${NC}"
    chmod +x ./shared/postgresql/init-multiple-dbs.sh

    # Crear red de Docker
    echo -e "${GREEN}Creando red de Docker...${NC}"
    docker network create automation-network || true

    # Generar archivos .env si no existen
    echo -e "${GREEN}Configurando variables de entorno...${NC}"
    if [ ! -f ./shared/.env ] || [ ! -f ./n8n/.env ] || [ ! -f ./chat/.env ]; then
        # Configurar autenticacion de Traefik primero
        if [ ! -f ./shared/traefik_users ]; then
            echo -n "Ingrese usuario para Traefik Dashboard [admin]: "
            read traefikuser
            traefikuser=${traefikuser:-admin}
            
            echo -n "Ingrese password para Traefik Dashboard: "
            read -s traefikpass
            echo

            mkdir -p ./shared/traefik/dynamic
            # Generar hash usando openssl en lugar de htpasswd
            HASHED_PASSWORD=$(openssl passwd -apr1 "$traefikpass")
            echo "${traefikuser}:${HASHED_PASSWORD}" > ./shared/traefik_users
        fi

        # Generar los archivos .env
        generate_env_vars
    fi

    echo -e "${GREEN}Setup completado. Por favor, revisa y ajusta los archivos .env segun sea necesario.${NC}"
    echo -e "${BLUE}Importante: Guarda los passwords generados en un lugar seguro.${NC}"
}

# Funcion para manejar servicios
manage_service() {
    local action=$1
    local service=$2
    
    case $action in
        "start")
            if [ "$service" = "all" ] || [ "$service" = "shared" ]; then
                echo -e "${GREEN}Iniciando servicios compartidos...${NC}"
                cd shared && docker-compose up -d
                cd ..
            fi
            if [ "$service" = "all" ] || [ "$service" = "n8n" ]; then
                echo -e "${GREEN}Iniciando N8N...${NC}"
                cd n8n && docker-compose up -d
                cd ..
            fi
            if [ "$service" = "all" ] || [ "$service" = "chat" ]; then
                echo -e "${GREEN}Iniciando Chatwoot...${NC}"
                cd chat && docker-compose up -d
                cd ..
            fi
            ;;
        "stop")
            if [ "$service" = "all" ] || [ "$service" = "chat" ]; then
                echo -e "${GREEN}Deteniendo Chatwoot...${NC}"
                cd chat && docker-compose down
                cd ..
            fi
            if [ "$service" = "all" ] || [ "$service" = "n8n" ]; then
                echo -e "${GREEN}Deteniendo N8N...${NC}"
                cd n8n && docker-compose down
                cd ..
            fi
            if [ "$service" = "all" ] || [ "$service" = "shared" ]; then
                echo -e "${GREEN}Deteniendo servicios compartidos...${NC}"
                cd shared && docker-compose down
                cd ..
            fi
            ;;
        "restart")
            manage_service "stop" "$service"
            manage_service "start" "$service"
            ;;
        "logs")
            case $service in
                "n8n")
                    cd n8n && docker-compose logs -f n8n
                    ;;
                "traefik")
                    cd shared && docker-compose logs -f traefik
                    ;;
                "postgres")
                    cd shared && docker-compose logs -f postgres
                    ;;
                "redis")
                    cd shared && docker-compose logs -f redis
                    ;;
                "chat")
                    cd chat && docker-compose logs -f
                    ;;
                *)
                    echo "Servicio no reconocido"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# Procesar argumentos
case $1 in
    "setup")
        setup
        ;;
    "start"|"stop"|"restart"|"logs")
        if [ -z "$2" ]; then
            echo "Error: Debe especificar un servicio"
            show_help
            exit 1
        fi
        manage_service "$1" "$2"
        ;;
    *)
        show_help
        exit 1
        ;;
esac