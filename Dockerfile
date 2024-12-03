FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Copy the entire source code
COPY . .

# Set execute permissions for gradlew
RUN chmod +x gradlew

# Build the application
RUN --mount=type=cache,id=FvbwKN6GcA-/root/gradle,target=/root/.gradle ./gradlew clean build -x test -x check -x asciidoctor

# Set environment variables
ENV FINERACT_HIKARI_USERNAME=root \
    FINERACT_HIKARI_JDBC_URL=jdbc:mariadb://srv-captain--fineract-db:3306/fineract_tenants \
    FINERACT_SERVER_SSL_ENABLED=false \
    FINERACT_SERVER_PORT=8080

EXPOSE 8080

# Run the application
CMD ["java", "-jar", "fineract-provider/build/libs/fineract-provider.jar"]
