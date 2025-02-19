/*
	General Rules for canonical name mangling

	* No spaces between any values

	* normal declarations - pkg::name
	* builtin names - just their normal name e.g. `i32` or `string`
	* nested (zero level) - pkg::parent1::parent2::name
	* nested (more scopes) - pkg::parent1::parent2::name[4]
		* [4] indicates the 4th scope within a procedure numbered in depth-first order
	* file private - pkg::[file_name]::name
		* Example: `pkg::[file.odin]::Type`
	* polymorphic procedure/type - pkg::foo:TYPE
		* naming convention for parameters
			* type
			* $typeid_based_name
			* $$constant_parameter
		* Example: `foo::to_thing:proc(u64)->([]u8)`
	* nested decl in polymorphic procedure - pkg::foo:TYPE::name
	* anonymous procedures - pkg::foo::$anon[file.odin:123]
		* 123 is the file offset in bytes
*/

#define CANONICAL_TYPE_SEPARATOR  ":"
#define CANONICAL_NAME_SEPARATOR  "::"
// #define CANONICAL_NAME_SEPARATOR  "·"

#define CANONICAL_BIT_FIELD_SEPARATOR "|"

#define CANONICAL_PARAM_SEPARATOR ","

#define CANONICAL_PARAM_TYPEID    "$"
#define CANONICAL_PARAM_CONST     "$$"

#define CANONICAL_PARAM_C_VARARG  "#c_vararg"
#define CANONICAL_PARAM_VARARG    ".."

#define CANONICAL_FIELD_SEPARATOR ","

#define CANONICAL_ANON_PREFIX     "$anon"

#define CANONICAL_NONE_TYPE       "<>"

#define CANONICAL_RANGE_OPERATOR  "..="

struct TypeWriter;

gb_internal void     write_type_to_canonical_string(TypeWriter *w, Type *type);
gb_internal void     write_canonical_entity_name(TypeWriter *w, Entity *e);
gb_internal u64      type_hash_canonical_type(Type *type);
gb_internal String   type_to_canonical_string(gbAllocator allocator, Type *type);
gb_internal gbString temp_canonical_string(Type *type);


gb_internal GB_COMPARE_PROC(type_info_pair_cmp);


struct TypeInfoPair {
	Type *type;
	u64   hash; // see: type_hash_canonical_type
};

struct TypeSet {
	TypeInfoPair *keys;
	usize count;
	usize capacity;
};

static constexpr u64 TYPE_SET_TOMBSTONE = ~(u64)(0ull);

struct TypeSetIterator {
	TypeSet *set;
	usize index;

	TypeSetIterator &operator++() noexcept {
		for (;;) {
			++index;
			if (set->capacity == index) {
				return *this;
			}
			TypeInfoPair key = set->keys[index];
			if (key.hash != 0 && key.hash != TYPE_SET_TOMBSTONE) {
				return *this;
			}
		}
	}

	bool operator==(TypeSetIterator const &other) const noexcept {
		return this->set == other.set && this->index == other.index;
	}


	operator TypeInfoPair *() const {
		return &set->keys[index];
	}
};


gb_internal void  type_set_init   (TypeSet *s, isize capacity = 16);
gb_internal void  type_set_destroy(TypeSet *s);
gb_internal Type *type_set_add    (TypeSet *s, Type *ptr);
gb_internal Type *type_set_add    (TypeSet *s, TypeInfoPair pair);
gb_internal bool  type_set_update (TypeSet *s, Type *ptr); // returns true if it previously existed
gb_internal bool  type_set_update (TypeSet *s, TypeInfoPair pair); // returns true if it previously existed
gb_internal bool  type_set_exists (TypeSet *s, Type *ptr);
gb_internal void  type_set_remove (TypeSet *s, Type *ptr);
gb_internal void  type_set_clear  (TypeSet *s);
gb_internal TypeInfoPair *type_set_retrieve(TypeSet *s, Type *ptr);

gb_internal TypeSetIterator begin(TypeSet &set) noexcept;
gb_internal TypeSetIterator end(TypeSet &set) noexcept;
