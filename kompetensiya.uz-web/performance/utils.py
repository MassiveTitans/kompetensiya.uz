"""Davomat uchun yordamchi hisob-kitoblar."""
import math


def distance_meters(lat1, lon1, lat2, lon2):
    """Ikki nuqta orasidagi masofa (metr) — haversine formulasi."""
    radius = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = (math.sin(dp / 2) ** 2
         + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2)
    return round(2 * radius * math.asin(math.sqrt(a)))
