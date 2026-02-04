# AeroTV Project Instructions

## Commit Conventions
- No co-author lines in commits (no "Co-Authored-By" footer)
- Follow global conventions for version/build numbering

## Technical Notes
- Uses private UIWebView API via NSClassFromString (only way to get web browsing on tvOS)
- Cannot be submitted to App Store - sideload only
- Requires GCEventViewController for Siri Remote handling
