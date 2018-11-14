+++
title = "presenting_science.md"
date = "2018-11-14"

draft = true
math = true
highlight = true
+++

- reproducibility
- science talks are more about how good you are not about communicating research
- focus on the communication of the science
- 'reproducible' science
    - what makes something reproducible
    - all results presented in papers should be reproducible
    - while the results technically are, they often require
        - communication with the author
        - a collaboration
        - spending 6 months trying to recreate the experiment

- Computational experiments should be really easy to reproduce
    - I have found we are really bad at this
    - missing dependencies
    - it works on my system

- Second Screen Browsing
    - most people in a talk will have a second device, phone/laptop
    - this is something you can use to engage the audience
    - Interaction is not something you can provide with a presentation,
        yet perfectly reasonable with a second screen
    - Lots of interesting interactive visualisation tools in JavaScript

- What would represent the *most* reproducible experiment?
    - during a talk
    - not just you, but everyone else in the room

- Technical Requirements
    - no installation -> browser based
    - Independent analysis -> docker containers
        - each person has own environment
        - can break or improve as much as they like
    - MyBinder
        - meets all these requirements
        - easy to setup/use

- How I went about doing it
    - instructions for setup/configuration

- Notes:
    - browser allows interactions not possible with static images
    - Robustness of research
        - How suitable is this to solving the problem
        - do tiny changes have huge impacts on the results
        - understanding beyond what you actually present
