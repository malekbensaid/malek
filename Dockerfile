# Dockerfile minimal pour l'application Spring Boot

# --- ÉTAPE 1: BUILD (Compilation du projet) ---
# Utilise Maven et le JDK 17 pour compiler le projet
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app

# Copie le pom.xml pour télécharger les dépendances (meilleur utilisation du cache Docker)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copie le code source et compile
COPY src ./src
RUN mvn clean package -DskipTests

# --- ÉTAPE 2: RUN (Image finale pour l'exécution) ---
# CONTRETOURNEMENT DU PROBLÈME RÉSEAU : 
# Nous utilisons l'étape 'build' elle-même comme image finale.
# C'est plus lourd (contient Maven/JDK) mais garantit l'exécution immédiate.
FROM build 

WORKDIR /app

# Déplace l'artefact JAR créé par Maven à la racine du WORKDIR
# Ceci évite d'avoir à spécifier le numéro de version dans l'ENTRYPOINT.
# L'artefact est déjà présent car nous utilisons 'FROM build'.
RUN mv /app/target/student-management-0.0.1-SNAPSHOT.jar /app/app.jar

EXPOSE 8080

# Commande pour démarrer l'application Spring Boot
ENTRYPOINT ["java", "-jar", "app.jar"]