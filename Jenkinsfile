pipeline {
    agent any
    
    // Déclaration des variables d'environnement
    environment {
        // VOS CREDENTIALS ET LIENS
        // Utilisé pour le push sur Docker Hub
        DOCKER_USERNAME = 'malek50'  
        
        // Configuration SonarQube. J'utilise 127.0.0.1:9001 comme URL si c'est la bonne.
        SONAR_HOST_URL = 'http://127.0.0.1:9001' 
        
        // Jeton SonarQube. NOTE: L'idéal est de le stocker comme un secret Jenkins, mais je le laisse ici
        // comme dans votre modèle pour l'analyse.
        SONAR_LOGIN = 'squ_2f7edc6f021ad73990345fa234d13409675fdf2a' 
    }

    // Déclaration des outils configurés dans Jenkins
    tools {
        maven 'M3'  // Assurez-vous que l'ID 'M3' correspond à votre configuration Maven
        jdk 'JDK17' // Assurez-vous que l'ID 'JDK17' correspond à votre configuration JDK
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                echo 'Clonage du code depuis GitHub...'
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/master']], 
                    // Utilisation de votre ID de credentials pour GitHub
                    userRemoteConfigs: [[credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git']]
                ])
            }
        }
        
        stage('Build & Package') {
            steps {
                echo 'Compilation et packaging du projet...'
                sh 'mvn clean install'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Exécution des tests unitaires...'
                sh 'mvn test'
            }
        }
        
        stage('Quality Analysis (SonarQube)') {
            steps {
                echo 'Lancement de l\'analyse SonarQube...'
                // Utilisation des variables d'environnement pour l'authentification SonarQube
                sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_LOGIN}"
            }
        }

        stage('Jacoco Code Coverage') {
            steps {
                echo 'Analyse de la couverture de code Jacoco...'
                // Publication des rapports JUnit et Jacoco
                junit 'target/surefire-reports/**/*.xml'
                jacoco(
                    execPattern: '**/target/jacoco.exec', 
                    classPattern: '**/target/classes', 
                    sourcePattern: '**/src/main/java'
                )
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
                echo "Construction de l\'image Docker: ${env.DOCKER_USERNAME}/students-app:latest"
                sh "docker build -t ${env.DOCKER_USERNAME}/students-app:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Authentification et déploiement sur Docker Hub...'
                // Utilisation de l'ID d'identifiant pour Docker Hub
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    sh "docker push ${env.DOCKER_USERNAME}/students-app:latest"
                }
            }
        }
        
        stage('Deploy to Nexus') {
            steps {
                echo 'Déploiement de l\'artefact sur Nexus...'
                // Nécessite une configuration correcte de Nexus dans le settings.xml de Maven
                sh 'mvn deploy'
            }
        }

        stage('Deploy to Kubernetes (Minikube)') {
            steps {
                echo 'Application du déploiement Kubernetes (students-app)...'
                // CORRECTION APPLIQUÉE : Utilisation du chemin racine 'deployment.yaml'
                sh 'kubectl apply -f deployment.yaml'  
            }
        }
        
        stage('Prometheus & Grafana') {
            steps {
                echo 'Démarrage des conteneurs de monitoring...'
                sh 'docker start prometheus || echo "Prometheus déjà démarré ou non trouvé"'
                sh 'docker start grafana || echo "Grafana déjà démarré ou non trouvé"'
            }
        }

        stage('Terraform Apply') {
            steps {
                echo 'Initialisation et application de Terraform...'
                // Ceci suppose que les fichiers Terraform (.tf) sont à la racine du workspace
                sh 'terraform init'  
                sh 'terraform apply -auto-approve'
            }
        }
    }
    
    post {
        always {
            echo 'Nettoyage des sessions Docker...'
            sh 'docker logout || true'
        }
        success {
            echo '✅ SUCCÈS : Le pipeline a réussi et l\'application est déployée.'
            // Si vous avez configuré le plugin Email Extension, vous pouvez ajouter :
            /* emailext(
                subject: "Build Success: ${currentBuild.fullDisplayName}",
                body: "Le pipeline a réussi. Voir les détails du build ici: ${env.BUILD_URL}",
                to: 'votre_email@example.com' 
            )
            */
        }
        failure {
            echo '❌ ÉCHEC : Le build a échoué. Veuillez vérifier la sortie de la console.'
            // Ajouter ici une notification d'échec si nécessaire
        }
    }
}