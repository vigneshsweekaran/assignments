
### Docker Image Build
```
docker build -t flask-api:1 .
```

### Install Nginx Ingress Controller
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
```

### Install helm chart
```
cd cicd/helm-chart
helm install flask-api -f values.yaml .
```

### Helm upgrade
```
helm upgrade flask-api -f values.yaml .
```

### MySQL Database Schema
```
CREATE DATABASE messages_db;
USE messages_db;

CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(255),
    message_id VARCHAR(255),
    sender_number VARCHAR(20),
    receiver_number VARCHAR(20)
);
```
