#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import pathlib
import os.path as path
import os
import sys

os.chdir(pathlib.Path(__file__).parent.parent.resolve())

# Note: I didn't want to hardcode the current path in this script,
# which is why we first go up the directory tree until we find the git repo root,
# then we find unicode.xml.
git_root = pathlib.Path(__file__).parent.resolve()
while not path.isdir(pathlib.Path(git_root).joinpath('.git')):
	git_root = git_root.parent
# TODO: unicode.xml is outdated (only characters upto unicode 8.0)
unicode_xml_path = str(git_root.joinpath('tests', 'core', 'assets', 'XML', 'unicode.xml').resolve())
if not path.isfile(unicode_xml_path):
	print(f"{unicode_xml_path} wasn't found. Run tests/core/download_assets.py to download it.")
	sys.exit(1)

tree = ET.parse(unicode_xml_path)
root = tree.getroot()
charlist_em = root.find('charlist')
assert charlist_em is not None

last_cp: int = -1
cp_data: list[tuple[int, str]] = []
for char_em in charlist_em.findall('character'):
	cp_id = char_em.attrib['id']
	if '-' in cp_id:
		continue
	cp: int = int(cp_id[1:], 16)
	if last_cp != -1 and cp != last_cp+1:
		for c in range(last_cp+1, cp):
			cp_data.append((cp, 'Cn'))
	data_em = char_em.find('unicodedata')
	if data_em is None:
		cp_data.append((cp, 'Cn'))
		continue
	category = data_em.get('category')
	if category is None:
		print(f'Characted codepoint u+{cp:x} didnt contain category data')
		sys.exit(1)
	if not isinstance(category, str):
		print(f'Characted codepoint u+{cp:x} has bad type of category data')
		sys.exit(1)
	cp_data.append((cp, category))
	last_cp = cp

# After we finished parsing the XML, the idea is as follows: Split up the whole
# range of unicode codepoints into equal blocks. Since unicode has a lot of contiguous
# blocks of the same character data we can only keep one copy of each block, and to
# map the codepoint to a specific block we use a separate table, index into which is the
# top bits of the codepoint.
LOG2_BLK_SIZE = 6
BLK_SIZE      = 1 << LOG2_BLK_SIZE

print(f'Got data for {len(cp_data)} characters')

blks: list[list[str]] = []
indices: list[int] = []

blk_index = 0
while blk_index*BLK_SIZE < len(cp_data):
	data = cp_data[blk_index*BLK_SIZE:(blk_index+1)*BLK_SIZE]
	new_blk: list[str] = []
	for d in data:
		new_blk.append(d[1])
	for blk_i, blk in enumerate(blks):
		if new_blk == blk:
			indices.append(blk_i)
			break
	else:
		new_blk_i = len(blks)
		blks.append(new_blk)
		indices.append(new_blk_i)
	blk_index += 1
	
OUT_FILENAME = 'category_tables.odin'

print(f'Got {len(blks)} blocks')
print(f'Got {len(indices)} indices')

HEADING = """package unicode

// AUTO-GENERATED FILE.
// Use ./tools/generate_category_tables.py to make this file

Category :: enum u8 {
	Lu, // Letter, uppercase
	Ll, // Letter, lowercase
	Lt, // Letter, titlecase
	Lm, // Letter, modifier
	Lo, // Letter, other
	Mn, // Mark, nonspacing
	Mc, // Mark, combining
	Me, // Mark, enclosing
	Nd, // Number, decimal
	Nl, // Number, letter
	No, // Number, other
	Pc, // Punctuation, connector
	Pd, // Punctuation, dash
	Ps, // Punctuation, open
	Pe, // Punctuation, close
	Pi, // Punctuation, initial quote
	Pf, // Punctuation, final quote
	Po, // Punctuation, other
	Sm, // Symbol, math
	Sc, // Symbol, currency
	Sk, // Symbol, modifier
	So, // Symbol, other
	Zs, // Separator, space
	Zl, // Separator, line
	Zp, // Separator, paragraph
	Cc, // Other, control
	Cf, // Other, format
	Cs, // Other, surrogate
	Co, // Other, private use
	Cn, // Other, not assigned
}

"""

# Now that we're in the world of bits and bytes we can do better compression.
# The blocks themselves just contain categories, which have 5 bits of entropy,
# meaning we can pack 12 codepoints in a single 64-bit word, which is 50% better
# than 1 category per byte.
# This is just an idea, seems like even without doing so the size is acceptable.

with open(OUT_FILENAME, 'w') as file:
	file.write(HEADING)
	file.write(f'@(private) LOG2_BLOCK_SIZE :: {LOG2_BLK_SIZE}\n')
	file.write(f'@(private) BLOCK_SIZE :: 1<<LOG2_BLOCK_SIZE\n')
	file.write(f'@(private) RUNE_LIMIT :: {len(cp_data)}\n')
	file.write('\n')
	file.write(f"blocks := [?][{BLK_SIZE}]Category {{\n")
	for blk_i, blk in enumerate(blks):
		file.write(f"\t{blk_i} = {{")
		for index, cat in enumerate(blk):
			if index%16 == 0:
				file.write('\n\t\t')
			file.write(f'.{cat}, ')
		if blk_i == len(blks)-1:
			index = len(blk)
			for i in range(len(blk), BLK_SIZE):
				if i%16 == 0:
					file.write('\n\t\t')
				file.write(f'.Cn, ')
		file.write("\n\t},\n")
	file.write('}\n\n')
	if len(blks) < 256:
		index_type = 'u8'
	else:
		index_type = 'u16'
	file.write(f'indices := [?]{index_type} {{')
	for i,idx in enumerate(indices):
		if i%16 == 0:
			file.write('\n\t')
		file.write(f'{idx:3}, ')
	file.write('\n}\n\n')

	
