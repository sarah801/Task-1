version: "3.8"
services:
  web:
    container_name: UC16_web
    build:
      context: .
      dockerfile: odoo.Dockerfile
    command: odoo --dev xml
    depends_on:
      - db
    ports:
      - 8069:8069
    volumes:
      - ./home/odoo/.local/share/Odoo:/var/lib/odoo
      - ./config:/etc/odoo
      - /home/odoo-support/uc_con/uc16_custom:/mnt/extra-addons
      - /home/odoo-support/uc_con/addons16_new:/mnt/enterprise
    env_file: ./config/.env
    restart: "always"
    stdin_open: true
    tty: true

  db:
    container_name: UC16_db
    build:
      context: .
      dockerfile: postgres.Dockerfile
    ports:
      - 5432:5432
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    env_file: ./config/.penv
    restart: "always"
