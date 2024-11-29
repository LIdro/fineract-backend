FROM apache/fineract:latest

# Environment variables for configuration
ENV FINERACT_HIKARI_USERNAME=root \
    FINERACT_HIKARI_JDBC_URL=jdbc:mariadb://srv-captain--fineract-db:3306/fineract_tenants \
    FINERACT_SERVER_SSL_ENABLED=false \
    FINERACT_SERVER_PORT=8080

EXPOSE 8080

# The entrypoint is already set in the base image
