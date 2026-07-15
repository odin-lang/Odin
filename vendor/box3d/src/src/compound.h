// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/types.h"

b3TOIOutput b3CompoundTimeOfImpact( const b3CompoundData* compound, b3Transform transform, const b3ShapeProxy* proxy,
									const b3Sweep* sweep, float maxFraction );

// Transforms a sweep for a compound child shape
b3Sweep b3MakeCompoundChildSweep( b3Transform compoundTransform, b3Transform childTransform );

int b3CollideMoverAndCompound( b3PlaneResult* planes, int capacity, const b3CompoundData* shape, const b3Capsule* mover );
