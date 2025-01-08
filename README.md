# MiBot Automation Infrastructure

Infraestructura de automatización que incluye:
- N8N para automatización de flujos de trabajo
- Chatwoot para gestión de chat
- Traefik como reverse proxy
- PostgreSQL y Redis como servicios compartidos

## Estructura del Proyecto

```
automation/
├── manage.sh                 # Script unificado de gestión
├── shared/                  # Servicios compartidos
│   ├── docker-compose.yml   # Traefik, PostgreSQL, Redis
│   ├── .env                # Variables compartidas
│   ├── postgresql/         # Scripts de PostgreSQL
│   └── traefik/           # Configuración de Traefik
├── n8n/                    # Servicio N8N
└── chat/                   # Servicio Chatwoot
```

## Requisitos

- Docker
- Docker Compose
- OpenSSL (para generación de secretos)
- Apache Utils (para htpasswd)

## Configuración Inicial

1. Clonar el repositorio:
```bash
git clone <repository-url>
cd automation
```

2. Ejecutar el setup inicial:
```bash
./manage.sh setup
```

3. Revisar y ajustar los archivos .env generados en:
- shared/.env
- n8n/.env
- chat/.env

## Uso

### Iniciar Servicios
```bash
./manage.sh start all    # Inicia todos los servicios
./manage.sh start n8n    # Inicia solo N8N
./manage.sh start chat   # Inicia solo Chatwoot
```

### Detener Servicios
```bash
./manage.sh stop all     # Detiene todos los servicios
./manage.sh stop n8n     # Detiene solo N8N
```

### Ver Logs
```bash
./manage.sh logs traefik # Logs de Traefik
./manage.sh logs n8n     # Logs de N8N
./manage.sh logs chat    # Logs de Chatwoot
```

## Acceso a Servicios

- N8N: https://automation.mibot.cl
- Chatwoot: https://chat-automation.mibot.cl
- Traefik Dashboard: https://traefik.mibot.cl

## Seguridad

- Todos los servicios están protegidos con SSL/TLS
- Autenticación básica habilitada para N8N y Traefik Dashboard
- Contraseñas generadas automáticamente durante el setup
- Headers de seguridad configurados en Traefik

## Mantenimiento

- Los datos persistentes se almacenan en /root/n8n/
- Las bases de datos se respaldan automáticamente
- Los logs se rotan automáticamente

## Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/amazing-feature`)
3. Commit tus cambios (`git commit -m 'Add some amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request
