+++
title = "Failure of Epic Proportions: How I 'lost' two years of data."
date = "2018-08-22"
authors = ["Malcolm Ramsay"]
tags = []

draft = true
math = true
highlight = true
+++

Failure is one of those things that is little discussed---It is hard to tell
other people about all the mistakes you have made. Yet so often failure is a
far better teacher than success, which is why I want to share my story of
making two years worth of data collected for my PhD useless. Despite the
provocative title, this is not a story of despair, rather one of rebuilding.
As I write this, a week after finding the bug, I am basically now just waiting
for simulations to finish to be back where I was beforehand.


I perform computer simulations of toy molecular systems, using something simple
and understandable to gain insights into more complicated chemical systems. A
major benefit of using a toy system is that it is simple to modify the
parameters of the simulation to test a hypothesis. I was testing a hypothesis
that the rotational motion of a molecule is more important than the
translational motion, so I was using a one of these toy systems which allows
me to control the effective magnitudes of these two types of motion. The
translational motion is governed by the *mass*; heavy objects are more
difficult to move in a straight line. While the rotational motion is governed by the
*moment-of-inertia*, a measure of how difficult something is to rotate.
Though varying these two properties, the *mass* and *moment-of-inertia*, I am
able to establish relationships between translational and rotational motion.
If I set the *moment-of-inertia* really large effectively stopping the
rotational motion, what happens to the translational motion? Or the opposite,
making the *moment-of-inertia* really small.

Before I started changing the parameters of the toy model, I need a reference
(or control) model which is related to existing results. Science is always
performed with reference to the existing knowledge at the time, so this
provides a link and point of comparison to existing results both of other toy
models and real chemical systems. I have a molecule comprised of three circles,
one large and two small, arranged somewhat like a Mickey Mouse head.

![The molecule I am studying, three circles arrraged like a Mickey Mouse
head.][image.png]

When working with these toy systems, I use a system of units such that most
values have a unitless quantity of 1. Each particle has a point mass at the
center of the circle of 1, the large circle has a radius of 1, a reasonable
temperature is 1---It is really nice when nearly all the multiplication and
division effectively disappears. The other smaller particles have a radius of
$0.63$ and are located at the radius of the large particle at an angle of
$120^\circ$.

I am using the above molecule in Molecular Dynamics (MD) simulations, which use
Newton's equations of motion, primarily $a=F/m$ and $\alpha = \tau/I$, that is
the acceleration $a$ of a molecule is related to the force $F$ acting on it
divided by the mass $m$ and the angular acceleration $\alpha$ is related to the
torque $\tau$ divided by the angular momentum $I$. MD simulations have two
different methods of dealing with the types of molecules I am using. The first
is to solve these equations for all particles individually followed by a second
step to restore the molecular shape. The second approach is to calculate the
force on each particle and then solve the above equations for a single point,
moving the entire molecule.

In concert with a major release, the software I use for running my simulations,
Hoomd, changed how it handled these systems from the first method to the
second. At the time I didn't completely understand the changes that were made,
assuming everything was the same, only I didn't actually check. Because of not
checking that




Introduction
- Failure
    - we don't talk about it enough
- this is not a data issue, it is an issue of testing
- Not a complete failure, since a week later I am basically where I was before
    this started

Problem definition
- what went wrong
    - incorrect mass of particles
    - also less importantly incorrect center-of-mass
- why that matters
    - key result is the relationship between rotations and translations
    - rotations assumed mass of 3, mass was actually 1
    - this mistake built this result into the simulations
        - it is not that the results themselves are completely wrong
        - a lack of a control group
            - you built this into your simulations, why would this apply to
                other simulations

Problem Solution
- Re-define all the quantities in my simulations
- Ensure everything still works

Not really a problem
- automated testing
    - Ensure each part of the program is doing what I expect
        - this means adding new tests for the masses of the particles
    - each time a bug is encountered, add a test to check for it
        - don't miss the same bug twice
        - always checking for this issue
        - it has been identified as a problem
- The automated testing provides confidence to break things
    - the upend a drawer onto the floor approach to cleaning up
    - checks everything all the time
- Code coverage is a method of checking all the tests are actually running
    - If a test doesn't run it can't fail
    - Is the test actually testing the right code path.

In four days I had
- completely overhauled my codebase
    - 1700 insertions, 1100 deletions
    - ~1/3 of the codebase
- 373 to 454 tests

This is only half the story
- The testing ensued that the API remained the same
- all the code I had been using to run the simulations still works
- I have been working on a reproducible science workflow
    - make it easy for others to replicate my result
    - this was really useful for me now that I had to rerun all my simulations.

Conclusion
- although we may not like to admit it, we all make mistakes
    - best practices are guidelines for making mistakes known an easy to fix
- while reproducible science is often geared towards helping others
    reproduce your results, sometimes it is really just for you.
- there are lots of tools available for open source projects, make use of them
