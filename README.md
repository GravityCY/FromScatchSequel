# Bunch of CC:T Programs / Libraries

A bunch of low quality libraries for CC:T and programs.

# Libraries

## Common

### CMDL
A doodoo command library

### EasyAddress
Makes it easier to assign certain peripherals as an address. <br>
For example: `EasyAddress.new("namespace").get("input_barrel")` will ensure that `input_barrel` is either loaded from disk or if doesn't exist, will ask the user to select it physically (uses peripheral events).

### Files
A library for handling some file utilities.

### Graphics
A library for handling some graphics utilities.

### Helper
A bunch of repeatedly used code that I seem to use.

### Inventorio
A library to create Inventorio objects around inventory peripherals, and providing alot of useful functions
like inventory caching, tries to update the cache based on `push` calls and `pull` calls (WIP)

### Inventoreez
A library for conglomerating a bunch of inventories to appear as one cohesive big inventory

### Language
A library for handling language translation, using identifiers `minecraft:block.stone` for example

### Logger
A library that provides a simple logger

### Path
A library for handling paths, as objects, joining paths, getting file names, file extensions, directories etc.

### Peripherelia
A library to attach some extra data to peripheral objects, like an `Address` objects that has more info about the address, like index, type, namespace etc.

## Turtle

### TurtyBoy
A library for making the turtle nice to use, like position tracking, rotation tracking, listing items etc...

# Programs

## Common

### Smelter
A program to smelt a bunch of items.

### Speed
A program to estimate player speed, by setting up 2 pressure plates.

## Turtle

### Mine
A program to make a turtle mine a given area. (Only works for X/Z)

## Pocket

### Timer
A program to simply time something, like a countdown from 300 seconds for example.