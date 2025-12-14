pipeline {
    agent any

    // Variables globales du pipeline
    environment {
        // --- Variables de Configuration ---
        DOCKER_IMAGE = 'malek50/students-app'
        DOCKER_TAG = 'latest'
        NAMESPACE = 'devops'
        
        // Nom du fichier de déploiement dans le dépôt
        DEPLOYMENT_FILE = 'deployment.yaml' 

        // Variables pour la connexion à SonarQube
        SONAR_HOST_URL = 'http://127.0.0.1:9000'
        
        // Variable pour contourner le problème DNS de K8s (si besoin, nous allons tester d'abord sans)
        SPRING_DATASOURCE_URL = 'jdbc:mysql://mysql-service:3306/db_example?useSSL=false'
    }

    stages {
        // --- ÉTAPE 1 : Préparation & Récupération du Code (GitHub) ---
        stage('1. Checkout Code') {
            steps {
                echo "1. Clonage du code depuis GitHub..."
                // Utiliser l'ID de credential que vous avez configuré pour GitHub
                git branch: 'master', credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git'
            }
        }
        
        // --- ÉTAPE 2 : Démarrage de l'Analyse (SonarQube) ---
        stage('2. Start SonarQube') {
            steps {
                echo "Démarrage du conteneur SonarQube via Docker..."
                // Nettoyer et relancer le conteneur SonarQube sur le port 9000
                sh 'sudo docker rm -f sonarqube'
                sh 'sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community'
                
                echo "Attente de la disponibilité de SonarQube (max 60 secondes)..."
                sh """
                    for i in \$(seq 1 60); do
                        curl -s ${SONAR_HOST_URL}/api/server/version && echo "SonarQube est prêt (\$i secondes)." && exit 0
                        sleep 1
                    done
                    echo "Erreur: SonarQube n'a pas démarré à temps." && exit 1
                """
            }
        }

        // --- ÉTAPE 3 : Compilation & Analyse de Qualité ---
        stage('3. Build & Quality Analysis') {
            steps {
                echo "2. Compilation (Maven) et analyse SonarQube."
                // Le withCredentials utilise l'ID 'SONAR_TOKEN'
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_AUTH_TOKEN')]) {
                    withSonarQubeEnv('SonarQube 9.9') { 
                        // Exécuter Maven clean install ET lancer l'analyse SonarQube
                        sh "mvn clean install -DskipTests sonar:sonar -Dsonar.login=${SONAR_AUTH_TOKEN} -Dsonar.host.url=${SONAR_HOST_URL}"
                    }
                }
            }
        }

        // --- ÉTAPE 4 : Création et Envoi de l'Image Docker ---
        stage('4. Docker Build and Push') {
            steps {
                echo "4. Construction et Push de l'image Docker."
                // Utiliser l'ID de credential pour Docker Hub
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    // Se connecter à Docker Hub
                    sh "sudo docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    
                    // Construire l'image (le .jar a été créé à l'étape 3)
                    sh "sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    
                    // Pousser l'image vers Docker Hub
                    sh "sudo docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        // --- ÉTAPE 5 : Déploiement sur Kubernetes ---
        stage('5. Deploy to Kubernetes') {
            steps {
                echo "5. Déploiement de l'application sur Minikube (K8S)."
                
                // --- STRATÉGIE DE DÉPLOIEMENT ---
                // 1. Mise à jour de la variable d'environnement (datasource URL) dans le déploiement YAML
                // On utilise le nom du service 'mysql-service'
                sh """
                    # Assurez-vous que le namespace existe (redondant, mais sécurisant)
                    minikube kubectl -- create namespace ${NAMESPACE} --dry-run=client -o yaml | minikube kubectl -- apply -f -
                    
                    # Mise à jour du fichier YAML pour injecter l'URL (utilise la variable d'env K8S)
                    sed "s|SPRING_DATASOURCE_URL_PLACEHOLDER|${SPRING_DATASOURCE_URL}|g" ${DEPLOYMENT_FILE} > updated_${DEPLOYMENT_FILE}
                    
                    # Appliquer la configuration K8S
                    minikube kubectl -- apply -f updated_${DEPLOYMENT_FILE} -n ${NAMESPACE}
                    
                    # Redémarrer l'application pour utiliser la nouvelle image/configuration
                    minikube kubectl -- rollout restart deployment students-app-deployment -n ${NAMESPACE}
                """
            }
        }
    }
    
    // --- POST-ACTIONS : Nettoyage ---
    post {
        always {
            echo "Nettoyage : Arrêt et suppression du conteneur SonarQube..."
            sh "sudo docker rm -f sonarqube"
            // Nettoyage de l'espace de travail Jenkins
            cleanWs()
        }
    }
}