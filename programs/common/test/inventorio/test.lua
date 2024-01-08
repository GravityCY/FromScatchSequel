package.path = package.path .. ";/lib/?.lua"

local Pretty = require("cc.pretty");
local Inventorio = require("gravityio.Inventorio");
local Helper = require("gravityio.Helper");

local _def = Helper._def;
local _if = Helper._if;
local _gnil = Helper._gnil;

local a = Inventorio.get("left");
local b = Inventorio.get("right");

a.init();
b.init();

local ac = _def(_gnil(a.getAt(1), "count"), 0);
local bc = _def(_gnil(b.getAt(1), "count"), 0);

print("(A) Count At 1:", ac);
print("(B) Count At 1:", bc);

a.push(b, 1, 1, 1);

print("");

ac = _def(_gnil(a.getAt(1), "count"), 0);
bc = _def(_gnil(b.getAt(1), "count"), 0);

print("(A) Count At 1:", ac);
print("(B) Count At 1:", bc);