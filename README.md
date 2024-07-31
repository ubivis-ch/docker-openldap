docker-openldap
===============

OpenLDAP image based on Alpine Linux.

Run
---

Simplest example:

    $ docker run -d -p 389:389 -e OPENLDAP_DOMAIN="[e.g. ldap.example.org]" ubivisgmbh/openldap

Typical example:

    $ docker run -d -p 389:389 -v openldap-data:/var/lib/openldap -e OPENLDAP_PASSWORD="[e.g. {SSHA}xxxxxxxxx]" -e OPENLDAP_DOMAIN="[e.g. ldap.example.org]" ubivisgmbh/openldap

Or using Docker Compose (`compose.yaml`):

```
services:

  openldap:
    image: ubivisgmbh/openldap:latest
    restart: always
    ports:
      - 389:389
    environment:
      - "OPENLDAP_PASSWORD=[{SSHA}xxxxxxxxx]"
      - OPENLDAP_DOMAIN=[e.g. ldap.example.org]
      - OPENLDAP_SCHEMAs=misc
      - OPENLDAP_OVERLAYS=memberof,ppolicy
    volumes:
      - data:/var/lib/openldap

volumes:
  data:
```

Configuration (environment variables)
-------------------------------------

### `OPENLDAP_DOMAIN` (mandatory)

Needs to be provided it in the format `example.org` and it will be translated to the root of your tree `dc=example,dc=org`.

### `OPENLDAP_USERNAME` (optional, defaults to `admin`)

Can be set to change the common name (`cn`) of your root DN. I.e. your "root user".

### `OPENLDAP_PASSWORD` (optional)

If not set, there will be a random password generated upon every restart and shown in the logs.

You can set the password either as plain text `OPENLDAP_PASSWORD=secret` or already as its hashed value like
`OPENLDAP_PASSWORD={SSHA}FNPZeM3kipS5uEoCmNIi+f7aq8cTjzPi`. There is a helper functionality to create the hash (see "Helper" below).

### `OPENLDAP_SCHEMAS` (optional)

As a comma-separated list, add additional "official" schemas to the ones already included by default (currently `core`,
`cosine`, `inetorgperson` and `nis`). Additional schemas are: `collective`, `corba`, `dsee`, `duaconf`, `dyngroup`,
`java`, `misc`, `msuser`, `namedobject`, `openldap` and `pmi`.

### `OPENLDAP_OVERLAYS` (optional)

As a comma-separated list, add overlays (see Alpine Linux package `openldap-overlay-all`) to your installation. Currently
only the overlays `memberof`, `ppolicy` and `refint` also contain a sensitive configuration, which is loaded.

Data persistence
----------------

### `/var/lib/openldap`

This is where the MDB data of your is held.

Helper
------

### ssha

It's never a good idea to have plaintext passwords in configurations. So it's a good prctice to always set `OPENLDAP_PASSWORD` with the hash.

Run 

    $ docker run --rm ubivisgmbh/openldap ssha very_secret
    Password hash: {SSHA}OeNfUDkfJPRdkx6QeouwAQW4DhJKJnoZ
    
to let it calculate the salted SHA hash for you.

Even better (to also hide it from your shell history), run

    $ docker run -it --rm ubivisgmbh/openldap ssha
    Password (hidden): 
    Password hash: {SSHA}bO1SVSruBDA23pBYsc04FigV0nQRsb6J

Notes
-----

Intentionally there is no configuration that needs to be saved between runs, as upon every container restart, the whole
configuration (i.e. `cn=config` tree) gets recreated (based on the envrionment variables). This means two things:

* You should *never* change anything in the `cn=config` tree as it will be lost on the next restart.
* Whenever you change `OPENLDAP_DOMAIN`, your "user-facing" database will not be accessible anymore.


Development / Bugs
------------------

Development takes place on Github:

https://github.com/ubivis-ch/docker-openldap

Please report any issues to:

https://github.com/ubivis-ch/docker-openldap/issues

