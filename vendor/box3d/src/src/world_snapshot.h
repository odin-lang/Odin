// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "recording.h"
#include "recording_replay.h"

#include <stdbool.h>
#include <stdint.h>

typedef struct b3World b3World;

// Serialize the live world into buf, interning shape geometry into rec->registry.
// On success buf holds a self-contained snapshot image. Returns the byte count.
int b3SerializeWorld( b3World* world, b3RecBuffer* buf, b3Recording* rec );

// Overwrite a freshly-created (shell) world with the simulation state held in the
// snapshot image [data, size). Geometry references are resolved via the shared
// registry slots in rdr. Returns false on a corrupt or incompatible image.
bool b3DeserializeIntoShell( const uint8_t* data, int size, b3World* world, b3RecReader* rdr );
