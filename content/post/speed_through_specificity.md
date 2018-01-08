+++
title = "Speed Through Specificity"
date = "2017-12-10"
draft = true

highlight = true
+++

One of the main complaints of Python is it's lack of speed.
Jake van der Plass has an excellent [blogpost][why python is slow]
explaining the technical details of what occurs in a function call.
The basic premise of this post is that in being a dynamically typed language
python code is written for a general case,
regardless of the intention of the  developer.
A simple `add` function

    def add(a: int, b: int) -> int:
        return a + b

is written to handle the addition of any two python objects
not just the `int` types that we intend.

When writing in statically typed C we write code for highly specific cases.
The same add function in C code will _only_ work with with integer values.

    int add(int a, int b){
        return a + b
    }

The specificity of the C code allows it to forgo many of the checks
the python code has to perform,
resulting in code that appears to run faster
because it is doing much less work.

This idea of specificity to improve performance
is not just present in the programming languages we use,
it is also also in the code we use and write.

Recently I needed to compute
the number of Voronoi neighbours for
about 2000 molecules in a simulation,
and I needed it to be fast,
performing the computation as a real time analysis.
One of the standard programs for
computing Voronoi cells in Molecular Dynamics simulations
is [Voro++][voro++],
a C++ library with support for
periodic boundary conditions and
2D or 3D simulations.
There is already a python library, [tess][tess]
which provides an interface to Voro++,
however being a library,
it is designed to be useful for a range of problems.
To compute the number of neighbours,
I first have to compute the Voronoi tessellation,
which creates a list of python objects representing each Voronoi cell.
I then need to loop over the cells
computing the number of faces in each.

    import tess
    # Compute Voronoi tesselation
    c = tess.Container(position, limits=box, periodic=True)
    # Count number of neighbours/faces in 2D  = (3D - top - bottom)
    num_neighs = [cell.number_of_faces() - 2 for cell in c]

This would be a perfectly reasonable method of computing
the number of Voronoi neighbours,
except it is too slow for real time analysis,
taking 250 ms to run.
I need a performance increase of about 10x
to have something that is really interactive.

Much of the time in the above code is taken up by
the generation of the Container object,
so there is not much that can be done.
There needs to be a significant shift
in the approach taken to compute the neighbours.
The tess package is designed to be general,
take as much of the functionality of Voro++
and make it available to python.
I only care about the number of neighbours and
none of the other functionality.


<!--So I don't really know where I am going here,
I have an excellent thesis
with what I think is an excellent introduction.

What is required now is a concrete example,
a simple to explain case where the specificity of code
makes a huge impact on the running time.
Ideally this would be an example that is simple
and will run slowly on C++.

Essentially the idea that Python isn't slow,
rather code to handle the general case is.
-->

[why python is slow]: https://jakevdp.github.io/blog/2014/05/09/why-python-is-slow/
[voro++]: http://math.lbl.gov/voro++/
[tess]: https://github.com/wackywendell/tess
[pyvoro]: https://github.com/joe-jordan/pyvoro
[ctyhon]: http://cython.org/
