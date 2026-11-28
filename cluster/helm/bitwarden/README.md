# Helm chart

Installs the project as a Deployment for Bitwarden community version.

# Installing chart

    cd <path-to-repo>
    ./decrypt.sh
    helm install -n <my-namespace> bitwarden -f values.yaml .

or use a deploy script

    ./deploy

# SSO with Authelia

Vaultwarden signs users in through Authelia (client `vaultwarden`, see
[`cluster/helm/authelia`](../authelia/README.md#openid-connect-provider)).
All `SSO_*` variables, `SSO_CLIENT_SECRET` included, are in `values.enc.yaml`.
They land in the `bitwarden-env` Secret that the pod reads through `envFrom`. The redirect URI is `DOMAIN` plus
`/identity/connect/oidc-signin`.

- `SSO_ONLY=false` keeps the email and master password login.
- SSO replaces only the login step. The master password still decrypts the
  vault, so users enter it after the Authelia login.
- On the first SSO login Vaultwarden links the Authelia identity to the
  existing account with the same email. The Authelia user's email must match
  the Vaultwarden account email.

# Migrating from sqlite to external postgres

## WARN

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

- db init container
