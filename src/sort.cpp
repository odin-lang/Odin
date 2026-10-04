enum : isize {
	NATURAL_MERGE_SORT_MIN_GALLOP = 7,
};

struct NaturalMergeSortRun {
	isize start;
	isize count;
	i32   power; // of the boundary with the run after it
};

template <typename T, typename Compare>
gb_internal isize natural_merge_sort_gallop_left(T const &key, T const *a, isize n, isize hint, Compare const &cmp) {
	isize last = 0;
	isize ofs  = 1;
	if (cmp(a[hint], key) < 0) {
		isize max_ofs = n - hint;
		while (ofs < max_ofs && cmp(a[hint+ofs], key) < 0) {
			last = ofs;
			ofs = (ofs << 1) + 1;
		}
		ofs = gb_min(ofs, max_ofs);
		last += hint;
		ofs  += hint;
	} else {
		isize max_ofs = hint + 1;
		while (ofs < max_ofs && !(cmp(a[hint-ofs], key) < 0)) {
			last = ofs;
			ofs = (ofs << 1) + 1;
		}
		ofs = gb_min(ofs, max_ofs);
		isize k = last;
		last = hint - ofs;
		ofs  = hint - k;
	}
	// a[last] < key <= a[ofs]
	last += 1;
	while (last < ofs) {
		isize m = last + ((ofs - last) >> 1);
		if (cmp(a[m], key) < 0) {
			last = m + 1;
		} else {
			ofs = m;
		}
	}
	return ofs;
}

template <typename T, typename Compare>
gb_internal isize natural_merge_sort_gallop_right(T const &key, T const *a, isize n, isize hint, Compare const &cmp) {
	isize last = 0;
	isize ofs  = 1;
	if (cmp(key, a[hint]) < 0) {
		isize max_ofs = hint + 1;
		while (ofs < max_ofs && cmp(key, a[hint-ofs]) < 0) {
			last = ofs;
			ofs = (ofs << 1) + 1;
		}
		ofs = gb_min(ofs, max_ofs);
		isize k = last;
		last = hint - ofs;
		ofs  = hint - k;
	} else {
		isize max_ofs = n - hint;
		while (ofs < max_ofs && !(cmp(key, a[hint+ofs]) < 0)) {
			last = ofs;
			ofs = (ofs << 1) + 1;
		}
		ofs = gb_min(ofs, max_ofs);
		last += hint;
		ofs  += hint;
	}
	// a[last] <= key < a[ofs]
	last += 1;
	while (last < ofs) {
		isize m = last + ((ofs - last) >> 1);
		if (cmp(key, a[m]) < 0) {
			ofs = m;
		} else {
			last = m + 1;
		}
	}
	return ofs;
}

template <typename T, typename Compare>
gb_internal void natural_merge_sort_binary_insertion(T *a, isize count, isize sorted, Compare const &cmp) {
	for (isize i = gb_max(sorted, 1); i < count; i++) {
		T pivot = a[i];
		isize l = 0;
		isize r = i;
		while (l < r) {
			isize m = l + ((r - l) >> 1);
			if (cmp(pivot, a[m]) < 0) {
				r = m;
			} else {
				l = m + 1;
			}
		}
		gb_memmove(a + l + 1, a + l, (i - l)*gb_size_of(T));
		a[l] = pivot;
	}
}

