from locust import HttpUser, task, between

class MyLoadTest(HttpUser):
    wait_time = between(1, 5)  # seconds between tasks

    @task
    def index_page(self):
        self.client.get("/")

    @task
    def api_data(self):
        self.client.get("/api/data")
