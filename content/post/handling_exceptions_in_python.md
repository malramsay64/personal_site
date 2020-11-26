+++
title= "Handling Exceptions in Numerical Python"
date = 2020-10-19

draft = false

[taxonomies]
tags = ["python"]
+++

The numerical computing capabilities of the Python ecosystem are incredibly powerful,
with the [Numpy] and [Scipy], and [Pandas] packages
providing high performance, well tested tools.
Additionally, tools like [Dask] and [Rapids]
build upon these foundational packages supporting larger datasets.
All these tools are excellent 
when the data is well formed and contains the expected values.
It is when we are handling the error cases
that we can run into issues.

During my PhD,
I used scipy for the analysis of molecular dynamics simulations.
These simulations are effectively putting things in a box 
and shaking it to see what happens.
The novel component of my research
was shaking the box for a really, really, really, long time.
So long that the software I was using ran out of numbers to count. [^1]
Having run the simulation,
I then needed to go though the terabytes of data generated
to calculate quantities of interest.

The huge benefit of using python and the suite of numerical tools
is the ability to quickly prototype a solution,
working through the ideas on a small scale
that can then be applied to the larger dataset.
One of the calculations I was performing
was to fit a straight line to a region of calculated values. [^2]
We could come up with the following solution
for fitting line of best fit to a region of a curve,
returning both the best parameters and the standard deviation.

```python
import scipy

def linear(x, m, b):
    """Define the linear relationship y=mx+b."""
    return m * x + b

def fit_linear_region(x, y):
    """Fit a linear curve where the points lie within a region of 2D space."""
    # Select a region of points
    region = np.logical_and(2 < y, y < 50)
    # Perform the curve fitting only using the linear region
    popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
    # Calculate the standard deviation of the fit parameters
    perr = 2 * np.sqrt(np.diag(pcov))
    # Returns the optimal curve and associated error
    return popt, perr
```

When performing tests on small numbers of values,
we typically choose those behaving as we expect.
Over the course of many long simulations
nearly all possible values are expressed,
meaning this initial testing only covers a small selection 
of all the possible values.
On many occasions,
these unexpected values resulted in the code raising an exception,
unexpectedly bringing an hours long calculation to a halt.
For interactive analysis,
these exceptions are not too problematic,
you can easily fix the problem and re-run the analysis.
However when leaving the calculation running overnight,
coming back to halted execution partway through the analysis
is incredibly frustrating.
In these long running analyses,
in moving from the prototyping
to the production step of the process,
we have to consider all the places
where our code might fail
allowing us to walk away knowing a result
will be waiting for us the next morning.

## Exploring the Solution Space

The problem of handling errors within code 
is faced by programmers in a wide range of disciplines.
Accordingly, there are a range of approaches
to ensure our code doesn't unexpectedly fail.

### Catch-all

One of the possible approaches we can take
is to capture all exceptions with a naked `except` block,
that is

```python
try:
    popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
except Exception:
    return np.nan, np.nan
```

While this approach handles all possible issues that could occur,
it is also heavy handed in its application.
The general goal is to prevent unexpected errors
in a particular configuration halting the execution of our program.
However, in capturing all possible errors,
we also capture errors that can be problematic. 
For example a `KeyboardInterrupt`,
meaning that rather than `<Ctrl>-c` stopping the execution of the program,
it instead describes a curve that doesn't fit.
This could also be problematic with a `FileNotFoundError`,
where instead of getting an error at the start of the program
we have to work out why our results file doesn't exist
when trying to look through them.

While the idea of the catch-all is useful,
it is primarily delaying problems identified when the program runs
to subsequent steps in analysis,
which become more difficult to solve,
amplified by the lack of error messages
and tracebacks that python provides.

### Hypothesis

The main issue with the catch-all case
is that we are overly broad 
in the types of exceptions that we catch.
Rather than catching all exceptions,
what if we could determine the exceptions expected from a function call,
only catching that smaller subset.
This is similar to the approach that you would take
in an interactive type analysis
where you keep adding the exceptions that arise
to the list of those caught and handled.
An alternative to finding these exceptions manually
is through [hypothesis],
a package for enhancing test suites by
using a directed random search,
probing for values that cause problems.
The directed part of hypothesis 
ensures values likely to cause issues,
including small values, large values, zero, NaN, and Infinities
are handled appropriately.
In ensuring we handle all these different values,
Hypothesis is a tool that ensures that we codify
the assumptions we make about the data we put into our algorithms.

Working with hypothesis requires a fair amount of setup,
building upon a test framework like pytest.
Additionally, as a property testing framework,
rather than testing specific values
we instead need to test properties,
requires a rethinking of how we test functions.
In the example covered in the this article,
the property we are testing is ensuring our function
is doesn't unexpectedly raise an exception.
The testing of this property
can be achieved by creating the test
as shown in the code snippet below.

```python
from hypothesis import given
from hypothesis.extra.numpy import arrays

@given(x=arrays(dtype=float, shape=10), y=arrays(dtype=float, shape=10))
def test_example(x, y):
    fit_linear_region(x, y)
```

