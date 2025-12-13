from django.db import models
from django.contrib.auth.models import User
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=100, blank=True, null=True)
    nickname = models.CharField(max_length=50, blank=True, null=True)
    license_id = models.CharField(max_length=50, blank=True, null=True)
class EVCar(models.Model):
    model_name = models.CharField(max_length=100)
    range_km = models.IntegerField()
    price_per_day = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, default='AVAILABLE')
class Transaction(models.Model):
    customer = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    car = models.ForeignKey(EVCar, on_delete=models.CASCADE)
    type = models.CharField(max_length=20)
    status = models.CharField(max_length=20, default='DRAFT')
    created_at = models.DateTimeField(auto_now_add=True)
