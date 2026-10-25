All PHP images always have the following drivers:
- redis
- sqlsrv
- pdo_sqlsrv
- odbc
- pgsql
- pdo_pgsql
- composer

| Image | Dockerfile | sqlsrv |
|---|---|---|
| `khgtrn/php:8.5-fpm-alpine` | `8.5-fpm-alpine.Dockerfile` | 5.13.3 |
| `khgtrn/php:8.4-fpm-alpine` | `8.4-fpm-alpine.Dockerfile` | 5.13.3 |
| `khgtrn/php:8.3-fpm-alpine` | `8.3-fpm-alpine.Dockerfile` | 5.13.3 |
| `khgtrn/php:8.2-fpm-alpine` | `8.2-fpm-alpine.Dockerfile` | 5.12.0 (5.13 requires PHP >= 8.3) |

Build deps are removed in the same layer and `asset/` is bind-mounted at build time, so only runtime files stay in the image.

```sh
make build-php-8.5   # or build-php-8.4 / build-php-8.3 / build-php-8.2
make push-php-8.5
make build-php push-php   # all versions
```
