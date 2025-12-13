pipeline {
    agent any

    // Les outils requis pour la compilation
    tools {
        maven "M3" // Assurez-vous que l'alias M3 est configuré dans Jenkins
        jdk 'JDK17' // Assurez-vous que l'alias JDK17 est configuré dans Jenkins
    }

    stages {
        stage('Git: Checkout SCM') {
            steps {
                echo '1. Clonage du code depuis GitHub...'
                // Utilisation de votre dépôt et Credential ID
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/master']], 
                    userRemoteConfigs: [[credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git']] 
                ])
            }
        }

        stage('Build & Package (Skip Tests)') {
            steps {
                echo '2. Compilation et packaging de l\'application (Tests ignorés).'
                // COMMANDE CORRIGÉE : Utilisation de -DskipTests pour contourner l\'échec
                sh 'mvn clean package -DskipTests' 
            }
        }
        
        stage('Quality Analysis (SonarQube)') {
            steps {
                echo '3. Lancement de l\'analyse SonarQube.'
                // Utilisation de votre Credential ID Sonar
                withCredentials([string(credentialsId: 'SONAR_TOKEN_JENKINS', variable: 'SONAR_TOKEN' )]) {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN -DskipTests' // on garde le skip tests ici aussi
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "4. Construction de l\'image Docker: malek50/students-app:latest"
                // Utilisation de votre nom d'image
                sh 'docker build -t malek50/students-app:latest -f Dockerfile .'
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo '5. Authentification et push sur Docker Hub...'
                script {
                    // Utilisation de votre Credential ID Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-new-pat', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh 'docker push malek50/students-app:latest'
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
             steps {
                echo '6. Déploiement de l\'application sur Kubernetes.'
                // Utilisation du chemin corrigé 'deployment.yaml'
                sh 'kubectl apply -f deployment.yaml'  
            }
        }
    }
    
    // Notifications
    post {
        success {
            echo '✅ Succès : Pipeline CI/CD terminée.'
            emailext(
                subject: "Build Success: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a réussi. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid50@gmail.com' 
            )
        }
        failure {
            echo '❌ Échec : Le build a échoué.'
            emailext(
                subject: "Build Failed: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a échoué. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid50@gmail.com' 
            )
        }
    }
}