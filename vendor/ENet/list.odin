package ENet

ListNode :: struct {
	next:     ^ListNode,
	previous: ^ListNode,
}

List :: struct {
	sentinel: ListNode,
}