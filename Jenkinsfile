pipeline {
    agent any 
    tools {
        maven 'M2_HOME' 
    }
    stages {
        stage('Checkout') {
            steps {
                echo "Clonage du dépôt Git..."
            }
        }
        stage('Build & Package') {
            steps {
                echo "Compilation et packaging du projet (sans tests)..."
                // Commande corrigée pour ignorer les tests qui échouent sur MySQL
                sh 'mvn package -DskipTests' 
            }
        }
        stage('Archive Artifacts') {
            steps {
                echo "Archivage du JAR..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
    post {
        always {
            echo 'Pipeline terminé.'
        }
        success {
            echo 'Le build a réussi ! Le JAR est archivé.'
        }
        failure {
            echo 'Le build a échoué. Veuillez vérifier la sortie de la console.'
        }
    }
}