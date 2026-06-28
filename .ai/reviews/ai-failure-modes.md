# AI failure mode review checklist

- [ ] Hallucinated dependencies were checked against manifests and lockfiles.
- [ ] Slopsquatting risk was checked for any new package name.
- [ ] Inadequate error handling was checked at external boundaries.
- [ ] Looks-right subtle correctness gaps were checked with targeted tests.
