package server

import (
	"fmt"
	"log"
)

var statChannel chan state

type commonPattern struct {
	Pattern string
	Count int
}

type statistics struct {
	Usage state
	Patterns []commonPattern
}

func Test() {
	initLoop()
	opt.evaluated = []string{
		"c",
		"d",
		"a",
		"b",
		"c",
		"d",
		"b",
		"e",
		"c",
		"d",
		"a",
		"b",
	}

	patterns := getPatterns()
	fmt.Print(patterns)
}

func countPatterns(patterns []commonPattern) []commonPattern {
	counted := make([]commonPattern, 0)
	for i := range patterns {
		count := 1
		for j := range patterns {
			if patterns[i].Pattern == patterns[j].Pattern {
				if j > i {
					count++
				} else if j < i {
					count = -1
					break
				}
			}
		}
		if count > 0 {
			counted = append(counted, commonPattern{
				Pattern: patterns[i].Pattern,
				Count: count,
			})
		}
	}

	return counted
}

func getPatterns() []commonPattern {
	patterns := make([]commonPattern, 0)
	for k := 1; k < len(opt.evaluated) - 1; k++{
	path := ""
	length := 0
		for j := 0; j < len(opt.evaluated) - k; j++{
			if opt.evaluated[j] == opt.evaluated[j + k] {
				path += opt.evaluated[j] + "\n"
				length++
			} else if length > 1 {
				patterns = append(patterns, commonPattern{
					Pattern: path,
					Count:   1,
				})
				path = ""
				length = 0
			} else {
				path = ""
				length = 0
			}
		}
		if length > 1 {
			patterns = append(patterns, commonPattern{
				Pattern: path,
				Count:   1,
			})
		}
	}

	opt.evaluated = opt.evaluated[:0]
	sendCommand(command{Cmd: "clearStats"})

	return countPatterns(patterns)
}

func gatherStatistics() {
	if statChannel == nil {
		statChannel = make(chan state)
	}

	sendCommand(command{Cmd: "getStats"})
	usage := <- statChannel
	stats := statistics{
		Usage: usage,
		Patterns: getPatterns(),
	}
	emitClient("updateStats", stats)
	log.Println("Updating Statistics")
}