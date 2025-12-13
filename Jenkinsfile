pipeline {
    agent any

    tools {
        maven "M3" // Utilisation de l'outil Maven
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Clonage du code..."
                // Manque la commande réelle de 'checkout' (git)
            }
        }

        stage('Build & Package') {
            steps {
                echo "Compilation et packaging du projet (sans tests)..."
                // sh "mvn package -DskipTests" est l'ancienne commande dans le commentaire
                // La commande 'mvn clean install' serait plus complète
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "Archivage du JAR..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
    
    // Le bloc 'post' est simple et ne contient pas les envois de mail
    post {
        success {
            echo 'echo "Le build a réussi ! Le JAR est archivé."'
        }
        failure {
            echo 'echo "Le build a échoué. Veuillez vérifier la sortie de la console."'
        }
    }
}