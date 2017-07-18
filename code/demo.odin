import "fmt.odin";

Table :: struct(Key, Value: type) {
	Slot :: struct {
		occupied: bool;
		hash:     u32;
		key:      Key;
		value:    Value;
	}
	SIZE_MIN :: 32;

	count:           int;
	allocator:       Allocator;
	slots:           []Slot;
}

allocate :: proc(table: ^$T/Table, capacity: int) {
	c := context;
	if table.allocator.procedure != nil do c.allocator = table.allocator;

	push_context c {
		table.slots = make([]T.Slot, max(capacity, T.SIZE_MIN));
	}
}

expand :: proc(table: ^$T/Table) {
	c := context;
	if table.allocator.procedure != nil do c.allocator = table.allocator;

	push_context c {
		old_slots := table.slots;

		cap := max(2*cap(table.slots), T.SIZE_MIN);
		allocate(table, cap);

		for s in old_slots do if s.occupied {
			put(table, s.key, s.value);
		}

		free(old_slots);
	}
}

// put :: proc(table: ^$T/Table, key: T.Key, value: T.Value) {
put :: proc(table: ^Table($Key, $Value), key: Key, value: Value) {
	hash := get_hash(key); // Ad-hoc method which would fail in differentcope
	index := find_index(table, key, hash);
	if index < 0 {
		if f64(table.count) >= 0.75*cast(f64)cap(table.slots) {
			expand(table);
		}
		assert(table.count <= cap(table.slots));

		hash := get_hash(key);
		index = cast(int)(hash % cast(u32)cap(table.slots));

		for table.slots[index].occupied {
			index += 1;
			if index >= cap(table.slots) {
				index = 0;
			}
		}

		table.count++;
	}

	slot := &table.slots[index];
	slot.occupied = true;
	slot.hash     = hash;
	slot.key      = key;
	slot.value    = value;
}


// find :: proc(table: ^$T/Table, key: T.Key) -> (T.Value, bool) {
find :: proc(table: ^Table($Key, $Value), key: Key) -> (Value, bool) {
	hash := get_hash(key);
	index := find_index(table, key, hash);
	if index < 0 {
		return Value{}, false;
	}
	return table.slots[index].value, true;
}

find_index :: proc(table: ^Table($Key, $Value), key: Key, hash: u32) -> int {
	if cap(table.slots) <= 0 do return -1;

	slot := int(hash % cast(u32)cap(table.slots));

	index := slot;
	for table.slots[index].occupied {
		if table.slots[index].hash == hash {
			if table.slots[index].key == key {
				return index;
			}
		}

		index++;
		if index >= cap(table.slots) do index = 0;
	}

	return -1;
}

get_hash :: proc(s: string) -> u32 {
	// djb2
	hash: u32 = 5381;
	for i in 0..len(s) do hash = (hash<<5) + hash + u32(s[i]);
	return hash;
}


/*
Vector :: struct(N: int, T: type) {
	using _: raw_union {
		using e: [N]T;
		when 0 < N && N <= 4 {
			using v: struct {
				when N >= 1 do x: T;
				when N >= 2 do y: T;
				when N >= 3 do z: T;
				when N >= 4 do w: T;
			};
		}
	};
}

Vector3 :: Vector(3, f32);

add :: proc(a, b: $T/Vector) -> T {
	c := a;
	for i in 0..3 {
		c[i] += b[i];
	}
	return c;
}

foo1 :: proc(a: type/Vector)         { fmt.println("foo1", a{}); }
// foo2 :: proc(a: type/Vector(3, f32)) {}
foo3 :: proc(a: type/Vector(3, $T))  {fmt.println("foo3", a{}); }
// foo4 :: proc(a: type/Vector3)        {}

*/


foo :: proc() -> (f32, f32) {
	return 1, 2;
}


main :: proc() {

	Vector3 :: struct {
		x: f32 = 1;
		y: f32 = 4;
		z: f32 = 9;
	}

	v := make([dynamic]Vector3, 3);

	array: [100]Vector3;
	v2 := array[50];
	fmt.println(v2);

/*	foo1(Vector(3, f32));
	foo1(Vector3);
	foo3(Vector(3, f32));
	foo3(Vector3);


	a, b: Vector3;
	a[0] = 1;
	a[1] = 4;
	a[2] = 9;

	b.x = 3;
	b.y = 4;
	b.z = 5;

	v := add(a, b);
	fmt.println(v.v);
*/

/*
	table: Table(string, int);

	for i in 0..36 do put(&table, "Hellope", i);
	for i in 0..42 do put(&table, "World!",  i);


	found, _ := find(&table, "Hellope");
	fmt.printf("found is %v\n", found);

	found, _ = find(&table, "World!");
	fmt.printf("found is %v\n", found);
*/
}
