# Software Quality Standards & Design Philosophy Confirmations

## TASK A: Objective Quality Standards

### ISO/IEC 25010 (SQuaRE: Product Quality Model)

**Source:** ISO/IEC 25010:2011, International Organization for Standardization  
**URL:** https://www.iso.org/obp/ui/#iso:std:iso-iec:25010:ed-1:v1:en  
**Standard:** https://www.iso.org/standard/35733.html

**8 Product Quality Characteristics (verified):**

1. **Functional Suitability** — How well a product provides functions meeting stated and implied needs
2. **Reliability** — How well a system performs specified functions under specified conditions
3. **Performance Efficiency** — Resource utilization (time behavior, capacity)
4. **Usability** — Effectiveness, efficiency, and satisfaction in achieving user goals
5. **Security** — Protection of data, integrity, and system against unauthorized access/use
6. **Compatibility** — Ability to exchange information with other systems and operate in different environments
7. **Maintainability** — Degree of effectiveness with which a product can be modified by intended maintainers
8. **Portability** — How easily the software installs on different target environments

**Maintainability Sub-characteristics (verified):**

- **Modularity** — Extent to which system components can be altered with minimal impact on others
- **Reusability** — Potential for assets to be utilized across multiple systems
- **Analysability** — Effectiveness of impact assessments and diagnosability for deficiencies
- **Modifiability** — Ease of system modification without compromising quality
- **Testability** — Effectiveness of establishing test criteria and conducting tests

