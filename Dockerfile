FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Copy gradle files first for better caching
COPY gradlew build.gradle settings.gradle ./
COPY gradle ./gradle
COPY buildSrc ./buildSrc

# Set execute permissions for gradlew
RUN chmod +x gradlew

# Download dependencies
RUN ./gradlew --no-daemon dependencies

# Copy the rest of the source code
COPY . .

# Build the application
RUN ./gradlew --no-daemon clean build -x test -x check

# Set environment variables
ENV FINERACT_HIKARI_USERNAME=root \
    FINERACT_HIKARI_JDBC_URL=jdbc:mariadb://srv-captain--fineract-db:3306/fineract_tenants \
    FINERACT_SERVER_SSL_ENABLED=false \
    FINERACT_SERVER_PORT=8080

EXPOSE 8080

# Run the application
CMD ["java", "-jar", "fineract-provider/build/libs/fineract-provider.jar"]
