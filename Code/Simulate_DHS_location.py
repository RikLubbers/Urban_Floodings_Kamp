import numpy as np
import rasterio
from shapely.geometry import box
from shapely.geometry import Point 
from shapely.ops import cascaded_union 
from scipy.spatial import distance 

"""_summary_
# This function generates random points within a buffer around DHS clusters, excluding open water and flooding areas, and within the admin boundary.
# Inputs:
# pts: list of tuples of coordinates of DHS clusters
# admin: shapely polygon of admin boundary
# samp_num: number of random points to sample
# other_num: number of random points to generate
# landcover_raster: path to landcover raster
# flood_raster: path to flood raster

# Outputs:
# r_pts: list of arrays of coordinates of random points

# Example:
# pts = [(0, 0), (1, 1)]
# admin = Polygon([(0, 0), (0, 5), (5, 5), (5, 0)])
# samp_num = 2
# other_num = 5
# landcover_raster = 'path_to_landcover_raster'
# flood_raster = 'path_to_flood_raster'
# r_pts = displace(pts, admin, samp_num, other_num, landcover_raster, flood_raster)
# print(r_pts)

# Author: Rik Lubbers
# Date: 2023-12-05
# Version: 1.0
# License: MIT License
"""

def displace(pts, admin, samp_num, other_num, landcover_raster, flood_raster):
    n = len(pts)
    offset_dist = 2000 #2 km buffer as it is an urban DHS cluster

    r_pts = []
    for i in range(n):
        r_pts_i = np.zeros((samp_num, 2)) # Matrix to store random points

        # Buffer around point
        pt = Point(pts[i]) # transform to shapely point
        buffer = pt.buffer(offset_dist) # buffer around point

        # Create a polygon of the open water areas
        with rasterio.open(landcover_raster) as src:
            open_water = box(*src.bounds)
            for value, (j, i) in src.sample([(pt.x, pt.y)], indexes=1):
                if value == 10:
                    open_water = open_water.union(box(i, j, i + 1, j + 1))

        # Subtract the open water areas from the buffer
        buffer = buffer.difference(open_water)

        # Create a polygon of the flooding areas
        with rasterio.open(flood_raster) as src:
            flood_area = box(*src.bounds)
            for value, (j, i) in src.sample([(pt.x, pt.y)], indexes=1):
                if value == 1:
                    flood_area = flood_area.union(box(i, j, i + 1, j + 1))

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


## Test
import unittest
from shapely.geometry import Polygon
import numpy as np

class TestDisplace(unittest.TestCase):
    def setUp(self):
        self.pts = [(0, 0), (1, 1)]
        self.admin = Polygon([(0, 0), (0, 5), (5, 5), (5, 0)])
        self.samp_num = 2
        self.other_num = 5
        self.landcover_raster = 'path_to_landcover_raster'
        self.flood_raster = 'path_to_flood_raster'

    def test_displace_returns_correct_shape(self):
        result = displace(self.pts, self.admin, self.samp_num, self.other_num, self.landcover_raster, self.flood_raster)
        self.assertEqual(len(result), len(self.pts))
        for r_pts_i in result:
            self.assertEqual(r_pts_i.shape, (self.samp_num, 2))

    def test_displace_returns_points_within_admin(self):
        result = displace(self.pts, self.admin, self.samp_num, self.other_num, self.landcover_raster, self.flood_raster)
        for r_pts_i in result:
            for pt in r_pts_i:
                self.assertTrue(self.admin.contains(Point(pt)))

    def test_displace_returns_different_points_for_different_input_points(self):
        result = displace(self.pts, self.admin, self.samp_num, self.other_num, self.landcover_raster, self.flood_raster)
        self.assertFalse(np.array_equal(result[0], result[1]))

if __name__ == '__main__':
    unittest.main()