/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef SPFX_H
#  define SPFX_H


#include "ntime.h"
#include "opengl.h"
#include "physics.h"


#define SPFX_LAYER_FRONT   0 /**< Front spfx layer. */
#define SPFX_LAYER_BACK    1 /**< Back spfx layer. */

#define SHAKE_DECAY        0.3 /**< Rumble decay parameter */
#define SHAKE_MAX          1.0 /**< Rumblemax parameter */


/**
 * @brief represents a set of colour for trails.
 */
typedef struct trailStyle_ {
   char* name;       /**< Colour set's name. */
   glColour idle_col;/**< Colour when idle. */
   glColour glow_col;/**< Colour when thrusting. */
   glColour aftb_col;/**< Colour when afterburning. */
   glColour jmpn_col;/**< Colour when jumping. */
   double thick;     /**< Thickness (in px). */
   double ttl;       /**< Time To Life (in seconds). */
} trailStyle;


typedef struct trailPoint_ {
   Vector2d p;    /**< Control points for the trail. */
   glColour c;   /**< Colour associated with the trail's control points. */
   double t; /**< Timer, normalized to the time to live of the trail (starts at 1, ends at 0). */
} trailPoint;


/**
 * @struct Trail_spfx
 *
 * @brief A trail generated by a ship or an ammo.
 */
typedef struct Trail_spfx_ {
   double ttl;       /**< Time To Life (in seconds). */
   double thickness; /**< Thickness of the trail. */
   trailPoint *point_ringbuf; /**< Circular buffer (malloced/freed) of trail points. */
   size_t capacity; /**< Buffer size, guaranteed to be a power of 2. */
   size_t iread; /**< Start index (NOT reduced modulo capacity). */
   size_t iwrite; /**< End index (NOT reduced modulo capacity). */
   int refcount;      /**< Number of referrers. If 0, trail dies after its TTL. */
} Trail_spfx;

/** @brief Indexes into a trail's circular buffer.  */
#define trail_at( trail, i ) ( (trail)->point_ringbuf[ (i) & ((trail)->capacity - 1) ] )
/** @brief Returns the number of elements of a trail's circular buffer.  */
#define trail_size( trail ) ( (trail)->iwrite - (trail)->iread )
/** @brief Returns the first element of a trail's circular buffer.  */
#define trail_front( trail ) trail_at( trail, (trail)->iread )
/** @brief Returns the last element of a trail's circular buffer.  */
#define trail_back( trail ) trail_at( trail, (trail)->iwrite-1 )


/*
 * stack manipulation
 */
int spfx_get( char* name );
const trailStyle* trailStyle_get( const char* name );
void spfx_add( const int effect,
      const double px, const double py,
      const double vx, const double vy,
      const int layer );


/*
 * stack mass manipulation functions
 */
void spfx_update( const double dt );
void spfx_render( const int layer );
void spfx_clear (void);
Trail_spfx* spfx_trail_create( const trailStyle* style );
void spfx_trail_sample( Trail_spfx* trail, Vector2d pos, glColour col  );
void spfx_trail_remove( Trail_spfx* trail );


/*
 * get ready to rumble
 */
void spfx_begin( const double dt, const double real_dt );
void spfx_end (void);
void spfx_shake( double mod );
void spfx_getShake( double *x, double *y );


/*
 * other effects
 */
void spfx_cinematic (void);


/*
 * spfx effect loading and freeing
 */
int spfx_load (void);
void spfx_free (void);


#endif /* SPFX_H */
