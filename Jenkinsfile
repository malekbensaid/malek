pipeline {
    agent any

    // Déclare les outils (Maven, JDK) pour les étapes de compilation et de test
    tools {
        maven "M3"
        jdk 'JDK17'
    }

    stages {
        stage('Git: Checkout SCM') {
            steps {
                echo 'Clonage du code depuis GitHub...'
                // Utilisation de VOS URL et Credentials ID
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/master']], 
                    userRemoteConfigs: [[credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git']]
                ])
            }
        }

        stage('Build with Maven') {
            steps {
                echo 'Nettoyage et compilation...'
                sh 'mvn clean install'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Exécution des tests unitaires...'
                sh 'mvn test'
            }
        }
        
        stage('MVN SONARQUBE') {
            steps {
                echo 'Lancement de l\'analyse SonarQube avec votre Jeton personnel...'
                // Utilise votre ID de credential Sonar pour une meilleure sécurité
                withCredentials([string(credentialsId: 'SONAR_TOKEN_JENKINS', variable: 'SONAR_TOKEN' )]) {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }
        
        stage('Jacoco Static Analysis') {
            steps {
                echo 'Analyse de la couverture de code Jacoco...'
                // Publie les rapports de tests
                junit 'target/surefire-reports/**/*.xml'
                jacoco() // Utilise la fonction Jacoco
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Archivage du JAR...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "Construction de l\'image Docker: malek50/students-app:latest"
                // Utilise VOS tags Docker
                sh 'docker build -t malek50/students-app:latest -f Dockerfile .'
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Authentification et déploiement sur Docker Hub...'
                // Utilise l'ID de credential standard pour Docker Hub
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        // Pousse VOS tags Docker
                        sh 'docker push malek50/students-app:latest'
                    }
                }
            }
        }
        
        stage('Docker Compose') {
            steps {
                echo 'Démarrage des services avec Docker Compose...'
                sh 'docker-compose up -d' // Commande du professeur
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo 'Déploiement de l\'artefact sur Nexus...'
                sh 'mvn deploy' // Commande du professeur
            }
        }
        
        stage('Deploy to Kubernetes') {
             steps {
                echo 'Application du déploiement Kubernetes (students-app)...'
                // Utilise votre chemin racine corrigé
                sh 'kubectl apply -f deployment.yaml'  
            }
        }
        
        // --- ÉTAPES D'INFRASTRUCTURE ET MONITORING ---
        
        stage('Prometheus') {
            steps {
                sh 'docker start prometheus' // Commande du professeur
            }
        }
        
        stage('Grafana') {
            steps {
                sh 'docker start grafana' // Commande du professeur
            }
        }
        
        stage('Terraform') {
            steps {
                echo 'Lancement des commandes Terraform...'
                sh 'terraform init'
                sh 'terraform apply -auto-approve' // Commandes du professeur
            }
        }
    }
    
    post {
        success {
            echo 'Build réussi. Envoi de la notification de succès.'
            // Utilise VOTRE email pour la notification de succès
            emailext(
                subject: "Build Success: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a réussi. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid50@gmail.com' 
            )
        }
        failure {
            echo 'Build échoué. Envoi de la notification d\'échec.'
            // Utilise VOTRE email pour la notification d'échec
            emailext(
                subject: "Build Failed: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a échoué. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid50@gmail.com' 
            )
        }
    }
}