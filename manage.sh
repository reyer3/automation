# Función para generar variables de entorno
generate_env_vars() {
    # Generar y almacenar todas las variables primero
    DOMAIN_NAME="mibot.cl"
    DATA_FOLDER="/opt/mibot"
    SSL_EMAIL="ricardo@onbotgo.cl"
    AUTOMATION_DOMAIN="automation.${DOMAIN_NAME}"
    EVOLUTION_DOMAIN="evolution.${DOMAIN_NAME}"
    CHAT_DOMAIN="chat-automation.${DOMAIN_NAME}"
    
    # Generar contraseñas
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
    N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)
    SECRET_KEY_BASE=$(openssl rand -base64 64)
    TRAEFIK_AUTH=$(cat ./shared/traefik_users)

    # Generar shared/.env
    echo "Generando shared/.env..."
    {
        echo "# Configuración General"
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
        echo "# N8N Configuración"
        echo "N8N_PORT=5678"
        echo "N8N_PROTOCOL=https"
        echo "N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}"
        echo "GENERIC_TIMEZONE=America/Santiago"
        echo
        echo "# N8N Autenticación"
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
        echo "# Chatwoot Configuración"
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
        echo "# Email (Configurar según necesidades)"
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

# Modificar la función setup para usar generate_env_vars
setup() {
    echo -e "${BLUE}Iniciando setup de MiBot Infrastructure...${NC}"

    # ... (resto del código de setup)

    # Generar archivos .env si no existen
    echo -e "${GREEN}Configurando variables de entorno...${NC}"
    if [ ! -f ./shared/.env ] || [ ! -f ./n8n/.env ] || [ ! -f ./chat/.env ]; then
        # Configurar autenticación de Traefik primero
        if [ ! -f ./shared/traefik_users ]; then
            echo -n "Ingrese usuario para Traefik Dashboard [admin]: "
            read traefikuser
            traefikuser=${traefikuser:-admin}
            
            echo -n "Ingrese contraseña para Traefik Dashboard: "
            read -s traefikpass
            echo

            mkdir -p ./shared/traefik/dynamic
            htpasswd -nb $traefikuser $traefikpass > ./shared/traefik_users
        fi

        # Generar los archivos .env
        generate_env_vars
    fi

    echo -e "${GREEN}Setup completado. Por favor, revisa y ajusta los archivos .env según sea necesario.${NC}"
    echo -e "${BLUE}Importante: Guarda las contraseñas generadas en un lugar seguro.${NC}"
}