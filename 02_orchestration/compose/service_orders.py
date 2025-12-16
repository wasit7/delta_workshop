from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def home():
    return {"service": "Order Service", "status": "active"}

@app.get("/orders/latest")
def latest_order():
    return {"order_id": 999, "total": "$500"}