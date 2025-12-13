from django.shortcuts import render
from django.http import HttpResponse
def chat_view(request):
    return HttpResponse("<h1>EV Rental Agent Active</h1><p>Chat interface placeholder.</p>")
