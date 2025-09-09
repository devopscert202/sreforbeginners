# 🧪 Lab 11: Setting Up CI/CD Pipeline with Jenkins and Docker

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.

Continuous Integration / Continuous Delivery (CI/CD) automates build, test and deploy steps so teams can ship safely and frequently. Jenkins is a widely used automation server; combined with Docker it allows pipelines that build images and deploy applications reproducibly. For freshers, this lab shows a minimal end-to-end Jenkins + Docker CI/CD pipeline that builds a simple Flask app image and runs it on the host.

> **SRE context:** Reliable delivery pipelines reduce human error and reduce toil. Production-grade pipelines also include tests, security scans, and controlled rollout (canaries, feature flags) tied to SLOs and error budgets.

---

## 🎯 Objective  
By the end of this lab you will be able to:

- Install Docker and Docker Compose on an EC2 instance.
- Create a simple Flask application, Dockerfile and requirements.
- Start Jenkins in Docker with Docker socket bind mounted.
- Create a Jenkins Pipeline job that clones a repo, builds a Docker image, and runs the container.
- Validate the pipeline run and the deployed app.

---

## 📋 Prerequisites  

- EC2 instance (Amazon Linux 2) from earlier labs.  
- Security group: allow ports **8080 (Jenkins)** and **5000 (Flask app)** and **22 (SSH)**.  
- Git access (a GitHub account or other Git host) — you can push your sample repo or use the local pipeline to clone the example repo URL given in the steps below.

---

## 🔨 Steps

> All commands below are intended to be executed on the EC2 instance terminal. Where the original doc used placeholders like `<EC2_PUBLIC_IP>` or `<your-repo>`, replace with actual values for your environment.

### Step 1 — Update the system
```bash
sudo yum update -y
````

---

### Step 2 — Install Docker

```bash
sudo yum install -y docker
sudo systemctl enable --now docker
```

Add `ec2-user` to docker group so you can run docker without `sudo`:

```bash
sudo usermod -aG docker ec2-user
# Apply group changes to the current shell
newgrp docker
```

Verify Docker:

```bash
docker --version
docker info
```

---

### Step 3 — Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

---

### Step 4 — Prepare a simple Flask app (project repo)

Create directories and files for the sample Flask app (you may instead clone an existing repo — replace the `git` URL in the Jenkinsfile later):

```bash
mkdir -p ~/cicd-lab/flask_app
cd ~/cicd-lab/flask_app
```

Create `app.py`:

```bash
cat > app.py <<'PY'
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Flask in Jenkins CI/CD!"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PY
```

Create `requirements.txt`:

```bash
cat > requirements.txt <<'REQ'
flask
REQ
```

Create `Dockerfile`:

```bash
cat > Dockerfile <<'DOCK'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
DOCK
```

Initialize Git and push (if you have a remote repo):

```bash
git init
git add .
git commit -m "Initial Flask app"
# Replace with your repo URL:
git remote add origin https://github.com/<your-user>/<your-repo>.git
git push -u origin main
```

> If you cannot push to GitHub, later in Jenkins pipeline you can point to a public example repo or you can configure Jenkins to use local workspace by alternate means.

---

### Step 5 — Create Docker Compose for Jenkins

Create a directory and docker-compose file:

```bash
cd ~/cicd-lab
cat > docker-compose.yml <<'YML'
version: "3.8"

services:
  jenkins:
    image: jenkins/jenkins:lts
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker   # optional: share Docker binary
    user: root
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock

volumes:
  jenkins_home:
