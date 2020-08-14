package common

import (
	"encoding/json"
	"time"
)

type Match struct {
	ID             string             `json:"-"`
	StartTime      string             `json:":time"`
	State          string             `json:":state"`
	Teams          [2]string          `json:":teams"`
	Strategy       Strategy           `json:":strat"`
	GameAlarms     interface{}        `json:"-"`
	GameTimestamps map[int]Timestamps `json:":gameTimestamps"`
}

type Strategy struct {
	Type  string `json:"type"`
	Count int    `json:"count"`
}

type Timestamps struct {
	ChampionSelectBegins time.Time `json:"-"`
	GameBegins           time.Time `json:"-"`
	FirstBlood           time.Time `json:"-"`
}

type Alarm struct {
	DeviceID   string      `json:"deviceID"`
	MatchID    string      `json:"-"`
	GameAlarms []GameAlarm `json:"-"`
}

type GameAlarm struct {
	GameNumber       int    `json:"-"`
	Trigger          string `json:"trigger"`
	Delay            int    `json:"delay"`
	HasBeenTriggered bool   `json:"hasBeenTriggered"`
}

func UnmarshalGameDetails(data []byte) (GameDetails, error) {
	var r GameDetails
	err := json.Unmarshal(data, &r)
	return r, err
}

type GameDetails struct {
	GameID     string  `json:"esportsGameId"`
	MatchID    string  `json:"esportsMatchId"`
	GameNumber string  `json:"gameNumber"`
	Matchup    string  `json:"matchup"`
	Frames     []Frame `json:"frames"`
}

type Frame struct {
	Rfc460Timestamp string    `json:"rfc460Timestamp"`
	GameState       GameState `json:"gameState"`
	BlueTeam        Team      `json:"blueTeam"`
	RedTeam         Team      `json:"redTeam"`
}

type Team struct {
	TotalGold  int64         `json:"totalGold"`
	Inhibitors int64         `json:"inhibitors"`
	Towers     int64         `json:"towers"`
	Barons     int64         `json:"barons"`
	TotalKills int64         `json:"totalKills"`
	Dragons    []interface{} `json:"dragons"`
}

type GameState string

const (
	InGame    GameState = "in_game"
	Paused    GameState = "paused"
	Completed GameState = "completed"
)
