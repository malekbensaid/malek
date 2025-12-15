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
                sh '''
                    MAX_ATTEMPTS=120
                    SONAR_URL=http://127.0.0.1:9000/api/server/version

                    for i in $(seq 1 $MAX_ATTEMPTS); do
                        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" $SONAR_URL || true)
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "SonarQube est opérationnel (Code HTTP 200 reçu après $i secondes)."
                            exit 0
                        elif [ "$HTTP_CODE" != "000" ] && [ "$HTTP_CODE" != "404" ]; then
                             echo "ATTENTION: Statut inattendu: $HTTP_CODE. Logs SonarQube pour diagnostic:"
                             sudo docker logs sonarqube
                        fi
                        echo "Tentative #$i : Statut actuel: $HTTP_CODE. Attente 1s..."
                        sleep 1
                    done
                    echo "Erreur: SonarQube n'a pas démarré dans les 120 secondes."
                    exit 1
                '''
                echo "Latence de 30 secondes pour la stabilité interne de SonarQube..."
                sh 'sleep 30'
            }
        }

        stage('3. SonarQube Analysis') {
            steps {
                echo "3. Exécution de l'analyse SonarQube."
                sh 'mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=students-app \
                    -Dsonar.host.url=http://127.0.0.1:9000 \
                    -Dsonar.token=$SONAR_TOKEN
            }
        }



        // --- ÉTAPE 4 : Création et Envoi de l'Image Docker ---
        stage('4. Docker Build and Push') {
            options {
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

        // --- ÉTAPE 6 : Validation de la Connectivité du Déploiement ---
        stage('6. Deployment Validation') {
            steps {
                echo "6. Récupération de l'URL et validation de l'accessibilité de l'application."

                script {
                    def appUrl = sh(
                        script: "minikube kubectl -- service students-app-service --url -n ${NAMESPACE}",
                        returnStdout: true
                    ).trim()

                    env.APP_URL = appUrl
                }

                echo "Application URL: ${env.APP_URL}"

                echo "Vérification de l'accessibilité de l'application (max 60s)..."
                sh '''
                    MAX_ATTEMPTS=60
                    APP_URL_CHECK="${APP_URL}/students"

                    for i in $(seq 1 $MAX_ATTEMPTS); do
                        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" $APP_URL_CHECK || true)

                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "✅ L'application est en ligne ! Réponse HTTP 200 reçue après $i secondes."
                            exit 0
                        fi
                        echo "Tentative #$i : Statut actuel: $HTTP_CODE. Attente 1s..."
                        sleep 1
                    done
                    echo "❌ Échec de la validation: L'application n'a pas répondu avec un code 200 dans les 60 secondes."
                    exit 1
                '''
            }
        }
    } // <--- FERMETURE CORRECTE DU BLOC PARENT 'stages'

    // --- POST-ACTIONS : Nettoyage ---
    post {
        always {
            echo "Nettoyage : Arrêt et suppression du conteneur SonarQube..."
            sh "sudo docker rm -f sonarqube || true"
            cleanWs()
        }
    }
}