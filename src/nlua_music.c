/*
 * See Licensing and Copyright notice in naev.h
 */
/**
 * @file nlua_music.c
 *
 * @brief Lua music playing module.
 */
/** @cond */
#include "SDL.h"

#include "naev.h"
/** @endcond */

#include "nlua_music.h"

#include "log.h"
#include "music.h"
#include "ndata.h"
#include "nluadef.h"

/* Music methods. */
static int musicL_choose( lua_State *L );
static int musicL_play( lua_State *L );
static int musicL_pause( lua_State *L );
static int musicL_stop( lua_State *L );
static int musicL_isPlaying( lua_State *L );
static int musicL_current( lua_State *L );
static int musicL_setRepeat( lua_State *L );
static int musicL_getVolume( lua_State *L );
static const luaL_Reg music_methods[] = {
   { "choose", musicL_choose },
   { "play", musicL_play },
   { "pause", musicL_pause },
   { "stop", musicL_stop },
   { "isPlaying", musicL_isPlaying },
   { "current", musicL_current },
   { "setRepeat", musicL_setRepeat },
   { "getVolume", musicL_getVolume },
   {0,0}
}; /**< Music specific methods. */

/**
 * @brief Music Lua module.
 *
 * Typical usage would be something like:
 * @code
 * music.load( "intro" ) -- Load the song
 * music.play() -- Play it
 * @endcode
 *
 * @luamod music
 */
/**
 * @brief Loads the music functions into a lua_State.
 *
 *    @param env Lua environment to load the music functions into.
 *    @return 0 on success.
 */
int nlua_loadMusic( nlua_env env )
{
   nlua_register(env, "music", music_methods, 0);
   return 0;
}

/**
 * @brief Delays a rechoose.
 *
 * @usage music.choose( "ambient" ) -- Rechooses ambient in 5 seconds
 *
 *    @luatparam string situation Situation to choose.
 * @luafunc choose
 */
static int musicL_choose( lua_State* L )
{
   const char *situation = luaL_checkstring(L,1);
   music_choose( situation );
   return 0;
}

/**
 * @brief Plays the loaded song.
 *
 * Restores the music system if it was temporarily disabled.
 *
 * @luafunc play
 */
static int musicL_play( lua_State *L )
{
   const char *str = luaL_optstring(L,1,NULL);
   music_tempDisable( 0 );
   music_play( str );
   return 0;
}

/**
 * @brief Pauses the music engine.
 */
static int musicL_pause( lua_State* L )
{
   (void) L;
   music_pause();
   return 0;
}

/**
 * @brief Stops playing the current song.
 *
 *    @luatparam[opt=false] boolean disable Whether or not to disable the music system temporarily after stopping.
 * @luafunc stop
 */
static int musicL_stop( lua_State *L )
{
   int disable = lua_toboolean(L,1);
   music_stop();
   music_tempDisable( disable );
   return 0;
}

/**
 * @brief Checks to see if something is playing.
 *
 *    @luatreturn boolean true if something is playing.
 * @luafunc isPlaying
 */
static int musicL_isPlaying( lua_State* L )
{
   MusicInfo_t *minfo = music_info();
   lua_pushboolean(L, minfo->playing);
   return 1;
}

/**
 * @brief Gets the name of the current playing song.
 *
 * @usage songname, songplayed = music.current()
 *
 *    @luatreturn string The name of the current playing song or "none" if no song is playing.
 *    @luatreturn number The current offset inside the song (0. if music is none).
 * @luafunc current
 */
static int musicL_current( lua_State* L )
{
   MusicInfo_t *minfo = music_info();
   lua_pushstring(L, minfo->name);
   lua_pushnumber(L, minfo->pos);
   return 2;
}

/**
 * @brief Makes the music repeat. This gets turned of when a new music is chosen, e.g., take-off or landing.
 *
 *    @luatparam boolean repeat Whether or not repeat should be set.
 * @luafunc setRepeat
 */
static int musicL_setRepeat( lua_State* L )
{
   int b = lua_toboolean(L,1);
   music_repeat( b );
   return 0;
}

/**
 * @brief Gets the volume level of the music.
 *
 *    @luatparam boolean log Whether or not to get the volume in log scale.
 *    @luatreturn number Volume level of the music.
 * @luafunc getVolume
 */
static int musicL_getVolume( lua_State *L )
{
   if (lua_toboolean(L,1))
      lua_pushnumber(L, music_getVolumeLog() );
   else
      lua_pushnumber(L, music_getVolume() );
   return 1;
}
