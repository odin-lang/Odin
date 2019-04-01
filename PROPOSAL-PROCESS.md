# The Proposal Process

## Introduction

The Odin project's development process is driven by design and pragmatism. Significant changes to the language, libraries, or tools _must_ be first discussed, and maybe formally documented, before they can be implemented.

This document describes the process for proposing, documenting, and implementing changes to the Odin project.

## The Proposal Process

The proposal process is the process for reviewing a proposal and reaching a decision about whether to accept or decline the proposal.

1. [Ginger Bill](https://github.com/gingerBill) is [BDFL](https://wikipedia.org/wiki/Benevolent_dictator_for_life) and significant changes _must_ be passed by him.

2. The proposal author creates a brief issue describing the proposal.

   Note: There is no need for a design document at this point.<br>
   Note: A non-proposal issue can be turned into a proposal by simply adding the _proposal_ label.

3. A discussion on the issue tracker will classify the proposal into one of three outcomes:
	* Accept proposal
	* Decline proposal
	* Ask for a design document.

	If the proposal is accepted or declined, the process is done. Otherwise the discussion around the process is expected to identify issues that ought to be addressed in a more detailed design.

4. The proposal author writes a design document to work out details of the proposed design and address the concerns raised in the initial discussion.

5. Once comments and revisions on the design document calm, there is a final discussion on the issue, to reach one of two outcomes:
	* Accept proposal
	* Decline proposal

After the proposal is accepted or declined, implementation of the proprosal proceeds in the same way as any other contribution to the project.

## Design Documents

The design document should follow this template:


```
# Proposal: [Title]

Author(s): [Author Name, Co-Author Name]
Last updated: [Date ISO-8601]
Discussion at https://github.com/odin-lang/Odin/issues/######

## Abstract

## Background

## Proposal

## Rationale

## Compatibility

## Implementation

```


## Help

If you need help with this process, please contact an Odin contributor by posting an issue to the [issue tracker](https://github.com/odin-lang/Odin/issues).
