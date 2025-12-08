pipeline {
    agent any
    
    // NOUVELLE SECTION: Déclaration des variables globales
    environment {
        // CORRIGÉ : Nom de l'image Docker mis à jour pour correspondre à votre dépôt Docker Hub
        DOCKER_IMAGE = 'malek50/students-app:latest' 
        // Le Jeton SonarQube valide qui a fonctionné
        SONAR_TOKEN = 'squ_59669dae40f1829cd795dddd0624af4ce19a62f9'
    }
    
    tools {
        // Assurez-vous que l'outil Maven 'M2_HOME' est bien configuré dans Jenkins
        maven 'M2_HOME' 
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Clonage du dépôt Git ou accès au dossier synchronisé..."
            }
        }
        
        stage('Build & Package') {
            steps {
                echo "Compilation et packaging du projet (sans tests)..."
                // CORRIGÉ : Suppression de 'sudo -u vagrant'
                sh 'mvn package -DskipTests' 
            }
        }
        
        // NOUVELLE ÉTAPE: Vérification de la qualité du code (exigence SonarQube)
        stage('Quality Analysis (SonarQube)') {
            steps {
                echo "Lancement de l'analyse SonarQube..."
                sh """
                mvn sonar:sonar \\
                  // CORRIGÉ : Utilisation de l'IP de la VM 10.0.2.15 au lieu de localhost
                  -Dsonar.host.url=http://10.0.2.15:9000 \\ 
                  -Dsonar.token=${SONAR_TOKEN}
                """
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                echo "Archivage du JAR..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        // NOUVELLE ÉTAPE: Création de l'image Docker (exigence Dockerfile)
        stage('Build Docker Image') {
            steps {
                echo "Construction de l'image Docker..."
                sh 'sudo docker build -t ${DOCKER_IMAGE} .'
            }
        }
        
        // NOUVELLE ÉTAPE: Déploiement sur Docker Hub (exigence Docker Hub)
        stage('Push to Docker Hub') {
            steps {
                echo "Authentification et déploiement sur Docker Hub..."
                // Utilise les identifiants créés dans Jenkins (ID: 'docker-hub-credentials')
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USER')]) {
                    sh 'sudo docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}'
                    sh 'sudo docker push ${DOCKER_IMAGE}'
                }
            }
        }
        
        // NOUVELLE ÉTAPE: Déploiement sur Minikube (exigence Minikube)
        stage('Deploy to Minikube') {
            steps {
                echo "Déploiement du cluster via kubectl..."
                // Nécessite que vous ayez un fichier de déploiement Kubernetes (.yaml)
                sh 'kubectl apply -f k8s/deployment.yaml'
            }
        }
    }
    
    post {
        always {
            sh 'sudo docker logout' // Déconnexion de Docker Hub pour la sécurité
            echo 'Pipeline terminé.'
        }
        success {
            echo 'Le build a réussi ! Le JAR est archivé et l\'image est déployée.'
        }
        failure {
            echo 'Le build a échoué. Veuillez vérifier la sortie de la console.'
        }
    }
}