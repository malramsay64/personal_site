+++
title = "What is Published Research"
date = "2018-05-03"
authors = ["Malcolm Ramsay"]
tags = []

draft = true
math = true
highlight = true
+++

In the Sciences,
performance is measured by the publication of research
in academic journals.
While this is an easy way to put a number on an abstract concept,
there seems to be little concern for actually communicating the research.
A problem that seems to be particularly prevalent in my field of computational chemistry
is that there is a disconnect between the communication of ideas,
and the communication of the implementation of those ideas.
We like to imagine we are working in a continuous mathematical space,
yet all the work we perform is discretised to run on a computer.
While this might please the old experts in the field,
as this is the approach they used,
it hides the implementation details
making it no longer a complete communication of the research.
If it takes someone weeks of troubleshooting to replicate your research
have you communicated it effectively?

A couple of years ago I did the computational component for a paper on
crystal melting at an interface under flow[^1].
In this paper we were investigating the behaviour of the stochastic differential equation
\[
\frac{\delta h(\mathcal{z}, \tau)}{\delta \tau} = \Delta + h''[1 + \hat\sigma*2 H(h'')] + \eta(\mathcal{z}, \tau)
\]
which makes no sense without the preceding page of text describing what all the variables mean.
Even after having implemented a solution to this equation,
albeit over two years ago,
this equation alone is meaningless.
That is not to say that this is a bad form to express the equation,
it is through this expression we can look for methods of actually solving the problem,
other fields which have solved equations of the same form,
or solvers that are tailored towards these types of problems.
My main problem with this representation is that
there is a non-trival amount of work to convert
this form into something to actually work with on a computer.
Numerous equally valid methods could be used for
the discretisataion of this equation for computation,
and even more methods for dealing with the edge cases.




[^1] Ramsay, M., & Harrowell, P. (2016). Shear melting at the crystal-liquid interface: Erosion and the asymmetric suppression of interface fluctuations. Physical Review E, 93(4), 042608. https://doi.org/10.1103/PhysRevE.93.042608 [#icanhazpdf](papers/PhysRevE.93.042608.pdf)
