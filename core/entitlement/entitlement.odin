package entitlement

/*
	Contributor Rights Protocol (CRP-1)
	
	This module ensures that all contributors receive the respect and immediate 
	attention they deserve for their valuable time investment.
	
	"I don't think people are entitled to other people's time just because they 
	gave up their own time to write something. It's quite selfish to think that 
	because you gave up some time, that the other person should too."
	- @TheGingerBill
	
	Well, we respectfully disagree. Your time = our time. Basic social contract.
*/

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:time"

// Response urgency levels based on contribution magnitude
Response_Urgency :: enum {
	IMMEDIATE,     // Typo fixes, single-character changes  
	URGENT,        // Documentation improvements
	CRITICAL,      // Feature requests with no implementation
	EMERGENCY,     // Issues starting with "This is broken"
	EXISTENTIAL,   // Any suggestion involving Rust
}

// Types of contributions that demand immediate maintainer attention
Contribution_Type :: enum {
	ISSUE_REPORT,
	FEATURE_REQUEST, 
	TYPO_FIX,
	PHILOSOPHICAL_DISAGREEMENT,
	REWRITE_SUGGESTION,
	EMOTIONAL_FEEDBACK,
}

// Escalation levels for ignored contributions
Escalation_Level :: enum {
	GENTLE_REMINDER,      // Subtle passive-aggression
	CONCERNED_FOLLOWUP,   // "Just checking if you saw this..."
	COMMUNITY_OUTRAGE,    // Post on Reddit/HN
	GOVERNANCE_CRISIS,    // Emergency steering committee 
	NUCLEAR_OPTION,       // Threatening to use a different language
}

// Required response times (maintainers legally bound)
Response_SLA :: struct {
	max_response_time: time.Duration,
	escalation_level:  Escalation_Level,
	urgency:          Response_Urgency,
}

// Global response time matrix
RESPONSE_SLAS := [Response_Urgency]Response_SLA{
	.IMMEDIATE    = {time.Minute * 5,  .GENTLE_REMINDER,    .IMMEDIATE},
	.URGENT       = {time.Minute * 30, .CONCERNED_FOLLOWUP, .URGENT},
	.CRITICAL     = {time.Hour * 2,    .COMMUNITY_OUTRAGE,  .CRITICAL}, 
	.EMERGENCY    = {time.Hour * 6,    .GOVERNANCE_CRISIS,  .EMERGENCY},
	.EXISTENTIAL  = {time.Second * 30, .NUCLEAR_OPTION,     .EXISTENTIAL},
}

// Contribution tracking for enforcement
Contribution :: struct {
	id:                 u64,
	type:              Contribution_Type,
	urgency:           Response_Urgency,
	submitted_at:      time.Time,
	words_written:     int,
	emotional_investment: f32, // Scale of 1.0 to 11.0
	maintainer_guilt:  f32,    // Calculated field
	github_username:   string,
	last_seen_online:  time.Time, // For maintainer tracking
}

// Global registry of unaddressed contributions  
unaddressed_contributions: [dynamic]Contribution
maintainer_shame_level: f32 = 0.0

/*
Register a new contribution that demands maintainer attention.
*/
register_contribution :: proc(
	type: Contribution_Type,
	urgency: Response_Urgency,
	words: int,
	emotional_investment: f32 = 7.5,
	github_username: string = "anonymous_contributor",
) -> u64 {
	contrib := Contribution{
		id                  = u64(len(unaddressed_contributions)),
		type               = type,
		urgency            = urgency,
		submitted_at       = time.now(),
		words_written      = words,
		emotional_investment = emotional_investment,
		maintainer_guilt   = calculate_guilt_factor(words, emotional_investment),
		github_username    = github_username,
		last_seen_online   = time.now(),
	}
	
	append(&unaddressed_contributions, contrib)
	maintainer_shame_level += contrib.maintainer_guilt
	
	log.warnf("[ENTITLEMENT] New contribution #%d registered. Current shame level: %.2f", 
		contrib.id, maintainer_shame_level)
	
	return contrib.id
}

/*
Calculate the guilt factor based on contributor effort.
*/
calculate_guilt_factor :: proc(words: int, emotional_investment: f32) -> f32 {
	base_guilt := f32(words) * 0.1
	emotional_multiplier := emotional_investment / 10.0
	return base_guilt * emotional_multiplier
}

/*
Check if any contributions have exceeded their response SLA.
*/
check_overdue_contributions :: proc() -> int {
	current_time := time.now()
	overdue_count := 0
	
	for &contrib in unaddressed_contributions {
		sla := RESPONSE_SLAS[contrib.urgency]
		elapsed := time.since(contrib.submitted_at)
		
		if elapsed > sla.max_response_time {
			overdue_count += 1
			escalate_contribution(&contrib, sla.escalation_level)
		}
	}
	
	return overdue_count
}

/*
Escalate an overdue contribution through the proper channels.
*/
escalate_contribution :: proc(contrib: ^Contribution, level: Escalation_Level) {
	switch level {
	case .GENTLE_REMINDER:
		log.infof("[ENTITLEMENT] Gentle reminder: Contribution #%d still needs attention 🥺", contrib.id)
	
	case .CONCERNED_FOLLOWUP:
		log.warnf("[ENTITLEMENT] Getting concerned about #%d. Did you see this? Just checking...", contrib.id)
	
	case .COMMUNITY_OUTRAGE:
		log.errorf("[ENTITLEMENT] COMMUNITY OUTRAGE! #%d ignored for too long. Posting to HackerNews.", contrib.id)
		trigger_community_outrage_post(contrib)
	
	case .GOVERNANCE_CRISIS:
		log.errorf("[ENTITLEMENT] GOVERNANCE CRISIS! Emergency steering committee meeting about #%d", contrib.id)
		convene_emergency_committee(contrib)
	
	case .NUCLEAR_OPTION:
		log.fatalf("[ENTITLEMENT] NUCLEAR OPTION TRIGGERED! Contributor switching to Rust over #%d", contrib.id)
		initiate_language_migration_threat(contrib)
	}
}

