--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Discovery">
 <trigger>enter</trigger>
 <chance>100</chance>
</event>
--]]
--[[
-- Shows the player fancy messages as they discover things. Meant to be flavourful.
--]]

local fmt = require 'format'
local lg = require 'love.graphics'
local audio = require 'love.audio'
local love_math = require 'love.math'
local love_shaders = require 'love_shaders'
local transitions = require 'vn.transitions'

-- luacheck: globals discovered endevent heartbeat textfg textupdate (Hook functions passed by name)

-- These trigger at specific places
local system_events = {
   --[[
   -- Unique / Interesting systems
   --]]
   Sol = {
      type = "enter",
      name = "disc_sol",
      title = _("Sol"),
      subtitle = _("Home"),
   },
   ["Gamma Polaris"] = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Emperor's Wrath"):pos(),
      name = "disc_emperorswrath",
      title = _("Emperor's Wrath"),
      subtitle = _("Human Made Divine"),
   },
   ["Za'lek"] = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("House Za'lek Central Station"):pos(),
      name = "disc_zalekcentral",
      title = _("House Za'lek Central Station"),
      subtitle = _("Bastion of Knowledge"),
   },
   Ruadan = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Ruadan Prime"):pos(),
      name = "disc_zalekruadan",
      title = _("Ruadan Prime"),
      subtitle = _("New Heart of the Za'lek"),
   },
   Dvaer = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Dvaered High Command"):pos(),
      name = "disc_dvaeredhigh",
      title = _("Dvaered High Command"),
      subtitle = _("Convening of the Warlords"),
   },
   Feye = {
      type = "enter",
      name = "disc_kataka",
      title = _("Feye"),
      subtitle = _("Remembering Sorom"),
   },
   Aesir = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Mutris"):pos(),
      name = "disc_mutris",
      title = _("Crater City"),
      subtitle = _("Touching the Universe"),
   },
   Taiomi = {
      type = "enter",
      name = "disc_taiomi",
      title = _("Taiomi"),
      subtitle = _("Ship Graveyard"),
   },
   Limbo = {
      -- Discover will not work if the planet is found through maps
      --type = "discover",
      --asset = spob.get("Minerva Station"),
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Minerva Station"):pos(),
      name = "disc_minerva",
      title = _("Minerva Station"),
      subtitle = _("Gambler's Paradise"),
   },
   Beeklo = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("Totoran"):pos(),
      name = "disc_totoran",
      title = _("Totoran"),
      subtitle = _("Brave your Fate in the #rCrimson Gauntlet#0"),
   },
   Haven = {
      type = "enter",
      name = "disc_haven",
      title = _("The Devastation of Haven"),
      subtitle = _("The Old Wound That Never Heals"),
   },
   --[[
   -- Pirate Strongholds
   -- ]]
   ["New Haven"] = {
      type = "distance",
      dist = 5e3,
      pos  = spob.get("New Haven"):pos(),
      name = "disc_newhaven",
      title = _("New Haven"),
      subtitle = _("They Will Never Destroy Us"),
   },
   Kretogg = {
      type = "enter",
      name = "disc_kretogg",
      title = _("Kretogg"),
      subtitle = _("Any Business is Good Business"),
   },
}
-- These trigger for specific factions controlled systems
local faction_events = {
   ["Za'lek"] = {
      type = "enter",
      name = "disc_zalek",
      title = _("The Za'lek Territories"),
      subtitle = _("Knowledge at All Costs"),
   },
   Dvaered = {
      type = "enter",
      name = "disc_dvaered",
      title = _("The Dvaered Territories"),
      subtitle = _("The Warlords are Eager for Blood"),
   },
   Soromid = {
      type = "enter",
      name = "disc_soromid",
      title = _("The Soromid Territories"),
      subtitle = _("Human is Just an Ephemeral Condition"),
   },
   Sirius = {
      type = "enter",
      name = "disc_sirius",
      title = _("The Sirius Territories"),
      subtitle = _("Sirichana Will Lead the Way"),
   },
   Proteron = {
      type = "enter",
      name = "disc_proteron",
      title = _("The Proteron Territories"),
      subtitle = _("United through Sacrifice"),
      func = function() faction.get("Proteron"):setKnown( true ) end
   },
   Thurion = {
      type = "enter",
      name = "disc_thurion",
      title = _("The Thurion Space"),
      subtitle = _("We Shall All Become One"),
   },
   Frontier = {
      type = "enter",
      name = "disc_frontier",
      title = _("The Frontier"),
      subtitle = _("Leading to a New Future"),
      func = function() faction.get("FLF"):setKnown( true ) end
   },
   Collective = {
      type = "enter",
      name = "disc_collective",
      title = _("The Collective"),
      subtitle = _("Do Robots Dream of Electric Sheep?"),
      func = function() faction.get("Collective"):setKnown( true ) end
   },
}
-- Custom events can handle custom triggers such as nebula systems
local function test_systems( syslist )
   local n = system.cur():nameRaw()
   for k,v in ipairs(syslist) do
      if v==n then
         return true
      end
   end
   return false
