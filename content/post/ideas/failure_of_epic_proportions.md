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

## The Problem

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
second. In getting my simulations to work with the updated version of hoomd, I
had to manually enter a moment of inertia which I calculated for particle being
a point mass of 1, yet I made no changes to the masses, which meant that the
rigid body only had a mass of 1 instead of 3. At the time I didn't completely
understand the changes that were made, assuming everything was the same, only I
didn't actually check. By not actually checking or testing that the simulations
were behaving as intended I spent the next two years of my PhD characterising
the behaviour of the wrong control experiment. I think it is fairly likely that
I will observe very similar results with the intended simulation, however I
need the data to back that hypothesis up.

## The solution

Somewhat similarly to the problem that put me put me in this position in the first
place, I can just redefine the molecules in my simulations now knowing the proper method
of doing so and re-run all my simulations. Looking back on that initial change, I
realise that the main issue was not that a part of simulation infrastructure changed, it
was that I had no structured method of testing that the simulations are working; that
is, they haven't changed.

A common tool for the prevention of change, particularly in the software development
space, is the use of automated testing. This is a suite of tests ensuring the
functionality of all parts of the codebase, from checking the return value of a small
function, to ensuring the application works as a whole. In the two years since I had
made the change to Hoomd v2.0.0 I had added a suite of test cases to ensure the correct
functioning of the codebase. Each time I encountered a bug, I created a new set of test
cases to ensure it didn't reappear. It is these test cases which are the real hero in
this situation, giving me the confidence to break things, taking the upend-a-drawer
approach to fixing up the code. In four days I had managed to completely overhaul my
codebase, making changes to roughly 1/3 of it. Yet even with all these changes, the
Application Programming Interface (API)---a fancy way of saying the parts of the program
that someone actually interacts with---remained constant, thanks to the test suite.
Since the API was the same, all the additional code I had to run my simulations still
worked with the updated code. All that remained was to set them all going.

Although we don't like to admit it, we all make mistakes. Mistakes, failures, and bugs
are all part of doing something on the cutting edge. While they may be disruptive or
inconvenient, they are only really damaging if they keep re-occurring. Making a mistake
once is just part of the process, repeatedly making the same mistake is a problem, like
the adage "fool me once shame on me, fool me twice shame on you". Best practices like
automated testing are really just ways of making the mistakes that do occur obvious and
simple to fix, as well as providing a way of preventing them from reoccurring. I am
fairly confident that should this particular bug reappear I will notice, although that
doesn't mean there isn't another just like it hiding away somewhere for me to find.