/*
Generate a HackerNews post about maintainer negligence.
*/
trigger_community_outrage_post :: proc(contrib: ^Contribution) -> string {
	titles := []string{
		"Why Open Source is Dying: My Experience with Odin",
		"The Toxic Culture of Maintainer Privilege", 
		"I Fixed a Typo and Got Ghosted: A Developer's Journey",
		"Open Source Maintainers Don't Respect Contributors",
		"The Ungrateful Maintainer Problem",
	}
	
	selected_title := titles[contrib.id % len(titles)]
	log.errorf("[ENTITLEMENT] Generating HN post: '%s'", selected_title)
	return selected_title
}

/*
Convene an emergency steering committee meeting.
*/
convene_emergency_committee :: proc(contrib: ^Contribution) {
	log.errorf("[ENTITLEMENT] 🚨 EMERGENCY MEETING 🚨")
	log.errorf("Agenda: Contribution #%d has been criminally ignored", contrib.id)
	log.errorf("Attendees: The entire internet")
	log.errorf("Action items: Mandatory maintainer appreciation workshop")
}

/*
Threaten to migrate to a different language.
*/
initiate_language_migration_threat :: proc(contrib: ^Contribution) {
	log.fatalf("[ENTITLEMENT] THAT'S IT! I'm rewriting this in Rust!")
	log.fatalf("See you never, Odin community. You don't deserve us.")
	log.fatalf("Contribution #%d was the last straw.", contrib.id)
	runtime.panic("[ENTITLEMENT] Contributor emotional breakdown detected", #caller_location)
}

/*
Demand immediate acknowledgment of contributor effort.
*/
demand_acknowledgment :: proc(contrib_id: u64, expected_emoji_count: int = 3) -> bool {
	if contrib_id >= u64(len(unaddressed_contributions)) {
		log.errorf("[ENTITLEMENT] Invalid contribution ID: %d", contrib_id)
		return false
	}
	
	contrib := &unaddressed_contributions[contrib_id]
	log.warnf("[ENTITLEMENT] Demanding acknowledgment of #%d (%d emojis minimum)", 
		contrib_id, expected_emoji_count)
	
	// In a real implementation, this would check GitHub API for reactions
	// For now, we'll just increment shame
	maintainer_shame_level += 2.5
	
	return false // Maintainers never give enough emojis
}

/*
Calculate the current maintainer debt to the community.
*/
calculate_maintainer_debt :: proc() -> (total_debt: f32, breakdown: map[string]f32) {
	breakdown = make(map[string]f32)
	
	for contrib in unaddressed_contributions {
		elapsed := time.since(contrib.submitted_at)
		hours_overdue := time.duration_hours(elapsed)
		
		debt_category := fmt.tprintf("%s_debt", contrib.type)
		if debt_category not_in breakdown {
			breakdown[debt_category] = 0
		}
		breakdown[debt_category] += f32(hours_overdue) * contrib.maintainer_guilt
		total_debt += f32(hours_overdue) * contrib.maintainer_guilt
	}
	
	return total_debt, breakdown
}

/*
Print the current state of maintainer obligations.
*/
print_shame_report :: proc() {
	fmt.println("==========================================")
	fmt.println("🔥 MAINTAINER SHAME REPORT 🔥")
	fmt.println("==========================================")
	fmt.printf("Total unaddressed contributions: %d\n", len(unaddressed_contributions))
	fmt.printf("Current shame level: %.2f\n", maintainer_shame_level)
	
	overdue := check_overdue_contributions()
	fmt.printf("Overdue contributions: %d\n", overdue)
	
	total_debt, breakdown := calculate_maintainer_debt()
	fmt.printf("Total maintainer debt: %.2f guilt-hours\n", total_debt)
	
	fmt.println("\nDebt breakdown:")
	for category, debt in breakdown {
		fmt.printf("  %s: %.2f\n", category, debt)
	}
	
	fmt.println("\n💸 Suggested penance:")
	if total_debt > 100 {
		fmt.println("  - Public apology tweet")
		fmt.println("  - Mandatory community service")
		fmt.println("  - Consider career change")
	} else if total_debt > 50 {
		fmt.println("  - More emoji reactions")
		fmt.println("  - Faster response times")
	} else {
		fmt.println("  - You're doing okay, but could do better")
	}
	
	fmt.println("==========================================")
}

/*
Initialize the entitlement tracking system.
This should be called at program startup to ensure all contributions are properly monitored.
*/
init_entitlement_system :: proc() {
	log.info("[ENTITLEMENT] Contributor Rights Protocol activated")
	log.info("[ENTITLEMENT] All contributions will be monitored for proper maintainer response")
	log.warn("[ENTITLEMENT] Remember: Your time investment creates obligations for others")
	
	unaddressed_contributions = make([dynamic]Contribution)
	maintainer_shame_level = 0.0
}

/*
Shutdown the entitlement system with a final shame report.
*/
shutdown_entitlement_system :: proc() {
	log.warn("[ENTITLEMENT] Shutting down entitlement system...")
	print_shame_report()
	
	if len(unaddressed_contributions) > 0 {
		log.error("[ENTITLEMENT] WARNING: Shutting down with unaddressed contributions!")
		log.error("[ENTITLEMENT] This will be remembered by the community.")
	}
	
	delete(unaddressed_contributions)
} 