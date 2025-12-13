import dspy
from .models import UserProfile, EVCar, Transaction
from django.contrib.auth.models import User
import json
def search_cars(query_str: str = "") -> str:
    cars = EVCar.objects.filter(status='AVAILABLE')
    if query_str: cars = cars.filter(model_name__icontains=query_str)
    return "\n".join([f"{c.model_name} (${c.price_per_day}/day)" for c in cars]) if cars.exists() else "No cars found."
class EVSignature(dspy.Signature):
    """EV Consultant Agent."""
    chat_history = dspy.InputField()
    user_query = dspy.InputField()
    response = dspy.OutputField()
class EVAgent(dspy.Module):
    def __init__(self):
        super().__init__()
        self.prog = dspy.ChainOfThought(EVSignature)
    def forward(self, history, query):
        return self.prog(chat_history=history, user_query=query)
