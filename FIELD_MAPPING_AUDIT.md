# Field Mapping Audit

## Constructor Parameters (34 total)
1. id (required) - no default
2. category (required) - no default  
3. title = '' 
4. cover (required)
5. opening (required)
6. problem (required)
7. lesson (required)
8. postFormat = 'Reel'
9. strategy = ''
10. caption = ''
11. pinnedComment = ''
12. forApp = true
13. usedOn = ''
14. custom = false
15. archived = false
16. storyDetail = ''
17. setting = ''
18. sceneDetail = ''
19. dialogue = ''
20. mess = ''
21. innerThought = ''
22. endingBeat = ''
23. defaultCast = const ['Ria', 'Rio', 'Cuty']
24. keepMoralOffScreen = false
25. quote = ''
26. detail = ''
27. punchline = ''
28. readyPrompt = ''
29. score = 0
30. band = ''
31. reviewedOn = ''

## toJson() Mapping
Serializes all 31 fields listed above (missing nothing from constructor that has values). All map 1:1 with same names.

## fromJson() Mapping  
- id: defaults to '' if missing (constructor requires it - potential issue)
- category: defaults to 'Relatable' if missing (constructor requires it - different from toJson, default not matching constructor)
- All others use their constructor defaults
- defaultCast: parses list of strings, defaults to ['Ria', 'Rio', 'Cuty']
- score: defaults to 0


## Issues Found
1. **category** in fromJson defaults to 'Relatable' but constructor requires it with no default - inconsistency if missing
2. **id** in fromJson defaults to '' but constructor requires it - inconsistency
3. **toJson() serializes 31 fields** while constructor has 34 parameters total - but the missing ones from serialization list? Let us count again carefully.

Looking up constructor again - params are: id, category, title, cover, opening, problem, lesson, postFormat, strategy, caption, pinnedComment, forApp, usedOn, custom, archived, storyDetail, setting, sceneDetail, dialogue, mess, innerThought, endingBeat, defaultCast, keepMoralOffScreen, quote, detail, punchline, readyPrompt, score, band, reviewedOn - that's 31 params total. Yes matches toJson. All covered.

