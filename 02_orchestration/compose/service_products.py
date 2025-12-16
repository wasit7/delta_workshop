from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def home():
    return {"service": "Product Service", "status": "active"}

@app.get("/products")
def list_products():
    return ["Laptop", "Mouse", "Keyboard"]