YML
```

Start Jenkins:

```bash
docker-compose up -d
```

Check Jenkins container:

```bash
docker-compose ps
```

Open Jenkins in the browser:

```
http://<EC2_PUBLIC_IP>:8080
```

---

### Step 6 — Retrieve initial Jenkins admin password

Get the Jenkins container ID and read the initial admin password:

```bash
CID=$(docker-compose ps -q jenkins)
docker exec -it $CID cat /var/jenkins_home/secrets/initialAdminPassword
```

Use that password to unlock Jenkins in the browser and follow the setup wizard:

* Install suggested plugins.
* Create the first admin user (you can use `admin` / `admin` for training but change in real environments).

---

### Step 7 — Install Docker CLI inside Jenkins container (optional but useful)

Open a shell inside the Jenkins container:

```bash
docker exec -it $CID bash
```

Inside container (Debian-based), update and install docker client (if needed):

```bash
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
docker --version
exit
```

> Note: Because we mounted the host Docker socket (`/var/run/docker.sock`), the Jenkins container can already access host Docker daemon. Installing the Docker client binary inside the container is optional.

---

### Step 8 — Create Jenkins Pipeline (Declarative)

In the Jenkins UI:

1. Click **New Item** → Enter name: `SimpleJob` → Select **Pipeline** → OK.
2. In pipeline configuration, under **Pipeline** section, choose **Pipeline script** and paste the following Pipeline script (update `git url` to your repository if you pushed the sample app):

```groovy
pipeline {
  agent any
  stages {
    stage('Clone Repo') {
      steps {
        git url: 'https://github.com/<your-user>/<your-repo>.git', branch: 'main'
      }
    }
    stage('Build Docker Image') {
      steps {
        sh 'docker build -t flask-app:latest .'
      }
    }
    stage('Stop & Remove Old Container') {
      steps {
        sh 'docker rm -f flask-app || true'
      }
    }
    stage('Run Docker Container') {
      steps {
        sh 'docker run -d --name flask-app -p 5000:5000 flask-app:latest'
      }
    }
  }
  post {
    always {
      echo "Build finished: ${currentBuild.fullDisplayName}"
    }
  }
}
```

Save the job.

---

### Step 9 — Run the Pipeline and Validate

* Click **Build Now** on the job page.
* Open **Console Output** to follow build logs.

Expected pipeline behavior:

* Checkout source from Git.
* Build Docker image (named `flask-app:latest`).
* Remove old container if present.
* Run the new container exposing port 5000.

Validate app:

```bash
curl http://<EC2_PUBLIC_IP>:5000/
curl -I http://<EC2_PUBLIC_IP>:5000/health
```

Expected:

* `curl` returns: `Hello from Flask in Jenkins CI/CD!`
* Health endpoint returns `HTTP/1.1 200 OK`

---

### Step 10 — Configure Webhook or Polling (optional)

* To run builds automatically on Git push, configure **GitHub Webhook**:

  * In Jenkins job: **Configure → Build Triggers → GitHub hook trigger for GITScm polling**
  * In GitHub repo settings: add webhook URL:

    ```
    http://<EC2_PUBLIC_IP>:8080/github-webhook/
    ```
* Alternatively use **Poll SCM**: in Jenkins job → **Build Triggers → Poll SCM** and provide a cron schedule (e.g., `H/5 * * * *`).

---

## 🧾 Testing & Validation (Consolidated)

1. **Jenkins up and accessible**

   ```bash
   docker-compose ps
   # Browser: http://<EC2_PUBLIC_IP>:8080
   ```

   Expected: Jenkins UI reachable.

2. **Initial admin password retrieval**

   ```bash
   CID=$(docker-compose ps -q jenkins)
   docker exec -it $CID cat /var/jenkins_home/secrets/initialAdminPassword
   ```

   Expected: password string to unlock Jenkins.

3. **Pipeline run**

   * Trigger **Build Now**.
   * Monitor **Console Output**.
     Expected: `docker build` completes and `docker run` launches container.

4. **App validation**

   ```bash
   curl http://<EC2_PUBLIC_IP>:5000/
   curl -I http://<EC2_PUBLIC_IP>:5000/health
   ```

   Expected: App responds and health endpoint returns `200`.

5. **Cleanup (optional)**
   Stop containers and remove compose stack:

   ```bash
   docker-compose down
   docker rm -f flask-app || true
   docker rmi flask-app:latest || true
   ```

---

## 💡 Trainer Notes & Common Pitfalls

* **Permissions**: Jenkins needs access to the host Docker daemon. Mounting `/var/run/docker.sock` is convenient for training, but it's a security risk in production. Use Docker-in-Docker or dedicated build agents with controlled access in production.
* **Ports**: Ensure your EC2 security group permits inbound 8080 and 5000 when testing.
* **Image caching**: Frequent image builds will consume disk space; monitor and prune unused images:

  ```bash
  docker image prune -af
  ```
* **User mapping**: The Jenkins container runs as user `root` here for convenience (`user: root` in compose). In production, follow least-privilege practices.
* **Alternate approach**: Use Jenkins agents (slaves) for builds instead of running builds inside the controller.

---

## 📌 Further Learning (SRE Context)

* Add unit/integration tests in the pipeline before deployment to reduce incidents caused by bad changes.
* Integrate security scans (SCA, SAST) into the pipeline.
* Tie deployments to SLOs & Error Budgets: automate rollbacks if new release increases error rate or exceeds latency SLOs (requires observability integration).
* Use blue-green or canary deployment patterns (covered in Lab 07) as part of pipeline promotion steps.

---

## ✅ Lab Completion

You have successfully:

* Set up Jenkins in Docker.
* Created a simple Flask app and Dockerfile.
* Created a Jenkins Declarative Pipeline that builds and deploys the app as a Docker container.
* Validated the pipeline and the running application.

This completes a basic CI/CD workflow example suitable for teaching SRE delivery automation practices.

---

## Appendix — Useful Commands (copy/paste)

```bash
# system update
sudo yum update -y

# docker install & start
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
newgrp docker

# docker-compose install
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# sample app setup
mkdir -p ~/cicd-lab/flask_app
cd ~/cicd-lab/flask_app
# create app.py, requirements.txt, Dockerfile as shown above

# bring up jenkins
cd ~/cicd-lab
docker-compose up -d
CID=$(docker-compose ps -q jenkins)
docker exec -it $CID cat /var/jenkins_home/secrets/initialAdminPassword

# run pipeline: build triggers in Jenkins UI or use Build Now
# validate app
curl http://<EC2_PUBLIC_IP>:5000/
```

