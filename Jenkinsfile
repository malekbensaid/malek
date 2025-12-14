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

        // Variable gardée pour la cohérence, mais la DB doit être configurée dans deployment.yaml
        SPRING_DATASOURCE_URL = 'jdbc:mysql://mysql-service:3306/db_example?useSSL=false'
    }

    stages {
        // --- ÉTAPE 1 : Préparation & Récupération du Code (GitHub) ---
        stage('1. Checkout Code') {
            steps {
                echo "1. Clonage du code depuis GitHub..."
                git branch: 'master', credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git'
            }
        }
        
        // --- ÉTAPE 2 : Démarrage de l'Analyse (SonarQube) ---
        stage('2. Start SonarQube') {
            steps {
                echo "Démarrage du conteneur SonarQube via Docker..."
                sh 'sudo docker rm -f sonarqube || true'
                sh 'sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community'

                echo "Attente de la disponibilité de SonarQube (max 120 secondes)..."

                sh """
                    MAX_ATTEMPTS=120
                    SONAR_URL="${SONAR_HOST_URL}/api/server/version"
                    
                    for i in \$(seq 1 \${MAX_ATTEMPTS}); do
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
            options {
                // Tente de ré-exécuter le stage 3 fois en cas d'échec
                retry(3) 
            }
            steps {
                echo "4. Construction et Push de l'image Docker."
                withCredentials([usernamePassword(credentialsId: 'docker-hub-new-pat', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh "sudo docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    sh "sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "sudo docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
// --- 4.5. NOUVEAU STAGE : Démarrage Minikube ---
stage('4.5. Start Minikube') {
            steps {
                echo "Désactivation temporaire de la protection du noyau pour Minikube..."
                // Correction pour HOST_JUJU_LOCK_PERMISSION
                sh 'sudo sysctl fs.protected_regular=0' 

                echo "Nettoyage de tout cluster Minikube existant..."
                sh 'sudo minikube delete || true'
                
                echo "Démarrage de Minikube (en utilisant le driver Docker et --force)..."
                sh 'sudo minikube start --driver=docker --force' 

                sh 'sudo minikube status'
                echo "Attribution des droits d'accès à Kubernetes pour l'utilisateur Jenkins..."
                sh 'sudo chown -R $USER $HOME/.kube $HOME/.minikube || true'
            }
        }    
        // --- ÉTAPE 5 : Déploiement sur Kubernetes (SIMPLIFIÉ) ---
        stage('5. Deploy to Kubernetes') {
            steps {
                echo "5. Déploiement de l'application sur Minikube (K8S)."
                
                sh """
                    # 1. Assurez-vous que le namespace existe
                    minikube kubectl -- create namespace ${NAMESPACE} --dry-run=client -o yaml | minikube kubectl -- apply -f - || true
                    
                    # 2. Appliquer la configuration K8S (avec le fichier propre)
                    minikube kubectl -- apply -f ${DEPLOYMENT_FILE} -n ${NAMESPACE}
                    
                    # 3. Redémarrer le déploiement pour s'assurer que la dernière image est utilisée
                    minikube kubectl -- rollout restart deployment students-app-deployment -n ${NAMESPACE}
                """
            }
        }
    }
    
    // --- POST-ACTIONS : Nettoyage ---
    post {
        always {
            echo "Nettoyage : Arrêt et suppression du conteneur SonarQube..."
            sh "sudo docker rm -f sonarqube || true"
            cleanWs()
        }
    }
}