Here we use hypothesis to generate the two inputs to our function, `x` and `y`.
Each of these is created from a numpy array of 10 elements (`shape=10`)
containing floating point values (`dtype=float`).
The `@given` decorator allows hypothesis to generate inputs
based on the values that we have provided,
running each to check that it runs.
In this code snippet
we are making clear some assumptions that we have made about our data.
Firstly that we are expecting floating point values,
being the `dtype` that we are generating.
The second is that the `shape` of both `x` and `y` is equal.
One of the advantages of hypothesis
is bringing to light these occasionally hidden assumptions
about the inputs to our functions.

By using hypothesis to generate inputs to our function,
we find some additional errors that can occur.
When there are no points that lie within our specified range,
we get a `ValueError`,
while when there is only a single value in that range 
we get a `TypeError`.
Additionally, when scipy is unable to find
and appropriate line of best fit,
an `OptimizeWarning` is raised.
This results in the following `fit_linear_region` function
to handle these three exception cases.

```python
def fit_linear_region(x, y):
    """Fit a linear curve where the points lie within a region of 2D space."""
    # Select a region of points
    region = np.logical_and(2 < y, y < 50)
    # Perform the curve fitting only using the linear region
    try:
        popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
    except (ValueError, TypeError, scipy.optimize.OptimizeWarning):
        return np.nan, np.nan
    # Calculate the standard deviation of the fit parameters
    perr = 2 * np.sqrt(np.diag(pcov))
    # Returns the optimal curve and associated error
    return popt, perr
```

While using hypothesis allows us to easily find
some of the failure modes of functions,
it is another tool to learn how to use effectively.
It would be nicer if there was a simpler solution
to finding the errors raised by a function
that made use of existing tools.

### Documentation

The documentation for a function
is something regularly referred to,
whether that be through the online documentation
or through the help messages of a function.
This makes the function docstrings a fantastic place
to put information about the exceptions a function could raise.
The scipy docs include this information
for some of the functions, including [curve fit][curve_fit_docs].
Within the **Raises** section,
it notes there are three different exceptions the function can raise,
a `ValueError`, `RuntimeError`, or `OptimizeWarning`.
This list of exceptions demonstrates a limitation of using hypothesis,
it won't always find *all* the possible exceptions a function can raise,
here missing the `RuntimeError`.
However, on the flip side, 
the `TypeError` we found with hypothesis is currently missing from the documentation.
This is a limitation of the documentation approach,
the exception comes from a function called by `curve_fit`,
propagating beyond the initial call site,
making it difficult to notice and to keep the documentation up to date.
The documentation approach is also prone to degrading over time,
as the code gets updated and changed,
the documentation has to be changed and updated alongside it,
and for exceptions this can be in multiple unrelated locations.
One of the solutions for this
is representing the possible exceptions in code,
rather than through the documentation
allowing tooling to provide assistance,
much like [mypy] and [pyright] do for type annotations.

### Rust

One of the highly regarded parts of the Rust programming language,
is the comprehensive type system that explicitly handles errors.
In a similar way to exceptions within Python,
the `Result` type within Rust
is a way of stating that something has gone wrong.
The big difference between an exception in python
and the `Result` type in Rust,
is that in Rust you *must* explicitly handle the error.
In the simplest case this error handling is equivalent to a python exception,
stopping the execution of the program and exiting.
The key enhancement with the Rust approach
is that there is a record of every place
within the code that an error could halt the execution.
When prototyping on the sample datasets within Rust,
we can use the exception model of error handling,
halting the execution of the program using `.unwrap()`.
However, when moving to a more complex analysis pipeline,
or when developing a library that people rely on,
unexpected errors are no longer a good option.
Here, all instances of `.unwrap()`
can be converted into more appropriate methods
to handle those errors.
These propagation of the `Result` type occurs similarly to
the handling of `Optional` values within type checked python code.
Whenever we call a function that returns a `Result`,
we have to check whether we have the `Ok` value,
in which case we can continue on,
or the `Err` value,
where it has to be either be handled
or passed on to a calling function through the `Result` type.

In principle, supporting a `Result` type within python
like exists within Rust is possible, however,
what makes the type so useful within Rust
is that it *must* be handled,
a guarantee that can't and won't be enforced within python.

## Conclusion

One of the key principles of python
is the ease of getting started.
Advanced parts of the language,
can be ignored until they are required.
Ignoring advanced parts of the language
is not just helpful for the learning process,
but also for slowly building up complexity
in the projects that we start.
When working with long running processes,
exception handling becomes an important part of the development process,
however, I don't know of a clear way
to find all the possible ways an exception could be raised
from a function we might use.
This makes the development process a continually iterative one,
run the code until you find an exception,
handle the exception and start again,
a process that is not ideal,
particularly for overnight calculations.

[^1]: It was only using 32 bit unsigned integers, however that was decided to be more than anyone would need.

[^2]: If you have to know, I was calculating the Diffusion constant, 
a measure of how fast particles move over long timescales.
This is a linear function of the Mean Squared Displacement vs time.

[Dask]: https://dask.org/
[Numpy]: https://numpy.org/
[Pandas]: https://pandas.pydata.org/
[Rapids]: https://rapids.ai/
[Scipy]: https://www.scipy.org/
[curve_fit_docs]: https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.curve_fit.html
[mypy]: http://mypy-lang.org/
[pyright]: https://github.com/microsoft/pyright
