+++
title = "Failure of Epic Proportions: How I 'lost' two years of data."
date = "2018-08-22"
authors = ["Malcolm Ramsay"]
tags = []

draft = true
math = true
highlight = true
+++

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
