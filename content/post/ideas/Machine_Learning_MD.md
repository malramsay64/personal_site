+++
title = "Machine Learning in Molecular Dynamics"
date = 2017-12-17

draft = true

[taxonomies]
tags = ["python", "ML"]
+++

## The Problem

One of the key goals of Molecular Dynamics (MD) is to understand
the structures that form in the course of a simulation.
These structures are often very similar and are
also distorted by thermal fluctuations
making it difficult to design metrics that effectively detect them.
Machine Learning is an approach that can simplify this classification problem,
providing a framework for the optimal classification of the component structures.

My interest in the use of Machine learning for structure classification
arises from my work on systems of small molecules.
The particular system I am using has three different crystal structures,
shown below, which are all potentially present in a simulation.

<images>

To understand the crystal growth of this system,
I need to be able to detect both
the presence of a crystal, and
the type of crystal that is present.
This makes four classes of interest for a machine learning model,
the p2 crystal,
the pg crystal,
the p2gg crystal, and
the liquid.

## The Data Curation

With a well defined problem,
the next step in machine learning is
the curation of a dataset used to train the model.
During this curation it is important to develop a dataset
that is representative of the range that exists
in the unknown datasets to be classified.
For MD simulations this should at least cover the range of
temperatures, pressures, structures, or any other variable property.
In addition to begin representative, the dataset needs to have
labels for each state in the dataset.

<images>

My training data is from a collection configurations
with a liquid/crystal interface,
like in the images above.
As I have constructed the interface I know the state of the
molecules at the beginning of a simulation.
It is important to note that I have excluded the interface from classification,
due to it being constructed by the constraint of the crystal region,
and additionally the interface is less well defined
than either the liquid or crystalline regions.

A vital component of the development of machine learning algorithms
is the feature detection step.
This requires finding parameters that
best describe the differences
between each of the classes.
These parameters can be anything from
intrinsic properties like the position or orientation,
or highly computed values like a bond order parameter.
Typically the best performance is gained by combining
a number of different metrics.

The crystal structures I am investigating have
distinct orientational arrangements of the neighbours.
The parameter I used as a starting point was
the relative orientation of all the neighbouring molecules.

<image>

This is depicted in the image above,
the center molecule in red has an orientation facing down.
In this case all the neighbouring molecules (in grey)
have orientations close to parallel or antiparallel
with that central molecule.
This gives 6 parameters to use for each molecule.

## The Machine Learning

One of the most persistent issues with
using supervised machine learning is
the machine learning algorithm just
learning the test dataset rather than
actually extracting useful information.
When I was performing early testing of
applying machine learning to this problem,
I had a bug where I was using
the index of nearest neighbours as the feature set,
rather than the relative orientation of the nearest neighbours.
Despite this bug,
the accuracy of the learning was still
close to 95% on the training data,
yet was wildly inaccurate when
tracking the evolution of the simulation through time.

To minimise the effect of algorithms learning the dataset,
there are a few methods we can employ,

Learning process

- training, test data
- cross validation
- random noise

Application to real problems
