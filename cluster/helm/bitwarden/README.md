# Helm chart

Installs the project as a Deployment for Bitwarden community version.

# Installing chart

    cd <path-to-repo>
    ./decrypt.sh
    helm install -n <my-namespace> bitwarden -f values.yaml .

or use a deploy script

    ./deploy

# Migrating from sqlite to external postgres

##### WARN:

pgloader compiled manually from git. Dist version is not working properly.

          load database
               from sqlite://bitwarden.sqlite3
               into postgres://<user>:<password>@<ip>:<port>/<yourdb>
               WITH data only, include no drop, reset sequences
               EXCLUDING TABLE NAMES LIKE '__diesel_schema_migrations'
               ALTER SCHEMA 'bitwarden' RENAME TO 'public'
          ;


    # values.yaml reference
        env:
            DATABASE_URL: postgres://<user>:<password>@<ip>:<port>/<yourdb>
            SIGNUPS_ALLOWED: false
            INVITATIONS_ALLOWED: true
            ADMIN_TOKEN: <yourpassword>
            SERVER_ADMIN_EMAIL: <email>
            DOMAIN: <domain>
            SMTP_HOST: smtp.gmail.com
            SMTP_FROM: <mailfrom>
            SMTP_PORT: 587
            SMTP_SSL: true
            SMPT_FROM_NAME: <mailfrom name>
            SMTP_USERNAME: <mail username>
            SMTP_PASSWORD: <mail password>
            WEB_VAULT_ENABLED: true

# TODO

-   db init container
