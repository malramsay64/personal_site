+++
title = "Wrapping with Cython"
date = "2017-12-17"
draft = True

highlight = true
+++

 <!--This really needs a good introduction to why this
 is an interesting problem.
 -->

I have been interested in computing the [Voronoi neighbours][voronoi wikipedia]
of a series of points in a 2D plane with periodic boundary conditions.
This amounts to finding the area 'occupied' by a point and
then counting the number of sides.
As with many other problems my first step with Python
is to look for existing libraries that already implement this functionality.
There is actually an implementation of this algorithm in the Scipy library.
This implementation wraps the [Qhull][qhull] library which is incredibly versatile,
able to deal with up to 27 dimensions and millions of points.
While dealing amazingly well with the general case,
it doesn't handle periodic boundary conditions,
and the additional processing required was too slow for my purposes.

The main library for computing these values is [Voro++][voro],
an optimised C++ library specifically for this purpose.
As with many libraries in the scientific computing world,
there is a python wrapper around this library,
with the currently maintained version being <author> [pyvoro][pyvoro]
This is an excellent implementation of all the functionality of voro++.
However in dealing with the general case this didn't reach my performance requirements.
A python object was being created for each Voronoi cell,
a perfectly valid approach


[voronoi wikipedia]:
[qhull]:
[voro]:
[pyvoro]:
