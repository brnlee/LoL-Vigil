package common

import "encoding/json"

type Alarm struct {
	DeviceID   string      `json:"deviceID"`
	MatchID    string      `json:"-"`
	GameAlarms []GameAlarm `json:"-"`
}

type GameAlarm struct {
	GameNumber int    `json:"-"`
	Trigger    string `json:"trigger"`
	Delay      int    `json:"delay"`
}

func UnmarshalGameDetails(data []byte) (GameDetails, error) {
	var r GameDetails
	err := json.Unmarshal(data, &r)
	return r, err
}

func (r *GameDetails) MarshalGameDetails() ([]byte, error) {
	return json.Marshal(r)
}

type GameDetails struct {
	EsportsGameID  string  `json:"esportsGameId"`
	EsportsMatchID string  `json:"esportsMatchId"`
	Frames         []Frame `json:"frames"`
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