end
local function pir_discovery( fname, disc, subtitle )
   return {
      test = function ()
         local p = system.cur():presences()[ fname ]
         return (p and p>0)
      end,
      type = "enter",
      name = disc,
      title = "#H"..fmt.f(_("{fname} Territory"),{fname=fname}).."#0",
      subtitle = "#H"..subtitle.."#0",
      func = function()
         local fpir = faction.get(fname)
         fpir:setKnown( true )
         for k,p in pilot.get( {fpir}, true ) do
            p:rename( p:ship():name() )
         end
      end,
   }
end

local custom_events = {
   Nebula = {
      test = function ()
         -- These are currently the only systems from which the player can
         -- enter the nebula
         local nsys = {
            "Thirty Stars",
            "Raelid",
            "Toaxis",
            "Myad",
            "Tormulex",
         }
         return test_systems( nsys )
      end,
      type = "enter",
      name = "disc_nebula",
      title = _("The Nebula"),
      subtitle = _("Grim Reminder of Our Fragility"),
   },
   NorthWinds = {
      test = function ()
         local nsys = {
            "Pilatis",
            "Defa",
            "Vedalus",
            "Titus",
            "New Haven",
            "Daled",
            "Mason",
         }
         return test_systems( nsys )
      end,
      type = "enter",
      name = "disc_northwinds",
      title = _("Northern Stellar Winds"),
      --subtitle = _("None"),
   },
   SouthWinds = {
      test = function ()
         local nsys = {
            "Kretogg",
            "Unicorn",
            "Volus",
            "Sheffield",
            "Gold",
            "Fried",
         }
         return test_systems( nsys )
      end,
      type = "enter",
      name = "disc_southwinds",
      title = _("Southern Stellar Winds"),
      --subtitle = _("None"),
   },
   BlackHole = {
      test = function ()
         return system.cur():background() == "blackhole"
      end,
      type = "enter",
      name = "disc_blackhole",
      title = _("Anubis Black Hole"),
      subtitle = _("Gaping Maw of the Abyss"),
   },
   WildOnes = pir_discovery( "Wild Ones", "disc_wildones", _("Uncontrolled and Raging Pirate Fury") ),
   RavenClan = pir_discovery( "Raven Clan", "disc_ravenclan", _("Dark Hand of the Black Market") ),
   BlackLotus = pir_discovery( "Black Lotus", "disc_blacklotus", _("Piracy has never been Snazzier") ),
   DreamerClan = pir_discovery( "Dreamer Clan", "disc_dreamerclan", _("Piracy to Rebel against Reality") ),
}

local discover_trigger, textinit -- function forward-declaration
local sfx, textcanvas, textshader, texttimer -- non-persistent state

local function sfxDiscovery()
   --sfx = audio.newSource( 'snd/sounds/jingles/success.ogg' )
   sfx = audio.newSource( 'snd/sounds/jingles/victory.ogg' )
   sfx:play()
end

local triggered = false
local function handle_event( event )
   -- Don't trigger if already done
   if var.peek( event.name ) then return false end

   -- Trigger
   if event.type=="enter" then
      if not triggered then
         discover_trigger( event )
         triggered = true
      end
   elseif event.type=="discover" then
      hook.discover( "discovered", event )
   elseif event.type=="distance" then
      hook.timer( 0.5, "heartbeat", event )
   end
   return true
end

local nw, nh
function create()
   nw, nh = gfx.dim()
   local sc = system.cur()
   local event = system_events[ sc:nameRaw() ]
   local hasevent = false
   if event then
      hasevent = hasevent or handle_event( event )
   end
   local sf = sc:faction()
   event = sf and faction_events[ sf:nameRaw() ] or false
   if event then
      hasevent = hasevent or handle_event( event )
   end
   for k,v in pairs(custom_events) do
      if not var.peek( v.name ) and v.test() then
         hasevent = hasevent or handle_event( v )
      end
   end

   -- Nothing triggered
   if not hasevent then
      endevent()
   end

   -- Ends when player lands or leaves either way
   hook.enter("endevent")
   hook.land("endevent")
end
function endevent () evt.finish() end
function discovered( type, discovery, event )
   if event.asset and type=="asset" and discovery==event.asset then
      discover_trigger( event )
   end
end
function heartbeat( event )
   local dist = player.pilot():pos():dist( event.pos )
   if dist < event.dist then
      discover_trigger( event )
   else
      hook.timer( 0.5, "heartbeat", event )
   end
end

