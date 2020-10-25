+++
title = "The Importance of Open Science"
date = 2018-08-23

draft = true

[taxonomies]
tags = ["research"]
+++

There was this article in physics today
- it raises some excellent points about the open science
- In summary two groups were fighting over getting different results for the
    'same' computational experiment

Computational Experiments
- This is not a lab experiment
    - exactly replicable
    - random numbers are not really random
    - exact same computational environment
        - you can replicate all of my experiments in 4 lines of shell script
- Computer code is also really complex
    - really easy to introduce bugs
    - I recently discovered I have to recompute two years worth of data because
        of a small bug in my simulation code
    - The output of the research is not so much the result but the computer
        code to run it
- Papers communicate in mathematical equations
    - these have to be translated to code
    - elements are lost in the translation to and from code

How do I get involved in open science
- Open lab notebooks
    - LabArchives
    - OSF
    - these are more suited to more physical experiments
- Data Analysis
    - cookiecutter data science
    - Jupyter Notebooks
        - google colab
        - nteract
        - binder
    - A framework for making your data analysis and code open source and
        accessible
    - check out my project
- code
    - All code should be prepared as though for an outsider
        - in 6 months you will be an outsider
    - Comments and documentation
    - Read the docs
    - tests
- License
    - I am not a lawyer
    - MIT
        - Do what you want with it
        - I am not responsible for any bugs
- Open science has more citations
    - more involvement
    - more trust


- Code available upon request
    - bullshit

Conclusion
- More projects are using computational workflows for some aspect of the work.
- Translation of code to maths
    - things lost in translation
- Making the research open benefits everyone





“One of the real travesties,” he says, is that “there’s no way you could have reproduced [the Berkeley team’s] algorithm—the way they had implemented their code—from reading their paper.” Palmer

 “I had and was very willing to share the code,” he says. What he didn’t have, he says, was the time or personnel to prepare the code in a form that could be useful to an outsider. “When Debenedetti’s group was making their code available,” Limmer explains, “he brought people in to clean up the code and document and run tests on it. He had resources available to him to be able to do that.” At Berkeley, “it was just me trying to get that done myself.” Limmer

 After several email exchanges with Limmer and Chandler and a direct plea to Nature editors, the Princeton group finally received a working version of the Berkeley code.


[war over water]: https://physicstoday.scitation.org/do/10.1063/PT.6.1.20180822a/full/
