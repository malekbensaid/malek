pipeline {
    agent any
    
    environment {
        // Remplacer par votre nom d'utilisateur Docker Hub
        DOCKER_USERNAME = 'malek50' 
        
        // Adresse IP de SonarQube et port
        SONAR_HOST_URL = 'http://10.0.2.15:9000'
        // Jeton SonarQube (à remplacer par le vôtre si différent)
        SONAR_LOGIN = 'squ_2f7edc6f021ad73990345fa234d13409675fdf2a' 
    }

    tools {
        // Assurez-vous que ces outils sont configurés dans Jenkins
        maven 'M3' 
        jdk 'JDK17'
        // Nous allons supposer que Docker est accessible sans tool specific
    }
    
    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/master']], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git']]
                ])
            }
        }
        
        stage('Build & Package') {
            steps {
                echo 'Compilation et packaging du projet (sans tests)...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('Quality Analysis (SonarQube)') {
            steps {
                echo 'Lancement de l\'analyse SonarQube...'
                sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_LOGIN}"
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
                echo 'Construction de l\'image Docker...'
                // CORRECTION 1: Suppression de 'sudo'
                sh "docker build -t ${env.DOCKER_USERNAME}/students-app:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Authentification et déploiement sur Docker Hub...'
                // Utilisation de l'identifiant stocké sous l'ID 'docker-hub-credentials'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    // CORRECTION 2: Suppression de 'sudo' pour l'authentification
                    sh "docker login -u ${env.DOCKER_USERNAME} -p ${env.DOCKER_PASSWORD}" 

                    // CORRECTION 3: Suppression de 'sudo' pour le push
                    sh "docker push ${env.DOCKER_USERNAME}/students-app:latest" 
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                echo 'Déploiement sur Minikube...'
                // Application du Deployment YAML
                sh 'kubectl apply -f k8s/deployment.yaml' 
            }
        }
    }
    
    post {
        always {
            echo 'Nettoyage des sessions Docker...'
            // CORRECTION 4: Suppression de 'sudo' pour la déconnexion
            sh 'docker logout' 
        }
        success {
            echo 'Félicitations ! Le pipeline a réussi et l\'application est déployée sur Minikube.'
        }
        failure {
            echo 'Le build a échoué. Veuillez vérifier la sortie de la console.'
        }
    }
}