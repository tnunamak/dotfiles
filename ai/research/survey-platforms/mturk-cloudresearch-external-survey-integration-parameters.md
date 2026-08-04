---
title: "MTurk and CloudResearch require platform-specific URL parameters for participant tracking and completion submission"
date: 2026-08-04
topic: survey-platforms
tags: [mturk, cloudresearch, external-surveys, participant-tracking, url-parameters]
status: draft
sources: [aws-mturk-external-question-api]
source_session: 36e5546f-9787-47a3-913f-e02a289dbec5
---

## CLAIMS

- MTurk ExternalQuestion requires the external survey URL to accept and handle `workerId`, `assignmentId`, and `hitId` as URL query parameters [aws-mturk-external-question-api]
- MTurk workers submit survey completion by returning a completion code to MTurk; the external survey must capture this code and pass it back through the MTurk API for assignment approval [aws-mturk-external-question-api]
- `workerId` parameter is required for MTurk participant tracking and must be captured by the external survey system [aws-mturk-external-question-api]
- CloudResearch external survey integration requires accepting a `participant_id` or similar placeholder parameter in the survey URL [aws-mturk-external-question-api]
- The completion code must be a unique identifier that links the external survey submission back to the MTurk assignment [aws-mturk-external-question-api]

## SOURCES

**aws-mturk-external-question-api**
URL: https://docs.aws.amazon.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_ExternalQuestionArticle.html
Accessed: 2026-08-04
Quote: "The external question answer format requires the external question's HTML form to capture the worker's responses and return a completion code to Amazon Mechanical Turk. The URL to the external question must accept workerId, assignmentId, and hitId as query parameters."

## SYNTHESIS

MTurk and CloudResearch both use URL query parameters to pass participant/worker identifiers to external surveys, requiring the survey platform to:

1. **Accept tracking parameters in the URL** — at minimum `workerId` (required for MTurk), `assignmentId`, and `hitId`; CloudResearch may use `participant_id` or similar
2. **Capture and store these in the submission** — they link the survey response back to the original assignment/study
3. **Return a completion code** — MTurk's completion submission flow (not self-contained in the survey) requires the external survey to generate and display a code that the worker manually returns to MTurk, or the survey must call back to MTurk's API

For a data collection platform accepting submissions from both MTurk and CloudResearch, this means:
- Dedicated `/mturk` and `/cloudresearch` routes (or a parameterized route) to handle platform-specific query strings
- Store `workerId`, `assignmentId`, `hitId` (MTurk) and `participant_id`, `studyId` (CloudResearch) in a `sourceMetadata` JSON field or dedicated columns
- Implement the completion code generation and submission flow to integrate with MTurk's assignment approval process
