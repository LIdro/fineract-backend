FROM eclipse-temurin:17-jdk-focal AS builder

WORKDIR /app

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    dos2unix \
    postgresql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set GRADLE_USER_HOME and other environment variables
ENV GRADLE_USER_HOME=/app/.gradle
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
ENV JAVA_TOOL_OPTIONS="-Xmx4g -Xms512m"

# Create gradle directories
RUN mkdir -p $GRADLE_USER_HOME && \
    mkdir -p /root/.gradle

# Copy gradle files first
COPY gradle gradle/
COPY gradlew gradlew.bat ./
COPY build.gradle settings.gradle gradle.properties ./
RUN dos2unix gradlew && chmod +x gradlew

# Create init.gradle with repository configurations
RUN echo "allprojects {" > /root/.gradle/init.gradle && \
    echo "    repositories {" >> /root/.gradle/init.gradle && \
    echo "        mavenCentral()" >> /root/.gradle/init.gradle && \
    echo "        gradlePluginPortal()" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://repo1.maven.org/maven2' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://plugins.gradle.org/m2/' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-snapshot-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-release-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://packages.confluent.io/maven/' }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "    configurations.all {" >> /root/.gradle/init.gradle && \
    echo "        resolutionStrategy {" >> /root/.gradle/init.gradle && \
    echo "            force 'org.mapstruct:mapstruct-processor:1.5.5.Final'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.mapstruct:mapstruct:1.5.5.Final'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.projectlombok:lombok:1.18.30'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.projectlombok:lombok-mapstruct-binding:0.2.0'" >> /root/.gradle/init.gradle && \
    echo "        }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "}" >> /root/.gradle/init.gradle

# Copy buildSrc
COPY buildSrc buildSrc/

# Copy source files in dependency order
COPY fineract-* fineract-*/
COPY integration-tests integration-tests/
COPY config config/

# Copy license files
COPY APACHE_LICENSETEXT.md LICENSE_SOURCE LICENSE_RELEASE NOTICE_SOURCE NOTICE_RELEASE README.md ./

# Apply license headers
RUN ./gradlew spotlessApply --no-daemon -x :custom:spotlessApply

# Build with specific settings
RUN ./gradlew --no-daemon --console=plain \
    -x downloadLicenses \
    -x rat \
    -x spotlessCheck \
    -x checkstyleMain \
    -x checkstyleTest \
    -x pmdMain \
    -x pmdTest \
    -x :custom:compileJava \
    -x :custom:processResources \
    -x :custom:classes \
    -x :custom:jar \
    -Dfineract.custom.modules.enabled=false \
    clean build && \
    rm -rf /root/.gradle && \
    rm -rf /app/.gradle/caches && \
    rm -rf /app/.gradle/wrapper && \
    rm -rf /app/*/build/reports && \
    rm -rf /app/*/build/test-results && \
    find /app -name "*.jar" -type f -delete

# Create final image
FROM eclipse-temurin:17-jre-focal as runtime

WORKDIR /app

# Install PostgreSQL client and cleanup apt cache
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy only the necessary files from builder
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./
COPY --from=builder /app/LICENSE* ./
COPY --from=builder /app/NOTICE* ./
COPY --from=builder /app/README.md ./

ENV JAVA_OPTS="-Xmx1G -Xms1G"
EXPOSE 8443

ENTRYPOINT ["java", "-jar", "fineract-provider.jar"]