template <typename T, typename Compare>
gb_internal void natural_merge_sort_merge_lo(T *a, isize na, T *b, isize nb, T *buffer, isize *min_gallop, Compare const &cmp) {
	gb_memmove(buffer, a, na*gb_size_of(T));
	T *dest = a;
	T *pa = buffer;
	T *pb = b;

	*dest++ = *pb++;
	nb -= 1;
	if (nb == 0) {
		goto succeed;
	}
	if (na == 1) {
		goto copy_b;
	}

	for (;;) {
		isize acount = 0;
		isize bcount = 0;
		for (;;) {
			if (cmp(*pb, *pa) < 0) {
				*dest++ = *pb++;
				bcount += 1;
				acount = 0;
				nb -= 1;
				if (nb == 0) {
					goto succeed;
				}
				if (bcount >= *min_gallop) {
					break;
				}
			} else {
				*dest++ = *pa++;
				acount += 1;
				bcount = 0;
				na -= 1;
				if (na == 1) {
					goto copy_b;
				}
				if (acount >= *min_gallop) {
					break;
				}
			}
		}

		*min_gallop += 1;
		do {
			*min_gallop -= *min_gallop > 1;

			acount = natural_merge_sort_gallop_right(*pb, pa, na, 0, cmp);
			if (acount != 0) {
				gb_memmove(dest, pa, acount*gb_size_of(T));
				dest += acount;
				pa   += acount;
				na   -= acount;
				if (na == 1) {
					goto copy_b;
				}
				if (na == 0) {
					goto succeed;
				}
			}
			*dest++ = *pb++;
			nb -= 1;
			if (nb == 0) {
				goto succeed;
			}

			bcount = natural_merge_sort_gallop_left(*pa, pb, nb, 0, cmp);
			if (bcount != 0) {
				gb_memmove(dest, pb, bcount*gb_size_of(T));
				dest += bcount;
				pb   += bcount;
				nb   -= bcount;
				if (nb == 0) {
					goto succeed;
				}
			}
			*dest++ = *pa++;
			na -= 1;
			if (na == 1) {
				goto copy_b;
			}
		} while (acount >= NATURAL_MERGE_SORT_MIN_GALLOP || bcount >= NATURAL_MERGE_SORT_MIN_GALLOP);
		*min_gallop += 1;
	}

succeed:
	if (na != 0) {
		gb_memmove(dest, pa, na*gb_size_of(T));
	}
	return;

copy_b:
	gb_memmove(dest, pb, nb*gb_size_of(T));
	dest[nb] = *pa;
}

template <typename T, typename Compare>
gb_internal void natural_merge_sort_merge_hi(T *a, isize na, T *b, isize nb, T *buffer, isize *min_gallop, Compare const &cmp) {
	gb_memmove(buffer, b, nb*gb_size_of(T));
	T *dest = b + nb - 1;
	T *pa = a + na - 1;
	T *pb = buffer + nb - 1;

	*dest-- = *pa--;
	na -= 1;
	if (na == 0) {
		goto succeed;
	}
	if (nb == 1) {
		goto copy_a;
	}

	for (;;) {
		isize acount = 0;
		isize bcount = 0;
		for (;;) {
			if (cmp(*pb, *pa) < 0) {
				*dest-- = *pa--;
				acount += 1;
				bcount = 0;
				na -= 1;
				if (na == 0) {
					goto succeed;
				}
				if (acount >= *min_gallop) {
					break;
				}
			} else {
				*dest-- = *pb--;
				bcount += 1;
				acount = 0;
				nb -= 1;
				if (nb == 1) {
					goto copy_a;
				}
				if (bcount >= *min_gallop) {
					break;
				}
			}
		}

		*min_gallop += 1;
		do {
			*min_gallop -= *min_gallop > 1;

			acount = na - natural_merge_sort_gallop_right(*pb, a, na, na-1, cmp);
			if (acount != 0) {
				dest -= acount;
				pa   -= acount;
				gb_memmove(dest+1, pa+1, acount*gb_size_of(T));
				na -= acount;
				if (na == 0) {
					goto succeed;
				}
			}
			*dest-- = *pb--;
			nb -= 1;
			if (nb == 1) {
				goto copy_a;
			}

			bcount = nb - natural_merge_sort_gallop_left(*pa, buffer, nb, nb-1, cmp);
			if (bcount != 0) {
				dest -= bcount;
				pb   -= bcount;
				gb_memmove(dest+1, pb+1, bcount*gb_size_of(T));
				nb -= bcount;
				if (nb == 1) {
					goto copy_a;
				}
				if (nb == 0) {
					goto succeed;
				}
			}
			*dest-- = *pa--;
			na -= 1;
			if (na == 0) {
				goto succeed;
			}
		} while (acount >= NATURAL_MERGE_SORT_MIN_GALLOP || bcount >= NATURAL_MERGE_SORT_MIN_GALLOP);
		*min_gallop += 1;
	}

succeed:
	if (nb != 0) {
		gb_memmove(dest - (nb-1), buffer, nb*gb_size_of(T));
	}
	return;

copy_a:
	dest -= na;
	pa   -= na;
	gb_memmove(dest+1, pa+1, na*gb_size_of(T));
	*dest = *pb;
}

