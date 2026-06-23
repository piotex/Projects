# Symulacja obciążenia

from locust import HttpUser, task, between

class MojTest(HttpUser):
    # Symulacja przerwy między akcjami (od 1 do 3 sekund)
    wait_time = between(1, 3)

    @task
    def sprawdz_strone(self):
        self.client.get("/index.html")