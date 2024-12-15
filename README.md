# Advent of Code 2024

![GitHub License](https://img.shields.io/github/license/WadeGulbrandsen/aoc2024?logo=github)
![GitHub top language](https://img.shields.io/github/languages/top/WadeGulbrandsen/aoc2024?logo=github)
![GitHub repo size](https://img.shields.io/github/repo-size/WadeGulbrandsen/aoc2024?logo=github)
![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/WadeGulbrandsen/aoc2024/.github/workflows/test.yml?logo=github&label=tests)

I'm doing [Advent of Code 2024](https://adventofcode.com/2024) in [Gleam](https://gleam.run/).

### Run time

The time each day's solutions take to run are available in [Times.md](./Times.md)


## Puzzle input

Puzzle input should be stored in the `./input` directory with file names formatted as `dayXX.txt` where XX is the two digit number of the day.

### Automatic download of puzzle input

If you don't want to manually download the data and copy it to the `input` directory it can be downloaded automatically if you have a `./input/session.txt` file that has your session cookie in it.

To get the session cookie:
1. Go to https://adventofcode.com/
1. If you are not logged in then log in
1. Right click and **Inspect** the page
1. Go to the **Network** tab
1. Refresh the page
1. Click `adventofcode.com` in the Name column
1. Go to the **Cookies** tab
1. Copy the value for the `session` cookie and paste it into `./input/session.txt`
