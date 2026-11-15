package test_issue_7798


@(export, link_name = "A_link_name")
a_real :: proc() {}

A :: proc() {
    foreign _ {
        @(link_name = "A_link_name")
        a_fake :: proc "odin" () ---
    }
    a_fake()
}


B :: proc() {
    foreign _ {
        @(link_name = "B_link_name")
        b_fake :: proc "odin" () ---
    }
    b_fake()
}

@(export, link_name = "B_link_name")
b_real :: proc() {}


main :: proc() {
    A()
    B()
}
