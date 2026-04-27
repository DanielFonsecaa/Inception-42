# 🐳 INCEPTION - Projeto 42 Docker Infrastructure

Infraestrutura Docker completa para o projeto Inception da 42School. Implementa WordPress + PHP-FPM + MariaDB + NGINX com TLS 1.2/1.3, seguindo rigorosamente as restrições do projeto.

![Status](https://img.shields.io/badge/Status-Production%20Ready-green)
![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## 📋 Visão Geral

### Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    🌍 Internet (HTTPS:443)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                    Port 443/80
                         │
        ┌────────────────▼────────────────┐
        │   🔒 NGINX (Reverse Proxy)      │
        │   - TLS 1.2 / 1.3               │
        │   - SSL Auto-Signed             │
        │   - Security Headers            │
        │   - HTTP → HTTPS Redirect       │
        └────────────────┬────────────────┘
                         │ (Port )
        ┌────────────────▼────────────────┐
        │  📝 WordPress + PHP-FPM 7.4     │
        │  - Debian 11.8 Base             │
        │  - WP 6.4.2                     │
        │  - 2 Usuários configurados      │
        │  - Volume persistente           │
        └────────────────┬────────────────┘
                         │ (Port 3306)
        ┌────────────────▼────────────────┐
        │  🗄️ MariaDB 10.5                │
        │  - Debian 11.8 Base             │
        │  - Banco wordpress              │
        │  - Usuário www-data com perms   │
        │  - Volume persistente           │
        └────────────────────────────────┘

        ─────── Rede Docker Dedicada ──────
```

### Serviços

| Serviço | Imagem Base | Versão | Porta | Dados Persistentes |
|---------|------------|--------|-------|-------------------|
| **NGINX** | Alpine 3.18.4 | 1.24.0 | 443/80 | - |
| **WordPress** | Debian 11.8 | 6.4.2 |  | `/home/user/data/wordpress` |
| **PHP-FPM** | Debian 11.8 | 7.4 |  | - |
| **MariaDB** | Debian 11.8 | 10.5 | 3306 | `/home/user/data/mariadb` |

---

## ✨ Características

### Conformidade com Restrições Projeto

✅ **Infraestrutura**
- ✓ Docker Compose para orquestração
- ✓ Debian 11.8 (penúltima versão estável)
- ✓ Dockerfiles customizados (sem imagens prontas)
- ✓ Domínio `dda-fons.42.fr` em hosts local

✅ **Serviços Obrigatórios**
- ✓ NGINX como reverse proxy
- ✓ TLS 1.2 + 1.3 (certificado SSL auto-assinado)
- ✓ WordPress + PHP-FPM
- ✓ MariaDB container separado
- ✓ Usuário admin: `fonsecaadm` (sem "admin" no nome)

✅ **Persistência e Rede**
- ✓ Volumes nomeados (proibido bind mounts)
- ✓ Dados em `$HOME/data`
- ✓ Rede Docker dedicada (`inception_network`)

✅ **Segurança e Execução**
- ✓ Sem tag `:latest` em imagens
- ✓ Senhas via `.env` (não em Dockerfiles)
- ✓ Sem `tail -f`, `sleep infinity` ou loops
- ✓ Health checks em todos serviços
- ✓ Usuários não-root

---

## 🚀 Quick Start

### Requisitos Mínimos

- Linux (Ubuntu 20.04+ ou Debian 11+)
- Docker 20.10+
- Docker Compose 1.29.2+
- 4GB RAM
- 20GB disco livre

### Instalação Rápida

```bash
# 1. Clonar/Baixar projeto
cd ~
git clone <seu-repo> inception && cd inception

# 2. Configurar domínio
echo "127.0.0.1  dda-fons.42.fr" | sudo tee -a /etc/hosts

# 3. Gerar certificado SSL
mkdir -p srcs/requirements/nginx/conf/ssl
cd srcs/requirements/nginx/conf/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout private.key -out certificate.crt \
    -subj "/C=PT/ST=Porto/L=Porto/O=42/CN=dda-fons.42.fr"
cd ~/inception

# 4. Build e iniciar
make all

# 5. Acessar
# Abrir navegador: https://dda-fons.42.fr
# Login: fonsecaadm / AdminPass@2024
```

### Credenciais Padrão

```
ADMIN WORDPRESS
├─ Usuário: fonsecaadm
├─ Senha: AdminPass@2024
└─ Email: admin@dda-fons.42.fr

USUÁRIO EDITOR
├─ Usuário: johndoe
├─ Senha: User1Pass@2024
└─ Email: john@dda-fons.42.fr

MARIADB
├─ Root: root / RootSecure@2024
└─ WordPress: wordpress / WPPass@2024
```

⚠️ **IMPORTANTE**: Alterar senhas em `srcs/.env` em produção!

---

## 📁 Estrutura de Projeto

```
inception/
├── Makefile                    # Automação
├── .env                        # Variáveis globais (NÃO COMMIT!)
├── .gitignore                  # Ignorar sensíveis
├── INSTALLATION.md             # Guia completo
├── README.md                   # Este arquivo
│
└── srcs/
    ├── docker-compose.yml      # Orquestração
    ├── .env                    # Backup variáveis
    │
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile      # Imagem NGINX
        │   └── conf/
        │       ├── nginx.conf   # Config TLS
        │       └── ssl/
        │           ├── certificate.crt
        │           └── private.key
        │
        ├── wordpress/
        │   ├── Dockerfile      # Imagem WordPress
        │   ├── conf/
        │   │   └── www.conf     # Config PHP-FPM
        │   └── tools/
        │       └── wordpress-init.sh
        │
        └── mariadb/
            ├── Dockerfile      # Imagem MariaDB
            ├── conf/
            │   └── mariadb.conf # Config MariaDB
            └── tools/
                └── mariadb-init.sh
```

---

## 🛠️ Makefile Commands

```bash
make help      # Mostrar todos os comandos
make all       # Build + iniciar (padrão)
make build     # Construir imagens
make up        # Iniciar containers
make down      # Parar containers
make re        # Rebuild completo (fclean + all)
make clean     # Remover imagens
make fclean    # Limpar TUDO (irreversível!)
make logs      # Ver logs em tempo real
make ps        # Status dos containers
```

---

## 🔐 Segurança Implementada

### SSL/TLS
- ✅ Certificado auto-assinado RSA 2048-bit
- ✅ TLS 1.2 e 1.3
- ✅ Cipher suites modernos
- ✅ HSTS (HTTP Strict Transport Security)
- ✅ Redirecionamento HTTP → HTTPS

### Headers HTTP
```
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### Banco de Dados
- ✅ Usuário não-root para WordPress
- ✅ Usuários anônimos removidos
- ✅ Banco `test` removido
- ✅ Acesso remoto root desabilitado

### Aplicação
- ✅ Desabilitar edição de arquivos
- ✅ Limitar uploads de arquivos (20MB)
- ✅ Bloquear acesso a wp-config.php

---

## 📊 Verificação de Saúde

### Health Checks
Todos os containers possuem health checks automáticos:

```bash
# Ver status
docker-compose -f srcs/docker-compose.yml ps

# Output esperado:
# STATUS: Up 5 minutes (healthy)
```

### Testes Manuais

```bash
# 1. Testar HTTPS
curl -k https://dda-fons.42.fr/

# 2. Verificar certificado
openssl s_client -connect localhost:443 </dev/null 2>/dev/null | openssl x509 -text

# 3. Testar banco de dados
docker exec mariadb mysql -u wordpress -pWPPass@2024 wordpress -e "SHOW TABLES;"

# 4. Ver logs
docker-compose -f srcs/docker-compose.yml logs -f
```

---

## 🐛 Troubleshooting

### HTTPS mostra aviso de certificado
**Esperado** - Certificado auto-assinado. Clique "Avançado" → "Aceitar Risco".

### Porto 443 já em uso
```bash
sudo lsof -i :443
sudo kill -9 <PID>
```

### MariaDB não inicia
```bash
docker logs mariadb
sudo chown -R 999:999 ~/data/mariadb/
docker-compose -f srcs/docker-compose.yml restart mariadb
```

### DNS não resolve
```bash
echo "127.0.0.1  dda-fons.42.fr" | sudo tee -a /etc/hosts
sudo systemctl restart systemd-resolved
```

Veja `INSTALLATION.md` para mais soluções.

---

## 📈 Monitoramento e Manutenção

### Verificar Espaço em Disco
```bash
du -sh ~/data/*
df -h
```

### Limpar Caches
```bash
docker system prune -a  # Remove images não usadas
docker volume prune     # Remove volumes órfãos
```

### Backup
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz ~/data/
```

### Atualizar Configuração
```bash
# Editar arquivo
nano srcs/requirements/nginx/conf/nginx.conf

# Rebuild serviço
docker-compose -f srcs/docker-compose.yml restart nginx
```

---

## 🔄 Ciclo de Vida

### Desenvolvimento
```bash
make down      # Parar containers
# Editar arquivos
make build     # Rebuild imagens
make up        # Reiniciar
```

### Produção
```bash
make all       # Deploy inicial
make logs      # Monitoramento
make ps        # Status check
```

### Limpeza Completa
```bash
make fclean    # Remove tudo (irreversível!)
# Repositório fica limpo, ready para redeploy
```

---

## 📚 Documentação Adicional

- **[INSTALLATION.md](./INSTALLATION.md)** - Guia passo-a-passo completo
- **[Dockerfile NGINX](./srcs/requirements/nginx/Dockerfile)** - Configuração NGINX
- **[Dockerfile WordPress](./srcs/requirements/wordpress/Dockerfile)** - WordPress + PHP-FPM
- **[Dockerfile MariaDB](./srcs/requirements/mariadb/Dockerfile)** - Banco de dados

---

## 📞 Suporte

### Verifique Primeiro
1. Ler `INSTALLATION.md` completamente
2. Verificar logs: `make logs`
3. Revisar `.env`: `cat srcs/.env | grep PASSWORD`
4. Status containers: `make ps`

### Comandos Úteis
```bash
make help              # Todos os comandos
docker-compose config  # Validar docker-compose.yml
docker inspect <container> # Info detalhada

```