**Citation from sources:**  
"ISO/IEC 25010 is part of the SQuaRE series...This standard is the successor to ISO/IEC 9126...In 2011, ISO/IEC 25010 was published to improve upon the previous version, refining the characteristics of software quality" ([ISO 25010 Medium Article](https://medium.com/@oczz/understanding-iso-iec-25010-a-comprehensive-framework-for-software-quality-evaluation-ae3cc5250057))

**Reliability:** HIGH — Authoritative ISO standard adopted 2011, confirmed across multiple sources (ISO official, Medium/Codacy technical summaries)

---

### CISQ / ISO/IEC 5055 (Automated Source Code Quality Measures)

**Source:** ISO/IEC 5055:2021, adopted by ISO from CISQ/OMG standard  
**URL:** https://www.it-cisq.org/standards/code-quality-standards/  
**Standard:** https://www.iso.org/standard/80623.html

**4 Structural Quality Factors (verified):**

1. **Reliability** — Structural weaknesses indicating maturity, fault tolerance, recoverability
2. **Security** — Structural weaknesses in confidentiality, integrity, authenticity, accountability
3. **Performance Efficiency** — Structural weaknesses indicating resource-use problems
4. **Maintainability** — Structural weaknesses affecting modifiability, clarity, and defect density

**Quote from CISQ/ISO:**  
"ISO/IEC 5055:2021 is an ISO standard for measuring the internal structure of a software product on four business-critical factors: Security, Reliability, Performance Efficiency, and Maintainability. These are the factors that determine how trustworthy, dependable, and resilient a software system will be." ([CISQ Standards Page](https://www.it-cisq.org/standards/code-quality-standards/))

**Additional Context:**  
"Before ISO 5055, there was no international standard for measuring the quality and integrity of a software system by analyzing its internal construction to detect severe structural weaknesses...ISO 5055 provides before-the-fact measures of the product's software during development to identify and eliminate structural weaknesses before they cause operational problems."

**Composition:** ISO/IEC 5055 contains **138 weaknesses** (mapped from CWE — Common Weakness Enumeration) across the 4 factors.

**Reliability:** HIGH — First ISO standard to measure source-code structural quality; adopted 2021; authoritative CISQ/OMG lineage

---

## TASK B: Design Philosophy Confirmations

### 1. David Parnas (1972) — "On the Criteria To Be Used in Decomposing Systems into Modules"

**Source:** David L. Parnas  
**Publication:** Communications of the ACM, Vol. 15, No. 12, pp. 1053–1058, December 1972  
**URLs:** 
- [CSE MSU PDF](https://cse.msu.edu/~cse870/Public/Lectures/SS2007/ParnasPapers/decomposition-macklem.pdf)
- [A Color's Blog Summary](https://blog.acolyer.org/2016/09/05/on-the-criteria-to-be-used-in-decomposing-systems-into-modules/)
- [ACM DL](https://dl.acm.org/doi/10.1145/361598.361623)

**Core Thesis — VERBATIM QUOTE:**

"We have tried to demonstrate by these examples **that it is almost always incorrect to begin the decomposition of a system into modules on the basis of a flowchart**. We propose instead that one begins with a list of difficult design decisions or design decisions which are likely to change. Each module is then designed to hide such a decision from the others. Since, in most cases, design decisions transcend time of execution, modules will not correspond to steps in the processing..."

**Summary of Argument:**
- Systems should be decomposed by **hiding design decisions likely to change**, NOT by processing steps or flowchart structure
- Each module is characterized by the design decision it hides from all others
- This approach yields simpler, more abstract interfaces enabling faster independent development
- Modules can be modified independently without affecting others

**Reliability:** VERY HIGH — Original peer-reviewed academic paper, foundational to software modularity, widely cited (40+ years)

---

### 2. John Ousterhout — "A Philosophy of Software Design"

**Source:** John K. Ousterhout, Stanford University  
**Publication:** Book (2018); based on Stanford CS169 course philosophy  
**References:** 
- [Philosophy of Software Design overview](https://www.mattduck.com/2021-04-a-philosophy-of-software-design.html)
- [Medium Summary](https://medium.com/swlh/a-philosophy-of-software-design-by-john-ousterhout-4a00d0ff9f1c)

**Deep Modules — VERBATIM QUOTE:**

"The best modules are those that provide powerful functionality but have a simple interface...a deep module—[one with] simple interface, complex functionality...Information hiding is paramount, and we don't hide as much complexity in shallow modules."

**Complexity Root Causes — QUOTE:**

Ousterhout identifies two fundamental causes of complexity:

1. **Dependencies** — Between software components, leading to change amplification and cognitive load
2. **Obscurity** — When important information is not obvious, creating unknown unknowns and cognitive load

**On Dependencies and Obscurity:**
"Dependencies are a fundamental part of software and can't be eliminated, but one of the goals of software design is to eliminate dependencies where possible, and to make the dependencies that remain as simple and obvious as possible."

**Reliability:** MEDIUM-HIGH — Contemporary design philosophy text, well-regarded in industry, not a formal empirical study but grounded in engineering experience

---

### 3. Ousterhout vs. Robert C. Martin: The Clean Code Debate

**Source:** GitHub discussion between John Ousterhout and Robert C. Martin  
**URL:** https://github.com/johnousterhout/aposd-vs-clean-code  
**Documentation:** "A Philosophy of Software Design vs Clean Code"

**Ousterhout's Critique of Clean Code — VERBATIM QUOTE:**

"Our first area of disagreement is method length...Like most ideas in software design, decomposition can be taken too far. As methods get smaller and smaller there is less and less benefit to further subdivision. The amount of functionality hidden behind each interface drops, while the interfaces often become more complex. I call these interfaces 'shallow': they don't help much in terms of reducing what the programmer needs to know."

**Direct Criticism:**
"The advice in Clean Code on method length is so extreme that it encourages programmers to create teeny-tiny methods that suffer from both shallow interfaces and entanglement."

Ousterhout specifically critiques Clean Code's arbitrary limits: "2-4 lines in a method and a single line in the body of an if or while statement."

**Martin's Response (Key Disagreement):**
Martin argues that short functions follow the Single Responsibility Principle and reduce cognitive load through separation of concerns. Ousterhout counters that over-separation creates shallow modules with complex interfaces that actually **increase** cognitive load due to interface complexity and entanglement.

**Core Disagreement:**
- **Martin:** Separation of concerns → smaller cognitive load per unit
- **Ousterhout:** Deep modules → simpler interfaces → lower overall cognitive load (fewer interactions to track)

**Reliability:** HIGH — Direct documented exchange; both parties are distinguished software engineers; GitHub source is authoritative record

---

### 4. John Hughes — "Why Functional Programming Matters" (1989)

**Source:** John Hughes  
**Publication:** The Computer Journal, Vol. 32, No. 2, April 1989  
**URLs:**
- [Chalmers CS](https://www.cse.chalmers.se/~rjmh/Papers/whyfp.html)
- [University of Auckland](https://www.cs.auckland.ac.nz/~j-hamer/360/why-fp-matters.html)
- [A Color's Blog](https://blog.acolyer.org/2016/09/14/why-functional-programming-matters/)
- [Oxford Academic](https://academic.oup.com/comjnl/article-abstract/32/2/98/543535)

**Modularity Through Glue — VERBATIM QUOTE:**

"Modular software is generally accepted to be _the_ key to successful software...When writing a modular program to solve a problem, one first divides the problem into sub-problems, then solves the sub-problems and combines the solutions. The ways in which the original problem can be divided up depends directly on the ways in which solutions can be \`\`glued'' together. Therefore, **providing new kinds of \`\`glue'' provides new opportunities for modularisation.**

**Higher-order functions and lazy evaluation are two very important kinds of glue.**"

**Higher-Order Functions as Glue:**
"A higher order function is a function that takes a function as an argument, or returns a function. Higher-order functions are a new kind of glue that enables simple functions to be glued together to make more complex ones."

**Lazy Evaluation as Glue:**
"Lazy evaluation is a 'call by need' execution strategy whereby a function is invoked only when needed. Lazy evaluation makes it practical to modularize a program as a generator that constructs a large number of possible answers, and a selector that chooses the appropriate one."

**Key Thesis Clarification:**
Hughes argues FP's advantage is **modularity via composition**, NOT the absence of side effects. The paper emphasizes that functional languages' combination of higher-order functions + lazy evaluation creates superior "glue" for combining modular pieces.

**Practical Impact:**
"Smaller and more general modules can be reused more widely, easing subsequent programming, which explains why functional programs are much smaller and easier to write than conventional ones."

**Reliability:** VERY HIGH — Foundational peer-reviewed academic paper (1989); widely cited; primary source on FP modularity thesis

---

## Summary

| Standard/Author | Type | Key Claim | Confidence |
|---|---|---|---|
| ISO/IEC 25010 | Formal Standard (2011) | 8 characteristics; maintainability has 5 sub-characteristics (modularity, reusability, analysability, modifiability, testability) | VERY HIGH |
| ISO/IEC 5055 | Formal Standard (2021) | 4 source-code quality factors: Reliability, Security, Performance, Maintainability | VERY HIGH |
| Parnas 1972 | Peer-reviewed Paper | Decompose by hiding design decisions likely to change, not by flowchart | VERY HIGH |
| Ousterhout 2018 | Design Philosophy Text | Deep modules (simple interface + powerful functionality) reduce cognitive load; complexity = dependencies + obscurity | MEDIUM-HIGH |
| Ousterhout vs. Martin | GitHub Exchange | Clean Code's tiny-functions create shallow, entangled interfaces; over-decomposition harms modularity | HIGH |
| Hughes 1989 | Peer-reviewed Paper | FP's modularity advantage is higher-order functions + lazy evaluation as "glue", not absence of side effects | VERY HIGH |
