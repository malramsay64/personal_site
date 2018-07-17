++
title = "Compiling LaTeX on Travis-CI"
date = "2018-07-16"

draft = true
math = true
highlight = true
+++

Currently in software development these is a proliferation of services offering Continuous
Integration (CI) and Continuous Delivery (CD). These are services that act as part of a git
workflow ensuring that an application works as expected by compiling and running tests (CI).
Should the code pass all the test requirements, it will see real world use (CD). This paradigm
takes the processes that you should be performing often, like running test suites, or compiling
the code and automates them so they actually occur.

Why would you want to use the CI/CD paradigm for LaTeX documents? Why not just build on my local
machine? When
Using the CI/CD paradigm for LaTeX
- Ensure all the required files like images are included in the repository
- Have a method of managing multiple document versions
- conduct the compilation of the entire document more regularly
- ability to set up automated checks
- Ensure the entire process works, not just because I have a file left over from something else

- Introduction to CI/CD
    - Why it is used in code
    - Why it can be useful for LaTeX docs

One of the biggest challenges for creating a CI configuration for LaTeX is that there is no
pre-configured image on CI providers. The closest to a configured server is the R container on
travis-CI which has a base installation of the TexLive distribution. A problem with LaTeX is there
is no simple method of working out which packages are required to build a document, an issue with is
particularly difficult when dealing with different version numbers. Another significant issue is
that downloading the entire TexLive distribution takes a really long time, with the same issue when
using a docker container with the entire TexLive distribution.

- Challenges for LaTeX
    - The complete TeXLive distribution takes forever to download
    - No simple way of specifying and updating the packages required
    - NO CI provider offers a complete LaTeX environment
        - closest is the R container on Travis CI
        - only offers the base packages

There are a number of different LaTeX distributions, all of which are slightly different. The
TeXLive distribution is the distribution provided with most linux distributions. While being the
canonical distribution the management of packages is difficult, with the recommended

- Solutions
    - TeXLive
        - too large to download completely
        - have to manually spec packages to download
        - Is installable using apt assuming you have the correct packages
            - You have to perform the entire installation each time
        - Docker container
            - Large image

    - MikTex
        - Docker image available
        - Can download required packages automatically
        - Biber is only supported on Windows
            - I don't want to try and deal with CI in windows

    - Tectonic
        - A relatively new project
        - Complete standalone (nearly) binary
        - Installable using conda
        - Downloads required packages automatically
        - No support for biber

    - There are no really good solutions for compiling latex documents using CI
        - at least none that I have found

- MY solution
    - Of the options above I like tectonic the best
        - Installable using conda
            - package manager I use for all the rest of my code
            - Really easy to use and install
            - I have travis scripts already using conda
        - Pandoc is also installable using conda
            - The workflow for LaTeX I want is markdown to .tex to .pdf
                - or just skip the tex part
            - Pandoc does the conversion, either to .tex or straight to .pdf using latex
        - Biber download binary from sourceforge

- Code

- Deployment
    - With the document compiling, how do we save it somewhere useful
    - Travis-CI deployments
        - I am deploying to GitHub to keep everything in a single location
        - can also deploy to others https://docs.travis-ci.com/user/deployment
        - or just use a script to upload somewhere
            - make sure to not include your credentials
    - I have chosen to use github releases
        - every time I tag a commit `git tag <tag>` a new version is uploaded to the releases
        - I am using a semver like approach so my tags are `v0.1.0`, `v0.1.1` ...
        - This keeps every historical release so you can go back in time
        - When I tag a commit, I also update a version number in the document, which is on the
            footer of every page.
            - This keeps continuity of versions even with printed documents

- Conclusion
    - This should work for almost all latex Documents
    - Tectonic compiles using xetex for unicode and font support

