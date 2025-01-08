#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función de ayuda
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

# Función de setup
setup() {
    echo -e "${BLUE}Iniciando setup de MiBot Infrastructure...${NC}"

    # Crear directorios necesarios
    echo -e "${GREEN}Creando directorios...${NC}"
    mkdir -p /root/n8n/{postgresql,redis,letsencrypt,.n8n,n8n-files,chatwoot/storage}
    chmod -R 777 /root/n8n

    # Asegurar permisos del script de inicialización de PostgreSQL
    echo -e "${GREEN}Configurando permisos de scripts...${NC}"
    chmod +x ./shared/postgresql/init-multiple-dbs.sh

    # Crear red de Docker
    echo -e "${GREEN}Creando red de Docker...${NC}"
    docker network create automation-network || true

    # Crear archivo de contraseña para Traefik Dashboard
    echo -e "${GREEN}Configurando autenticación para Traefik Dashboard...${NC}"
    if [ ! -f ./shared/traefik_users ]; then
        echo -n "Ingrese usuario para Traefik Dashboard [admin]: "
        read traefikuser
        traefikuser=${traefikuser:-admin}
        
        echo -n "Ingrese contraseña para Traefik Dashboard: "
        read -s traefikpass
        echo

        # Instalar apache2-utils si no está instalado
        if ! command -v htpasswd &> /dev/null; then
            apt-get update && apt-get install -y apache2-utils
        fi

        mkdir -p ./shared/traefik/dynamic
        htpasswd -nb $traefikuser $traefikpass > ./shared/traefik_users
    fi

    # Generar archivos .env si no existen
    echo -e "${GREEN}Configurando variables de entorno...${NC}"
    if [ ! -f ./shared/.env ]; then
        cat > ./shared/.env << EOL
# Configuración General
DOMAIN_NAME=mibot.cl
DATA_FOLDER=/root/n8n
SSL_EMAIL=ricardo@onbotgo.cl

# Dominios
AUTOMATION_DOMAIN=automation.\${DOMAIN_NAME}
EVOLUTION_DOMAIN=evolution.\${DOMAIN_NAME}
CHAT_DOMAIN=chat-automation.\${DOMAIN_NAME}

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=\$(openssl rand -base64 32)
POSTGRES_DB=postgres
POSTGRES_MULTIPLE_DATABASES=n8n,chatwoot

# Redis
REDIS_PASSWORD=\$(openssl rand -base64 32)

# Traefik Dashboard
TRAEFIK_DASHBOARD_AUTH=\$(cat ./shared/traefik_users)
EOL
    fi

    if [ ! -f ./n8n/.env ]; then
        cat > ./n8n/.env << EOL
# N8N Configuración
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_ENCRYPTION_KEY=\$(openssl rand -base64 32)
GENERIC_TIMEZONE=America/Santiago

# N8N Autenticación
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=\$(openssl rand -base64 16)

# Base de datos
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}

# Redis
REDIS_USER=default
REDIS_PASSWORD=\${REDIS_PASSWORD}
EOL
    fi

    if [ ! -f ./chat/.env ]; then
        cat > ./chat/.env << EOL
# Chatwoot Configuración
SECRET_KEY_BASE=\$(openssl rand -base64 64)
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker

# Base de datos
POSTGRES_HOST=postgres
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
POSTGRES_DB=chatwoot

# Redis
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=\${REDIS_PASSWORD}

# Email (Configurar según necesidades)
SMTP_DOMAIN=mibot.cl
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@mibot.cl
SMTP_PASSWORD=your_email_password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
DEFAULT_MAILER_FROM_EMAIL=your_email@mibot.cl

# Storage
ACTIVE_STORAGE_SERVICE=local
RAILS_MAX_THREADS=5

# Otros
ENABLE_ACCOUNT_SIGNUP=false
FORCE_SSL=true
EOL
    fi

    echo -e "${GREEN}Setup completado. Por favor, revisa y ajusta los archivos .env según sea necesario.${NC}"
    echo -e "${BLUE}Importante: Guarda las contraseñas generadas en un lugar seguro.${NC}"
}

# Función para manejar servicios
manage_service() {
    local action=$1
    local service=$2
    
    case $action in
        "start")
            if [ "$service" = "all" ] || [ "$service" = "shared" ]; then
                echo -e "${GREEN}Iniciando servicios compartidos...${NC}"
                cd shared && docker-compose up -d
            fi
            if [ "$service" = "all" ] || [ "$service" = "n8n" ]; then
                echo -e "${GREEN}Iniciando N8N...${NC}"
                cd ../n8n && docker-compose up -d
            fi
            if [ "$service" = "all" ] || [ "$service" = "chat" ]; then
                echo -e "${GREEN}Iniciando Chatwoot...${NC}"
                cd ../chat && docker-compose up -d
            fi
            ;;
        "stop")
            if [ "$service" = "all" ] || [ "$service" = "chat" ]; then
                echo -e "${GREEN}Deteniendo Chatwoot...${NC}"
                cd chat && docker-compose down
            fi
            if [ "$service" = "all" ] || [ "$service" = "n8n" ]; then
                echo -e "${GREEN}Deteniendo N8N...${NC}"
                cd n8n && docker-compose down
            fi
            if [ "$service" = "all" ] || [ "$service" = "shared" ]; then
                echo -e "${GREEN}Deteniendo servicios compartidos...${NC}"
                cd shared && docker-compose down
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
