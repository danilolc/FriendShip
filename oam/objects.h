//AUTOGENERATED FILE FROM png2asset
#ifndef METASPRITE_objects_H
#define METASPRITE_objects_H

#include <stdint.h>
#include <gbdk/platform.h>
#include <gbdk/metasprites.h>

#define objects_TILE_ORIGIN 0
#define objects_TILE_W 8
#define objects_TILE_H 16
#define objects_WIDTH 24
#define objects_HEIGHT 32
#define objects_TILE_COUNT 32
#define objects_PALETTE_COUNT 1
#define objects_COLORS_PER_PALETTE 4
#define objects_TOTAL_COLORS 4
#define objects_PIVOT_X 12
#define objects_PIVOT_Y 16
#define objects_PIVOT_W 24
#define objects_PIVOT_H 32

BANKREF_EXTERN(objects)

extern const palette_color_t objects_palettes[4];
extern const uint8_t objects_tiles[512];

extern const metasprite_t* const objects_metasprites[4];

#endif