function discover_trigger( event )
   local template = (event.subtitle and _("You found #o{title} - {subtitle}#0!")) or _("You found #o{title}#0!")
   local msg = fmt.f(template, event)
   -- Log and message
   player.msg( msg )
   shiplog.create( "discovery", _("Discovery"), _("Travel") )
   shiplog.append( "discovery", msg )

   -- Break autonav
   player.autonavReset( 3 )

   -- If custom function, run it
   if event.func then
      event.func()
   end

   -- Mark as done
   var.push( event.name, true )

   -- Play sound and show message
   sfxDiscovery()
   textinit( event.title, event.subtitle )
end

local text_fadein = 1.5
local text_fadeout = 1.5
local text_length = 10.0
function textinit( titletext, subtitletext )
   local title, subtitle
   --local fontname = _("fonts/CormorantUnicase-Medium.ttf")
   -- Title
   title = { text=titletext, h=48 }
   title.font = lg.newFont( title.h )
   --title.font = lg.newFont( fontname, title.h )
   title.font:setOutline(3)
   title.w = title.font:getWidth( title.text )
   -- Subtitle
   if subtitletext then
      subtitle = { text=subtitletext, h=32 }
      subtitle.font = lg.newFont( subtitle.h )
      --subtitle.font = lg.newFont( fontname, subtitle.h )
      subtitle.font:setOutline(2)
      subtitle.w = subtitle.font:getWidth( subtitle.text )
   end

   local oldcanvas = lg.getCanvas()
   local emptycanvas = lg.newCanvas()
   lg.setCanvas( emptycanvas )
   lg.clear( 0, 0, 0, 0 )
   lg.setCanvas( oldcanvas )

   -- TODO probably rewrite the shader as this is being computed with the full
   -- screen resolution, breaks with all transitions that use love_ScreenSize...
   textshader  = transitions.get( "perlin" )
   textshader:send( "texprev", emptycanvas )
   textshader._emptycanvas = emptycanvas
   texttimer   = 0

   -- Render to canvas
   local pixelcode = string.format([[
precision highp float;

#include "lib/simplex.glsl"

const float u_r = %f;
const float u_sharp = %f;

float vignette( vec2 uv )
{
   uv *= 1.0 - uv.yx;
   float vig = uv.x*uv.y * 15.0; // multiply with sth for intensity
   vig = pow(vig, 0.5); // change pow for modifying the extend of the  vignette
   return vig;
}

vec4 effect( vec4 color, Image tex, vec2 uv, vec2 px )
{
   vec4 texcolor = color * texture( tex, uv );

   float n = 0.0;
   for (float i=1.0; i<8.0; i=i+1.0) {
      float m = pow( 2.0, i );
      n += snoise( px * u_sharp * 0.003 * m + 1000.0 * u_r ) * (1.0 / m);
   }

   texcolor.a *= 0.4*n+0.8;
   texcolor.a *= vignette( uv );
   texcolor.rgb *= 0.0;

   return texcolor;
}
]], love_math.random(), 3 )
   local shader = lg.newShader( pixelcode, love_shaders.vertexcode )
   local w, h
   if subtitle then
      w = math.max( title.w, subtitle.w )*1.5
      h = (title.h * 1.5 + subtitle.h)*2
   else
      w = title.w*1.5
      h = title.h*2
   end
   textcanvas = love_shaders.shader2canvas( shader, w, h )

   lg.setCanvas( textcanvas )
   title.x = (w-title.w)/2
   title.y = h*0.2
   lg.print( title.text, title.font, title.x, title.y )
   if subtitle then
      subtitle.x = (w-subtitle.w)/2
      subtitle.y = title.y + title.h*1.5
      lg.print( subtitle.text, subtitle.font, subtitle.x, subtitle.y )
   end
   lg.setCanvas()

   hook.renderfg( "textfg" )
   hook.update( "textupdate" )
   --hook.timer( text_length*1.0, "endevent")
end
function textfg ()
   local progress
   if texttimer < text_fadein then
      progress = texttimer / text_fadein
   elseif texttimer > text_length-text_fadeout then
      progress = (text_length-texttimer) / text_fadeout
   end

   if progress then
      lg.setShader( textshader )
      textshader:send( "progress", progress )
   end

   lg.setColor( 1, 1, 1, 1 )

   local x = (nw-textcanvas.w)*0.5
   local y = (nh-textcanvas.h)*0.3
   x = math.floor(x)
   y = math.floor(y)
   lg.draw( textcanvas, x, y )
   if progress then
      lg.setShader()
   end
end
function textupdate( dt, _real_dt )
   -- We want to show it regardless of the time compression and such
   -- TODO Why is real_dt not equal to dt / player.dt_mod()? :/
   texttimer = texttimer + dt / player.dt_mod()
end
