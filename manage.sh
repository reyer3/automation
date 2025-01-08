# Generar archivos .env si no existen
    echo -e "${GREEN}Configurando variables de entorno...${NC}"
    if [ ! -f ./shared/.env ]; then
        # Generar contraseñas
        POSTGRES_PASSWORD=$(openssl rand -base64 32)
        REDIS_PASSWORD=$(openssl rand -base64 32)
        
        # Usar heredoc sin comillas para permitir expansión de variables
        cat > ./shared/.env << EOL
# Configuración General
DOMAIN_NAME=mibot.cl
DATA_FOLDER=/opt/mibot
SSL_EMAIL=ricardo@onbotgo.cl

# Dominios
AUTOMATION_DOMAIN=automation.mibot.cl
EVOLUTION_DOMAIN=evolution.mibot.cl
CHAT_DOMAIN=chat-automation.mibot.cl

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=postgres
POSTGRES_MULTIPLE_DATABASES=n8n,chatwoot

# Redis
REDIS_PASSWORD=${REDIS_PASSWORD}

# Traefik Dashboard
TRAEFIK_DASHBOARD_AUTH=$(cat ./shared/traefik_users)
EOL
    fi

    if [ ! -f ./n8n/.env ]; then
        # Generar claves para N8N
        N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
        N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)
        
        # Crear archivo N8N .env
        cat > ./n8n/.env << EOL
# N8N Configuración
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
GENERIC_TIMEZONE=America/Santiago

# N8N Autenticación
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}

# Base de datos
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Redis
REDIS_USER=default
REDIS_PASSWORD=${REDIS_PASSWORD}
EOL
    fi

    if [ ! -f ./chat/.env ]; then
        # Generar clave para Chatwoot
        SECRET_KEY_BASE=$(openssl rand -base64 64)
        
        # Crear archivo Chatwoot .env
        cat > ./chat/.env << EOL
# Chatwoot Configuración
SECRET_KEY_BASE=${SECRET_KEY_BASE}
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker

# Base de datos
POSTGRES_HOST=postgres
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=chatwoot

# Redis
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=${REDIS_PASSWORD}

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