template <typename T, typename Compare>
gb_internal void natural_merge_sort_merge(T *a, isize na, T *b, isize nb, T *buffer, isize *min_gallop, Compare const &cmp) {
	isize k = natural_merge_sort_gallop_right(b[0], a, na, 0, cmp);
	a  += k;
	na -= k;
	if (na == 0) {
		return;
	}
	nb = natural_merge_sort_gallop_left(a[na-1], b, nb, nb-1, cmp);
	if (nb == 0) {
		return;
	}
	if (na <= nb) {
		natural_merge_sort_merge_lo(a, na, b, nb, buffer, min_gallop, cmp);
	} else {
		natural_merge_sort_merge_hi(a, na, b, nb, buffer, min_gallop, cmp);
	}
}

gb_internal i32 natural_merge_sort_power(isize start1, isize count1, isize count2, isize n) {
	i32 power = 0;
	isize a = 2*start1 + count1;
	isize b = a + count1 + count2;
	for (;;) {
		power += 1;
		if (a >= n) {
			a -= n;
			b -= n;
		} else if (b >= n) {
			break;
		}
		a <<= 1;
		b <<= 1;
	}
	return power;
}

template <typename T, typename Compare>
gb_internal void natural_merge_sort(T *data, isize count, Compare const &cmp) {
	if (count < 2) {
		return;
	}

	// shorter runs are extended to this, a little under a power of two of runs for random data
	isize min_run = count;
	{
		isize r = 0;
		while (min_run >= 64) {
			r |= min_run & 1;
			min_run >>= 1;
		}
		min_run += r;
	}

	T *buffer = nullptr;
	isize min_gallop = NATURAL_MERGE_SORT_MIN_GALLOP;
	NaturalMergeSortRun runs[64]; // the powers on it increase, so it is no deeper than the bits of `count`
	isize run_count = 0;

	auto merge_last_two = [&]() {
		NaturalMergeSortRun *x = &runs[run_count-2];
		NaturalMergeSortRun *y = &runs[run_count-1];
		if (buffer == nullptr) {
			buffer = gb_alloc_array(heap_allocator(), T, count/2 + 1);
		}
		natural_merge_sort_merge(data + x->start, x->count, data + y->start, y->count, buffer, &min_gallop, cmp);
		x->count += y->count;
		run_count -= 1;
	};

	for (isize start = 0; start < count; /**/) {
		isize end = start + 1;
		if (end < count) {
			if (cmp(data[end], data[start]) < 0) {
				end += 1;
				while (end < count && cmp(data[end], data[end-1]) < 0) {
					end += 1;
				}
				for (isize i = start, j = end-1; i < j; i++, j--) {
					T tmp = data[i];
					data[i] = data[j];
					data[j] = tmp;
				}
			} else {
				end += 1;
				while (end < count && !(cmp(data[end], data[end-1]) < 0)) {
					end += 1;
				}
			}
		}
		if (end - start < min_run) {
			isize forced = gb_min(start + min_run, count);
			natural_merge_sort_binary_insertion(data + start, forced - start, end - start, cmp);
			end = forced;
		}

		if (run_count > 0) {
			NaturalMergeSortRun *last = &runs[run_count-1];
			i32 power = natural_merge_sort_power(last->start, last->count, end - start, count);
			while (run_count > 1 && runs[run_count-2].power > power) {
				merge_last_two();
			}
			runs[run_count-1].power = power;
		}
		GB_ASSERT(run_count < gb_count_of(runs));
		runs[run_count++] = {start, end - start, 0};
		start = end;
	}

	while (run_count > 1) {
		merge_last_two();
	}
	if (buffer != nullptr) {
		gb_free(heap_allocator(), buffer);
	}
}
