// Contenu à mettre dans le fichier Jenkinsfile
pipeline {
    agent any
    
    // Assurez-vous que l'outil Maven est configuré dans Jenkins sous l'ID 'M2_HOME'
    tools {
        maven 'M2_HOME' 
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "Récupération du code via le SCM du job..."
            }
        }
        
        stage('Build and Package') {
            steps {
                // Compile et génère le livrable (requis: mvn package)
                sh 'mvn package'
            }
        }
        
        // BONUS : Exécution explicite des tests unitaires
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
    }
}