from locust import HttpUser, task, between
import json
import random

class BlogUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def view_posts(self):
        """Simula usuarios viendo el blog"""
        self.client.get("/")
    
    @task(1)
    def create_post(self):
        """Simula usuarios creando posts"""
        titles = [
            "My First Post",
            "Learning Kubernetes",
            "Autoscaling with HPA",
            "Load Testing with Locust",
            "DevOps Best Practices",
            "Microservices Architecture",
            "Cloud Native Applications",
            "Container Orchestration"
        ]
        
        contents = [
            "This is a test post to generate load on the application.",
            "Kubernetes is amazing for orchestrating containers at scale.",
            "Horizontal Pod Autoscaler helps maintain application performance.",
            "Locust is a great tool for load testing web applications.",
            "Implementing proper monitoring is crucial for production systems.",
            "Breaking down monoliths into microservices improves scalability.",
            "Cloud native apps are designed to leverage cloud computing benefits.",
            "Container orchestration automates deployment and scaling."
        ]
        
        payload = {
            "title": random.choice(titles) + f" #{random.randint(1, 1000)}",
            "content": random.choice(contents)
        }
        
        self.client.post(
            "/submit",
            data=json.dumps(payload),
            headers={"Content-Type": "application/json"}
        )
