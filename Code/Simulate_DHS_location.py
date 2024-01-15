import numpy as np
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

def displace(pts, buffer_clipped, samp_num, other_num):
    n = len(pts) # Number of DHS clusters

    r_pts = [] # List to store random points
    for i in range(n): # Loop over DHS clusters
        r_pts_i = np.zeros((samp_num, 2)) # Matrix to store random points

        # Generating random points within the buffer
        random_pts = [Point(buffer_clipped.exterior.coords[i]) for i in range(other_num)]

        # Sample random points
        probs = 1 / distance.cdist([pts[i]], [pt.coords[0] for pt in random_pts])
        probs /= np.sum(probs)
        indices = np.random.choice(range(len(random_pts)), size=samp_num, p=probs)
        r_pts_i = np.array([random_pts[idx].coords[0] for idx in indices])

        r_pts.append(r_pts_i)

    return r_pts

# Apply function


displace(pts, admin, samp_num, other_num, open_water, flood_area)