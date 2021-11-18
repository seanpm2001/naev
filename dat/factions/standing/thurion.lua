-- Thurion faction standing script
require "factions.standing.lib.base"

_fcap_kill       = 10 -- Kill cap
_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill     = {-5, 1} -- Maximum change constraints
_fcap_misn       = 30 -- Starting mission cap, gets overwritten
_fcap_misn_var   = "_fcap_thurion" -- Mission variable to use for limits
_fthis         = faction.get("Thurion")
