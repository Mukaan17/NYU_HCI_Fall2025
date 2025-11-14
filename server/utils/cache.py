import requests_cache
from datetime import timedelta

def init_requests_cache():
    requests_cache.install_cache(
        "nyightout_cache",
        expire_after=timedelta(minutes=5),
        allowable_methods=("GET",),
    )