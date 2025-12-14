pipeline {
    agent any

    // Variables globales du pipeline
    environment {
        // --- Variables de Configuration ---
	SONAR_HOST_URL = 'http://10.0.2.15:9000'
        DOCKER_IMAGE = 'malek50/students-app'
        DOCKER_TAG = 'latest'
        NAMESPACE = 'devops'
        
        // Nom du fichier de déploiement dans le dépôt
        DEPLOYMENT_FILE = 'deployment.yaml'

        
        // Variable pour contourner le problème DNS de K8s
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
// --- ÉTAPE 2 : Démarrage de l'Analyse (SonarQube) ---
        stage('2. Start SonarQube') {
            steps {
                echo "Démarrage du conteneur SonarQube via Docker..."
                sh 'sudo docker rm -f sonarqube || true'
                sh 'sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community'

                echo "Attente de la disponibilité de SonarQube (max 120 secondes)..."

                // NOUVELLE VÉRIFICATION : Attend un code HTTP 200 sur l'API version
                sh """
                    MAX_ATTEMPTS=120
                    SONAR_URL="${SONAR_HOST_URL}/api/server/version"
                    
                    for i in \$(seq 1 \${MAX_ATTEMPTS}); do
                        # Tenter d'obtenir le code HTTP, ignorer les erreurs de connexion temporaires (|| true)
                        HTTP_CODE=\$(curl -o /dev/null -s -w "%{http_code}" "\${SONAR_URL}" || true)

                        if [ "\$HTTP_CODE" = "200" ]; then
                            echo "SonarQube est opérationnel (Code HTTP 200 reçu après \$i secondes)."
                            exit 0
                        fi
                        
                        echo "Tentative #\$i : Statut actuel: \$HTTP_CODE. Attente 1s..."
                        sleep 1
                    done
                    
                    echo "Erreur: SonarQube n'a pas démarré dans les \${MAX_ATTEMPTS} secondes."
                    exit 1
                """

                echo "Latence de 30 secondes pour la stabilité interne de SonarQube..."
                sh 'sleep 30'
            }
        }
        


        // --- ÉTAPE 4 : Création et Envoi de l'Image Docker ---
        stage('4. Docker Build and Push') {
            steps {
                echo "4. Construction et Push de l'image Docker."
                // Utiliser l'ID de credential pour Docker Hub
                withCredentials([usernamePassword(credentialsId: 'docker-hub-new-pat', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    // Se connecter à Docker Hub
                    sh "sudo docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    
                    // Construire l'image (le .jar a été créé à l'étape 3)
                    sh "sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    
                    // Pousser l'image vers Docker Hub
                    sh "sudo docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
stage('4.5. Start Minikube') {
    steps {
        echo "Démarrage de Minikube (si non démarré)..."
        // Utiliser 'sudo' car l'utilisateur jenkins n'a peut-être pas les droits docker/minikube
        sh 'sudo minikube start || true' 
        sh 'sudo minikube status' // Vérifier si le cluster est bien démarré
        echo "Attribution des droits d'accès à Kubernetes pour l'utilisateur Jenkins/Root..."
        // Cette commande est souvent nécessaire pour que l'utilisateur sous lequel Jenkins s'exécute puisse utiliser kubectl.
        sh 'sudo chown -R $USER $HOME/.kube $HOME/.minikube'
    }
}
// --- ÉTAPE 5 : Déploiement sur Kubernetes ---
        stage('5. Deploy to Kubernetes') {
            steps {
                echo "5. Déploiement de l'application sur Minikube (K8S)."
                
                sh """
                    # 1. Assurez-vous que le namespace existe
                    minikube kubectl -- create namespace ${NAMESPACE} --dry-run=client -o yaml | minikube kubectl -- apply -f - || true
                    
                    # 2. Appliquer la configuration K8S (deployment.yaml contient maintenant tout)
                    minikube kubectl -- apply -f ${DEPLOYMENT_FILE} -n ${NAMESPACE}
                    
                    # 3. Redémarrer (rollout) le déploiement après les changements (si nécessaire)
                    minikube kubectl -- rollout restart deployment students-app-deployment -n ${NAMESPACE}
                """
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
