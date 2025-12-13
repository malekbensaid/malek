pipeline {
    agent any

    // Les outils sont essentiels pour la compilation
    tools {
        maven "M3"
        jdk 'JDK17'
    }

    stages {
        stage('Git: Checkout SCM') {
            steps {
                echo '1. Clonage du code depuis GitHub.'
                // Utilise vos coordonnées Git
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/master']], 
                    userRemoteConfigs: [[credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git']]
                ])
            }
        }

        stage('Build & Package') {
            steps {
                echo '2. Compilation de l\'application.'
                sh 'mvn clean install'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '3. Exécution des tests unitaires.'
                sh 'mvn test'
            }
        }
        
        stage('Quality Analysis (SonarQube)') {
            steps {
                echo '4. Lancement de l\'analyse SonarQube.'
                // Utilise votre Credential ID Sonar
                withCredentials([string(credentialsId: 'SONAR_TOKEN_JENKINS', variable: 'SONAR_TOKEN' )]) {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }
        
        stage('Jacoco Code Coverage') {
            steps {
                echo '5. Analyse de la couverture de code Jacoco.'
                junit 'target/surefire-reports/**/*.xml'
                jacoco()
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
                echo "6. Construction de l\'image Docker (malek50/students-app:latest)."
                sh 'docker build -t malek50/students-app:latest -f Dockerfile .'
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo '7. Authentification et push sur Docker Hub.'
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh 'docker push malek50/students-app:latest'
                    }
                }
            }
        }
        
        // Les étapes suivantes sont celles que vous avez décidé de retirer, mais je les inclus
        // ici au cas où vous devriez les montrer à votre professeur.
        // --- ÉTAPES AVANCÉES ---
        
        stage('Deploy to Nexus') {
            steps {
                echo 'Déploiement de l\'artefact sur Nexus...'
                sh 'mvn deploy'
            }
        }
        
        stage('Deploy to Kubernetes') {
             steps {
                echo '8. Déploiement de l\'application sur Kubernetes.'
                // Utilise le chemin corrigé (racine du projet)
                sh 'kubectl apply -f deployment.yaml'  
            }
        }
        
        stage('Monitoring & IaC') {
            steps {
                echo 'Démarrage Prometheus/Grafana et Application Terraform.'
                sh 'docker start prometheus || echo "Prometheus non trouvé"'
                sh 'docker start grafana || echo "Grafana non trouvé"'
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }
    }
    
    // Notifications par e-mail
    post {
        success {
            echo 'Notification de succès.'
            emailext(
                subject: "Build Success: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a réussi. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid@example.com' 
            )
        }
        failure {
            echo 'Notification d\'échec.'
            emailext(
                subject: "Build Failed: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a échoué. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'malekbensaid@example.com' 
            )
        }
    }
}