package main

import "core:fmt"
import "core:encoding/json"

Employee :: struct {
	name:   string `json:"name"`,
	age:    int    `json:"age"`,
	salary: int    `json:"salary"`,
}

main :: proc() {

}
