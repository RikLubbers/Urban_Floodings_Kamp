import numpy as np
import rasterio
from shapely.geometry import box
from shapely.geometry import Point 
from shapely.ops import cascaded_union 

"""_summary_
This function generates random points within a buffer around DHS clusters, excluding open water and flooding areas, and within the admin boundary.

Inputs:
- pts: list of tuples of coordinates of DHS clusters
- admin: shapely polygon of admin boundary
- samp_num: number of random points to sample
- other_num: number of random points to generate
- open_water: shapely polygon of open water areas
- flood_area: shapely polygon of flooding areas

Outputs:
- r_pts: list of arrays of coordinates of random points

Author: Rik Lubbers
Date: 2023-12-05
Version: 1.0
"""

def displace(pts, admin, samp_num, other_num, open_water, flood_area):
    n = len(pts)
    offset_dist = 2000 #2 km buffer as it is an urban DHS cluster

    r_pts = []
    for i in range(n):
        r_pts_i = np.zeros((samp_num, 2)) # Matrix to store random points

        # Buffer around point
        pt = Point(pts[i]) # transform to shapely point
        buffer = pt.buffer(offset_dist) # buffer around point

        # Check if buffer is a GeometryCollection
        if buffer.geom_type == 'GeometryCollection':
            # If buffer is a GeometryCollection, take the union of all geometries
            buffer = cascaded_union(buffer)

        # Subtract the open water areas from the buffer
        buffer = buffer.difference(open_water)

        # Subtract the flooding areas from the buffer
        buffer = buffer.difference(flood_area)

        # Intersection with admin
        intersection = buffer.intersection(admin) # intersection with admin boundary to ensure points are within the admin boundary

        # Generating random points
        if intersection.is_empty:
            # If no intersection, generate random points within the buffer
            random_pts = [Point(buffer.exterior.coords[i]) for i in range(other_num)]
        else:
            # If intersection exists, generate random points within the intersection
            random_pts = [Point(intersection.exterior.coords[i]) for i in range(other_num)]

        # Sample random points
        probs = 1 / distance.cdist([pts[i]], [pt.coords[0] for pt in random_pts])
        probs /= np.sum(probs)
        indices = np.random.choice(range(len(random_pts)), size=samp_num, p=probs)
        r_pts_i = np.array([random_pts[idx].coords[0] for idx in indices])

        r_pts.append(r_pts_i)

    return r_pts

# Apply function
pts = [(3, 4), (5, 6), (7, 8)]
admin = box(0, 0, 10, 10)
samp_num = 10
other_num = 1000
open_water = box(0, 0, 2, 2)
flood_area = box(0, 0, 1, 1)

displace(pts, admin, samp_num, other_num, open_water, flood_area)
from scipy.spatial import distance 

"""_summary_
This function generates random points within a buffer around DHS clusters, excluding open water and flooding areas, and within the admin boundary.

Inputs:
- pts: list of tuples of coordinates of DHS clusters
- admin: shapely polygon of admin boundary
- samp_num: number of random points to sample
- other_num: number of random points to generate
- open_water: shapely polygon of open water areas
- flood_area: shapely polygon of flooding areas

Outputs:
- r_pts: list of arrays of coordinates of random points

Author: Rik Lubbers
Date: 2023-12-05
Version: 1.0
"""

def displace(pts, admin, samp_num, other_num, open_water, flood_area):
    n = len(pts)
    offset_dist = 2000 #2 km buffer as it is an urban DHS cluster

    r_pts = []
    for i in range(n):
        r_pts_i = np.zeros((samp_num, 2)) # Matrix to store random points

        # Buffer around point
        pt = Point(pts[i]) # transform to shapely point
        buffer = pt.buffer(offset_dist) # buffer around point

        # Subtract the open water areas from the buffer
        buffer = buffer.difference(open_water)

        # Subtract the flooding areas from the buffer
        buffer = buffer.difference(flood_area)

        # Intersection with admin
        intersection = buffer.intersection(admin) # intersection with admin boundary to ensure points are within the admin boundary

        # Generating random points
        if intersection.is_empty:
            # If no intersection, generate random points within the buffer
            random_pts = [Point(buffer.exterior.coords[i]) for i in range(other_num)]
        else:
            # If intersection exists, generate random points within the intersection
            random_pts = [Point(intersection.exterior.coords[i]) for i in range(other_num)]

        # Sample random points
        probs = 1 / distance.cdist([pts[i]], [pt.coords[0] for pt in random_pts])
        probs /= np.sum(probs)
        indices = np.random.choice(range(len(random_pts)), size=samp_num, p=probs)
        r_pts_i = np.array([random_pts[idx].coords[0] for idx in indices])

        r_pts.append(r_pts_i)

    return r_pts

# Apply function
pts = [(3, 4), (5, 6), (7, 8)]
admin = box(0, 0, 10, 10)
samp_num = 10
other_num = 1000
open_water = box(0, 0, 2, 2)
flood_area = box(0, 0, 1, 1)

displace(pts, admin, samp_num, other_num, open_water, flood_area)