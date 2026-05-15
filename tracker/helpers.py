from math import asin, cos, radians, sin, sqrt


def haversine_distance_meters(lat1, lon1, lat2, lon2):
    """
    Calculate the great-circle distance between two latitude/longitude pairs.

    The result is returned in meters, which keeps the geofence threshold easy
    to reason about in the serializer validation layer.
    """
    lat1, lon1, lat2, lon2 = map(float, (lat1, lon1, lat2, lon2))

    earth_radius_m = 6_371_000
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)

    a = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    )
    c = 2 * asin(sqrt(a))
    return earth_radius_m * c
