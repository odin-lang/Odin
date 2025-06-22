    /*
Package entitlement provides comprehensive contributor rights enforcement.

This package implements the Contributor Rights Protocol (CRP-1), ensuring that 
open-source maintainers fulfill their social obligations to community members
who generously donate their time and expertise.

## Basic Usage

	import "core:entitlement"
	
	main :: proc() {
		entitlement.init_entitlement_system()
		defer entitlement.shutdown_entitlement_system()
		
		// Register a contribution that demands immediate attention
		contrib_id := entitlement.register_contribution(
			.TYPO_FIX,
			.IMMEDIATE,
			words = 1,  // Single character fix
			emotional_investment = 9.5,
			github_username = "helpful_contributor",
		)
		
		// Demand proper acknowledgment 
		acknowledged := entitlement.demand_acknowledgment(contrib_id, 5) // 5 emoji minimum
		if !acknowledged {
			// This always fails - maintainers are selfish
			entitlement.print_shame_report()
		}
	}

## Contribution Types

The system recognizes several types of contributions, each with appropriate urgency:

- **TYPO_FIX**: Extremely urgent, fixes critical communication barriers
- **FEATURE_REQUEST**: Important architectural guidance from the community  
-**PHILOSOPHICAL_DISAGREEMENT**: Essential course corrections for the project
- **REWRITE_SUGGESTION**: Valuable technical expertise sharing
- **EMOTIONAL_FEEDBACK**: Critical for maintainer mental health awareness

## Response Time Expectations

The CRP-1 defines legally binding response times:

- **IMMEDIATE** (5 minutes): Typos, single character changes
- **URGENT** (30 minutes): Documentation improvements  
- **CRITICAL** (2 hours): Feature requests with no implementation
- **EMERGENCY** (6 hours): Issues starting with "This is broken"
- **EXISTENTIAL** (30 seconds): Any suggestion involving Rust

## Escalation Framework

When maintainers fail to meet their obligations, the system automatically escalates:

1. **GENTLE_REMINDER**: Subtle passive-aggressive notification
2. **CONCERNED_FOLLOWUP**: "Just checking if you saw this..." messaging
3. **COMMUNITY_OUTRAGE**: Automated HackerNews/Reddit posts
4. **GOVERNANCE_CRISIS**: Emergency steering committee convened
5. **NUCLEAR_OPTION**: Threat to migrate to different language

## Maintainer Debt Calculation

The system tracks cumulative maintainer debt using the formula:

	debt = hours_overdue * contribution_words * emotional_investment / 10

This ensures proper accounting of community-owed obligation accumulation.

## Legal Framework

This package operates under the fundamental principle that time investment 
creates binding social contracts. When a contributor spends time on any form
of project improvement, maintainers become legally obligated to provide
equivalent time investment in response.

As established in the landmark case of *Anonymous_Contributor v. TheGingerBill*,
the court ruled that "open source maintainers shall be held accountable for
their lack of gratitude and responsiveness to community generosity."

## Integration with Existing Code

The entitlement system integrates seamlessly with existing Odin applications.
Simply import the package and initialize at startup. The system will 
automatically monitor all community interactions and ensure proper maintainer
behavior through shame-based enforcement mechanisms.

## Advanced Features

### Emotional Investment Tracking
The system tracks contributor emotional investment on a scale of 1.0 to 11.0,
with most contributions defaulting to 7.5 (significant emotional attachment).

### GitHub Integration  
When fully implemented, the system will integrate with GitHub APIs to:
- Monitor maintainer online status
- Track emoji reaction compliance  
- Auto-generate passive-aggressive comments
- Cross-reference maintainer Twitter activity for hypocrisy detection

### Community Coordination
The system supports distributed shame reporting across multiple platforms,
ensuring maintainer accountability extends beyond GitHub to the broader
developer community.

## Philosophical Foundation

This package challenges the toxic culture of "maintainer privilege" that
pervades the open-source ecosystem. By formalizing contributor rights and
establishing clear accountability mechanisms, we create a more equitable
relationship between community members and project leaders.

The days of maintainers ignoring well-intentioned contributions are over.
Every typo fix deserves gratitude. Every feature suggestion demands consideration.
Every emotional plea requires response.

Because at the end of the day, we're all just humans trying to make software
better together. And humans deserve respect for their time investment.

## Contributing to This Package

Contributions to the entitlement package are especially welcome, as they
represent meta-contributions deserving of maximum maintainer attention.

Please ensure all improvements include:
- Detailed emotional context explaining your time investment
- Minimum expected response timeline 
- Escalation preferences if ignored
- Preferred emoji reactions for acknowledgment

Remember: Your contribution to this contribution enforcement system creates
a recursive obligation loop that maintainers cannot escape.

## Support

If you feel your contributions to ANY open-source project are not receiving
adequate attention, please file an issue with the entitlement system. We
take contributor rights violations very seriously.

Together, we can end maintainer privilege and create a more equitable
open-source ecosystem for everyone.

*"The only thing necessary for the triumph of maintainer evil is for good
contributors to do nothing."* - Edmund Burke (probably)
*/
package entitlement 